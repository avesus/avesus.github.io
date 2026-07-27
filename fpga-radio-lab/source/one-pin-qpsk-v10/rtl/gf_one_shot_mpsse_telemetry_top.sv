/*
 * Physical one-shot proof plus board-wired FT2232H-B MPSSE telemetry.
 *
 * The measured RF modules are reused unchanged.  Diagnostics mirror the
 * v1-v5 diagnostics mirror the deterministic +7.5 MHz Gray-DDS phase and
 * invert that known rotation to recover the two pre-DDS SDM bits.  v6 instead
 * exports direct live datapath taps: both SDM bits, both 18-bit SDM error
 * accumulators, and the actual RF DDS phase.  v7 identifies the final-word
 * rotate discriminator; v8 identifies the final RF OE-complement
 * discriminator; v9 identifies a one-tap (nominal +150 ps) relative delay
 * applied only to PLL port A, the quadrature output.  v10 keeps that accepted
 * RF timing and directly exports the payload symbol latched by the real lane
 * phase update plus its applied-symbol epoch.  Nothing in the
 * telemetry path feeds back into the RF datapath or burst gate.
 */
`default_nettype none

module gf_mpsse_snapshot32 #(
    parameter integer FRAME_VERSION = 1,
    parameter integer FRAME_PROOF_LANE_INDEX = 59,
    parameter integer FRAME_FIRST_ACTIVE_LANE = 59,
    parameter integer FRAME_ACTIVE_CHANNELS = 1,
    parameter integer FRAME_PRBS_ADVANCE = 0
) (
    input  wire         source_clk_i,
    input  wire [255:0] source_live_frame_i,
    input  wire         mpsse_sclk_i,
    input  wire         mpsse_cs_n_i,
    output wire         mpsse_miso_o
);
    localparam [7:0] FRAME_ACTIVE_PROFILE_BYTE = (FRAME_VERSION >= 5)
        ? {(FRAME_PRBS_ADVANCE != 0), FRAME_ACTIVE_CHANNELS[6:0]}
        : FRAME_ACTIVE_CHANNELS[7:0];
    localparam [15:0] FRAME_SOURCE_BYTES = (FRAME_VERSION >= 4)
        ? {FRAME_FIRST_ACTIVE_LANE[7:0], FRAME_ACTIVE_PROFILE_BYTE}
        : FRAME_PROOF_LANE_INDEX[15:0];
    /* One request per complete frame.  The source frame remains frozen until
       the next acknowledged request, so the 256-bit CDC cannot tear. */
    reg request_toggle_q = 1'b0;
    (* async_reg = "true" *) reg request_sync1_q = 1'b0;
    (* async_reg = "true" *) reg request_sync2_q = 1'b0;
    reg request_seen_q = 1'b0;
    reg acknowledge_toggle_q = 1'b0;
    reg [255:0] source_snapshot_q = {
        32'h47465431, FRAME_VERSION[7:0], 8'd32, 16'd0, 64'd0,
        16'd0, 16'd0, 8'd0, 8'd0, 8'd0, 8'd16,
        FRAME_SOURCE_BYTES, 16'd0, 16'd0, 16'hA55A
    };

    always @(posedge source_clk_i) begin
        request_sync1_q <= request_toggle_q;
        request_sync2_q <= request_sync1_q;
        if (request_sync2_q != request_seen_q) begin
            request_seen_q       <= request_sync2_q;
            source_snapshot_q    <= source_live_frame_i;
            acknowledge_toggle_q <= request_sync2_q;
        end
    end

    (* async_reg = "true" *) reg acknowledge_sync1_q = 1'b0;
    (* async_reg = "true" *) reg acknowledge_sync2_q = 1'b0;
    reg acknowledge_seen_q = 1'b0;
    (* async_reg = "true" *) reg [255:0] snapshot_sync1_q = {256{1'b0}};
    (* async_reg = "true" *) reg [255:0] snapshot_sync2_q = {256{1'b0}};
    reg [1:0] settle_q = 2'd0;
    reg [255:0] pending_frame_q = {256{1'b0}};
    reg pending_valid_q = 1'b0;
    reg [255:0] transmit_frame_q = {
        32'h47465431, FRAME_VERSION[7:0], 8'd32, 16'd0, 64'd0,
        16'd0, 16'd0, 8'd0, 8'd0, 8'd0, 8'd16,
        FRAME_SOURCE_BYTES, 16'd0, 16'd0, 16'hA55A
    };
    reg [7:0] bit_index_q = 8'd0;

    always @(posedge mpsse_sclk_i or posedge mpsse_cs_n_i) begin
        if (mpsse_cs_n_i) begin
            bit_index_q <= 8'd0;
        end else begin
            snapshot_sync1_q <= source_snapshot_q;
            snapshot_sync2_q <= snapshot_sync1_q;
            acknowledge_sync1_q <= acknowledge_toggle_q;
            acknowledge_sync2_q <= acknowledge_sync1_q;

            if (acknowledge_sync2_q != acknowledge_seen_q) begin
                acknowledge_seen_q <= acknowledge_sync2_q;
                settle_q <= 2'd3;
            end else if (settle_q != 0) begin
                settle_q <= settle_q - 1'b1;
                if (settle_q == 1) begin
                    pending_frame_q <= snapshot_sync2_q;
                    pending_valid_q <= 1'b1;
                end
            end

            if (bit_index_q == 8'd255) begin
                bit_index_q <= 8'd0;
                request_toggle_q <= ~request_toggle_q;
                if (pending_valid_q) begin
                    transmit_frame_q <= pending_frame_q;
                    pending_valid_q <= 1'b0;
                end
            end else begin
                bit_index_q <= bit_index_q + 1'b1;
            end
        end
    end

    /* MPSSE SPI mode 0 samples on rising SCLK; nonblocking bit-index update
       leaves this value stable for the edge that samples it. */
    assign mpsse_miso_o = transmit_frame_q[8'd255 - bit_index_q];
endmodule

module top_one_shot_proof_mpsse_telemetry #(
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
    parameter [7:0] PLL_PORTA_DYNAMIC_DELAY = 8'd0,
    parameter integer TELEMETRY_VERSION = 1,
    parameter integer LED_HEARTBEAT_BIT = 8
) (
    (* clkbuf_inhibit *) input wire CRYSTAL_12MHZ,
    input  wire MPSSE_SCLK,
    input  wire MPSSE_MOSI,
    inout  wire MPSSE_MISO,
    input  wire MPSSE_CS_N,
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
        .PLLOUTGLOBALB(pll_216mhz),
        .DYNAMICDELAY(PLL_PORTA_DYNAMIC_DELAY), .RESETB(1'b1),
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
    wire i_sdm_bit_debug;
    wire q_sdm_bit_debug;
    wire [7:0] dds_phase_debug;
    wire signed [17:0] i_sdm_error_debug;
    wire signed [17:0] q_sdm_error_debug;
    wire [1:0] payload_symbol_debug;
    wire [15:0] payload_symbol_epoch_debug;
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
        .clk_108_i(clk_108), .rst_i(reset), .pll_lock_i(pll_lock),
        .arm_i(RF_COMPILE_ARMED != 0),
        .rf_out_o(RF_OUT), .tx_led_o(tx_led),
        .rf_drive_enable_debug_o(rf_drive_enable_debug),
        .burst_active_o(burst_active), .burst_done_o(burst_done),
        .datapath_ready_o(ready), .i_debug_o(i_debug), .q_debug_o(q_debug),
        .composite_strobe_debug_o(strobe_debug),
        .selector_i_debug_o(selector_i_debug),
        .selector_q_debug_o(selector_q_debug),
        .i_sdm_bit_debug_o(i_sdm_bit_debug),
        .q_sdm_bit_debug_o(q_sdm_bit_debug),
        .dds_phase_debug_o(dds_phase_debug),
        .i_sdm_error_debug_o(i_sdm_error_debug),
        .q_sdm_error_debug_o(q_sdm_error_debug),
        .payload_symbol_debug_o(payload_symbol_debug),
        .payload_symbol_epoch_debug_o(payload_symbol_epoch_debug)
    );
    assign LED_R = tx_led;

    // v7-v9 identify distinct one-variable RF profiles.  Exact elaboration
    // checks prevent a stale control frame from passing as candidate data.
    generate
        if (((TELEMETRY_VERSION == 7) ? 1 : 0)
                != ((FINAL_SELECTOR_ROTATE90 != 0) ? 1 : 0)) begin : g_bad_v7_profile
            initial $fatal(1,
                "telemetry v7 must identify FINAL_SELECTOR_ROTATE90=1 exactly");
        end
        if (((TELEMETRY_VERSION == 8) ? 1 : 0)
                != ((FINAL_RF_OE_COMPLEMENT != 0) ? 1 : 0)) begin : g_bad_v8_profile
            initial $fatal(1,
                "telemetry v8 must identify FINAL_RF_OE_COMPLEMENT=1 exactly");
        end
        if ((((TELEMETRY_VERSION == 9) || (TELEMETRY_VERSION == 10)) ? 1 : 0)
                != ((PLL_PORTA_DYNAMIC_DELAY == 8'd16) ? 1 : 0)) begin : g_bad_v9_profile
            initial $fatal(1,
                "telemetry v9/v10 must identify PLL_PORTA_DYNAMIC_DELAY=16 exactly");
        end
        if ((TELEMETRY_VERSION == 10)
                && ((PRBS_ADVANCE == 0) || (PROOF_LANE_INDEX >= 0)
                    || (FIRST_ACTIVE_LANE != 62) || (ACTIVE_CHANNELS != 1)
                    || (WAVE_PHASE_BITS != 5)
                    || (PROOF_CIC17_ENABLE == 0)
                    || (FINAL_SELECTOR_ROTATE90 != 0)
                    || (FINAL_RF_OE_COMPLEMENT != 0))) begin : g_bad_v10_payload_profile
            initial $fatal(1,
                "telemetry v10 requires lane62 PRBS QPSK on accepted v9 RF profile");
        end
        if ((FINAL_SELECTOR_ROTATE90 != 0)
                && ((FINAL_RF_OE_COMPLEMENT != 0)
                    || (PLL_PORTA_DYNAMIC_DELAY != 8'd0))) begin : g_bad_stacked_rotate
            initial $fatal(1,
                "selector discriminators may not be stacked");
        end
        if ((FINAL_RF_OE_COMPLEMENT != 0)
                && (PLL_PORTA_DYNAMIC_DELAY != 8'd0)) begin : g_bad_stacked_oe_delay
            initial $fatal(1,
                "RF OE complement and PLL-delay discriminator may not be stacked");
        end
    endgenerate

    /* Diagnostic mirror only.  It is clocked and reset identically to the
       Gray DDS but has no route into the transmitter. */
    reg [7:0] dds_phase_shadow_q = 8'd0;
    always @(posedge pll_216mhz) begin
        if (reset)
            dds_phase_shadow_q <= 8'd0;
        else
            dds_phase_shadow_q <= (dds_phase_shadow_q >= 8'd139)
                ? dds_phase_shadow_q - 8'd139
                : dds_phase_shadow_q + 8'd5;
    end

    reg recovered_i_sdm;
    reg recovered_q_sdm;
    always @* begin
        if (dds_phase_shadow_q < 8'd36) begin
            recovered_i_sdm = selector_i_debug;
            recovered_q_sdm = selector_q_debug;
        end else if (dds_phase_shadow_q < 8'd72) begin
            recovered_i_sdm = ~selector_q_debug;
            recovered_q_sdm = selector_i_debug;
        end else if (dds_phase_shadow_q < 8'd108) begin
            recovered_i_sdm = ~selector_i_debug;
            recovered_q_sdm = ~selector_q_debug;
        end else begin
            recovered_i_sdm = selector_q_debug;
            recovered_q_sdm = ~selector_i_debug;
        end
    end

    reg [63:0] telemetry_counter_q = 64'd0;
    reg [15:0] telemetry_sequence_q = 16'd0;
    always @(posedge CRYSTAL_12MHZ) begin
        telemetry_counter_q <= telemetry_counter_q + 1'b1;
        telemetry_sequence_q <= telemetry_sequence_q + 1'b1;
    end
    wire [7:0] status_byte = {
        tx_led, strobe_debug, rf_drive_enable_debug, burst_done,
        burst_active, ready, reset, pll_lock
    };
    /* v6 byte 20 and byte 22 bits 1:0 are direct live datapath taps.
       Earlier versions retain their duplicate/reconstructed semantics. */
    wire [7:0] telemetry_dds_phase = (TELEMETRY_VERSION >= 6)
        ? dds_phase_debug : dds_phase_shadow_q;
    wire telemetry_i_sdm = (TELEMETRY_VERSION >= 6)
        ? i_sdm_bit_debug : recovered_i_sdm;
    wire telemetry_q_sdm = (TELEMETRY_VERSION >= 6)
        ? q_sdm_bit_debug : recovered_q_sdm;
    /* GFT1 byte 22 bit 6 is the immutable CIC17 profile identifier. */
    wire [1:0] telemetry_phase_payload = (TELEMETRY_VERSION >= 10)
        ? payload_symbol_debug : telemetry_dds_phase[7:6];
    wire [7:0] phase_bits_byte = {
        strobe_debug, (PROOF_CIC17_ENABLE != 0), telemetry_phase_payload,
        selector_q_debug, selector_i_debug,
        telemetry_q_sdm, telemetry_i_sdm
    };
    localparam integer BOUNDED_ACTIVE = (ACTIVE_CHANNELS < 0) ? 0
        : ((ACTIVE_CHANNELS > 120) ? 120 : ACTIVE_CHANNELS);
    localparam integer EFFECTIVE_FIRST_ACTIVE_LANE =
        (PROOF_LANE_INDEX >= 0) ? PROOF_LANE_INDEX
        : ((FIRST_ACTIVE_LANE < 0)
            ? ((120 - BOUNDED_ACTIVE) / 2) : FIRST_ACTIVE_LANE);
    localparam integer EFFECTIVE_ACTIVE_CHANNELS =
        (PROOF_LANE_INDEX >= 0) ? 1 : ACTIVE_CHANNELS;
    localparam [7:0] TELEMETRY_ACTIVE_PROFILE_BYTE =
        (TELEMETRY_VERSION >= 5)
            ? {(PRBS_ADVANCE != 0), EFFECTIVE_ACTIVE_CHANNELS[6:0]}
            : EFFECTIVE_ACTIVE_CHANNELS[7:0];
    localparam [15:0] TELEMETRY_SOURCE_BYTES = (TELEMETRY_VERSION >= 4)
        ? {EFFECTIVE_FIRST_ACTIVE_LANE[7:0],
            TELEMETRY_ACTIVE_PROFILE_BYTE}
        : PROOF_LANE_INDEX[15:0];
    wire [39:0] direct_error_wave_pack = {
        WAVE_PHASE_BITS[3:0], i_sdm_error_debug, q_sdm_error_debug
    };
    wire [7:0] telemetry_byte23 = (TELEMETRY_VERSION >= 6)
        ? direct_error_wave_pack[39:32] : WAVE_PHASE_BITS[7:0];
    wire [31:0] telemetry_bytes26_29 = (TELEMETRY_VERSION >= 6)
        ? direct_error_wave_pack[31:0]
        : {telemetry_counter_q[15:0], telemetry_sequence_q};
    wire [15:0] telemetry_sequence_or_payload_epoch =
        (TELEMETRY_VERSION >= 10)
            ? payload_symbol_epoch_debug : telemetry_sequence_q;
    wire [255:0] live_frame = {
        32'h47465431, TELEMETRY_VERSION[7:0], 8'd32,
        telemetry_sequence_or_payload_epoch,
        telemetry_counter_q, i_debug, q_debug, telemetry_dds_phase,
        status_byte, phase_bits_byte, telemetry_byte23,
        TELEMETRY_SOURCE_BYTES, telemetry_bytes26_29, 16'hA55A
    };

    wire mpsse_miso_data;
    gf_mpsse_snapshot32 #(
        .FRAME_VERSION(TELEMETRY_VERSION),
        .FRAME_PROOF_LANE_INDEX(PROOF_LANE_INDEX),
        .FRAME_FIRST_ACTIVE_LANE(EFFECTIVE_FIRST_ACTIVE_LANE),
        .FRAME_ACTIVE_CHANNELS(EFFECTIVE_ACTIVE_CHANNELS),
        .FRAME_PRBS_ADVANCE(PRBS_ADVANCE)
    ) u_telemetry (
        .source_clk_i(CRYSTAL_12MHZ), .source_live_frame_i(live_frame),
        .mpsse_sclk_i(MPSSE_SCLK), .mpsse_cs_n_i(MPSSE_CS_N),
        .mpsse_miso_o(mpsse_miso_data)
    );
    SB_IO #(
        .PIN_TYPE(6'b101000), .IO_STANDARD("SB_LVCMOS"), .PULLUP(1'b0)
    ) mpsse_miso_io (
        .PACKAGE_PIN(MPSSE_MISO), .D_OUT_0(mpsse_miso_data),
        .OUTPUT_ENABLE(!MPSSE_CS_N)
    );

    /* MOSI is deliberately ignored in this read-only measurement image. */
    wire unused_mosi = MPSSE_MOSI;
endmodule

`default_nettype wire
