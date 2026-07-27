/*
 * Brian Greenforest one-pin universal 222-225 MHz transmitter milestone.
 *
 * This is the copy-paste channelizer architecture:
 *   - 240 physical DDS/data lanes for the 12.5 kHz grid;
 *   - the same frontend can select 120 physical lanes on a 25 kHz grid;
 *   - one shared bubbles-free bit-serial multiplier streams measured-tank
 *     pre-emphasis magnitudes across lanes;
 *   - two 256-leaf registered bit-serial adder trees combine I and Q;
 *   - opposite-polarity SDMs precede a +7.5 MHz quadrature DDS;
 *   - all four Weaver products feed Brian's published phase selector and N16.
 *
 * Host I/Q, application payload formatting, ARC8, phase warps, parallel
 * multipliers, and 120/240 conventional FIR chains are deliberately absent.
 */

`default_nettype none

module gf_240lane_channelizer #(
    parameter integer DEFAULT_25KHZ_MODE = 0,
    parameter integer DEFAULT_ACTIVE_CHANNELS = 240,
    parameter integer PRBS_ADVANCE = 1
) (
    input  wire        clk_216_i,
    input  wire        rst_i,
    input  wire        mode_25khz_i,
    input  wire [8:0]  active_channels_i,
    output reg  signed [15:0] composite_i_o,
    output reg  signed [15:0] composite_q_o,
    output reg          composite_strobe_o,
    output wire         coefficients_ready_o,
    output wire [8:0]   physical_channel_count_o,
    output wire [15:0]  lane0_phase_debug_o,
    output wire [15:0]  lane_last_phase_debug_o,
    output wire [7:0]   lane0_gain_debug_o
);
    localparam integer LANES = 240;
    localparam integer TREE_LEAVES = 256;
    localparam integer TREE_LEVELS = 8;
    localparam integer WORD_BITS = 16;

`include "generated/gf_tank_preemphasis_222_225.svh"

    function signed [15:0] tune_from_bin;
        input signed [15:0] bin;
        integer numerator;
        integer rounded;
        begin
            // 216 MHz / 16 serial bits = 13.5 Msps complex-word cadence.
            // One requested bin is 6.25 kHz.  This constant expression is
            // folded at elaboration; no hardware multiply or divide exists.
            numerator = bin * 65536;
            if (numerator >= 0)
                rounded = (numerator + 1080) / 2160;
            else
                rounded = (numerator - 1080) / 2160;
            tune_from_bin = rounded;
        end
    endfunction

    function signed [15:0] waveform_i;
        input [2:0] sector;
        input [7:0] axial;
        input [6:0] diagonal;
        begin
            case (sector)
                3'd0: waveform_i =  $signed({1'b0, axial});
                3'd1: waveform_i =  $signed({1'b0, diagonal});
                3'd2: waveform_i =  16'sd0;
                3'd3: waveform_i = -$signed({1'b0, diagonal});
                3'd4: waveform_i = -$signed({1'b0, axial});
                3'd5: waveform_i = -$signed({1'b0, diagonal});
                3'd6: waveform_i =  16'sd0;
                default: waveform_i = $signed({1'b0, diagonal});
            endcase
        end
    endfunction

    function signed [15:0] waveform_q;
        input [2:0] sector;
        input [7:0] axial;
        input [6:0] diagonal;
        begin
            case (sector)
                3'd0: waveform_q =  16'sd0;
                3'd1: waveform_q =  $signed({1'b0, diagonal});
                3'd2: waveform_q =  $signed({1'b0, axial});
                3'd3: waveform_q =  $signed({1'b0, diagonal});
                3'd4: waveform_q =  16'sd0;
                3'd5: waveform_q = -$signed({1'b0, diagonal});
                3'd6: waveform_q = -$signed({1'b0, axial});
                default: waveform_q = -$signed({1'b0, diagonal});
            endcase
        end
    endfunction

    reg [3:0] word_bit_q;
    reg [11:0] symbol_divider_q;
    wire word_start = word_bit_q == 4'd0;
    wire symbol_tick = word_start && (mode_25khz_i
        ? (&symbol_divider_q[10:0]) : (&symbol_divider_q));

    always @(posedge clk_216_i) begin
        if (rst_i) begin
            word_bit_q       <= 4'd0;
            symbol_divider_q <= 12'd0;
        end else begin
            word_bit_q <= word_bit_q + 1'b1;
            if (word_start)
                symbol_divider_q <= symbol_divider_q + 1'b1;
        end
    end

    /*
     * One shared Greenforest multiplier continuously computes gain*3 for one
     * lane after another.  Eight-bit words are adjacent without bubbles.
     */
    reg [2:0] mul_input_bit_q;
    reg [7:0] mul_input_lane_q;
    wire [4:0] mul_gain_q5 = mode_25khz_i
        ? gf_tank_gain_25k_q5(mul_input_lane_q)
        : gf_tank_gain_12k5_q5(mul_input_lane_q);
    wire [7:0] mul_a_word = {3'd0, mul_gain_q5};
    localparam [7:0] MUL_B_WORD = 8'd3;
    wire mul_product_bit;
    wire mul_product_start;
    gf_bubbles_free_mul #(.WORD_BITS(8)) u_preemphasis_multiplier (
        .clk_i(clk_216_i), .rst_i(rst_i),
        .a_bit_i(mul_a_word[mul_input_bit_q]),
        .b_bit_i(MUL_B_WORD[mul_input_bit_q]),
        .product_bit_o(mul_product_bit), .word_start_o(mul_product_start)
    );

    reg [7:0] lane_gain3_q [0:LANES-1];
    reg [2:0] mul_output_bit_q;
    reg [7:0] mul_output_lane_q;
    reg [7:0] mul_product_word_q;
    reg       coefficients_ready_q;
    integer reset_lane;
    always @(posedge clk_216_i) begin
        if (rst_i) begin
            mul_input_bit_q     <= 3'd0;
            mul_input_lane_q    <= 8'd0;
            mul_output_bit_q    <= 3'd0;
            mul_output_lane_q   <= 8'd0;
            mul_product_word_q  <= 8'd0;
            coefficients_ready_q <= 1'b0;
            for (reset_lane = 0; reset_lane < LANES; reset_lane = reset_lane + 1)
                lane_gain3_q[reset_lane] <= 8'd0;
        end else begin
            if (mul_input_bit_q == 3'd7) begin
                mul_input_bit_q <= 3'd0;
                mul_input_lane_q <= (mul_input_lane_q == LANES-1)
                    ? 8'd0 : mul_input_lane_q + 1'b1;
            end else begin
                mul_input_bit_q <= mul_input_bit_q + 1'b1;
            end

            if (mul_product_start) begin
                mul_output_bit_q   <= 3'd0;
                // Three pipeline clocks are shorter than one eight-bit input
                // word, so the source lane is still current at output bit 0.
                mul_output_lane_q  <= mul_input_lane_q;
                mul_product_word_q[0] <= mul_product_bit;
            end else begin
                mul_output_bit_q <= mul_output_bit_q + 1'b1;
                mul_product_word_q[mul_output_bit_q + 1'b1] <= mul_product_bit;
                if (mul_output_bit_q == 3'd6) begin
                    lane_gain3_q[mul_output_lane_q] <=
                        {mul_product_bit, mul_product_word_q[6:0]};
                    if (mul_output_lane_q == LANES-1)
                        coefficients_ready_q <= 1'b1;
                end
            end
        end
    end
    assign coefficients_ready_o = coefficients_ready_q;

    wire [TREE_LEAVES-1:0] lane_i_bit;
    wire [TREE_LEAVES-1:0] lane_q_bit;
    wire [TREE_LEAVES-1:0] lane_word_start;
    wire [15:0] lane_phase_debug [0:LANES-1];

    genvar lane;
    generate
        for (lane = 0; lane < TREE_LEAVES; lane = lane + 1) begin : g_lane
            if (lane < LANES) begin : g_physical_lane
                localparam signed [15:0] BIN_12K5 = -16'sd239 + (lane * 2);
                localparam signed [15:0] BIN_25K  = (lane < 120)
                    ? (-16'sd238 + (lane * 4)) : 16'sd0;
                localparam signed [15:0] TUNE_12K5 = tune_from_bin(BIN_12K5);
                localparam signed [15:0] TUNE_25K = tune_from_bin(BIN_25K);
                localparam [7:0] PRBS_SEED = ((lane * 8'h5d) ^ 8'ha7) | 8'h01;

                wire [15:0] tune_word = mode_25khz_i ? TUNE_25K : TUNE_12K5;
                wire [15:0] initial_phase = mode_25khz_i
                    ? gf_tank_phase_25k_u16(lane)
                    : gf_tank_phase_12k5_u16(lane);
                wire [4:0] gain_q5 = mode_25khz_i
                    ? gf_tank_gain_25k_q5(lane)
                    : gf_tank_gain_12k5_q5(lane);

                reg [15:0] phase_q;
                reg phase_carry_q;
                reg [7:0] prbs_q;
                reg [2:0] output_sector_q;

                // The phase word itself is the P/S and S/P boundary: its LSB
                // feeds the one-bit adder and each result bit enters at MSB.
                // After sixteen clocks the complete new word is back in its
                // original bit order, with no 16-way write-address decoder.
                wire phase_a = phase_q[0];
                wire phase_b = tune_word[word_bit_q];
                wire phase_carry_in = word_start ? 1'b0 : phase_carry_q;
                wire phase_sum = phase_a ^ phase_b ^ phase_carry_in;
                wire phase_carry = (phase_a & phase_b)
                    | (phase_a & phase_carry_in)
                    | (phase_b & phase_carry_in);
                wire [7:0] prbs_next = {prbs_q[6:0],
                    prbs_q[7] ^ prbs_q[5] ^ prbs_q[4] ^ prbs_q[3]};

                always @(posedge clk_216_i) begin
                    if (rst_i) begin
                        phase_q        <= initial_phase;
                        phase_carry_q  <= 1'b0;
                        prbs_q         <= PRBS_SEED;
                        output_sector_q <= 3'd0;
                    end else begin
                        // Brian's one-carry bit-serial adder updates exactly
                        // one DDS phase bit per clock, in place, LSB first.
                        phase_q <= {phase_sum, phase_q[15:1]};
                        phase_carry_q <= phase_carry;
                        if (word_start) begin
                            // QPSK is a cardinal phase offset; no multiplier.
                            output_sector_q <= phase_q[15:13]
                                + {prbs_q[1:0], 1'b0};
                            if (symbol_tick && (PRBS_ADVANCE != 0))
                                prbs_q <= prbs_next;
                        end
                    end
                end

                wire [8:0] mode_channel_count = mode_25khz_i ? 9'd120 : 9'd240;
                wire [8:0] bounded_active = (active_channels_i > mode_channel_count)
                    ? mode_channel_count : active_channels_i;
                wire [8:0] first_active = (mode_channel_count - bounded_active) >> 1;
                wire lane_present = !mode_25khz_i || (lane < 120);
                wire lane_active = lane_present && (bounded_active != 0)
                    && (lane >= first_active)
                    && (lane < first_active + bounded_active);

                wire [6:0] diagonal_gain = {gain_q5, 1'b0};
                wire signed [15:0] i_word = lane_active
                    ? waveform_i(output_sector_q, lane_gain3_q[lane], diagonal_gain)
                    : 16'sd0;
                wire signed [15:0] q_word = lane_active
                    ? waveform_q(output_sector_q, lane_gain3_q[lane], diagonal_gain)
                    : 16'sd0;
                assign lane_i_bit[lane] = i_word[word_bit_q];
                assign lane_q_bit[lane] = q_word[word_bit_q];
                assign lane_word_start[lane] = word_start;
                assign lane_phase_debug[lane] = phase_q;
            end else begin : g_zero_lane
                assign lane_i_bit[lane] = 1'b0;
                assign lane_q_bit[lane] = 1'b0;
                assign lane_word_start[lane] = word_start;
            end
        end
    endgenerate

    /* Two balanced Greenforest serial-adder trees; 256 -> 1 in eight clocks. */
    wire [TREE_LEAVES-1:0] i_tree_bits [0:TREE_LEVELS];
    wire [TREE_LEAVES-1:0] q_tree_bits [0:TREE_LEVELS];
    wire [TREE_LEAVES-1:0] tree_starts [0:TREE_LEVELS];
    assign i_tree_bits[0] = lane_i_bit;
    assign q_tree_bits[0] = lane_q_bit;
    assign tree_starts[0] = lane_word_start;

    genvar level;
    genvar node;
    generate
        for (level = 0; level < TREE_LEVELS; level = level + 1) begin : g_sum_level
            for (node = 0; node < TREE_LEAVES; node = node + 1) begin : g_sum_node
                if (node < (TREE_LEAVES >> (level + 1))) begin : g_active_sum
                    gf_serial_add_cell u_i_add (
                        .clk_i(clk_216_i), .rst_i(rst_i),
                        .word_start_i(tree_starts[level][node << 1]),
                        .x_bit_i(i_tree_bits[level][node << 1]),
                        .y_bit_i(i_tree_bits[level][(node << 1) | 1]),
                        .sum_bit_o(i_tree_bits[level+1][node]),
                        .word_start_o(tree_starts[level+1][node])
                    );
                    gf_serial_add_cell u_q_add (
                        .clk_i(clk_216_i), .rst_i(rst_i),
                        .word_start_i(tree_starts[level][node << 1]),
                        .x_bit_i(q_tree_bits[level][node << 1]),
                        .y_bit_i(q_tree_bits[level][(node << 1) | 1]),
                        .sum_bit_o(q_tree_bits[level+1][node]),
                        .word_start_o()
                    );
                end else begin : g_unused_sum
                    assign i_tree_bits[level+1][node] = 1'b0;
                    assign q_tree_bits[level+1][node] = 1'b0;
                    assign tree_starts[level+1][node] = 1'b0;
                end
            end
        end
    endgenerate

    reg [3:0] output_bit_q;
    reg [15:0] i_output_word_q;
    reg [15:0] q_output_word_q;
    wire root_start = tree_starts[TREE_LEVELS][0];
    wire root_i_bit = i_tree_bits[TREE_LEVELS][0];
    wire root_q_bit = q_tree_bits[TREE_LEVELS][0];
    always @(posedge clk_216_i) begin
        if (rst_i) begin
            output_bit_q         <= 4'd0;
            i_output_word_q      <= 16'd0;
            q_output_word_q      <= 16'd0;
            composite_i_o        <= 16'sd0;
            composite_q_o        <= 16'sd0;
            composite_strobe_o   <= 1'b0;
        end else begin
            composite_strobe_o <= 1'b0;
            if (root_start) begin
                output_bit_q <= 4'd0;
                i_output_word_q[0] <= root_i_bit;
                q_output_word_q[0] <= root_q_bit;
            end else begin
                output_bit_q <= output_bit_q + 1'b1;
                i_output_word_q[output_bit_q + 1'b1] <= root_i_bit;
                q_output_word_q[output_bit_q + 1'b1] <= root_q_bit;
                if (output_bit_q == 4'd14) begin
                    composite_i_o <= $signed({root_i_bit, i_output_word_q[14:0]});
                    composite_q_o <= $signed({root_q_bit, q_output_word_q[14:0]});
                    composite_strobe_o <= 1'b1;
                end
            end
        end
    end

    assign physical_channel_count_o = mode_25khz_i ? 9'd120 : 9'd240;
    assign lane0_phase_debug_o = lane_phase_debug[0];
    assign lane_last_phase_debug_o = lane_phase_debug[LANES-1];
    assign lane0_gain_debug_o = lane_gain3_q[0];
endmodule

/* First-order signed pulse-density encoder. */
module gf_signed_sdm (
    input  wire               clk_i,
    input  wire               rst_i,
    input  wire signed [15:0] sample_i,
    output reg                bit_o
);
    reg signed [17:0] error_q;
    wire signed [17:0] feedback = bit_o ? 18'sd32768 : -18'sd32768;
    always @(posedge clk_i) begin
        if (rst_i) begin
            error_q <= 18'sd0;
            bit_o   <= 1'b1;
        end else begin
            error_q <= error_q + sample_i - feedback;
            bit_o   <= !error_q[17];
        end
    end
endmodule

module gf_opposite_iq_sdm (
    input  wire               clk_i,
    input  wire               rst_i,
    input  wire signed [15:0] i_sample_i,
    input  wire signed [15:0] q_sample_i,
    output wire               i_bit_o,
    output wire               negative_q_bit_o
);
    wire signed [15:0] negative_q = -q_sample_i;
    gf_signed_sdm u_i_sdm (
        .clk_i(clk_i), .rst_i(rst_i), .sample_i(i_sample_i), .bit_o(i_bit_o)
    );
    gf_signed_sdm u_q_sdm (
        .clk_i(clk_i), .rst_i(rst_i), .sample_i(negative_q),
        .bit_o(negative_q_bit_o)
    );
endmodule

/* +7.5 MHz DDS and the required four cross-products. */
module gf_weaver_four_product (
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

module gf_published_four_phase_selector (
    input  wire pll_216mhz_i,
    input  wire pll_216mhz_90_i,
    input  wire selector_i_i,
    input  wire selector_q_i,
    output wire modulated_rf_o
);
    wire p1 =  pll_216mhz_i;
    wire p2 =  pll_216mhz_90_i;
    wire p3 = ~pll_216mhz_i;
    wire p4 = ~pll_216mhz_90_i;
    assign modulated_rf_o = selector_i_i
        ? (selector_q_i ? p1 : p4)
        : (selector_q_i ? p2 : p3);
endmodule

module gf_multichannel_tx_core #(
    parameter integer MODE_25KHZ = 0,
    parameter integer ACTIVE_CHANNELS = 240,
    parameter integer LED_HEARTBEAT_BIT = 23,
    parameter integer PRBS_ADVANCE = 1
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
    output wire selector_q_debug_o
);
    wire signed [15:0] composite_i;
    wire signed [15:0] composite_q;
    wire composite_strobe;
    wire coefficients_ready;
    wire [15:0] lane0_phase;
    wire [15:0] lane_last_phase;
    wire [7:0] lane0_gain;
    gf_240lane_channelizer #(.PRBS_ADVANCE(PRBS_ADVANCE)) u_channelizer (
        .clk_216_i(clk_216_i), .rst_i(rst_i),
        .mode_25khz_i(MODE_25KHZ != 0),
        .active_channels_i(ACTIVE_CHANNELS),
        .composite_i_o(composite_i), .composite_q_o(composite_q),
        .composite_strobe_o(composite_strobe),
        .coefficients_ready_o(coefficients_ready),
        .physical_channel_count_o(channel_count_o),
        .lane0_phase_debug_o(lane0_phase),
        .lane_last_phase_debug_o(lane_last_phase),
        .lane0_gain_debug_o(lane0_gain)
    );

    wire i_sdm_bit;
    wire negative_q_sdm_bit;
    gf_opposite_iq_sdm u_sdms (
        .clk_i(clk_108_i), .rst_i(rst_i),
        .i_sample_i(composite_i), .q_sample_i(composite_q),
        .i_bit_o(i_sdm_bit), .negative_q_bit_o(negative_q_sdm_bit)
    );

    wire selector_i;
    wire selector_q;
    wire [7:0] dds_phase;
    wire mux_phase;
    gf_weaver_four_product u_weaver (
        .clk_216_i(clk_216_i), .rst_i(rst_i),
        .i_bit_i(i_sdm_bit), .negative_q_bit_i(negative_q_sdm_bit),
        .selector_i_o(selector_i), .selector_q_o(selector_q),
        .dds_phase_o(dds_phase), .mux_phase_o(mux_phase)
    );

    wire modulated_rf;
    gf_published_four_phase_selector u_selector (
        .pll_216mhz_i(clk_216_i), .pll_216mhz_90_i(clk_216_90_i),
        .selector_i_i(selector_i), .selector_q_i(selector_q),
        .modulated_rf_o(modulated_rf)
    );

    reg [23:0] led_divider_q;
    always @(posedge clk_108_i) begin
        if (rst_i)
            led_divider_q <= 24'd0;
        else
            led_divider_q <= led_divider_q + 1'b1;
    end
    wire tx_active = tx_enable_i && coefficients_ready && !rst_i;
    assign rf_output_enable_o = tx_active && modulated_rf;
    assign tx_led_o = tx_active && led_divider_q[LED_HEARTBEAT_BIT];
    assign ready_o = coefficients_ready;
    assign i_debug_o = composite_i;
    assign q_debug_o = composite_q;
    assign composite_strobe_debug_o = composite_strobe;
    assign selector_i_debug_o = selector_i;
    assign selector_q_debug_o = selector_q;
endmodule

module top #(
    parameter integer RF_COMPILE_ARMED = 0,
    parameter integer MODE_25KHZ = 0,
    parameter integer ACTIVE_CHANNELS = 240
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
    gf_multichannel_tx_core #(
        .MODE_25KHZ(MODE_25KHZ), .ACTIVE_CHANNELS(ACTIVE_CHANNELS)
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
        .OUTPUT_ENABLE(rf_output_enable)
    );
    assign LED_R = tx_led;
endmodule

`default_nettype wire
