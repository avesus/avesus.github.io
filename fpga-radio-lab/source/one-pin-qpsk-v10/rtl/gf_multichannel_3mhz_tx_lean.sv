/*
 * Lean explicit-lane Greenforest 222-225 MHz transmitter.
 *
 * This revision keeps one physical bit-serial phase/data lane per RF slot,
 * but deletes state and muxes that the first 342%-of-HX8K experiment proved
 * were false necessities.  In particular, authoritative Q1.11 complex tank
 * coefficients are compile-time constants: their magnitude becomes the lane
 * amplitude and their phase becomes the DDS initial phase.  That polar form is
 * mathematically the same complex scalar before the deliberately small lane
 * waveform quantizer, so no per-lane cached gain or runtime wide multiply is
 * required.
 */

`default_nettype none

module gf_serial_add_cell_lean (
    input  wire clk_i,
    input  wire run_i,
    input  wire word_start_i,
    input  wire x_bit_i,
    input  wire y_bit_i,
    output reg  sum_bit_o
);
    reg carry_q;
    initial begin
        carry_q   = 1'b0;
        sum_bit_o = 1'b0;
    end

    wire carry_in = word_start_i ? 1'b0 : carry_q;
    wire sum_d = x_bit_i ^ y_bit_i ^ carry_in;
    wire carry_d = (x_bit_i & y_bit_i)
        | (x_bit_i & carry_in)
        | (y_bit_i & carry_in);

    always @(posedge clk_i) begin
        if (run_i) begin
            carry_q   <= carry_d;
            sum_bit_o <= sum_d;
        end
    end
endmodule

/*
 * Proof-only CIC1 / 17-sample moving average for one continuous signed
 * 16-bit, LSB-first stream.  This is the recurrence
 *
 *     S[n] = S[n-1] + x[n] - x[n-17]
 *
 * expressed only as two one-bit full adders and local serial state:
 *
 * - history_q is exactly 17 * 16 = 272 clocks, so history_q[271] is the
 *   same bit position of x[n-17];
 * - x - x[n-17] is x + ~x[n-17] with carry-in one at word start;
 * - accumulator_q is a 16-clock rotating feedback word, exposing the same
 *   bit position of S[n-1] while accepting the new S[n] bit at its MSB.
 *
 * Scaling is intentionally not present here.  The enclosing channelizer
 * reconstructs S[n] and implements /16 as signed wiring (>>> 4).
 */
module gf_serial_cic17_lean #(
    // A legitimate serial-integrator constant.  Eight implements
    // floor((sum + 8) / 16) when the enclosing stage later applies >>> 4.
    parameter integer ROUND_BIAS = 0
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire word_start_i,
    input  wire x_bit_i,
    output wire sum_bit_o
);
    reg [271:0] history_q;
    reg [15:0] accumulator_q;
    reg subtract_carry_q;
    reg accumulate_carry_q;
    reg aligned_q;

    wire delayed_bit = history_q[271];
    wire subtract_y = ~delayed_bit;
    wire subtract_carry_in = word_start_i ? 1'b1 : subtract_carry_q;
    wire difference_bit = x_bit_i ^ subtract_y ^ subtract_carry_in;
    wire subtract_carry_d = (x_bit_i & subtract_y)
        | (x_bit_i & subtract_carry_in)
        | (subtract_y & subtract_carry_in);

    wire previous_sum_bit = accumulator_q[0];
    wire accumulate_carry_in = word_start_i ? 1'b0 : accumulate_carry_q;
    wire new_sum_bit = previous_sum_bit ^ difference_bit
        ^ accumulate_carry_in;
    wire accumulate_carry_d = (previous_sum_bit & difference_bit)
        | (previous_sum_bit & accumulate_carry_in)
        | (difference_bit & accumulate_carry_in);

    always @(posedge clk_i) begin
        if (rst_i) begin
            history_q          <= 272'd0;
            accumulator_q      <= ROUND_BIAS[15:0];
            subtract_carry_q   <= 1'b0;
            accumulate_carry_q <= 1'b0;
            aligned_q          <= 1'b0;
        end else if (!aligned_q && !word_start_i) begin
            /* Reset can end while the registered root tree is mid-word.
               Until its first real bit zero arrives, advancing x + ~0 with
               carry-in zero would seed a permanent accumulator constant. */
            history_q          <= 272'd0;
            accumulator_q      <= ROUND_BIAS[15:0];
            subtract_carry_q   <= 1'b0;
            accumulate_carry_q <= 1'b0;
            aligned_q          <= 1'b0;
        end else begin
            // The first word_start executes bit zero normally, then locks the
            // filter to the root stream for all subsequent serial words.
            aligned_q <= 1'b1;
            history_q <= {history_q[270:0], x_bit_i};
            // LSB-first bits enter at bit 15; after 16 right shifts the new
            // word is again presented LSB-first at accumulator_q[0].
            accumulator_q <= {new_sum_bit, accumulator_q[15:1]};
            subtract_carry_q <= subtract_carry_d;
            accumulate_carry_q <= accumulate_carry_d;
        end
    end

    assign sum_bit_o = (aligned_q || word_start_i) ? new_sum_bit : 1'b0;
endmodule

module gf_explicit_lane_channelizer_lean #(
    parameter integer MODE_25KHZ = 1,
    parameter integer ACTIVE_CHANNELS = 120,
    // -1 preserves the original centered contiguous-range placement.
    parameter integer FIRST_ACTIVE_LANE = -1,
    parameter integer PROOF_LANE_INDEX = -1,
    parameter integer WAVE_PHASE_BITS = 3,
    parameter integer PROOF_CIC17_ENABLE = 0,
    parameter integer PROOF_CIC17_ROUND_BIAS = 0,
    parameter integer PRBS_ADVANCE = 1
) (
    input  wire               clk_lane_i,
    input  wire               rst_i,
    output reg signed [15:0]  composite_i_o,
    output reg signed [15:0]  composite_q_o,
    output reg                composite_strobe_o,
    output wire               coefficients_ready_o,
    output wire               symbol_tick_o,
    output wire [1:0]         payload_symbol_debug_o,
    output wire [15:0]        payload_symbol_epoch_debug_o,
    output wire [8:0]         physical_channel_count_o,
    output wire [15:0]        lane0_phase_debug_o,
    output wire [15:0]        lane_last_phase_debug_o
);
    localparam integer LANES = MODE_25KHZ ? 120 : 240;
    localparam integer TREE_LEAVES = MODE_25KHZ ? 128 : 256;
    localparam integer TREE_LEVELS = MODE_25KHZ ? 7 : 8;
    localparam integer PHASE_BITS = MODE_25KHZ ? 16 : 15;
    localparam integer BOUNDED_ACTIVE = (ACTIVE_CHANNELS < 0) ? 0
        : ((ACTIVE_CHANNELS > LANES) ? LANES : ACTIVE_CHANNELS);
    localparam integer FIRST_ACTIVE = (FIRST_ACTIVE_LANE < 0)
        ? ((LANES - BOUNDED_ACTIVE) / 2) : FIRST_ACTIVE_LANE;

`include "generated/gf_tank_preemphasis_authoritative_q111.svh"

    function signed [15:0] tune_from_bin;
        input signed [15:0] bin;
        integer numerator;
        integer rounded;
        begin
            // 108 MHz / 16 serial bits = 6.75 Msps. One bin is 6.25 kHz.
            numerator = bin * (MODE_25KHZ ? 65536 : 32768);
            if (numerator >= 0)
                rounded = (numerator + 540) / 1080;
            else
                rounded = (numerator - 540) / 1080;
            tune_from_bin = rounded;
        end
    endfunction

    function wave_i_bit;
        input [2:0] sector;
        input axial_positive;
        input axial_negative;
        input diagonal_positive;
        input diagonal_negative;
        begin
            case (sector)
                3'd0: wave_i_bit = axial_positive;
                3'd1: wave_i_bit = diagonal_positive;
                3'd2: wave_i_bit = 1'b0;
                3'd3: wave_i_bit = diagonal_negative;
                3'd4: wave_i_bit = axial_negative;
                3'd5: wave_i_bit = diagonal_negative;
                3'd6: wave_i_bit = 1'b0;
                default: wave_i_bit = diagonal_positive;
            endcase
        end
    endfunction

    function wave_q_bit;
        input [2:0] sector;
        input axial_positive;
        input axial_negative;
        input diagonal_positive;
        input diagonal_negative;
        begin
            case (sector)
                3'd0: wave_q_bit = 1'b0;
                3'd1: wave_q_bit = diagonal_positive;
                3'd2: wave_q_bit = axial_positive;
                3'd3: wave_q_bit = diagonal_positive;
                3'd4: wave_q_bit = 1'b0;
                3'd5: wave_q_bit = diagonal_negative;
                3'd6: wave_q_bit = axial_negative;
                default: wave_q_bit = diagonal_negative;
            endcase
        end
    endfunction

    function wave16_i_bit;
        input [3:0] phase;
        input axial_positive;
        input axial_negative;
        input diagonal_positive;
        input diagonal_negative;
        input near_axis_positive;
        input near_axis_negative;
        input near_zero_positive;
        input near_zero_negative;
        begin
            case (phase)
                4'd0:  wave16_i_bit = axial_positive;
                4'd1:  wave16_i_bit = near_axis_positive;
                4'd2:  wave16_i_bit = diagonal_positive;
                4'd3:  wave16_i_bit = near_zero_positive;
                4'd4:  wave16_i_bit = 1'b0;
                4'd5:  wave16_i_bit = near_zero_negative;
                4'd6:  wave16_i_bit = diagonal_negative;
                4'd7:  wave16_i_bit = near_axis_negative;
                4'd8:  wave16_i_bit = axial_negative;
                4'd9:  wave16_i_bit = near_axis_negative;
                4'd10: wave16_i_bit = diagonal_negative;
                4'd11: wave16_i_bit = near_zero_negative;
                4'd12: wave16_i_bit = 1'b0;
                4'd13: wave16_i_bit = near_zero_positive;
                4'd14: wave16_i_bit = diagonal_positive;
                default: wave16_i_bit = near_axis_positive;
            endcase
        end
    endfunction

    function wave16_q_bit;
        input [3:0] phase;
        input axial_positive;
        input axial_negative;
        input diagonal_positive;
        input diagonal_negative;
        input near_axis_positive;
        input near_axis_negative;
        input near_zero_positive;
        input near_zero_negative;
        begin
            case (phase)
                4'd0:  wave16_q_bit = 1'b0;
                4'd1:  wave16_q_bit = near_zero_positive;
                4'd2:  wave16_q_bit = diagonal_positive;
                4'd3:  wave16_q_bit = near_axis_positive;
                4'd4:  wave16_q_bit = axial_positive;
                4'd5:  wave16_q_bit = near_axis_positive;
                4'd6:  wave16_q_bit = diagonal_positive;
                4'd7:  wave16_q_bit = near_zero_positive;
                4'd8:  wave16_q_bit = 1'b0;
                4'd9:  wave16_q_bit = near_zero_negative;
                4'd10: wave16_q_bit = diagonal_negative;
                4'd11: wave16_q_bit = near_axis_negative;
                4'd12: wave16_q_bit = axial_negative;
                4'd13: wave16_q_bit = near_axis_negative;
                4'd14: wave16_q_bit = diagonal_negative;
                default: wave16_q_bit = near_zero_negative;
            endcase
        end
    endfunction

    function wave32_i_bit;
        input [4:0] phase;
        input axial_positive;
        input axial_negative;
        input diagonal_positive;
        input diagonal_negative;
        input cos11_positive;
        input cos11_negative;
        input cos22_positive;
        input cos22_negative;
        input cos33_positive;
        input cos33_negative;
        input cos56_positive;
        input cos56_negative;
        input cos67_positive;
        input cos67_negative;
        input cos78_positive;
        input cos78_negative;
        begin
            case (phase)
                5'd0:  wave32_i_bit = axial_positive;
                5'd1:  wave32_i_bit = cos11_positive;
                5'd2:  wave32_i_bit = cos22_positive;
                5'd3:  wave32_i_bit = cos33_positive;
                5'd4:  wave32_i_bit = diagonal_positive;
                5'd5:  wave32_i_bit = cos56_positive;
                5'd6:  wave32_i_bit = cos67_positive;
                5'd7:  wave32_i_bit = cos78_positive;
                5'd8:  wave32_i_bit = 1'b0;
                5'd9:  wave32_i_bit = cos78_negative;
                5'd10: wave32_i_bit = cos67_negative;
                5'd11: wave32_i_bit = cos56_negative;
                5'd12: wave32_i_bit = diagonal_negative;
                5'd13: wave32_i_bit = cos33_negative;
                5'd14: wave32_i_bit = cos22_negative;
                5'd15: wave32_i_bit = cos11_negative;
                5'd16: wave32_i_bit = axial_negative;
                5'd17: wave32_i_bit = cos11_negative;
                5'd18: wave32_i_bit = cos22_negative;
                5'd19: wave32_i_bit = cos33_negative;
                5'd20: wave32_i_bit = diagonal_negative;
                5'd21: wave32_i_bit = cos56_negative;
                5'd22: wave32_i_bit = cos67_negative;
                5'd23: wave32_i_bit = cos78_negative;
                5'd24: wave32_i_bit = 1'b0;
                5'd25: wave32_i_bit = cos78_positive;
                5'd26: wave32_i_bit = cos67_positive;
                5'd27: wave32_i_bit = cos56_positive;
                5'd28: wave32_i_bit = diagonal_positive;
                5'd29: wave32_i_bit = cos33_positive;
                5'd30: wave32_i_bit = cos22_positive;
                default: wave32_i_bit = cos11_positive;
            endcase
        end
    endfunction

    function wave32_q_bit;
        input [4:0] phase;
        input axial_positive;
        input axial_negative;
        input diagonal_positive;
        input diagonal_negative;
        input cos11_positive;
        input cos11_negative;
        input cos22_positive;
        input cos22_negative;
        input cos33_positive;
        input cos33_negative;
        input cos56_positive;
        input cos56_negative;
        input cos67_positive;
        input cos67_negative;
        input cos78_positive;
        input cos78_negative;
        begin
            case (phase)
                5'd0:  wave32_q_bit = 1'b0;
                5'd1:  wave32_q_bit = cos78_positive;
                5'd2:  wave32_q_bit = cos67_positive;
                5'd3:  wave32_q_bit = cos56_positive;
                5'd4:  wave32_q_bit = diagonal_positive;
                5'd5:  wave32_q_bit = cos33_positive;
                5'd6:  wave32_q_bit = cos22_positive;
                5'd7:  wave32_q_bit = cos11_positive;
                5'd8:  wave32_q_bit = axial_positive;
                5'd9:  wave32_q_bit = cos11_positive;
                5'd10: wave32_q_bit = cos22_positive;
                5'd11: wave32_q_bit = cos33_positive;
                5'd12: wave32_q_bit = diagonal_positive;
                5'd13: wave32_q_bit = cos56_positive;
                5'd14: wave32_q_bit = cos67_positive;
                5'd15: wave32_q_bit = cos78_positive;
                5'd16: wave32_q_bit = 1'b0;
                5'd17: wave32_q_bit = cos78_negative;
                5'd18: wave32_q_bit = cos67_negative;
                5'd19: wave32_q_bit = cos56_negative;
                5'd20: wave32_q_bit = diagonal_negative;
                5'd21: wave32_q_bit = cos33_negative;
                5'd22: wave32_q_bit = cos22_negative;
                5'd23: wave32_q_bit = cos11_negative;
                5'd24: wave32_q_bit = axial_negative;
                5'd25: wave32_q_bit = cos11_negative;
                5'd26: wave32_q_bit = cos22_negative;
                5'd27: wave32_q_bit = cos33_negative;
                5'd28: wave32_q_bit = diagonal_negative;
                5'd29: wave32_q_bit = cos56_negative;
                5'd30: wave32_q_bit = cos67_negative;
                default: wave32_q_bit = cos78_negative;
            endcase
        end
    endfunction

    reg [3:0] word_bit_q;
    reg [11:0] symbol_divider_q;
    reg [15:0] shared_prbs_q;
    reg symbol_apply_pending_q;
    reg [15:0] payload_symbol_epoch_q;
    wire word_start = word_bit_q == 4'd0;
    wire symbol_tick = word_start && (MODE_25KHZ
        ? (&symbol_divider_q[10:0]) : (&symbol_divider_q));
    assign symbol_tick_o = symbol_tick;

    always @(posedge clk_lane_i) begin
        if (rst_i) begin
            word_bit_q       <= 4'd0;
            symbol_divider_q <= 12'd0;
            shared_prbs_q    <= 16'h1d2b;
            symbol_apply_pending_q <= 1'b0;
            payload_symbol_epoch_q <= 16'd0;
        end else begin
            word_bit_q <= word_bit_q + 1'b1;
            if (word_start)
                symbol_divider_q <= symbol_divider_q + 1'b1;
            if (word_start && symbol_apply_pending_q) begin
                symbol_apply_pending_q <= 1'b0;
                payload_symbol_epoch_q <= payload_symbol_epoch_q + 1'b1;
            end
            if (symbol_tick && (PRBS_ADVANCE != 0)) begin
                shared_prbs_q <= {shared_prbs_q[14:0],
                    shared_prbs_q[15] ^ shared_prbs_q[13]
                    ^ shared_prbs_q[12] ^ shared_prbs_q[10]};
                // The phase registers consume the old PRBS on this edge and
                // the advanced PRBS on the next word_start.  Mark that exact
                // apply boundary rather than exporting an easy-to-miss pulse.
                symbol_apply_pending_q <= 1'b1;
            end
        end
    end

    wire [TREE_LEAVES-1:0] lane_i_bit;
    wire [TREE_LEAVES-1:0] lane_q_bit;
    wire [15:0] lane_phase_debug [0:LANES-1];
    wire [1:0] lane_payload_symbol_debug [0:LANES-1];

    genvar lane;
    generate
        for (lane = 0; lane < TREE_LEAVES; lane = lane + 1) begin : g_lane
            if (lane < LANES) begin : g_physical_lane
                localparam signed [15:0] BIN = MODE_25KHZ
                    ? (-16'sd238 + (lane * 4))
                    : (-16'sd239 + (lane * 2));
                localparam signed [15:0] TUNE_FULL = tune_from_bin(BIN);
                localparam signed [PHASE_BITS-1:0] TUNE_WORD = TUNE_FULL[PHASE_BITS-1:0];
                localparam [15:0] INITIAL_PHASE_U16 = MODE_25KHZ
                    ? gf_q111_phase_120x25k_u16(lane)
                    : gf_q111_phase_240x12k5_u16(lane);
                localparam [PHASE_BITS-1:0] INITIAL_PHASE =
                    INITIAL_PHASE_U16[15 -: PHASE_BITS];
                localparam [6:0] AXIAL = MODE_25KHZ
                    ? gf_q111_axial_120x25k_u7(lane)
                    : gf_q111_axial_240x12k5_u7(lane);
                localparam [6:0] DIAGONAL = MODE_25KHZ
                    ? gf_q111_diagonal_120x25k_u7(lane)
                    : gf_q111_diagonal_240x12k5_u7(lane);
                localparam signed [15:0] AXIAL_POS_WORD = $signed({9'd0, AXIAL});
                localparam signed [15:0] AXIAL_NEG_WORD = -AXIAL_POS_WORD;
                localparam signed [15:0] DIAGONAL_POS_WORD = $signed({9'd0, DIAGONAL});
                localparam signed [15:0] DIAGONAL_NEG_WORD = -DIAGONAL_POS_WORD;
                // Elaboration-time constants only: no runtime multiplier.
                localparam integer NEAR_AXIS_INT = (AXIAL * 118 + 64) >> 7;
                localparam integer NEAR_ZERO_INT = (AXIAL * 49 + 64) >> 7;
                localparam integer COS11_INT = (AXIAL * 126 + 64) >> 7;
                localparam integer COS33_INT = (AXIAL * 106 + 64) >> 7;
                localparam integer COS56_INT = (AXIAL * 71 + 64) >> 7;
                localparam integer COS78_INT = (AXIAL * 25 + 64) >> 7;
                localparam signed [15:0] NEAR_AXIS_POS_WORD =
                    $signed(NEAR_AXIS_INT);
                localparam signed [15:0] NEAR_AXIS_NEG_WORD =
                    -NEAR_AXIS_POS_WORD;
                localparam signed [15:0] NEAR_ZERO_POS_WORD =
                    $signed(NEAR_ZERO_INT);
                localparam signed [15:0] NEAR_ZERO_NEG_WORD =
                    -NEAR_ZERO_POS_WORD;
                localparam signed [15:0] COS11_POS_WORD = $signed(COS11_INT);
                localparam signed [15:0] COS11_NEG_WORD = -COS11_POS_WORD;
                localparam signed [15:0] COS33_POS_WORD = $signed(COS33_INT);
                localparam signed [15:0] COS33_NEG_WORD = -COS33_POS_WORD;
                localparam signed [15:0] COS56_POS_WORD = $signed(COS56_INT);
                localparam signed [15:0] COS56_NEG_WORD = -COS56_POS_WORD;
                localparam signed [15:0] COS78_POS_WORD = $signed(COS78_INT);
                localparam signed [15:0] COS78_NEG_WORD = -COS78_POS_WORD;
                localparam integer TAP_I = (lane * 5 + 1) % 16;
                localparam integer TAP_Q = (lane * 7 + 3) % 16;
                localparam [1:0] DATA_SALT = lane % 4;
                localparam integer LANE_ACTIVE = (PROOF_LANE_INDEX >= 0)
                    ? (lane == PROOF_LANE_INDEX)
                    : ((lane >= FIRST_ACTIVE)
                        && (lane < FIRST_ACTIVE + BOUNDED_ACTIVE));

                reg [PHASE_BITS-1:0] phase_q;
                reg phase_carry_q;
                reg [4:0] output_phase_q;
                reg [1:0] applied_payload_symbol_q;
                initial begin
                    phase_q         = INITIAL_PHASE;
                    phase_carry_q   = 1'b0;
                    output_phase_q  = INITIAL_PHASE[PHASE_BITS-1 -: 5];
                    applied_payload_symbol_q = 2'b00;
                end

                wire phase_a = phase_q[0];
                wire phase_bit_active = word_bit_q < PHASE_BITS;
                wire phase_b = phase_bit_active ? TUNE_WORD[word_bit_q] : 1'b0;
                wire phase_carry_in = word_start ? 1'b0 : phase_carry_q;
                wire phase_sum = phase_a ^ phase_b ^ phase_carry_in;
                wire phase_carry = (phase_a & phase_b)
                    | (phase_a & phase_carry_in)
                    | (phase_b & phase_carry_in);
                wire [1:0] lane_symbol = {
                    shared_prbs_q[TAP_Q] ^ DATA_SALT[1],
                    shared_prbs_q[TAP_I] ^ DATA_SALT[0]
                };

                always @(posedge clk_lane_i) begin
                    if (!rst_i) begin
                        if (phase_bit_active) begin
                            phase_q <= {phase_sum, phase_q[PHASE_BITS-1:1]};
                            phase_carry_q <= phase_carry;
                        end
                        if (word_start) begin
                            output_phase_q <= phase_q[PHASE_BITS-1 -: 5]
                                + {lane_symbol, 3'b000};
                            // This is the exact symbol consumed by the same
                            // update that drives the real lane waveform.
                            applied_payload_symbol_q <= lane_symbol;
                        end
                    end
                end

                wire axial_positive = AXIAL_POS_WORD[word_bit_q];
                wire axial_negative = AXIAL_NEG_WORD[word_bit_q];
                wire diagonal_positive = DIAGONAL_POS_WORD[word_bit_q];
                wire diagonal_negative = DIAGONAL_NEG_WORD[word_bit_q];
                wire near_axis_positive = NEAR_AXIS_POS_WORD[word_bit_q];
                wire near_axis_negative = NEAR_AXIS_NEG_WORD[word_bit_q];
                wire near_zero_positive = NEAR_ZERO_POS_WORD[word_bit_q];
                wire near_zero_negative = NEAR_ZERO_NEG_WORD[word_bit_q];
                wire cos11_positive = COS11_POS_WORD[word_bit_q];
                wire cos11_negative = COS11_NEG_WORD[word_bit_q];
                wire cos33_positive = COS33_POS_WORD[word_bit_q];
                wire cos33_negative = COS33_NEG_WORD[word_bit_q];
                wire cos56_positive = COS56_POS_WORD[word_bit_q];
                wire cos56_negative = COS56_NEG_WORD[word_bit_q];
                wire cos78_positive = COS78_POS_WORD[word_bit_q];
                wire cos78_negative = COS78_NEG_WORD[word_bit_q];
                wire lane_i_bit_d = LANE_ACTIVE
                    ? ((WAVE_PHASE_BITS == 5)
                        ? wave32_i_bit(output_phase_q, axial_positive,
                            axial_negative, diagonal_positive, diagonal_negative,
                            cos11_positive, cos11_negative,
                            near_axis_positive, near_axis_negative,
                            cos33_positive, cos33_negative,
                            cos56_positive, cos56_negative,
                            near_zero_positive, near_zero_negative,
                            cos78_positive, cos78_negative)
                        : ((WAVE_PHASE_BITS == 4)
                        ? wave16_i_bit(output_phase_q[4:1], axial_positive,
                            axial_negative, diagonal_positive, diagonal_negative,
                            near_axis_positive, near_axis_negative,
                            near_zero_positive, near_zero_negative)
                        : wave_i_bit(output_phase_q[4:2], axial_positive,
                            axial_negative, diagonal_positive, diagonal_negative)))
                    : 1'b0;
                wire lane_q_bit_d = LANE_ACTIVE
                    ? ((WAVE_PHASE_BITS == 5)
                        ? wave32_q_bit(output_phase_q, axial_positive,
                            axial_negative, diagonal_positive, diagonal_negative,
                            cos11_positive, cos11_negative,
                            near_axis_positive, near_axis_negative,
                            cos33_positive, cos33_negative,
                            cos56_positive, cos56_negative,
                            near_zero_positive, near_zero_negative,
                            cos78_positive, cos78_negative)
                        : ((WAVE_PHASE_BITS == 4)
                        ? wave16_q_bit(output_phase_q[4:1], axial_positive,
                            axial_negative, diagonal_positive, diagonal_negative,
                            near_axis_positive, near_axis_negative,
                            near_zero_positive, near_zero_negative)
                        : wave_q_bit(output_phase_q[4:2], axial_positive,
                            axial_negative, diagonal_positive, diagonal_negative)))
                    : 1'b0;
                reg lane_i_bit_q;
                reg lane_q_bit_q;
                initial begin
                    lane_i_bit_q = 1'b0;
                    lane_q_bit_q = 1'b0;
                end
                always @(posedge clk_lane_i) begin
                    if (!rst_i) begin
                        lane_i_bit_q <= lane_i_bit_d;
                        lane_q_bit_q <= lane_q_bit_d;
                    end
                end
                assign lane_i_bit[lane] = lane_i_bit_q;
                assign lane_q_bit[lane] = lane_q_bit_q;
                assign lane_phase_debug[lane] =
                    {{(16-PHASE_BITS){1'b0}}, phase_q} << (16-PHASE_BITS);
                assign lane_payload_symbol_debug[lane] =
                    applied_payload_symbol_q;
            end else begin : g_zero_lane
                assign lane_i_bit[lane] = 1'b0;
                assign lane_q_bit[lane] = 1'b0;
            end
        end
    endgenerate

    /*
     * Two balanced registered bit-serial adder trees. A single global start
     * delay per level replaces hundreds of replicated word-start flops.
     */
    wire [TREE_LEAVES-1:0] i_tree_bits [0:TREE_LEVELS];
    wire [TREE_LEAVES-1:0] q_tree_bits [0:TREE_LEVELS];
    reg [TREE_LEVELS:0] word_start_delay_q;
    wire [TREE_LEVELS:0] word_start_at_level;
    assign i_tree_bits[0] = lane_i_bit;
    assign q_tree_bits[0] = lane_q_bit;
    genvar delay_level;
    generate
        for (delay_level = 0; delay_level <= TREE_LEVELS; delay_level = delay_level + 1)
            assign word_start_at_level[delay_level] = word_start_delay_q[delay_level];
    endgenerate

    integer delay_index;
    always @(posedge clk_lane_i) begin
        if (rst_i)
            word_start_delay_q <= {(TREE_LEVELS+1){1'b0}};
        else begin
            word_start_delay_q[0] <= word_start;
            for (delay_index = 1; delay_index <= TREE_LEVELS; delay_index = delay_index + 1)
                word_start_delay_q[delay_index] <= word_start_delay_q[delay_index-1];
        end
    end

    genvar level;
    genvar node;
    generate
        for (level = 0; level < TREE_LEVELS; level = level + 1) begin : g_sum_level
            for (node = 0; node < TREE_LEAVES; node = node + 1) begin : g_sum_node
                if (node < (TREE_LEAVES >> (level + 1))) begin : g_active_sum
                    gf_serial_add_cell_lean u_i_add (
                        .clk_i(clk_lane_i), .run_i(!rst_i),
                        .word_start_i(word_start_at_level[level]),
                        .x_bit_i(i_tree_bits[level][node << 1]),
                        .y_bit_i(i_tree_bits[level][(node << 1) | 1]),
                        .sum_bit_o(i_tree_bits[level+1][node])
                    );
                    gf_serial_add_cell_lean u_q_add (
                        .clk_i(clk_lane_i), .run_i(!rst_i),
                        .word_start_i(word_start_at_level[level]),
                        .x_bit_i(q_tree_bits[level][node << 1]),
                        .y_bit_i(q_tree_bits[level][(node << 1) | 1]),
                        .sum_bit_o(q_tree_bits[level+1][node])
                    );
                end else begin : g_unused_sum
                    assign i_tree_bits[level+1][node] = 1'b0;
                    assign q_tree_bits[level+1][node] = 1'b0;
                end
            end
        end
    endgenerate

    reg [3:0] output_bit_q;
    reg [15:0] i_output_word_q;
    reg [15:0] q_output_word_q;
    reg pipeline_ready_q;
    wire root_start = word_start_at_level[TREE_LEVELS];
    wire root_i_bit = i_tree_bits[TREE_LEVELS][0];
    wire root_q_bit = q_tree_bits[TREE_LEVELS][0];

    /* A constant-disabled generate branch leaves every existing build's root
       stream and synthesized RF behavior unchanged. */
    wire selected_i_bit;
    wire selected_q_bit;
    generate
        if (PROOF_CIC17_ENABLE != 0) begin : g_proof_cic17
            wire cic_i_sum_bit;
            wire cic_q_sum_bit;
            gf_serial_cic17_lean #(
                .ROUND_BIAS(PROOF_CIC17_ROUND_BIAS)
            ) u_i_cic17 (
                .clk_i(clk_lane_i), .rst_i(rst_i),
                .word_start_i(root_start), .x_bit_i(root_i_bit),
                .sum_bit_o(cic_i_sum_bit)
            );
            gf_serial_cic17_lean #(
                .ROUND_BIAS(PROOF_CIC17_ROUND_BIAS)
            ) u_q_cic17 (
                .clk_i(clk_lane_i), .rst_i(rst_i),
                .word_start_i(root_start), .x_bit_i(root_q_bit),
                .sum_bit_o(cic_q_sum_bit)
            );
            assign selected_i_bit = cic_i_sum_bit;
            assign selected_q_bit = cic_q_sum_bit;
        end else begin : g_no_proof_cic17
            assign selected_i_bit = root_i_bit;
            assign selected_q_bit = root_q_bit;
        end
    endgenerate

    wire signed [15:0] completed_i_word =
        $signed({selected_i_bit, i_output_word_q[14:0]});
    wire signed [15:0] completed_q_word =
        $signed({selected_q_bit, q_output_word_q[14:0]});
    // The only division is signed rewiring after the serial sum is rebuilt.
    wire signed [15:0] scaled_i_word = (PROOF_CIC17_ENABLE != 0)
        ? (completed_i_word >>> 4) : completed_i_word;
    wire signed [15:0] scaled_q_word = (PROOF_CIC17_ENABLE != 0)
        ? (completed_q_word >>> 4) : completed_q_word;
    always @(posedge clk_lane_i) begin
        if (rst_i) begin
            output_bit_q       <= 4'd0;
            i_output_word_q    <= 16'd0;
            q_output_word_q    <= 16'd0;
            composite_i_o      <= 16'sd0;
            composite_q_o      <= 16'sd0;
            composite_strobe_o <= 1'b0;
            pipeline_ready_q   <= 1'b0;
        end else begin
            composite_strobe_o <= 1'b0;
            if (root_start) begin
                output_bit_q <= 4'd0;
                i_output_word_q[0] <= selected_i_bit;
                q_output_word_q[0] <= selected_q_bit;
            end else begin
                output_bit_q <= output_bit_q + 1'b1;
                i_output_word_q[output_bit_q + 1'b1] <= selected_i_bit;
                q_output_word_q[output_bit_q + 1'b1] <= selected_q_bit;
                if (output_bit_q == 4'd14) begin
                    composite_i_o <= scaled_i_word;
                    composite_q_o <= scaled_q_word;
                    composite_strobe_o <= 1'b1;
                    pipeline_ready_q <= 1'b1;
                end
            end
        end
    end

    assign physical_channel_count_o = LANES;
    assign coefficients_ready_o = pipeline_ready_q;
    assign lane0_phase_debug_o = lane_phase_debug[0];
    assign lane_last_phase_debug_o = lane_phase_debug[LANES-1];
    localparam integer PAYLOAD_DEBUG_LANE = (PROOF_LANE_INDEX >= 0)
        ? PROOF_LANE_INDEX : FIRST_ACTIVE;
    assign payload_symbol_debug_o =
        lane_payload_symbol_debug[PAYLOAD_DEBUG_LANE];
    assign payload_symbol_epoch_debug_o = payload_symbol_epoch_q;
endmodule

/*
 * Signed first-order SDM with one combinational quantizer decision.  The same
 * decision drives both the emitted bit and that cycle's feedback; this avoids
 * the one-sample inconsistency in the frozen provisional implementation.
 */
module gf_signed_sdm_lean (
    input  wire               clk_i,
    input  wire               rst_i,
    input  wire signed [15:0] sample_i,
    output reg                bit_o,
    output wire signed [17:0] error_o
);
    reg signed [17:0] error_q;
    // Published ordering: decide from the current error, then use that exact
    // decision for both this output bit and the feedback in the state update.
    wire quantizer_d = !error_q[17];
    wire signed [18:0] feedback_d = quantizer_d
        ? 19'sd32768 : -19'sd32768;
    wire signed [18:0] corrected_d =
        $signed({error_q[17], error_q})
        + $signed({{3{sample_i[15]}}, sample_i})
        - feedback_d;
    always @(posedge clk_i) begin
        if (rst_i) begin
            error_q <= 18'sd0;
            bit_o   <= 1'b1;
        end else begin
            error_q <= corrected_d[17:0];
            bit_o   <= quantizer_d;
        end
    end
    assign error_o = error_q;
endmodule

module gf_opposite_iq_sdm_lean #(
    // Keep the frozen production polarity as the default.  The one-shot
    // proof wrapper can flip this one variable for the required true-90-degree
    // wanted/image A/B measurement without moving I/Q outside the FPGA chain.
    parameter integer Q_SIGN_INVERT = 1
) (
    input  wire               clk_i,
    input  wire               rst_i,
    input  wire signed [15:0] i_sample_i,
    input  wire signed [15:0] q_sample_i,
    output wire               i_bit_o,
    output wire               negative_q_bit_o,
    output wire signed [17:0] i_error_o,
    output wire signed [17:0] negative_q_error_o
);
    wire signed [15:0] q_for_sdm = Q_SIGN_INVERT
        ? -q_sample_i : q_sample_i;
    gf_signed_sdm_lean u_i_sdm (
        .clk_i(clk_i), .rst_i(rst_i), .sample_i(i_sample_i),
        .bit_o(i_bit_o), .error_o(i_error_o)
    );
    gf_signed_sdm_lean u_q_sdm (
        .clk_i(clk_i), .rst_i(rst_i), .sample_i(q_for_sdm),
        .bit_o(negative_q_bit_o), .error_o(negative_q_error_o)
    );
endmodule

/* +7.5 MHz DDS and four time-divided Weaver cross-products. */
module gf_weaver_four_product_lean (
    input  wire       clk_216_i,
    input  wire       rst_i,
    input  wire       i_bit_i,
    input  wire       negative_q_bit_i,
    output wire       selector_i_o,
    output wire       selector_q_o,
    output wire [7:0] dds_phase_o,
    output wire       mux_phase_o
);
    reg [7:0] dds_phase_q;
    reg mux_phase_q;
    always @(posedge clk_216_i) begin
        if (rst_i) begin
            dds_phase_q <= 8'd0;
            mux_phase_q <= 1'b0;
        end else begin
            if (mux_phase_q)
                dds_phase_q <= (dds_phase_q >= 8'd134)
                    ? dds_phase_q - 8'd134 : dds_phase_q + 8'd10;
            mux_phase_q <= ~mux_phase_q;
        end
    end
    wire k0 = (dds_phase_q < 8'd36) || (dds_phase_q >= 8'd108);
    wire k1 = dds_phase_q < 8'd72;
    wire x_i_k0       = ~(i_bit_i ^ k0);
    wire x_nq_k1      = ~(negative_q_bit_i ^ k1);
    wire y_i_k1       = ~(i_bit_i ^ k1);
    wire y_minus_nqk0 =  (negative_q_bit_i ^ k0);
    assign selector_i_o = mux_phase_q ? x_nq_k1 : x_i_k0;
    assign selector_q_o = mux_phase_q ? y_minus_nqk0 : y_i_k1;
    assign dds_phase_o = dds_phase_q;
    assign mux_phase_o = mux_phase_q;
endmodule

/*
 * Add the +7.5 MHz DDS quadrant to the complete two-bit phase word.
 * The published selector is the cyclic Gray group 11->10->00->01, so a
 * quadrant rotation is only permutation/inversion of the two SDM bits.
 */
module gf_gray_quadrant_dds_lean (
    input  wire       clk_216_i,
    input  wire       rst_i,
    input  wire       i_sdm_bit_i,
    input  wire       q_sdm_bit_i,
    output reg        selector_i_o,
    output reg        selector_q_o,
    output wire [7:0] dds_phase_o
);
    reg [7:0] dds_phase_q;
    always @(posedge clk_216_i) begin
        if (rst_i)
            dds_phase_q <= 8'd0;
        else
            dds_phase_q <= (dds_phase_q >= 8'd139)
                ? dds_phase_q - 8'd139 : dds_phase_q + 8'd5;
    end

    always @* begin
        if (dds_phase_q < 8'd36) begin
            selector_i_o =  i_sdm_bit_i;
            selector_q_o =  q_sdm_bit_i;
        end else if (dds_phase_q < 8'd72) begin
            selector_i_o =  q_sdm_bit_i;
            selector_q_o = ~i_sdm_bit_i;
        end else if (dds_phase_q < 8'd108) begin
            selector_i_o = ~i_sdm_bit_i;
            selector_q_o = ~q_sdm_bit_i;
        end else begin
            selector_i_o = ~q_sdm_bit_i;
            selector_q_o =  i_sdm_bit_i;
        end
    end
    assign dds_phase_o = dds_phase_q;
endmodule

module gf_multichannel_tx_core_lean #(
    parameter integer MODE_25KHZ = 1,
    parameter integer ACTIVE_CHANNELS = 120,
    parameter integer FIRST_ACTIVE_LANE = -1,
    parameter integer PROOF_LANE_INDEX = -1,
    parameter integer PROOF_GAIN_SHIFT = 0,
    parameter integer Q_SIGN_INVERT = 1,
    parameter integer WAVE_PHASE_BITS = 3,
    parameter integer PROOF_CIC17_ENABLE = 0,
    parameter integer PROOF_CIC17_ROUND_BIAS = 0,
    parameter integer LED_HEARTBEAT_BIT = 6,
    parameter integer PRBS_ADVANCE = 1,
    // Root-cause discriminator only: cyclically rotate the complete final
    // Gray selector word by +90 degrees.  This must not change ideal spectral
    // magnitudes; it only permutes which physical clock phase carries them.
    parameter integer FINAL_SELECTOR_ROTATE90 = 0,
    // One-variable physical discriminator applied only after the unchanged
    // published selector.  Outside tx_active the pin remains high impedance.
    parameter integer FINAL_RF_OE_COMPLEMENT = 0
) (
    input  wire clk_216_i,
    input  wire clk_216_90_i,
    input  wire clk_108_i,
    input  wire rst_i,
    input  wire tx_enable_i,
    output wire rf_output_enable_o,
    output wire tx_led_o,
    output wire ready_o,
    output wire [8:0] channel_count_o,
    output wire signed [15:0] i_debug_o,
    output wire signed [15:0] q_debug_o,
    output wire composite_strobe_debug_o,
    output wire selector_i_debug_o,
    output wire selector_q_debug_o,
    output wire i_sdm_bit_debug_o,
    output wire q_sdm_bit_debug_o,
    output wire [7:0] dds_phase_debug_o,
    output wire signed [17:0] i_sdm_error_debug_o,
    output wire signed [17:0] q_sdm_error_debug_o,
    output wire [1:0] payload_symbol_debug_o,
    output wire [15:0] payload_symbol_epoch_debug_o
);
    wire signed [15:0] composite_i;
    wire signed [15:0] composite_q;
    wire composite_strobe;
    wire coefficients_ready;
    wire channel_symbol_tick;
    wire [1:0] payload_symbol_debug;
    wire [15:0] payload_symbol_epoch_debug;
    wire [15:0] lane0_phase;
    wire [15:0] lane_last_phase;
    gf_explicit_lane_channelizer_lean #(
        .MODE_25KHZ(MODE_25KHZ), .ACTIVE_CHANNELS(ACTIVE_CHANNELS),
        .FIRST_ACTIVE_LANE(FIRST_ACTIVE_LANE),
        .PROOF_LANE_INDEX(PROOF_LANE_INDEX),
        .WAVE_PHASE_BITS(WAVE_PHASE_BITS),
        .PROOF_CIC17_ENABLE(PROOF_CIC17_ENABLE),
        .PROOF_CIC17_ROUND_BIAS(PROOF_CIC17_ROUND_BIAS),
        .PRBS_ADVANCE(PRBS_ADVANCE)
    ) u_channelizer (
        .clk_lane_i(clk_108_i), .rst_i(rst_i),
        .composite_i_o(composite_i), .composite_q_o(composite_q),
        .composite_strobe_o(composite_strobe),
        .coefficients_ready_o(coefficients_ready),
        .symbol_tick_o(channel_symbol_tick),
        .payload_symbol_debug_o(payload_symbol_debug),
        .payload_symbol_epoch_debug_o(payload_symbol_epoch_debug),
        .physical_channel_count_o(channel_count_o),
        .lane0_phase_debug_o(lane0_phase),
        .lane_last_phase_debug_o(lane_last_phase)
    );

    // One explicit proof lane inherits the per-lane amplitude intended for a
    // 120/240-lane sum.  A proof-only constant shift makes that lane visible
    // to the SDM without changing the guarded multi-lane production scaling.
    // Lane 59's largest coefficient is 71, so its <<8 proof value is 18176
    // and remains safely inside signed 16-bit range.
    wire signed [15:0] sdm_i_sample = (PROOF_GAIN_SHIFT == 0)
        ? composite_i : $signed(composite_i <<< PROOF_GAIN_SHIFT);
    wire signed [15:0] sdm_q_sample = (PROOF_GAIN_SHIFT == 0)
        ? composite_q : $signed(composite_q <<< PROOF_GAIN_SHIFT);

    wire i_sdm_bit;
    wire q_sdm_bit;
    wire signed [17:0] i_sdm_error;
    wire signed [17:0] q_sdm_error;
    gf_opposite_iq_sdm_lean #(
        .Q_SIGN_INVERT(Q_SIGN_INVERT)
    ) u_sdms (
        .clk_i(clk_108_i), .rst_i(rst_i),
        .i_sample_i(sdm_i_sample), .q_sample_i(sdm_q_sample),
        .i_bit_o(i_sdm_bit), .negative_q_bit_o(q_sdm_bit),
        .i_error_o(i_sdm_error), .negative_q_error_o(q_sdm_error)
    );

    wire selector_i;
    wire selector_q;
    wire [7:0] dds_phase;
    gf_gray_quadrant_dds_lean u_gray_quadrant_dds (
        .clk_216_i(clk_216_i), .rst_i(rst_i),
        .i_sdm_bit_i(i_sdm_bit), .q_sdm_bit_i(q_sdm_bit),
        .selector_i_o(selector_i), .selector_q_o(selector_q),
        .dds_phase_o(dds_phase)
    );

    // Published Gray cycle: 11 -> 01 -> 00 -> 10.  The single experimental
    // variable maps (I,Q) -> (~Q,I), a cyclic +90-degree rotation.  SDM, DDS,
    // phase order, four-phase selector, and the one-pin boundary are unchanged.
    wire routed_selector_i = (FINAL_SELECTOR_ROTATE90 != 0)
        ? ~selector_q : selector_i;
    wire routed_selector_q = (FINAL_SELECTOR_ROTATE90 != 0)
        ?  selector_i : selector_q;

    wire modulated_rf;
    gf_published_four_phase_selector u_selector (
        .pll_216mhz_i(clk_216_i), .pll_216mhz_90_i(clk_216_90_i),
        .selector_i_i(routed_selector_i), .selector_q_i(routed_selector_q),
        .modulated_rf_o(modulated_rf)
    );

    reg [LED_HEARTBEAT_BIT:0] led_divider_q;
    always @(posedge clk_108_i) begin
        if (rst_i)
            led_divider_q <= {(LED_HEARTBEAT_BIT+1){1'b0}};
        else if (channel_symbol_tick)
            led_divider_q <= led_divider_q + 1'b1;
    end
    wire tx_active = tx_enable_i && coefficients_ready && !rst_i;
    wire final_rf_oe = (FINAL_RF_OE_COMPLEMENT != 0)
        ? ~modulated_rf : modulated_rf;
    assign rf_output_enable_o = tx_active && final_rf_oe;
    assign tx_led_o = tx_active && led_divider_q[LED_HEARTBEAT_BIT];
    assign ready_o = coefficients_ready;
    assign i_debug_o = sdm_i_sample;
    assign q_debug_o = sdm_q_sample;
    assign composite_strobe_debug_o = composite_strobe;
    assign selector_i_debug_o = routed_selector_i;
    assign selector_q_debug_o = routed_selector_q;
    assign i_sdm_bit_debug_o = i_sdm_bit;
    assign q_sdm_bit_debug_o = q_sdm_bit;
    assign dds_phase_debug_o = dds_phase;
    assign i_sdm_error_debug_o = i_sdm_error;
    assign q_sdm_error_debug_o = q_sdm_error;
    assign payload_symbol_debug_o = payload_symbol_debug;
    assign payload_symbol_epoch_debug_o = payload_symbol_epoch_debug;
endmodule

module top_multichannel_lean #(
    parameter integer RF_COMPILE_ARMED = 0,
    parameter integer MODE_25KHZ = 1,
    parameter integer ACTIVE_CHANNELS = 120,
    parameter integer FIRST_ACTIVE_LANE = -1,
    parameter integer PROOF_LANE_INDEX = -1,
    parameter integer PROOF_CIC17_ENABLE = 0,
    parameter integer PROOF_CIC17_ROUND_BIAS = 0,
    parameter integer PRBS_ADVANCE = 1
) (
    (* clkbuf_inhibit *) input wire CRYSTAL_12MHZ,
    output wire RF_OUT,
    output wire LED_R
);
    wire pll_216mhz;
    wire pll_216mhz_90;
    wire pll_lock;
    SB_PLL40_2F_CORE #(
        .FEEDBACK_PATH("PHASE_AND_DELAY"),
        .DIVF(7'd17), .FILTER_RANGE(3'd1), .DIVQ(3'd1),
        .DELAY_ADJUSTMENT_MODE_RELATIVE("DYNAMIC"), .DIVR(4'd0),
        .SHIFTREG_DIV_MODE(0),
        .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"), .FDA_FEEDBACK(4'b0000),
        .PLLOUT_SELECT_PORTA("SHIFTREG_90deg"),
        .PLLOUT_SELECT_PORTB("SHIFTREG_0deg"),
        .ENABLE_ICEGATE_PORTA(0), .ENABLE_ICEGATE_PORTB(0)
    ) pll2 (
        .REFERENCECLK(CRYSTAL_12MHZ), .PLLOUTCOREA(pll_216mhz_90),
        .PLLOUTCOREB(pll_216mhz), .DYNAMICDELAY(8'd0), .RESETB(1'b1),
        .BYPASS(1'b0), .LATCHINPUTVALUE(1'b0), .LOCK(pll_lock),
        .SDI(1'b0), .SDO(), .SCLK(1'b0)
    );
    reg clk_108 = 1'b0;
    always @(posedge pll_216mhz)
        clk_108 <= ~clk_108;

    reg [7:0] startup_q = 8'd0;
    always @(posedge clk_108) begin
        if (!pll_lock)
            startup_q <= 8'd0;
        else if (!&startup_q)
            startup_q <= startup_q + 1'b1;
    end
    wire reset = !&startup_q;

    wire rf_output_enable;
    wire tx_led;
    wire ready;
    wire [8:0] channel_count;
    (* keep *) wire signed [15:0] composite_i_debug;
    (* keep *) wire signed [15:0] composite_q_debug;
    (* keep *) wire composite_strobe_debug;
    (* keep *) wire selector_i_debug;
    (* keep *) wire selector_q_debug;
    gf_multichannel_tx_core_lean #(
        .MODE_25KHZ(MODE_25KHZ), .ACTIVE_CHANNELS(ACTIVE_CHANNELS),
        .FIRST_ACTIVE_LANE(FIRST_ACTIVE_LANE),
        .PROOF_LANE_INDEX(PROOF_LANE_INDEX),
        .PROOF_CIC17_ENABLE(PROOF_CIC17_ENABLE),
        .PROOF_CIC17_ROUND_BIAS(PROOF_CIC17_ROUND_BIAS),
        .PRBS_ADVANCE(PRBS_ADVANCE)
    ) u_core (
        .clk_216_i(pll_216mhz), .clk_216_90_i(pll_216mhz_90),
        .clk_108_i(clk_108), .rst_i(reset),
        .tx_enable_i(RF_COMPILE_ARMED != 0),
        .rf_output_enable_o(rf_output_enable), .tx_led_o(tx_led),
        .ready_o(ready), .channel_count_o(channel_count),
        .i_debug_o(composite_i_debug), .q_debug_o(composite_q_debug),
        .composite_strobe_debug_o(composite_strobe_debug),
        .selector_i_debug_o(selector_i_debug),
        .selector_q_debug_o(selector_q_debug)
    );

    SB_IO #(
        .PIN_TYPE(6'b101000), .IO_STANDARD("SB_LVCMOS"), .PULLUP(1'b0)
    ) rf_output_io (
        .PACKAGE_PIN(RF_OUT), .D_OUT_0(1'b1),
        // Continuous-RF wrapper is permanently electrically quarantined.
        // Only top_one_shot_proof may control N16.
        .OUTPUT_ENABLE(1'b0)
    );
    assign LED_R = 1'b0;
endmodule

`default_nettype wire
