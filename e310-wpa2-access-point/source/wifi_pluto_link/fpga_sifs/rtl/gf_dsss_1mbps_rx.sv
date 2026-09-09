// Streaming IEEE 802.11 long-preamble 1 Mb/s DSSS receiver.
//
// This is the narrow RX PHY needed by the hard-real-time ACK/CTS path. It
// consumes complex IQ16 samples at 20 MS/s, correlates the 20-sample image of
// the 11-chip Barker code, tracks all 20 symbol phases, differentially detects
// DBPSK, self-synchronizes the scrambler, validates SFD and PLCP CRC-16, and
// emits the PSDU bytes (including FCS). Higher-rate PHYs remain separate.

`timescale 1ns/1ps

module gf_dsss_1mbps_rx #(
    parameter integer DECISION_AGE_WIDTH = 16,
    parameter integer MAX_PSDU_BYTES = 4095,
    parameter integer COUNT_WIDTH = 32,
    parameter integer PIPELINED_DIFFERENTIAL = 0,
    parameter integer SINGLE_PHASE_RX = 0,
    parameter integer SERIAL_DIFFERENTIAL = 0,
    parameter integer TIMING_SCORE_RAM = 0,
    parameter integer RECURSIVE_CORRELATOR = 0,
    // Optional SAME-clk correlation boundary. The producer suppresses the
    // first 19 incomplete windows, then supplies x[n..n-19] every sample.
    // This is not itself a clock-domain crossing or a radio deployment.
    parameter integer EXTERNAL_CORRELATOR = 0,
    parameter integer EXTERNAL_CORRELATOR_LATENCY = 0
) (
    input  wire                            clk,
    input  wire                            resetn,
    input  wire                            enable,
    input  wire                            rx_sample_valid,
    input  wire signed [15:0]              rx_i,
    input  wire signed [15:0]              rx_q,

    output reg                             psdu_start,
    output reg                             psdu_byte_valid,
    output reg  [7:0]                      psdu_byte,
    output reg                             psdu_byte_last,
    output reg  [DECISION_AGE_WIDTH-1:0]   psdu_end_age_cycles,
    output wire                            receiver_active,
    // Sideband before byte assembly, including FCS bits. The restart is at
    // accepted PLCP end, never at PSDU end while the final CRC is in flight.
    output wire                            psdu_bit_valid,
    output wire                            psdu_bit_value,
    output wire                            psdu_crc_restart,

    output reg  [COUNT_WIDTH-1:0]          sfd_count,
    output reg  [COUNT_WIDTH-1:0]          plcp_ok_count,
    output reg  [COUNT_WIDTH-1:0]          plcp_error_count,
    output reg  [COUNT_WIDTH-1:0]          psdu_count,
    input wire                            external_correlation_valid,
    input wire signed [23:0]             external_correlation_i,
    input wire signed [23:0]             external_correlation_q
);

    localparam integer SYMBOL_SAMPLES = 20;
    localparam integer PHASE_WIDTH = 5;
    localparam integer CORRELATION_WIDTH = 24;
    localparam integer DIFFERENTIAL_INPUT_WIDTH = 18;
    localparam integer DIFFERENTIAL_SCALE_BITS = 3;
    localparam integer TIMING_SCORE_WIDTH = CORRELATION_WIDTH + 5;
    localparam integer PSDU_LENGTH_WIDTH = 12;

    localparam [1:0] SEARCH_SFD = 2'd0;
    localparam [1:0] READ_PLCP = 2'd1;
    localparam [1:0] READ_PSDU = 2'd2;

    reg [1:0] receive_state;
    reg [PHASE_WIDTH-1:0] phase_index;
    reg [PHASE_WIDTH-1:0] locked_phase;
    reg [PHASE_WIDTH-1:0] candidate_phase;
    wire [PHASE_WIDTH-1:0] decode_phase_index = SINGLE_PHASE_RX ? 5'd0 : phase_index;
    reg [5:0] window_fill;
    reg [DECISION_AGE_WIDTH-1:0] clocks_since_sample;

    reg signed [15:0] i_delay [0:SYMBOL_SAMPLES-1];
    reg signed [15:0] q_delay [0:SYMBOL_SAMPLES-1];
    reg signed [CORRELATION_WIDTH-1:0] previous_i [0:SYMBOL_SAMPLES-1];
    reg signed [CORRELATION_WIDTH-1:0] previous_q [0:SYMBOL_SAMPLES-1];
    reg phase_has_previous [0:SYMBOL_SAMPLES-1];
    reg [6:0] lane_scrambler [0:SYMBOL_SAMPLES-1];
    reg [7:0] lane_one_run [0:SYMBOL_SAMPLES-1];
    reg [5:0] lane_sfd_budget [0:SYMBOL_SAMPLES-1];
    reg [15:0] lane_sfd_shift [0:SYMBOL_SAMPLES-1];
    reg [TIMING_SCORE_WIDTH-1:0] timing_score [0:SYMBOL_SAMPLES-1];
    reg [TIMING_SCORE_WIDTH-1:0] timing_best_score;
    reg [PHASE_WIDTH-1:0] timing_best_phase;
    // Select timing from all 20 unchanged full-precision correlation scores,
    // then keep one differential/descrambler context. Eight consecutive
    // preamble ones freeze its phase through SFD; an early zero releases it.
    // This gives the later serial detector one symbol period per decision.
    wire candidate_hold = lane_one_run[0] >= 8 || lane_sfd_budget[0] != 0;

    reg serial_fault_seen;
    integer reset_index;

    reg [5:0] plcp_bit_index;
    reg [7:0] plcp_signal;
    reg [7:0] plcp_service;
    reg [15:0] plcp_length_us;
    reg [15:0] plcp_crc_state;
    reg [15:0] plcp_crc_received;

    reg [2:0] psdu_bit_index;
    reg [7:0] psdu_byte_accumulator;
    reg [PSDU_LENGTH_WIDTH-1:0] psdu_bytes_expected;
    reg [PSDU_LENGTH_WIDTH-1:0] psdu_bytes_emitted;

    function automatic template_negative;
        input integer sample_index;
        begin
            case (sample_index)
                2, 3, 8, 9, 15, 16, 17, 18, 19:
                    template_negative = 1'b1;
                default:
                    template_negative = 1'b0;
            endcase
        end
    endfunction

    function automatic [15:0] crc16_plcp_bit;
        input [15:0] crc_in;
        input data_bit;
        reg mix;
        begin
            mix = crc_in[0] ^ data_bit;
            crc16_plcp_bit = crc_in >> 1;
            if (mix)
                crc16_plcp_bit = crc16_plcp_bit ^ 16'h8408;
        end
    endfunction

    // The delay line is newest at index 0 and oldest at index 19. Correlate
    // the oldest-to-newest window against floor(sample*11/20) Barker chips.
    // Keep the sum mathematically identical to the former loop, but express it
    // as a balanced tree.  The loop synthesized as a 20-adder serial chain;
    // five balanced logic levels are substantially easier to place and route.
    wire signed [CORRELATION_WIDTH-1:0] correlation_i_tap [0:19];
    wire signed [CORRELATION_WIDTH-1:0] correlation_q_tap [0:19];
    wire signed [CORRELATION_WIDTH-1:0] correlation_i_pair [0:9];
    wire signed [CORRELATION_WIDTH-1:0] correlation_q_pair [0:9];
    wire signed [CORRELATION_WIDTH-1:0] correlation_i_quad [0:4];
    wire signed [CORRELATION_WIDTH-1:0] correlation_q_quad [0:4];
    genvar correlation_index;
    generate
        for (correlation_index = 0; correlation_index < SYMBOL_SAMPLES;
             correlation_index = correlation_index + 1) begin : g_corr_taps
            wire signed [CORRELATION_WIDTH-1:0] i_extended =
                {{(CORRELATION_WIDTH-16){i_delay[19-correlation_index][15]}},
                  i_delay[19-correlation_index]};
            wire signed [CORRELATION_WIDTH-1:0] q_extended =
                {{(CORRELATION_WIDTH-16){q_delay[19-correlation_index][15]}},
                  q_delay[19-correlation_index]};
            assign correlation_i_tap[correlation_index] =
                template_negative(correlation_index) ? -i_extended : i_extended;
            assign correlation_q_tap[correlation_index] =
                template_negative(correlation_index) ? -q_extended : q_extended;
        end
        for (correlation_index = 0; correlation_index < 10;
             correlation_index = correlation_index + 1) begin : g_corr_pairs
            assign correlation_i_pair[correlation_index] =
                correlation_i_tap[2*correlation_index] +
                correlation_i_tap[2*correlation_index+1];
            assign correlation_q_pair[correlation_index] =
                correlation_q_tap[2*correlation_index] +
                correlation_q_tap[2*correlation_index+1];
        end
        for (correlation_index = 0; correlation_index < 5;
             correlation_index = correlation_index + 1) begin : g_corr_quads
            assign correlation_i_quad[correlation_index] =
                correlation_i_pair[2*correlation_index] +
                correlation_i_pair[2*correlation_index+1];
            assign correlation_q_quad[correlation_index] =
                correlation_q_pair[2*correlation_index] +
                correlation_q_pair[2*correlation_index+1];
        end
    endgenerate

    wire signed [CORRELATION_WIDTH-1:0] correlation_i_octet_0 =
        correlation_i_quad[0] + correlation_i_quad[1];
    wire signed [CORRELATION_WIDTH-1:0] correlation_q_octet_0 =
        correlation_q_quad[0] + correlation_q_quad[1];
    wire signed [CORRELATION_WIDTH-1:0] correlation_i_octet_1 =
        correlation_i_quad[2] + correlation_i_quad[3];
    wire signed [CORRELATION_WIDTH-1:0] correlation_q_octet_1 =
        correlation_q_quad[2] + correlation_q_quad[3];
    wire signed [CORRELATION_WIDTH-1:0] correlation_i_sixteen =
        correlation_i_octet_0 + correlation_i_octet_1;
    wire signed [CORRELATION_WIDTH-1:0] correlation_q_sixteen =
        correlation_q_octet_0 + correlation_q_octet_1;
    wire signed [CORRELATION_WIDTH-1:0] legacy_correlation_i =
        correlation_i_sixteen + correlation_i_quad[4];
    wire signed [CORRELATION_WIDTH-1:0] legacy_correlation_q =
        correlation_q_sixteen + correlation_q_quad[4];
    wire signed [CORRELATION_WIDTH-1:0] correlation_i,correlation_q;
    wire process_sample_valid;
    generate if(EXTERNAL_CORRELATOR) begin : g_external_correlator
        reg signed [23:0] aligned_i,aligned_q;
        assign process_sample_valid=external_correlation_valid;
        always @(posedge clk)begin
            if(!resetn || !enable)begin aligned_i<=0;aligned_q<=0;end
            else if(process_sample_valid)begin
                aligned_i<=external_correlation_i;aligned_q<=external_correlation_q;
            end
        end
        // Preserve the detector's previous-window/operand pipeline contract.
        assign correlation_i=aligned_i;assign correlation_q=aligned_q;
    end else if(RECURSIVE_CORRELATOR) begin : g_recursive_correlator
        wire q_valid_unused;
        wire signed [23:0] next_i,next_q;
        reg signed [23:0] aligned_i,aligned_q;
        gf_dsss_barker_recurrence i_path(
            .clk(clk),.clear(!resetn || !enable),.sample_valid(rx_sample_valid),
            .sample(rx_i),.correlation(next_i),.result_valid(process_sample_valid)
        );
        gf_dsss_barker_recurrence q_path(
            .clk(clk),.clear(!resetn || !enable),.sample_valid(rx_sample_valid),
            .sample(rx_q),.correlation(next_q),.result_valid(q_valid_unused)
        );
        // Match the original history update edge. On process_sample_valid the
        // detector must still see the PREVIOUS window; merely forwarding the
        // completed recurrence makes its pipelined operand one sample newer.
        always @(posedge clk)begin
            if(!resetn || !enable)begin aligned_i<=0;aligned_q<=0;end
            else if(process_sample_valid)begin aligned_i<=next_i;aligned_q<=next_q;end
        end
        assign correlation_i=aligned_i;
        assign correlation_q=aligned_q;
    end else begin : g_direct_correlator
        assign process_sample_valid=rx_sample_valid;
        assign correlation_i=legacy_correlation_i;
        assign correlation_q=legacy_correlation_q;
    end endgenerate

    wire signed [CORRELATION_WIDTH-1:0] decision_correlation_i;
    wire signed [CORRELATION_WIDTH-1:0] decision_correlation_q;
    wire signed [DIFFERENTIAL_INPUT_WIDTH-1:0] differential_input_i =
        $signed(decision_correlation_i) >>> DIFFERENTIAL_SCALE_BITS;
    wire signed [DIFFERENTIAL_INPUT_WIDTH-1:0] differential_input_q =
        $signed(decision_correlation_q) >>> DIFFERENTIAL_SCALE_BITS;
    wire signed [DIFFERENTIAL_INPUT_WIDTH-1:0] differential_previous_i =
        $signed(previous_i[decode_phase_index]) >>> DIFFERENTIAL_SCALE_BITS;
    wire signed [DIFFERENTIAL_INPUT_WIDTH-1:0] differential_previous_q =
        $signed(previous_q[decode_phase_index]) >>> DIFFERENTIAL_SCALE_BITS;
    wire signed [(2*DIFFERENTIAL_INPUT_WIDTH)-1:0] differential_i;
    wire signed [(2*DIFFERENTIAL_INPUT_WIDTH)-1:0] differential_q;


    wire candidate_reselect = process_sample_valid && SINGLE_PHASE_RX &&
        phase_index == SYMBOL_SAMPLES-1 && receive_state == SEARCH_SFD &&
        !candidate_hold && candidate_phase != timing_best_phase;
    wire selected_sample = process_sample_valid && window_fill >= SYMBOL_SAMPLES &&
        (!SINGLE_PHASE_RX || phase_index == candidate_phase) && !candidate_reselect;
    wire serial_result_valid,serial_result_sign,serial_overflow;
    wire [4:0] serial_result_phase;
    wire [15:0] serial_result_age;
    wire [7:0] serial_request_age = current_sample_interval + 1'b1;
    wire decode_bit_valid = SERIAL_DIFFERENTIAL
        ? serial_result_valid && !candidate_reselect && !serial_overflow
        : selected_sample && phase_has_previous[decode_phase_index];
    wire [4:0] decoded_bit_phase = SERIAL_DIFFERENTIAL ? serial_result_phase : phase_index;
    wire [DECISION_AGE_WIDTH-1:0] decoded_end_age = SERIAL_DIFFERENTIAL
        ? serial_result_age + (EXTERNAL_CORRELATOR ? 1+EXTERNAL_CORRELATOR_LATENCY : RECURSIVE_CORRELATOR ? 13 : 1)
        : current_sample_interval + 1'b1 + (EXTERNAL_CORRELATOR ? EXTERNAL_CORRELATOR_LATENCY : 0);

    generate
        if (SERIAL_DIFFERENTIAL) begin : g_serial_differential
            reg signed [23:0] correlation_i_pipe,correlation_q_pipe;
            reg signed [17:0] ai_pipe,bi_pipe,aq_pipe,bq_pipe;
            wire ready_unused;
            always @(posedge clk) begin
                if (!resetn || !enable) begin
                    correlation_i_pipe<=0;correlation_q_pipe<=0;
                    ai_pipe<=0;bi_pipe<=0;aq_pipe<=0;bq_pipe<=0;
                end else begin
                    correlation_i_pipe<=correlation_i;
                    correlation_q_pipe<=correlation_q;
                    // Exactly the operands consumed by the previous cycle's
                    // pipelined parallel multiplier, not a newer IQ window.
                    ai_pipe<=differential_input_i;bi_pipe<=differential_previous_i;
                    aq_pipe<=differential_input_q;bq_pipe<=differential_previous_q;
                end
            end
            assign decision_correlation_i=correlation_i_pipe;
            assign decision_correlation_q=correlation_q_pipe;
            assign differential_i=0;
            assign differential_q=0;
            gf_serial_differential detector(
                .clk(clk),.resetn(resetn),.enable(enable),.flush(candidate_reselect),
                .request_valid(selected_sample && phase_has_previous[0] && !serial_overflow),
                .ai(ai_pipe),.bi(bi_pipe),.aq(aq_pipe),.bq(bq_pipe),
                .request_phase(phase_index),.request_age(serial_request_age),
                .request_ready(ready_unused),.result_valid(serial_result_valid),
                .result_sign(serial_result_sign),.result_phase(serial_result_phase),
                .result_age(serial_result_age),.overflow(serial_overflow)
            );
        end else if (PIPELINED_DIFFERENTIAL != 0) begin : g_pipelined_differential
            reg signed [CORRELATION_WIDTH-1:0] correlation_i_pipe;
            reg signed [CORRELATION_WIDTH-1:0] correlation_q_pipe;
            reg signed [(2*DIFFERENTIAL_INPUT_WIDTH)-1:0]
                differential_i_pipe;
            reg signed [(2*DIFFERENTIAL_INPUT_WIDTH)-1:0]
                differential_q_pipe;

            always @(posedge clk) begin
                if (!resetn || !enable) begin
                    correlation_i_pipe <= {CORRELATION_WIDTH{1'b0}};
                    correlation_q_pipe <= {CORRELATION_WIDTH{1'b0}};
                    differential_i_pipe <=
                        {(2*DIFFERENTIAL_INPUT_WIDTH){1'b0}};
                    differential_q_pipe <=
                        {(2*DIFFERENTIAL_INPUT_WIDTH){1'b0}};
                end else begin
                    correlation_i_pipe <= correlation_i;
                    correlation_q_pipe <= correlation_q;
                    differential_i_pipe <= $signed(differential_input_i) *
                        $signed(differential_previous_i);
                    differential_q_pipe <= $signed(differential_input_q) *
                        $signed(differential_previous_q);
                end
            end

            assign decision_correlation_i = correlation_i_pipe;
            assign decision_correlation_q = correlation_q_pipe;
            assign differential_i = differential_i_pipe;
            assign differential_q = differential_q_pipe;
        end else begin : g_direct_differential
            assign decision_correlation_i = correlation_i;
            assign decision_correlation_q = correlation_q;
            assign differential_i = $signed(differential_input_i) *
                $signed(differential_previous_i);
            assign differential_q = $signed(differential_input_q) *
                $signed(differential_previous_q);
        end
    endgenerate

    generate if (!SERIAL_DIFFERENTIAL) begin : g_no_serial_metadata
        assign serial_result_valid=1'b0;
        assign serial_result_sign=1'b0;
        assign serial_result_phase=5'd0;
        assign serial_result_age=16'd0;
        assign serial_overflow=1'b0;
    end endgenerate

    wire signed [(2*DIFFERENTIAL_INPUT_WIDTH):0] differential_real =
        $signed({differential_i[(2*DIFFERENTIAL_INPUT_WIDTH)-1],
                 differential_i}) +
        $signed({differential_q[(2*DIFFERENTIAL_INPUT_WIDTH)-1],
                 differential_q});
    wire scrambled_bit = SERIAL_DIFFERENTIAL ? serial_result_sign :
        differential_real[2*DIFFERENTIAL_INPUT_WIDTH];
    wire plain_bit = scrambled_bit ^ lane_scrambler[decode_phase_index][3] ^
        lane_scrambler[decode_phase_index][6];

    // Long-preamble bits can be decoded at several fractional symbol phases,
    // but only the phase with the complete Barker window identifies the real
    // PPDU boundary needed for SIFS.  Accumulate a short leaky magnitude score
    // independently for all 20 phases and accept SFD only on the strongest.
    // This uses no additional multipliers and naturally follows slow gain
    // changes while forgetting idle/noise history.
    wire [CORRELATION_WIDTH-1:0] correlation_i_magnitude =
        decision_correlation_i[CORRELATION_WIDTH-1]
            ? (~decision_correlation_i + 1'b1) : decision_correlation_i;
    wire [CORRELATION_WIDTH-1:0] correlation_q_magnitude =
        decision_correlation_q[CORRELATION_WIDTH-1]
            ? (~decision_correlation_q + 1'b1) : decision_correlation_q;
    wire [CORRELATION_WIDTH:0] correlation_magnitude =
        {1'b0, correlation_i_magnitude} +
        {1'b0, correlation_q_magnitude};
    wire [TIMING_SCORE_WIDTH-1:0] current_timing_score;
    wire [TIMING_SCORE_WIDTH-1:0] extended_correlation_magnitude =
        {{(TIMING_SCORE_WIDTH-(CORRELATION_WIDTH+1)){1'b0}},
         correlation_magnitude};
    wire [TIMING_SCORE_WIDTH-1:0] next_timing_score =
        current_timing_score - (current_timing_score >> 4) +
        extended_correlation_magnitude;

    // Reset validity, not RAM contents. Every visible score is still cleared
    // on exactly the original clock, including frame-end and fault/disable.
    // Async read preserves the existing sample-side read/modify/write timing.
    wire score_frame_end = decode_bit_valid && receive_state == READ_PSDU &&
        decoded_bit_phase == locked_phase && psdu_bit_index == 3'd7 &&
        psdu_bytes_emitted + 1'b1 >= psdu_bytes_expected;
    generate if (TIMING_SCORE_RAM) begin : g_score_ram
        gf_dsss_timing_score_ram #(.WIDTH(TIMING_SCORE_WIDTH)) scores (
            .clk(clk),.clear(!resetn || !enable || serial_overflow || score_frame_end),
            .write_enable(process_sample_valid && window_fill >= SYMBOL_SAMPLES &&
                          receive_state == SEARCH_SFD),
            .address(phase_index),.write_data(next_timing_score),
            .read_data(current_timing_score)
        );
    end else begin : g_score_registers
        assign current_timing_score = timing_score[phase_index];
    end endgenerate

    wire begin_sfd_search = !plain_bit &&
        lane_one_run[decode_phase_index] >= 8'd87;
    wire sfd_search_active = begin_sfd_search ||
        lane_sfd_budget[decode_phase_index] != 0;
    wire [15:0] shifted_sfd = begin_sfd_search
        ? {15'd0, plain_bit}
        : {lane_sfd_shift[decode_phase_index][14:0], plain_bit};
    wire sfd_match = sfd_search_active && shifted_sfd == 16'h05cf;

    wire [15:0] plcp_crc_next =
        crc16_plcp_bit(plcp_crc_state, plain_bit);
    wire [15:0] completed_plcp_crc =
        {plain_bit, plcp_crc_received[14:0]};
    // HR/DSSS SERVICE bit 2 indicates a shared transmit carrier/chip clock.
    // It is independent of the 1 Mb/s payload format. A real ESP8266 capture
    // has SERVICE=04 with a valid PLCP CRC; requiring 00 discarded that frame.
    // Keep unsupported modulation/length-extension/reserved bits rejected.
    wire plcp_fields_valid = plcp_signal == 8'h0a &&
        (plcp_service & 8'hfb) == 8'h00 && plcp_length_us != 0 &&
        plcp_length_us[2:0] == 3'b000 &&
        (plcp_length_us >> 3) <= MAX_PSDU_BYTES;
    wire [7:0] completed_psdu_byte =
        {plain_bit, psdu_byte_accumulator[6:0]};
    wire [DECISION_AGE_WIDTH-1:0] current_sample_interval =
        clocks_since_sample + 1'b1;

    assign receiver_active = receive_state != SEARCH_SFD;
    assign psdu_bit_valid = enable && decode_bit_valid &&
        receive_state == READ_PSDU && decoded_bit_phase == locked_phase;
    assign psdu_bit_value = plain_bit;
    assign psdu_crc_restart = decode_bit_valid && receive_state == READ_PLCP &&
        decoded_bit_phase == locked_phase && plcp_bit_index == 47 &&
        plcp_fields_valid && completed_plcp_crc == (plcp_crc_state ^ 16'hffff);

    initial begin
        if(RECURSIVE_CORRELATOR && !SERIAL_DIFFERENTIAL)
            $error("Recursive correlator requires the qualified serial 40-MHz receiver");
        if (SERIAL_DIFFERENTIAL && (!SINGLE_PHASE_RX || !PIPELINED_DIFFERENTIAL || DECISION_AGE_WIDTH < 16))
            $error("Serial differential requires single-phase pipelined RX and 16-bit age");
        if (MAX_PSDU_BYTES < 1 || MAX_PSDU_BYTES > 4095)
            $error("MAX_PSDU_BYTES must fit the long-PLCP LENGTH field");
        if (DECISION_AGE_WIDTH < 2)
            $error("DECISION_AGE_WIDTH is too small");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            serial_fault_seen <= 1'b0;
            receive_state <= SEARCH_SFD;
            phase_index <= EXTERNAL_CORRELATOR ? 5'd19 : {PHASE_WIDTH{1'b0}};
            locked_phase <= {PHASE_WIDTH{1'b0}};
            candidate_phase <= {PHASE_WIDTH{1'b0}};
            window_fill <= EXTERNAL_CORRELATOR ? 6'd19 : 6'd0;
            clocks_since_sample <= {DECISION_AGE_WIDTH{1'b0}};
            plcp_bit_index <= 6'd0;
            plcp_signal <= 8'd0;
            plcp_service <= 8'd0;
            plcp_length_us <= 16'd0;
            plcp_crc_state <= 16'hffff;
            plcp_crc_received <= 16'd0;
            psdu_bit_index <= 3'd0;
            psdu_byte_accumulator <= 8'd0;
            psdu_bytes_expected <= {PSDU_LENGTH_WIDTH{1'b0}};
            psdu_bytes_emitted <= {PSDU_LENGTH_WIDTH{1'b0}};
            psdu_start <= 1'b0;
            psdu_byte_valid <= 1'b0;
            psdu_byte <= 8'd0;
            psdu_byte_last <= 1'b0;
            psdu_end_age_cycles <= {DECISION_AGE_WIDTH{1'b0}};
            sfd_count <= {COUNT_WIDTH{1'b0}};
            plcp_ok_count <= {COUNT_WIDTH{1'b0}};
            plcp_error_count <= {COUNT_WIDTH{1'b0}};
            psdu_count <= {COUNT_WIDTH{1'b0}};
            timing_best_score <= {TIMING_SCORE_WIDTH{1'b0}};
            timing_best_phase <= {PHASE_WIDTH{1'b0}};
            for (reset_index = 0; reset_index < SYMBOL_SAMPLES;
                 reset_index = reset_index + 1) begin
                if(!RECURSIVE_CORRELATOR) begin
                    i_delay[reset_index] <= 16'sd0;
                    q_delay[reset_index] <= 16'sd0;
                end
                previous_i[reset_index] <=
                    {CORRELATION_WIDTH{1'b0}};
                previous_q[reset_index] <=
                    {CORRELATION_WIDTH{1'b0}};
                phase_has_previous[reset_index] <= 1'b0;
                lane_scrambler[reset_index] <= 7'd0;
                lane_one_run[reset_index] <= 8'd0;
                lane_sfd_budget[reset_index] <= 6'd0;
                lane_sfd_shift[reset_index] <= 16'd0;
                if (!TIMING_SCORE_RAM) timing_score[reset_index] <=
                    {TIMING_SCORE_WIDTH{1'b0}};
            end
        end else begin
            psdu_start <= 1'b0;
            psdu_byte_valid <= 1'b0;
            psdu_byte_last <= 1'b0;

            if (!enable || serial_overflow) begin
                if (!enable) serial_fault_seen <= 1'b0;
                else if (!serial_fault_seen) begin
                    serial_fault_seen <= 1'b1;
                    plcp_error_count <= plcp_error_count + 1'b1;
                end
                receive_state <= SEARCH_SFD;
                candidate_phase <= {PHASE_WIDTH{1'b0}};
                phase_index <= EXTERNAL_CORRELATOR ? 5'd19 : {PHASE_WIDTH{1'b0}};
                window_fill <= EXTERNAL_CORRELATOR ? 6'd19 : 6'd0;
                clocks_since_sample <= {DECISION_AGE_WIDTH{1'b0}};
                timing_best_score <= {TIMING_SCORE_WIDTH{1'b0}};
                timing_best_phase <= {PHASE_WIDTH{1'b0}};
                for (reset_index = 0; reset_index < SYMBOL_SAMPLES;
                     reset_index = reset_index + 1) begin
                    phase_has_previous[reset_index] <= 1'b0;
                    lane_scrambler[reset_index] <= 7'd0;
                    lane_one_run[reset_index] <= 8'd0;
                    lane_sfd_budget[reset_index] <= 6'd0;
                    lane_sfd_shift[reset_index] <= 16'd0;
                    if (!TIMING_SCORE_RAM) timing_score[reset_index] <=
                        {TIMING_SCORE_WIDTH{1'b0}};
                end
            end else begin
                if (process_sample_valid)
                    clocks_since_sample <= {DECISION_AGE_WIDTH{1'b0}};
                else if (!( &clocks_since_sample))
                    clocks_since_sample <= clocks_since_sample + 1'b1;

                if (process_sample_valid) begin
                    if(!RECURSIVE_CORRELATOR) begin
                    for (reset_index = SYMBOL_SAMPLES - 1; reset_index > 0;
                         reset_index = reset_index - 1) begin
                        i_delay[reset_index] <= i_delay[reset_index - 1];
                        q_delay[reset_index] <= q_delay[reset_index - 1];
                    end
                    i_delay[0] <= rx_i;
                    q_delay[0] <= rx_q;
                    end

                    if (window_fill < SYMBOL_SAMPLES)
                        window_fill <= window_fill + 1'b1;
                    if (phase_index == SYMBOL_SAMPLES - 1)
                        phase_index <= {PHASE_WIDTH{1'b0}};
                    else
                        phase_index <= phase_index + 1'b1;

                    if (window_fill >= SYMBOL_SAMPLES && receive_state == SEARCH_SFD) begin
                            if (!TIMING_SCORE_RAM) timing_score[phase_index] <= next_timing_score;
                            if (phase_index == timing_best_phase)
                                timing_best_score <= next_timing_score;
                            if (next_timing_score > timing_best_score) begin
                                timing_best_score <= next_timing_score;
                                timing_best_phase <= phase_index;
                            end
                    end
                    // The sample-side history does not wait for arithmetic.
                    // A new phase cancels all pending old-phase decisions.
                    if (candidate_reselect) begin
                        candidate_phase <= timing_best_phase;
                        phase_has_previous[0] <= 1'b0;
                        lane_scrambler[0] <= 7'd0;
                        lane_one_run[0] <= 8'd0;
                        lane_sfd_budget[0] <= 6'd0;
                        lane_sfd_shift[0] <= 16'd0;
                    end else if (selected_sample) begin
                        previous_i[decode_phase_index] <= decision_correlation_i;
                        previous_q[decode_phase_index] <= decision_correlation_q;
                        phase_has_previous[decode_phase_index] <= 1'b1;
                    end
                end
                if (decode_bit_valid) begin
                    lane_scrambler[decode_phase_index] <=
                        {lane_scrambler[decode_phase_index][5:0],
                         scrambled_bit};

                    if (receive_state == SEARCH_SFD) begin
                        if (plain_bit) begin
                            if (!( &lane_one_run[decode_phase_index]))
                                lane_one_run[decode_phase_index] <=
                                    lane_one_run[decode_phase_index] + 1'b1;
                        end else begin
                            lane_one_run[decode_phase_index] <= 8'd0;
                        end

                        if (begin_sfd_search) begin
                            lane_sfd_shift[decode_phase_index] <=
                                {15'd0, plain_bit};
                            lane_sfd_budget[decode_phase_index] <= 6'd31;
                        end else if (
                            lane_sfd_budget[decode_phase_index] != 0) begin
                            lane_sfd_shift[decode_phase_index] <= shifted_sfd;
                            lane_sfd_budget[decode_phase_index] <=
                                lane_sfd_budget[decode_phase_index] - 1'b1;
                        end

                        if (sfd_match &&
                            (SINGLE_PHASE_RX || decoded_bit_phase == timing_best_phase)) begin
                            receive_state <= READ_PLCP;
                            locked_phase <= decoded_bit_phase;
                            plcp_bit_index <= 6'd0;
                            plcp_signal <= 8'd0;
                            plcp_service <= 8'd0;
                            plcp_length_us <= 16'd0;
                            plcp_crc_state <= 16'hffff;
                            plcp_crc_received <= 16'd0;
                            sfd_count <= sfd_count + 1'b1;
                            for (reset_index = 0;
                                 reset_index < SYMBOL_SAMPLES;
                                 reset_index = reset_index + 1) begin
                                lane_one_run[reset_index] <= 8'd0;
                                lane_sfd_budget[reset_index] <= 6'd0;
                                lane_sfd_shift[reset_index] <= 16'd0;
                            end
                        end
                    end else if (decoded_bit_phase == locked_phase) begin
                        if (receive_state == READ_PLCP) begin
                            if (plcp_bit_index < 8)
                                plcp_signal[plcp_bit_index] <= plain_bit;
                            else if (plcp_bit_index < 16)
                                plcp_service[plcp_bit_index - 8] <=
                                    plain_bit;
                            else if (plcp_bit_index < 32)
                                plcp_length_us[plcp_bit_index - 16] <=
                                    plain_bit;

                            if (plcp_bit_index < 32)
                                plcp_crc_state <= plcp_crc_next;
                            else
                                plcp_crc_received[
                                    plcp_bit_index - 32] <= plain_bit;

                            if (plcp_bit_index == 47) begin
                                if (plcp_fields_valid &&
                                    completed_plcp_crc ==
                                        (plcp_crc_state ^ 16'hffff)) begin
                                    receive_state <= READ_PSDU;
                                    psdu_bit_index <= 3'd0;
                                    psdu_byte_accumulator <= 8'd0;
                                    psdu_bytes_expected <=
                                        plcp_length_us >> 3;
                                    psdu_bytes_emitted <=
                                        {PSDU_LENGTH_WIDTH{1'b0}};
                                    plcp_ok_count <=
                                        plcp_ok_count + 1'b1;
                                end else begin
                                    receive_state <= SEARCH_SFD;
                                    plcp_error_count <=
                                        plcp_error_count + 1'b1;
                                end
                                plcp_bit_index <= 6'd0;
                            end else begin
                                plcp_bit_index <=
                                    plcp_bit_index + 1'b1;
                            end
                        end else begin
                            psdu_byte_accumulator[psdu_bit_index] <=
                                plain_bit;
                            if (psdu_bit_index == 3'd7) begin
                                psdu_byte <= completed_psdu_byte;
                                psdu_byte_valid <= 1'b1;
                                psdu_start <=
                                    psdu_bytes_emitted == 0;
                                psdu_byte_last <=
                                    psdu_bytes_emitted + 1'b1 >=
                                        psdu_bytes_expected;
                                if (psdu_bytes_emitted + 1'b1 >=
                                    psdu_bytes_expected) begin
                                    psdu_end_age_cycles <=
                                        decoded_end_age;
                                    receive_state <= SEARCH_SFD;
                                    psdu_count <= psdu_count + 1'b1;
                                    for (reset_index = 0;
                                         reset_index < SYMBOL_SAMPLES;
                                         reset_index = reset_index + 1) begin
                                        lane_one_run[reset_index] <= 8'd0;
                                        lane_sfd_budget[reset_index] <=
                                            6'd0;
                                        lane_sfd_shift[reset_index] <=
                                            16'd0;
                                        if (!TIMING_SCORE_RAM) timing_score[reset_index] <=
                                            {TIMING_SCORE_WIDTH{1'b0}};
                                    end
                                    timing_best_score <=
                                        {TIMING_SCORE_WIDTH{1'b0}};
                                    timing_best_phase <=
                                        {PHASE_WIDTH{1'b0}};
                                end else begin
                                    psdu_bytes_emitted <=
                                        psdu_bytes_emitted + 1'b1;
                                end
                                psdu_bit_index <= 3'd0;
                                psdu_byte_accumulator <= 8'd0;
                            end else begin
                                psdu_bit_index <=
                                    psdu_bit_index + 1'b1;
                            end
                        end
                    end
                end
            end
        end
    end

endmodule

// Exact existing 20-sample Barker FIR; no resampling or equalization.
// C[n]=C[n-1]-x[n]-x[n-20]+2*(x[n-5]-x[n-10]+x[n-12]-x[n-16]+x[n-18]).
// Sparse history taps and all sign-extension branches are registered explicitly.
// Exact ranges: first differences/sum 17 bits; a=2*(p0+p1) 19 bits;
// b=2*x18-p3 18 bits; delta 20 bits. EVERY signed IQ16 input is represented;
// no information is discarded. The recurrence and output remain full 24-bit.
// Twelve clocks of latency; supports consecutive inputs. At one input per two
// radio clocks, serial 24-bit addition would require another clock domain.
module gf_dsss_barker_recurrence(
    input wire clk,clear,sample_valid,
    input wire signed [15:0] sample,
    output wire signed [23:0] correlation,
    output wire result_valid
);
    wire [15:0] history[0:19],taps[0:6];
    wire [16:0] extended[0:6];
    reg [11:0] valid_pipe;
    always @(posedge clk) begin
        if(clear) valid_pipe<=0;
        else valid_pipe<={valid_pipe[10:0],sample_valid};
    end
    generate for(genvar n=0;n<20;n=n+1)begin:g_history
        wire [15:0] previous;
        if(n==0) assign previous=sample;
        else assign previous=history[n-1];
        gf_barker_word_reg #(.WIDTH(16)) r(.clk(clk),.clear(clear),
            .enable(sample_valid),.d(previous),.q(history[n]));
    end
    for(genvar n=0;n<7;n=n+1)begin:g_tap
        // History successor and tap are separate loads (maximum two).
        localparam integer OFFSET=n==0?0:n==1?5:n==2?10:n==3?12:n==4?16:n==5?18:20;
        wire [15:0] previous;
        if(OFFSET==0) assign previous=sample;
        else assign previous=history[OFFSET-1];
        gf_barker_word_reg #(.WIDTH(16)) tap(.clk(clk),.clear(clear),
            .enable(sample_valid),.d(previous),.q(taps[n]));
        gf_barker_sign_extend #(.INPUT_WIDTH(16),.OUTPUT_WIDTH(17),.DEPTH(1)) extend(
            .clk(clk),.clear(clear),.data_in(taps[n]),.data_out(extended[n]));
    end endgenerate
    wire signed [16:0] p0,p1,p2,p3;
    wire [16:0] p0_next=$signed(extended[1])-$signed(extended[2]);
    wire [16:0] p1_next=$signed(extended[3])-$signed(extended[4]);
    wire [16:0] p2_next={extended[5][15:0],1'b0}; // exact signed IQ16 times two
    wire [16:0] p3_next=$signed(extended[0])+$signed(extended[6]);
    gf_barker_word_reg #(.WIDTH(17)) p0_r(.clk(clk),.clear(clear),.enable(valid_pipe[1]),.d(p0_next),.q(p0));
    gf_barker_word_reg #(.WIDTH(17)) p1_r(.clk(clk),.clear(clear),.enable(valid_pipe[1]),.d(p1_next),.q(p1));
    gf_barker_word_reg #(.WIDTH(17)) p2_r(.clk(clk),.clear(clear),.enable(valid_pipe[1]),.d(p2_next),.q(p2));
    gf_barker_word_reg #(.WIDTH(17)) p3_r(.clk(clk),.clear(clear),.enable(valid_pipe[1]),.d(p3_next),.q(p3));
    wire signed [17:0] e0,e1,e2,e3;
    gf_barker_sign_extend #(.INPUT_WIDTH(17),.OUTPUT_WIDTH(18),.DEPTH(1)) e0_r(.clk(clk),.clear(clear),.data_in(p0),.data_out(e0));
    gf_barker_sign_extend #(.INPUT_WIDTH(17),.OUTPUT_WIDTH(18),.DEPTH(1)) e1_r(.clk(clk),.clear(clear),.data_in(p1),.data_out(e1));
    gf_barker_sign_extend #(.INPUT_WIDTH(17),.OUTPUT_WIDTH(18),.DEPTH(1)) e2_r(.clk(clk),.clear(clear),.data_in(p2),.data_out(e2));
    gf_barker_sign_extend #(.INPUT_WIDTH(17),.OUTPUT_WIDTH(18),.DEPTH(1)) e3_r(.clk(clk),.clear(clear),.data_in(p3),.data_out(e3));
    wire [17:0] a_sum=e0+e1;
    wire signed [18:0] a;
    wire signed [17:0] b;
    gf_barker_word_reg #(.WIDTH(19)) a_r(.clk(clk),.clear(clear),.enable(valid_pipe[3]),.d({a_sum,1'b0}),.q(a));
    gf_barker_word_reg #(.WIDTH(18)) b_r(.clk(clk),.clear(clear),.enable(valid_pipe[3]),.d(e2-e3),.q(b));
    wire signed [19:0] ae,be,delta;
    gf_barker_sign_extend #(.INPUT_WIDTH(19),.OUTPUT_WIDTH(20),.DEPTH(2)) ae_r(.clk(clk),.clear(clear),.data_in(a),.data_out(ae));
    gf_barker_sign_extend #(.INPUT_WIDTH(18),.OUTPUT_WIDTH(20),.DEPTH(2)) be_r(.clk(clk),.clear(clear),.data_in(b),.data_out(be));
    gf_barker_word_reg #(.WIDTH(20)) delta_r(.clk(clk),.clear(clear),.enable(valid_pipe[6]),.d(ae+be),.q(delta));
    wire signed [23:0] delta24,feedback;
    gf_barker_sign_extend #(.INPUT_WIDTH(20),.OUTPUT_WIDTH(24),.DEPTH(3)) delta_extend(
        .clk(clk),.clear(clear),.data_in(delta),.data_out(delta24));
    wire [23:0] next_correlation=feedback+delta24;
    // Two loads on each adder output. Feedback Q drives only the adder;
    // the separate output register drives only the downstream graph.
    gf_barker_word_reg #(.WIDTH(24)) feedback_r(.clk(clk),.clear(clear),
        .enable(valid_pipe[10]),.d(next_correlation),.q(feedback));
    gf_barker_word_reg #(.WIDTH(24)) output_r(.clk(clk),.clear(clear),
        .enable(valid_pipe[10]),.d(next_correlation),.q(correlation));
    assign result_valid=valid_pipe[11];
endmodule

// Protected clock-enabled registers: no shared SRL reset-mask data net and no
// synthesis merging of deliberate history/sign/feedback duplication.
module gf_barker_word_reg #(parameter integer WIDTH=1)(
    input wire clk,clear,enable,
    input wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] q
);
    generate for(genvar bit_index=0;bit_index<WIDTH;bit_index=bit_index+1)begin:g_bit
`ifdef SYNTHESIS
        (* DONT_TOUCH="true" *) FDRE #(.INIT(1'b0)) r(
            .C(clk),.R(clear),.CE(enable),.D(d[bit_index]),.Q(q[bit_index]));
