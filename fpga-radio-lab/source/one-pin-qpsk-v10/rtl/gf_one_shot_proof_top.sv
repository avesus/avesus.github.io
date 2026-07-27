/* Finite, fail-off wrapper for the production one-pin TX chain. */
`default_nettype none

module gf_one_shot_burst_gate #(
    parameter integer BURST_CYCLES_108 = 324000000
) (
    input  wire clk_108_i,
    input  wire rst_i,
    input  wire arm_i,
    input  wire datapath_ready_i,
    output reg  burst_active_o,
    output reg  burst_done_o
);
    localparam integer COUNT_BITS = (BURST_CYCLES_108 <= 1)
        ? 1 : $clog2(BURST_CYCLES_108);
    reg [COUNT_BITS-1:0] cycle_q;
    // Configuration-initialized and deliberately never cleared by PLL/reset.
    // Once a burst has started, PLL loss cannot create a second burst.
    reg started_q = 1'b0;
    initial begin
        cycle_q        = {COUNT_BITS{1'b0}};
        burst_active_o = 1'b0;
        burst_done_o   = 1'b0;
    end
    always @(posedge clk_108_i) begin
        if (rst_i) begin
            cycle_q        <= {COUNT_BITS{1'b0}};
            burst_active_o <= 1'b0;
            if (started_q)
                burst_done_o <= 1'b1;
        end else if (!started_q) begin
            burst_done_o <= 1'b0;
            if (arm_i && datapath_ready_i) begin
                started_q       <= 1'b1;
                cycle_q         <= {COUNT_BITS{1'b0}};
                burst_active_o  <= 1'b1;
            end
        end else if (burst_active_o) begin
            if ((BURST_CYCLES_108 <= 1)
                    || (cycle_q == BURST_CYCLES_108-1)) begin
                burst_active_o <= 1'b0;
                burst_done_o   <= 1'b1;
            end else begin
                cycle_q <= cycle_q + 1'b1;
            end
        end else begin
            burst_done_o <= 1'b1;
        end
    end
endmodule

module gf_one_shot_proof_core #(
    parameter integer PROOF_LANE_INDEX = 59,
    // 1 = 223.40-223.52 MHz FM-simplex segment; 2 = digital/packet segment.
    parameter integer PROOF_BANDPLAN_MODE = 1,
    parameter integer ACTIVE_CHANNELS = 1,
    parameter integer FIRST_ACTIVE_LANE = -1,
    parameter integer PRBS_ADVANCE = 0,
    parameter integer BURST_CYCLES_108 = 324000000,
    parameter integer PROOF_GAIN_SHIFT = 8,
    parameter integer Q_SIGN_INVERT = 1,
    parameter integer WAVE_PHASE_BITS = 4,
    parameter integer PROOF_CIC17_ENABLE = 0,
    parameter integer PROOF_CIC17_ROUND_BIAS = 0,
    parameter integer FINAL_SELECTOR_ROTATE90 = 0,
    parameter integer FINAL_RF_OE_COMPLEMENT = 0,
    // 3295.9 channelizer symbol ticks/s / 2^(8+1) = 6.44 Hz.
    parameter integer LED_HEARTBEAT_BIT = 8
) (
    input  wire clk_216_i,
    input  wire clk_216_90_i,
    input  wire clk_108_i,
    input  wire rst_i,
    input  wire arm_i,
    output wire rf_pulse_o,
    output wire tx_led_o,
    output wire burst_active_o,
    output wire burst_done_o,
    output wire datapath_ready_o,
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
    localparam integer BANDPLAN_FM_SIMPLEX = 1;
    localparam integer BANDPLAN_DIGITAL_PACKET = 2;
    localparam integer BOUNDED_ACTIVE = (ACTIVE_CHANNELS < 0) ? 0
        : ((ACTIVE_CHANNELS > 120) ? 120 : ACTIVE_CHANNELS);
    localparam integer EFFECTIVE_FIRST_ACTIVE_LANE =
        (FIRST_ACTIVE_LANE < 0)
            ? ((120 - BOUNDED_ACTIVE) / 2) : FIRST_ACTIVE_LANE;
    localparam integer EFFECTIVE_LAST_ACTIVE_LANE =
        EFFECTIVE_FIRST_ACTIVE_LANE + ACTIVE_CHANNELS - 1;
    localparam integer EXPLICIT_PROOF_LANE_IS_ALLOWED =
        ((PROOF_BANDPLAN_MODE == BANDPLAN_FM_SIMPLEX)
            && (PROOF_LANE_INDEX >= 56) && (PROOF_LANE_INDEX <= 59))
        || ((PROOF_BANDPLAN_MODE == BANDPLAN_DIGITAL_PACKET)
            && (PROOF_LANE_INDEX >= 61) && (PROOF_LANE_INDEX <= 64));
    localparam integer RANGE_IS_ALLOWED =
        (ACTIVE_CHANNELS >= 1) && (ACTIVE_CHANNELS <= 120)
        && (FIRST_ACTIVE_LANE >= -1)
        && (((PROOF_BANDPLAN_MODE == BANDPLAN_FM_SIMPLEX)
                && (EFFECTIVE_FIRST_ACTIVE_LANE >= 56)
                && (EFFECTIVE_LAST_ACTIVE_LANE <= 59))
            || ((PROOF_BANDPLAN_MODE == BANDPLAN_DIGITAL_PACKET)
                && (EFFECTIVE_FIRST_ACTIVE_LANE >= 61)
                && (EFFECTIVE_LAST_ACTIVE_LANE <= 64)));
    localparam integer SELECTION_IS_ALLOWED = (PROOF_LANE_INDEX >= 0)
        ? EXPLICIT_PROOF_LANE_IS_ALLOWED : RANGE_IS_ALLOWED;

    // Generic one-shot images may never silently land in repeater input,
    // repeater output, or coordinator allocations.  An unsafe lane/mode pair
    // is rejected at elaboration before any image can be produced.
    generate
        if (!SELECTION_IS_ALLOWED) begin : g_reject_unsafe_selection
            initial $fatal(1,
                "unsafe generic proof lane/range and bandplan selection");
        end
    endgenerate

    wire [8:0] channel_count_unused;
    wire datapath_ready;
    wire burst_active;
    // This constant electrical interlock remains effective even in a tool that
    // discards simulation-only initial assertions.
    wire bandplan_safe_arm = arm_i && SELECTION_IS_ALLOWED;
    gf_one_shot_burst_gate #(
        .BURST_CYCLES_108(BURST_CYCLES_108)
    ) u_burst (
        .clk_108_i(clk_108_i), .rst_i(rst_i), .arm_i(bandplan_safe_arm),
        .datapath_ready_i(datapath_ready),
        .burst_active_o(burst_active), .burst_done_o(burst_done_o)
    );

    gf_multichannel_tx_core_lean #(
        .MODE_25KHZ(1), .ACTIVE_CHANNELS(ACTIVE_CHANNELS),
        .FIRST_ACTIVE_LANE(FIRST_ACTIVE_LANE),
        .PROOF_LANE_INDEX(PROOF_LANE_INDEX),
        .PROOF_GAIN_SHIFT(PROOF_GAIN_SHIFT),
        .Q_SIGN_INVERT(Q_SIGN_INVERT),
        .WAVE_PHASE_BITS(WAVE_PHASE_BITS),
        .PROOF_CIC17_ENABLE(PROOF_CIC17_ENABLE),
        .PROOF_CIC17_ROUND_BIAS(PROOF_CIC17_ROUND_BIAS),
        .FINAL_SELECTOR_ROTATE90(FINAL_SELECTOR_ROTATE90),
        .FINAL_RF_OE_COMPLEMENT(FINAL_RF_OE_COMPLEMENT),
        .PRBS_ADVANCE(PRBS_ADVANCE),
        .LED_HEARTBEAT_BIT(LED_HEARTBEAT_BIT)
    ) u_tx (
        .clk_216_i(clk_216_i), .clk_216_90_i(clk_216_90_i),
        .clk_108_i(clk_108_i), .rst_i(rst_i),
        .tx_enable_i(burst_active),
        .rf_output_enable_o(rf_pulse_o), .tx_led_o(tx_led_o),
        .ready_o(datapath_ready), .channel_count_o(channel_count_unused),
        .i_debug_o(i_debug_o), .q_debug_o(q_debug_o),
        .composite_strobe_debug_o(composite_strobe_debug_o),
        .selector_i_debug_o(selector_i_debug_o),
        .selector_q_debug_o(selector_q_debug_o),
        .i_sdm_bit_debug_o(i_sdm_bit_debug_o),
        .q_sdm_bit_debug_o(q_sdm_bit_debug_o),
        .dds_phase_debug_o(dds_phase_debug_o),
        .i_sdm_error_debug_o(i_sdm_error_debug_o),
        .q_sdm_error_debug_o(q_sdm_error_debug_o),
        .payload_symbol_debug_o(payload_symbol_debug_o),
        .payload_symbol_epoch_debug_o(payload_symbol_epoch_debug_o)
    );
    assign burst_active_o = burst_active;
    assign datapath_ready_o = datapath_ready;
endmodule

/* Testable physical boundary with asynchronous PLL-lock veto. */
module gf_one_shot_proof_boundary #(
    parameter integer PROOF_LANE_INDEX = 59,
    parameter integer PROOF_BANDPLAN_MODE = 1,
    parameter integer ACTIVE_CHANNELS = 1,
    parameter integer FIRST_ACTIVE_LANE = -1,
    parameter integer PRBS_ADVANCE = 0,
    parameter integer BURST_CYCLES_108 = 324000000,
    parameter integer PROOF_GAIN_SHIFT = 8,
    parameter integer Q_SIGN_INVERT = 1,
    parameter integer WAVE_PHASE_BITS = 4,
    parameter integer PROOF_CIC17_ENABLE = 0,
    parameter integer PROOF_CIC17_ROUND_BIAS = 0,
    parameter integer FINAL_SELECTOR_ROTATE90 = 0,
    parameter integer FINAL_RF_OE_COMPLEMENT = 0,
    parameter integer LED_HEARTBEAT_BIT = 8
) (
    input  wire clk_216_i,
    input  wire clk_216_90_i,
    input  wire clk_108_i,
    input  wire rst_i,
    input  wire pll_lock_i,
    input  wire arm_i,
    output wire rf_out_o,
    output wire tx_led_o,
    output wire rf_drive_enable_debug_o,
    output wire burst_active_o,
    output wire burst_done_o,
    output wire datapath_ready_o,
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
    wire rf_pulse;
    wire core_tx_led;
    gf_one_shot_proof_core #(
        .PROOF_LANE_INDEX(PROOF_LANE_INDEX),
        .PROOF_BANDPLAN_MODE(PROOF_BANDPLAN_MODE),
        .ACTIVE_CHANNELS(ACTIVE_CHANNELS),
        .FIRST_ACTIVE_LANE(FIRST_ACTIVE_LANE),
        .PRBS_ADVANCE(PRBS_ADVANCE),
        .BURST_CYCLES_108(BURST_CYCLES_108),
        .PROOF_GAIN_SHIFT(PROOF_GAIN_SHIFT),
        .Q_SIGN_INVERT(Q_SIGN_INVERT),
        .WAVE_PHASE_BITS(WAVE_PHASE_BITS),
        .PROOF_CIC17_ENABLE(PROOF_CIC17_ENABLE),
        .PROOF_CIC17_ROUND_BIAS(PROOF_CIC17_ROUND_BIAS),
        .FINAL_SELECTOR_ROTATE90(FINAL_SELECTOR_ROTATE90),
        .FINAL_RF_OE_COMPLEMENT(FINAL_RF_OE_COMPLEMENT),
        .LED_HEARTBEAT_BIT(LED_HEARTBEAT_BIT)
    ) u_proof (
        .clk_216_i(clk_216_i), .clk_216_90_i(clk_216_90_i),
        .clk_108_i(clk_108_i), .rst_i(rst_i), .arm_i(arm_i),
        .rf_pulse_o(rf_pulse), .tx_led_o(core_tx_led),
        .burst_active_o(burst_active_o), .burst_done_o(burst_done_o),
        .datapath_ready_o(datapath_ready_o),
        .i_debug_o(i_debug_o), .q_debug_o(q_debug_o),
        .composite_strobe_debug_o(composite_strobe_debug_o),
        .selector_i_debug_o(selector_i_debug_o),
        .selector_q_debug_o(selector_q_debug_o),
        .i_sdm_bit_debug_o(i_sdm_bit_debug_o),
        .q_sdm_bit_debug_o(q_sdm_bit_debug_o),
        .dds_phase_debug_o(dds_phase_debug_o),
        .i_sdm_error_debug_o(i_sdm_error_debug_o),
        .q_sdm_error_debug_o(q_sdm_error_debug_o),
        .payload_symbol_debug_o(payload_symbol_debug_o),
        .payload_symbol_epoch_debug_o(payload_symbol_epoch_debug_o)
    );

    wire physical_enable = pll_lock_i && !rst_i && rf_pulse;
    assign rf_drive_enable_debug_o = physical_enable;
    SB_IO #(
        .PIN_TYPE(6'b101000), .IO_STANDARD("SB_LVCMOS"), .PULLUP(1'b0)
    ) rf_output_io (
        .PACKAGE_PIN(rf_out_o), .D_OUT_0(1'b1),
        .OUTPUT_ENABLE(physical_enable)
    );
    assign tx_led_o = pll_lock_i && !rst_i && core_tx_led;
endmodule

module top_one_shot_proof #(
    parameter integer RF_COMPILE_ARMED = 0,
    parameter integer PROOF_LANE_INDEX = 59,
    parameter integer PROOF_BANDPLAN_MODE = 1,
    parameter integer ACTIVE_CHANNELS = 1,
    parameter integer FIRST_ACTIVE_LANE = -1,
    parameter integer PRBS_ADVANCE = 0,
    parameter integer BURST_CYCLES_108 = 324000000,
    parameter integer PROOF_GAIN_SHIFT = 8,
    parameter integer Q_SIGN_INVERT = 1,
    parameter integer WAVE_PHASE_BITS = 4,
    parameter integer PROOF_CIC17_ENABLE = 0,
    parameter integer PROOF_CIC17_ROUND_BIAS = 0,
    parameter integer FINAL_SELECTOR_ROTATE90 = 0,
    parameter integer FINAL_RF_OE_COMPLEMENT = 0,
    parameter integer LED_HEARTBEAT_BIT = 8
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
        .REFERENCECLK(CRYSTAL_12MHZ), .PLLOUTGLOBALA(pll_216mhz_90),
        .PLLOUTGLOBALB(pll_216mhz), .DYNAMICDELAY(8'd0), .RESETB(1'b1),
        .BYPASS(1'b0), .LATCHINPUTVALUE(1'b0), .LOCK(pll_lock),
        .SDI(1'b0), .SDO(), .SCLK(1'b0)
    );
    reg clk_108_div = 1'b0;
    always @(posedge pll_216mhz)
        clk_108_div <= ~clk_108_div;
    wire clk_108;
    SB_GB clk_108_global_buffer (
        .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_108_div),
        .GLOBAL_BUFFER_OUTPUT(clk_108)
    );

    reg [7:0] startup_q = 8'd0;
    always @(posedge clk_108) begin
        if (!pll_lock)
            startup_q <= 8'd0;
        else if (!&startup_q)
            startup_q <= startup_q + 1'b1;
    end
    wire reset = !&startup_q;

    wire tx_led;
    wire rf_drive_enable_debug;
    wire burst_active;
    wire burst_done;
    wire ready;
    wire signed [15:0] i_debug;
    wire signed [15:0] q_debug;
    wire strobe_debug;
    wire selector_i_debug;
    wire selector_q_debug;
    gf_one_shot_proof_boundary #(
        .PROOF_LANE_INDEX(PROOF_LANE_INDEX),
        .PROOF_BANDPLAN_MODE(PROOF_BANDPLAN_MODE),
        .ACTIVE_CHANNELS(ACTIVE_CHANNELS),
        .FIRST_ACTIVE_LANE(FIRST_ACTIVE_LANE),
        .PRBS_ADVANCE(PRBS_ADVANCE),
        .BURST_CYCLES_108(BURST_CYCLES_108),
        .PROOF_GAIN_SHIFT(PROOF_GAIN_SHIFT),
        .Q_SIGN_INVERT(Q_SIGN_INVERT),
        .WAVE_PHASE_BITS(WAVE_PHASE_BITS),
        .PROOF_CIC17_ENABLE(PROOF_CIC17_ENABLE),
        .PROOF_CIC17_ROUND_BIAS(PROOF_CIC17_ROUND_BIAS),
        .FINAL_SELECTOR_ROTATE90(FINAL_SELECTOR_ROTATE90),
        .FINAL_RF_OE_COMPLEMENT(FINAL_RF_OE_COMPLEMENT),
        .LED_HEARTBEAT_BIT(LED_HEARTBEAT_BIT)
    ) u_boundary (
        .clk_216_i(pll_216mhz), .clk_216_90_i(pll_216mhz_90),
        .clk_108_i(clk_108), .rst_i(reset),
        .pll_lock_i(pll_lock),
        .arm_i(RF_COMPILE_ARMED != 0),
        .rf_out_o(RF_OUT), .tx_led_o(tx_led),
        .rf_drive_enable_debug_o(rf_drive_enable_debug),
        .burst_active_o(burst_active), .burst_done_o(burst_done),
        .datapath_ready_o(ready),
        .i_debug_o(i_debug), .q_debug_o(q_debug),
        .composite_strobe_debug_o(strobe_debug),
        .selector_i_debug_o(selector_i_debug),
        .selector_q_debug_o(selector_q_debug)
    );

    assign LED_R = tx_led;
endmodule

`default_nettype wire
