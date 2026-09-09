// Compact IEEE 802.11 1 Mb/s long-preamble ACK/CTS formatter.
//
// This block stores no I/Q waveform. It formats the 14-byte control PSDU,
// computes its FCS, scrambles the complete PPDU, applies DBPSK and the
// 11-chip Barker sequence, and uses a 11/20 fractional chip clock to emit
// 6,080 complex samples at 20 MS/s. The initial implementation deliberately
// uses rectangular chip pulses; retained-I/Q testing decides the pulse-shaping
// refinement before this path is connected to Pluto's AD9361 TX datapath.

`timescale 1ns/1ps

module gf_dsss_1mbps_control_tx #(
    parameter integer IQ_WIDTH = 32,
    parameter integer AMPLITUDE = 8192,
    parameter integer COUNT_WIDTH = 32,
    parameter integer SERIAL_CONTROL_CRC = 0
) (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    arm,
    input  wire                    kill,

    input  wire                    response_prepare,
    input  wire                    response_start,
    input  wire                    response_is_cts,
    input  wire [15:0]             response_duration_us,
    input  wire [47:0]             response_station_mac,

    // tx_sample_tick is the AD9361 DAC sample-rate strobe. The formatter
    // holds state on intervening fabric clocks and advances only when a sample
    // is consumed. tx_sink_ready is an independent mux/backpressure gate.
    input  wire                    tx_sample_tick,
    input  wire                    tx_sink_ready,
    output wire                    response_path_ready,
    output wire                    response_active,
    output wire                    tx_override_valid,
    output wire [IQ_WIDTH-1:0]     tx_override_iq,
    output reg                     response_done,
    output reg                     stream_abort,
    output reg [COUNT_WIDTH-1:0]   stream_abort_count
);

    localparam integer PPDU_BITS = 304;
    localparam integer BARKER_CHIPS = 11;
    localparam integer PPDU_CHIPS = PPDU_BITS * BARKER_CHIPS;
    localparam integer SAMPLE_TICKS = 20;
    localparam integer CHIP_TICKS = 11;
    localparam integer PPDU_SAMPLES =
        (PPDU_CHIPS * SAMPLE_TICKS) / CHIP_TICKS;
    localparam integer SAMPLE_INDEX_WIDTH = $clog2(PPDU_SAMPLES);
    localparam signed [15:0] AMP = AMPLITUDE;

    reg prepared;
    reg active;
    reg start_pending;
    reg frame_is_cts;
    reg [15:0] frame_duration_us;
    reg [47:0] frame_station_mac;
    wire [31:0] frame_fcs;

    reg [8:0] bit_index;
    reg [3:0] barker_index;
    reg [4:0] sample_phase;
    reg [6:0] scrambler_state;
    reg carrier_negative;
    reg [SAMPLE_INDEX_WIDTH-1:0] sample_index;

    reg [8:0] next_bit_index;
    reg [3:0] next_barker_index;
    reg [4:0] next_sample_phase;
    reg [6:0] next_scrambler_state;
    reg next_carrier_negative;
    reg following_plain_bit;
    reg following_scrambled_bit;
    reg [5:0] phase_sum;

    initial begin
        if (IQ_WIDTH != 32)
            $error("The compact DSSS formatter requires 16-bit I and Q");
        if (PPDU_SAMPLES != 6080)
            $error("Unexpected 1 Mb/s ACK/CTS sample count");
        if (AMPLITUDE < 1 || AMPLITUDE > 32767)
            $error("AMPLITUDE must fit positive signed IQ16");
    end

    function automatic [7:0] control_prefix_byte;
        input integer byte_number;
        input is_cts;
        input [15:0] duration_us;
        input [47:0] station_mac;
        begin
            case (byte_number)
                0: control_prefix_byte = is_cts ? 8'hc4 : 8'hd4;
                1: control_prefix_byte = 8'h00;
                2: control_prefix_byte = is_cts ? duration_us[7:0] : 8'h00;
                3: control_prefix_byte = is_cts ? duration_us[15:8] : 8'h00;
                4: control_prefix_byte = station_mac[47:40];
                5: control_prefix_byte = station_mac[39:32];
                6: control_prefix_byte = station_mac[31:24];
                7: control_prefix_byte = station_mac[23:16];
                8: control_prefix_byte = station_mac[15:8];
                9: control_prefix_byte = station_mac[7:0];
                default: control_prefix_byte = 8'h00;
            endcase
        end
    endfunction

    function automatic [31:0] control_crc32;
        input is_cts;
        input [15:0] duration_us;
        input [47:0] station_mac;
        integer byte_number;
        integer crc_bit;
        reg [7:0] value;
        reg [31:0] crc;
        begin
            crc = 32'hffff_ffff;
            for (byte_number = 0; byte_number < 10;
                 byte_number = byte_number + 1) begin
                value = control_prefix_byte(byte_number, is_cts,
                                            duration_us, station_mac);
                crc = crc ^ value;
                for (crc_bit = 0; crc_bit < 8; crc_bit = crc_bit + 1) begin
                    if (crc[0])
                        crc = (crc >> 1) ^ 32'hedb8_8320;
                    else
                        crc = crc >> 1;
                end
            end
            control_crc32 = ~crc;
        end
    endfunction

    function automatic plain_bit_at;
        input [8:0] requested_bit;
        input is_cts;
        input [15:0] duration_us;
        input [47:0] station_mac;
        input [31:0] fcs;
        integer offset;
        integer byte_number;
        integer bit_number;
        reg [7:0] value;
        reg [15:0] sfd;
        begin
            value = 8'h00;
            sfd = 16'hf3a0;
            if (requested_bit < 128) begin
                plain_bit_at = 1'b1;
            end else if (requested_bit < 144) begin
                plain_bit_at = sfd[requested_bit - 128];
            end else if (requested_bit < 192) begin
                offset = requested_bit - 144;
                byte_number = offset >> 3;
                bit_number = offset & 7;
                case (byte_number)
                    0: value = 8'h0a; // 1 Mb/s SIGNAL.
                    1: value = 8'h00; // SERVICE.
                    2: value = 8'h70; // 14 bytes * 8 us.
                    3: value = 8'h00;
                    4: value = 8'hb4; // CRC-16 of 0a 00 70 00.
                    5: value = 8'hd0;
                    default: value = 8'h00;
                endcase
                plain_bit_at = value[bit_number];
            end else begin
                offset = requested_bit - 192;
                byte_number = offset >> 3;
                bit_number = offset & 7;
                if (byte_number < 10)
                    value = control_prefix_byte(byte_number, is_cts,
                                                duration_us, station_mac);
                else begin
                    case (byte_number)
                        10: value = fcs[7:0];
                        11: value = fcs[15:8];
                        12: value = fcs[23:16];
                        13: value = fcs[31:24];
                        default: value = 8'h00;
                    endcase
                end
                plain_bit_at = value[bit_number];
            end
        end
    endfunction

    function automatic barker_negative;
        input [3:0] index;
        begin
            case (index)
                1, 4, 8, 9, 10: barker_negative = 1'b1;
                default: barker_negative = 1'b0;
            endcase
        end
    endfunction

    // The SIFS scheduler runs on the fabric clock, while DAC samples may be a
    // sparse clock-enable in that domain.  Accept the deadline command on any
    // fabric cycle and hold it until the exact next DAC sample boundary.
    wire launch = (response_start || start_pending) && prepared && !active &&
                  tx_sample_tick && tx_sink_ready && arm && !kill;
    wire chip_negative =
        carrier_negative ^ barker_negative(barker_index);
    wire signed [15:0] output_i = chip_negative ? -AMP : AMP;
    wire signed [15:0] first_output_i = -AMP;

    assign response_path_ready = prepared && !active && !start_pending &&
                                 tx_sink_ready && arm && !kill;
    assign response_active = active || start_pending || launch;
    assign tx_override_valid = arm && !kill && (launch || active);
    assign tx_override_iq = launch
        ? {16'h0000, first_output_i}
        : {16'h0000, output_i};

    // A header bit enters the transmitter once per 20 DAC samples. Advance
    // the FCS over that same plain bit; it is not needed until bit 272.
    // The registered feedback tree commits in five clocks, well before the
    // next bit at either 20 or 40 fabric clocks/symbol. First-sample timing,
    // preparation readiness and every emitted sample remain unchanged.
    wire crc_header_bit = active && tx_sample_tick && tx_sink_ready &&
        phase_sum >= SAMPLE_TICKS && barker_index == BARKER_CHIPS-1 &&
        bit_index >= 191 && bit_index < 271 && !response_prepare;
    generate if (SERIAL_CONTROL_CRC) begin : g_serial_control_crc
        gf_control_crc_bitserial crc (
            .clk(clk),.clear(!resetn || !arm || kill || response_prepare),
            .bit_valid(crc_header_bit),.data_bit(following_plain_bit),.fcs(frame_fcs)
        );
    end else begin : g_parallel_control_crc
        reg [31:0] prepared_fcs;
        always @(posedge clk) begin
            if (!resetn) prepared_fcs <= 32'd0;
            else if (arm && !kill && response_prepare)
                prepared_fcs <= control_crc32(response_is_cts,
                    response_duration_us,response_station_mac);
        end
        assign frame_fcs = prepared_fcs;
    end endgenerate

    always @* begin
        next_bit_index = bit_index;
        next_barker_index = barker_index;
        next_sample_phase = sample_phase + CHIP_TICKS;
        next_scrambler_state = scrambler_state;
        next_carrier_negative = carrier_negative;
        following_plain_bit = 1'b0;
        following_scrambled_bit = 1'b0;
        phase_sum = sample_phase + CHIP_TICKS;

        if (phase_sum >= SAMPLE_TICKS) begin
            next_sample_phase = phase_sum - SAMPLE_TICKS;
            if (barker_index < BARKER_CHIPS - 1) begin
                next_barker_index = barker_index + 1'b1;
            end else begin
                next_barker_index = 4'd0;
                next_bit_index = bit_index + 1'b1;
                following_plain_bit = plain_bit_at(
                    bit_index + 1'b1, frame_is_cts, frame_duration_us,
                    frame_station_mac, frame_fcs);
                following_scrambled_bit = following_plain_bit ^
                    scrambler_state[3] ^ scrambler_state[6];
                next_scrambler_state =
                    {scrambler_state[5:0], following_scrambled_bit};
                if (following_scrambled_bit)
                    next_carrier_negative = ~carrier_negative;
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            prepared <= 1'b0;
            active <= 1'b0;
            start_pending <= 1'b0;
            frame_is_cts <= 1'b0;
            frame_duration_us <= 16'd0;
            frame_station_mac <= 48'd0;
            bit_index <= 9'd0;
            barker_index <= 4'd0;
            sample_phase <= 5'd0;
            // Plain sync bit zero scrambles to one from seed 0x5d.
            scrambler_state <= 7'h3b;
            carrier_negative <= 1'b1;
            sample_index <= {SAMPLE_INDEX_WIDTH{1'b0}};
            response_done <= 1'b0;
            stream_abort <= 1'b0;
            stream_abort_count <= {COUNT_WIDTH{1'b0}};
        end else begin
            response_done <= 1'b0;
            stream_abort <= 1'b0;

            if (kill || !arm) begin
                prepared <= 1'b0;
                active <= 1'b0;
                start_pending <= 1'b0;
            end else begin
                if (response_prepare) begin
                    prepared <= 1'b1;
                    active <= 1'b0;
                    start_pending <= 1'b0;
                    frame_is_cts <= response_is_cts;
                    frame_duration_us <= response_duration_us;
                    frame_station_mac <= response_station_mac;
                    bit_index <= 9'd0;
                    barker_index <= 4'd0;
                    sample_phase <= 5'd0;
                    scrambler_state <= 7'h3b;
                    carrier_negative <= 1'b1;
                    sample_index <= {SAMPLE_INDEX_WIDTH{1'b0}};
                end

                if (response_start && !response_path_ready) begin
                    prepared <= 1'b0;
                    active <= 1'b0;
                    start_pending <= 1'b0;
                    stream_abort <= 1'b1;
                    stream_abort_count <= stream_abort_count + 1'b1;
                end else if (response_start && !tx_sample_tick) begin
                    start_pending <= 1'b1;
                end else if (launch) begin
                    prepared <= 1'b0;
                    active <= 1'b1;
                    start_pending <= 1'b0;
                    sample_index <= {{(SAMPLE_INDEX_WIDTH-1){1'b0}}, 1'b1};
                    bit_index <= next_bit_index;
                    barker_index <= next_barker_index;
                    sample_phase <= next_sample_phase;
                    scrambler_state <= next_scrambler_state;
                    carrier_negative <= next_carrier_negative;
                end else if (start_pending && tx_sample_tick) begin
                    // A sink stall at the one legal launch boundary is fatal;
                    // never slide an ACK/CTS to a later sample.
                    if (!tx_sink_ready) begin
                        prepared <= 1'b0;
                        active <= 1'b0;
                        start_pending <= 1'b0;
                        stream_abort <= 1'b1;
                        stream_abort_count <= stream_abort_count + 1'b1;
                    end
                end else if (active && tx_sample_tick) begin
                    if (!tx_sink_ready) begin
                        active <= 1'b0;
                        stream_abort <= 1'b1;
                        stream_abort_count <= stream_abort_count + 1'b1;
                    end else if (sample_index + 1 >= PPDU_SAMPLES) begin
                        active <= 1'b0;
                        response_done <= 1'b1;
                    end else begin
                        sample_index <= sample_index + 1'b1;
                        bit_index <= next_bit_index;
                        barker_index <= next_barker_index;
                        sample_phase <= next_sample_phase;
                        scrambler_state <= next_scrambler_state;
                        carrier_negative <= next_carrier_negative;
                    end
                end
            end
        end
    end

endmodule

// Reflected CRC-32, one input bit at a time. Store the complemented CRC so
// reset-to-zero represents the all-ones seed and the output is directly FCS.
// Reuse the Greenforest registered binary duplication trees: no feedback or
// bit-valid leaf drives more than two CRC-state bits. Minimum input interval
// is six clocks; the formatter supplies at least twenty. Clear discards all
// in-flight bits and wins over a pending state update.
module gf_control_crc_bitserial (
    input wire clk,clear,bit_valid,data_bit,
    output wire [31:0] fcs
);
    localparam [31:0] POLYNOMIAL=32'hedb88320;
    wire [15:0] feedback_leaf,valid_leaf;
    gf_serial_fanout #(.N(16)) feedback_tree (
        .clk(clk),.reset(clear),.bit_in((~fcs[0]) ^ data_bit),.leaves(feedback_leaf)
    );
    gf_serial_fanout #(.N(16)) valid_tree (
        .clk(clk),.reset(clear),.bit_in(bit_valid),.leaves(valid_leaf)
    );
    generate for(genvar bit_number=0;bit_number<32;bit_number=bit_number+1) begin : g_bit
        wire state;
        wire shifted;
        if(bit_number==31) assign shifted=1'b1;
        else assign shifted=fcs[bit_number+1];
        wire next_state=shifted ^ (POLYNOMIAL[bit_number] && feedback_leaf[bit_number/2]);
`ifdef SYNTHESIS
        // Keep enable in the flip-flop, not an inferred Q-feedback hold mux:
        // Q then drives only its successor/feedback and the output consumer.
        (* DONT_TOUCH = "true" *) FDCE #(.INIT(1'b0)) state_reg (
            .C(clk),.CE(valid_leaf[bit_number/2]),.CLR(clear),.D(next_state),.Q(state)
        );
`else
        reg state_model;
        always @(posedge clk or posedge clear) begin
            if(clear) state_model<=1'b0;
            else if(valid_leaf[bit_number/2])
                state_model<=next_state;
        end
        assign state=state_model;
`endif
        assign fcs[bit_number]=state;
    end endgenerate
endmodule
