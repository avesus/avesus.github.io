// SPDX-License-Identifier: MIT
// General IEEE 802.11 long-preamble 1 Mb/s DSSS PSDU transmitter.
//
// C++ writes a complete PSDU, including its FCS, into the frame memory and
// commits the byte count.  This block adds PLCP, scrambling, DBPSK, and the
// 11-chip Barker sequence.  It emits one rectangular complex sample per
// 20 MS/s DAC tick and stores no I/Q waveform.

`timescale 1ns/1ps

module gf_dsss_1mbps_psdu_tx #(
    parameter integer IQ_WIDTH = 32,
    parameter integer AMPLITUDE = 8192,
    parameter integer RF_LEAD_CYCLES = 80
) (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    arm,
    input  wire                    kill,

    input  wire                    frame_commit,
    input  wire [11:0]             frame_length_bytes,
    output reg  [11:0]             frame_read_address,
    input  wire [7:0]              frame_read_data,

    input  wire                    tx_channel_available,
    input  wire                    tx_sample_tick,
    input  wire                    tx_sink_ready,
    output wire                    ready,
    output wire                    busy,
    output wire                    tx_rf_claim,
    output wire                    tx_valid,
    output wire [IQ_WIDTH-1:0]     tx_iq,
    output reg                     frame_done,
    output reg                     frame_error
);
    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_PRELOAD = 2'd1;
    localparam [1:0] STATE_LEAD = 2'd2;
    localparam [1:0] STATE_ACTIVE = 2'd3;
    localparam integer LEAD_WIDTH =
        RF_LEAD_CYCLES < 2 ? 1 : $clog2(RF_LEAD_CYCLES + 1);
    localparam signed [15:0] AMP = AMPLITUDE;

    initial begin
        if (IQ_WIDTH != 32)
            $error("gf_dsss_1mbps_psdu_tx requires IQ16 packed as 32 bits");
        if (AMPLITUDE < 1 || AMPLITUDE > 32767)
            $error("AMPLITUDE must fit positive signed IQ16");
        if (RF_LEAD_CYCLES < 1)
            $error("RF_LEAD_CYCLES must be positive");
    end

    reg [1:0] state = STATE_IDLE;
    reg [11:0] length_bytes = 12'd0;
    reg [15:0] plcp_duration_us = 16'd0;
    reg [15:0] plcp_crc = 16'd0;
    reg [19:0] samples_remaining = 20'd0;
    reg [LEAD_WIDTH-1:0] lead_cycles = {LEAD_WIDTH{1'b0}};

    reg [15:0] bit_index = 16'd0;
    reg [3:0] barker_index = 4'd0;
    reg [4:0] sample_phase = 5'd0;
    reg [6:0] scrambler_state = 7'h3b;
    reg carrier_negative = 1'b1;
    reg [11:0] current_psdu_byte_index = 12'd0;
    reg [7:0] current_psdu_byte = 8'd0;

    function automatic [15:0] crc16_plcp_for_duration;
        input [15:0] duration_us;
        integer byte_number;
        integer bit_number;
        reg [7:0] value;
        reg mix;
        reg [15:0] crc;
        begin
            crc = 16'hffff;
            for (byte_number = 0; byte_number < 4;
                 byte_number = byte_number + 1) begin
                case (byte_number)
                    0: value = 8'h0a;
                    1: value = 8'h00;
                    2: value = duration_us[7:0];
                    default: value = duration_us[15:8];
                endcase
                for (bit_number = 0; bit_number < 8;
                     bit_number = bit_number + 1) begin
                    mix = crc[0] ^ value[bit_number];
                    crc = crc >> 1;
                    if (mix)
                        crc = crc ^ 16'h8408;
                end
            end
            crc16_plcp_for_duration = crc ^ 16'hffff;
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

    function automatic plain_bit_at;
        input [15:0] requested_bit;
        input [15:0] duration_us;
        input [15:0] header_crc;
        input [11:0] current_byte_index;
        input [7:0] current_byte;
        input [7:0] prefetched_byte;
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
                    0: value = 8'h0a;
                    1: value = 8'h00;
                    2: value = duration_us[7:0];
                    3: value = duration_us[15:8];
                    4: value = header_crc[7:0];
                    5: value = header_crc[15:8];
                    default: value = 8'h00;
                endcase
                plain_bit_at = value[bit_number];
            end else begin
                offset = requested_bit - 192;
                byte_number = offset >> 3;
                bit_number = offset & 7;
                if (byte_number == current_byte_index)
                    value = current_byte;
                else if (byte_number == current_byte_index + 1)
                    value = prefetched_byte;
                else
                    value = 8'h00;
                plain_bit_at = value[bit_number];
            end
        end
    endfunction

    reg [15:0] next_bit_index;
    reg [3:0] next_barker_index;
    reg [4:0] next_sample_phase;
    reg [6:0] next_scrambler_state;
    reg next_carrier_negative;
    reg following_plain_bit;
    reg following_scrambled_bit;
    reg [5:0] phase_sum;
    reg advances_bit;

    always @* begin
        next_bit_index = bit_index;
        next_barker_index = barker_index;
        next_sample_phase = sample_phase + 5'd11;
        next_scrambler_state = scrambler_state;
        next_carrier_negative = carrier_negative;
        following_plain_bit = 1'b0;
        following_scrambled_bit = 1'b0;
        phase_sum = sample_phase + 5'd11;
        advances_bit = 1'b0;

        if (phase_sum >= 20) begin
            next_sample_phase = phase_sum - 20;
            if (barker_index < 10) begin
                next_barker_index = barker_index + 1'b1;
            end else begin
                next_barker_index = 4'd0;
                next_bit_index = bit_index + 1'b1;
                advances_bit = 1'b1;
                following_plain_bit = plain_bit_at(
                    bit_index + 1'b1,
                    plcp_duration_us,
                    plcp_crc,
                    current_psdu_byte_index,
                    current_psdu_byte,
                    frame_read_data);
                following_scrambled_bit = following_plain_bit ^
                    scrambler_state[3] ^ scrambler_state[6];
                next_scrambler_state =
                    {scrambler_state[5:0], following_scrambled_bit};
                if (following_scrambled_bit)
                    next_carrier_negative = ~carrier_negative;
            end
        end
    end

    wire chip_negative =
        carrier_negative ^ barker_negative(barker_index);
    wire signed [15:0] output_i = chip_negative ? -AMP : AMP;

    assign ready = state == STATE_IDLE && arm && !kill;
    assign busy = state != STATE_IDLE;
    assign tx_rf_claim =
        state == STATE_ACTIVE ||
        (state == STATE_LEAD && tx_channel_available);
    assign tx_valid = state == STATE_ACTIVE && arm && !kill;
    assign tx_iq = {16'h0000, output_i};

    wire [15:0] committed_duration = {frame_length_bytes, 3'b000};
    wire [15:0] committed_bits =
        16'd192 + {frame_length_bytes, 3'b000};
    wire [19:0] committed_samples =
        ({4'd0, committed_bits} << 4) +
        ({4'd0, committed_bits} << 2);

    always @(posedge clk) begin
        if (!resetn) begin
            state <= STATE_IDLE;
            length_bytes <= 12'd0;
            plcp_duration_us <= 16'd0;
            plcp_crc <= 16'd0;
            samples_remaining <= 20'd0;
            lead_cycles <= {LEAD_WIDTH{1'b0}};
            frame_read_address <= 12'd0;
            bit_index <= 16'd0;
            barker_index <= 4'd0;
            sample_phase <= 5'd0;
            scrambler_state <= 7'h3b;
            carrier_negative <= 1'b1;
            current_psdu_byte_index <= 12'd0;
            current_psdu_byte <= 8'd0;
            frame_done <= 1'b0;
            frame_error <= 1'b0;
        end else begin
            frame_done <= 1'b0;
            frame_error <= 1'b0;

            if (kill || !arm) begin
                if (state != STATE_IDLE)
                    frame_error <= 1'b1;
                state <= STATE_IDLE;
            end else begin
                case (state)
                    STATE_IDLE: begin
                        if (frame_commit) begin
                            if (frame_length_bytes == 0) begin
                                frame_error <= 1'b1;
                            end else begin
                                length_bytes <= frame_length_bytes;
                                plcp_duration_us <= committed_duration;
                                plcp_crc <= crc16_plcp_for_duration(
                                    committed_duration);
                                samples_remaining <= committed_samples;
                                frame_read_address <= 12'd0;
                                current_psdu_byte_index <= 12'd0;
                                state <= STATE_PRELOAD;
                            end
                        end
                    end

                    STATE_PRELOAD: begin
                        current_psdu_byte <= frame_read_data;
                        frame_read_address <=
                            length_bytes > 1 ? 12'd1 : 12'd0;
                        lead_cycles <= RF_LEAD_CYCLES[LEAD_WIDTH-1:0];
                        bit_index <= 16'd0;
                        barker_index <= 4'd0;
                        sample_phase <= 5'd0;
                        // The first plain sync bit produces transmitted one
                        // from seed 0x5d, so carrier and state begin after it.
                        scrambler_state <= 7'h3b;
                        carrier_negative <= 1'b1;
                        state <= STATE_LEAD;
                    end

                    STATE_LEAD: begin
                        if (!tx_channel_available) begin
                            lead_cycles <= RF_LEAD_CYCLES[LEAD_WIDTH-1:0];
                        end else if (lead_cycles != 0) begin
                            lead_cycles <= lead_cycles - 1'b1;
                        end else if (tx_sample_tick && tx_sink_ready) begin
                            state <= STATE_ACTIVE;
                        end
                    end

                    STATE_ACTIVE: begin
                        if (tx_sample_tick) begin
                            if (!tx_sink_ready) begin
                                state <= STATE_IDLE;
                                frame_error <= 1'b1;
                            end else if (samples_remaining <= 1) begin
                                state <= STATE_IDLE;
                                samples_remaining <= 20'd0;
                                frame_done <= 1'b1;
                            end else begin
                                samples_remaining <= samples_remaining - 1'b1;
                                bit_index <= next_bit_index;
                                barker_index <= next_barker_index;
                                sample_phase <= next_sample_phase;
                                scrambler_state <= next_scrambler_state;
                                carrier_negative <= next_carrier_negative;

                                if (advances_bit &&
                                    next_bit_index >= 192 &&
                                    ((next_bit_index - 192) & 16'h0007) == 0 &&
                                    next_bit_index != 192) begin
                                    current_psdu_byte <= frame_read_data;
                                    current_psdu_byte_index <=
                                        (next_bit_index - 192) >> 3;
                                    if (((next_bit_index - 192) >> 3) + 1 <
                                        length_bytes)
                                        frame_read_address <=
                                            ((next_bit_index - 192) >> 3) + 1;
                                end
                            end
                        end
                    end

                    default: begin
                        state <= STATE_IDLE;
                        frame_error <= 1'b1;
                    end
                endcase
            end
        end
    end
endmodule