`else
        reg value=0;
        always @(posedge clk) if(clear)value<=0;else if(enable)value<=d[bit_index];
        assign q[bit_index]=value;
`endif
    end endgenerate
endmodule

// Exact signed extension, not precision truncation. Each sign-tree node drives
// at most two registered children; payload bits receive the same delay.
module gf_barker_sign_extend #(
    parameter integer INPUT_WIDTH=16, OUTPUT_WIDTH=17, DEPTH=1
)(
    input wire clk,clear,
    input wire [INPUT_WIDTH-1:0] data_in,
    output wire [OUTPUT_WIDTH-1:0] data_out
);
    localparam integer LEAVES=1<<DEPTH;
    localparam integer SIGN_BITS=OUTPUT_WIDTH-INPUT_WIDTH+1;
    initial if(DEPTH<1 || SIGN_BITS>LEAVES || OUTPUT_WIDTH<INPUT_WIDTH)
        $error("Invalid registered signed extension");
    wire [LEAVES-1:0] sign_tree[0:DEPTH];
    wire [INPUT_WIDTH-2:0] payload[0:DEPTH];
    assign sign_tree[0][0]=data_in[INPUT_WIDTH-1];
    assign payload[0]=data_in[INPUT_WIDTH-2:0];
    generate for(genvar level=1;level<=DEPTH;level=level+1)begin:g_level
        gf_barker_word_reg #(.WIDTH(INPUT_WIDTH-1)) body(
            .clk(clk),.clear(clear),.enable(1'b1),.d(payload[level-1]),.q(payload[level]));
        for(genvar node=0;node<(1<<level);node=node+1)begin:g_branch
            gf_barker_word_reg branch(.clk(clk),.clear(clear),.enable(1'b1),
                .d(sign_tree[level-1][node>>1]),.q(sign_tree[level][node]));
        end
    end endgenerate
    assign data_out={sign_tree[DEPTH][SIGN_BITS-1:0],payload[DEPTH]};
endmodule

// Full-width twenty-phase score bank. Clear has priority over a coincident
// write. Unwritten entries return zero; no stale RAM word can enter the score
// recurrence after a reset, disable, fault or completed frame.
module gf_dsss_timing_score_ram #(parameter integer WIDTH = 29) (
    input wire clk,
    input wire clear,
    input wire write_enable,
    input wire [4:0] address,
    input wire [WIDTH-1:0] write_data,
    output wire [WIDTH-1:0] read_data
);
    (* ram_style = "distributed" *) reg [WIDTH-1:0] storage [0:31];
    reg [19:0] written;
    wire valid_address = address < 20;
    always @(posedge clk) begin
        if (write_enable && !clear && valid_address)
            storage[address] <= write_data;
        if (clear) written <= 20'd0;
        else if (write_enable && valid_address) written[address] <= 1'b1;
    end
    assign read_data = valid_address && written[address] ? storage[address] : {WIDTH{1'b0}};
endmodule
