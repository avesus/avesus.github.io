/*
 * Physical USB snapshot harness for the fully retimed continuous multiplier.
 *
 * USB commits a stable A/B word.  The 216 MHz serializer repeats that word
 * without pausing the arithmetic graph.  The multiplier itself has no load,
 * wait, ready, valid, enable, or stall input and consumes one bit every edge.
 */

`default_nettype none

module hx8k_mpsse_mul64_low_full_retime_216_top (
    (* clkbuf_inhibit *) input wire CRYSTAL_12MHZ,
    input  wire MPSSE_SCLK,
    input  wire MPSSE_MOSI,
    inout  wire MPSSE_MISO,
    input  wire MPSSE_CS_N,
    inout  wire RF_OUT,
    output wire [7:0] LED
);
    wire pll_216mhz;
    wire pll_lock;
    wire unused_pll_216mhz_90;
    SB_PLL40_2F_CORE #(
        .FEEDBACK_PATH("PHASE_AND_DELAY"),
        .DIVR(4'd0), .DIVF(7'd17), .DIVQ(3'd1),
        .FILTER_RANGE(3'd1),
        .DELAY_ADJUSTMENT_MODE_RELATIVE("DYNAMIC"),
        .SHIFTREG_DIV_MODE(0),
        .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
        .FDA_FEEDBACK(4'b0000),
        .PLLOUT_SELECT_PORTA("SHIFTREG_90deg"),
        .PLLOUT_SELECT_PORTB("SHIFTREG_0deg"),
        .ENABLE_ICEGATE_PORTA(0), .ENABLE_ICEGATE_PORTB(0)
    ) pll216 (
        .REFERENCECLK(CRYSTAL_12MHZ),
        .PLLOUTGLOBALA(unused_pll_216mhz_90),
        .PLLOUTGLOBALB(pll_216mhz),
        .DYNAMICDELAY(8'd0), .RESETB(1'b1),
        .BYPASS(1'b0), .LATCHINPUTVALUE(1'b0), .LOCK(pll_lock),
        .SDI(1'b0), .SDO(), .SCLK(1'b0)
    );

    /* The RF experiment is out of scope: N16 is always high impedance. */
    SB_IO #(
        .PIN_TYPE(6'b101000), .IO_STANDARD("SB_LVCMOS"), .PULLUP(1'b0)
    ) rf_out_always_highz (
        .PACKAGE_PIN(RF_OUT), .D_OUT_0(1'b0), .OUTPUT_ENABLE(1'b0)
    );

    /* USB frame: A bit then B bit, both LSB-first, for 64 bit positions. */
    reg pair_slot_q;
    reg [5:0] word_bit_q;
    reg [63:0] a_shift_q;
    reg [63:0] b_shift_q;
    reg [63:0] usb_a_word_q;
    reg [63:0] usb_b_word_q;
    (* async_reg = "true" *) reg [63:0] product_sync1_q;
    (* async_reg = "true" *) reg [63:0] product_sync2_q;
    reg [63:0] mpsse_product_word_q;

    always @(posedge MPSSE_SCLK or posedge MPSSE_CS_N) begin
        if (MPSSE_CS_N) begin
            pair_slot_q  <= 1'b0;
            word_bit_q   <= 6'd0;
            a_shift_q    <= 64'd0;
            b_shift_q    <= 64'd0;
            usb_a_word_q <= 64'd0;
            usb_b_word_q <= 64'd0;
        end else begin
            if (!pair_slot_q) begin
                a_shift_q <= {MPSSE_MOSI, a_shift_q[63:1]};
            end else begin
                b_shift_q <= {MPSSE_MOSI, b_shift_q[63:1]};
                if (word_bit_q == 6'd63) begin
                    usb_a_word_q <= a_shift_q;
                    usb_b_word_q <= {MPSSE_MOSI, b_shift_q[63:1]};
                    word_bit_q <= 6'd0;
                end else begin
                    word_bit_q <= word_bit_q + 1'b1;
                end
            end
            pair_slot_q <= !pair_slot_q;
        end
    end

    always @(posedge MPSSE_SCLK or posedge MPSSE_CS_N) begin
        if (MPSSE_CS_N)
            mpsse_product_word_q <= 64'd0;
        else if (pair_slot_q && (word_bit_q == 6'd63))
            mpsse_product_word_q <= product_sync2_q;
    end

    /* Bundled operands remain stable for many 216 MHz product windows. */
    (* async_reg = "true" *) reg [63:0] a_sync1_q;
    (* async_reg = "true" *) reg [63:0] a_sync2_q;
    (* async_reg = "true" *) reg [63:0] b_sync1_q;
    (* async_reg = "true" *) reg [63:0] b_sync2_q;
    always @(posedge pll_216mhz) begin
        a_sync1_q <= usb_a_word_q;
        a_sync2_q <= a_sync1_q;
        b_sync1_q <= usb_b_word_q;
        b_sync2_q <= b_sync1_q;
    end

    reg [7:0] startup_q;
    always @(posedge pll_216mhz) begin
        if (!pll_lock)
            startup_q <= 8'd0;
        else
            startup_q <= {startup_q[6:0], 1'b1};
    end
    /*
     * Register the active-high reset before its global distribution network.
     * This removes the startup-DFF -> inverter -> global-reset combinational
     * path and makes deassertion synchronous to the 216 MHz domain.
     */
    reg core_reset_q;
    always @(posedge pll_216mhz or negedge pll_lock) begin
        if (!pll_lock)
            core_reset_q <= 1'b1;
        else
            core_reset_q <= !startup_q[7];
    end
    wire core_reset = core_reset_q;

    /*
     * The core's first fanout stage samples bit zero while its local phase is
     * zero.  Load these source shifters on phase 63 so their old bit zero is
     * visible to the core on the following phase-zero edge.
     */
    reg [63:0] serializer_phase_q;
    reg [63:0] a_stream_q;
    reg [63:0] b_stream_q;
    always @(posedge pll_216mhz or posedge core_reset) begin
        if (core_reset) begin
            serializer_phase_q <= 64'd1;
            a_stream_q <= 64'd0;
            b_stream_q <= 64'd0;
        end else begin
            serializer_phase_q <= {serializer_phase_q[62:0], serializer_phase_q[63]};
            if (serializer_phase_q[63]) begin
                a_stream_q <= a_sync2_q;
                b_stream_q <= b_sync2_q;
            end else begin
                a_stream_q <= {1'b0, a_stream_q[63:1]};
                b_stream_q <= {1'b0, b_stream_q[63:1]};
            end
        end
    end

    wire product_bit;
    wire product_word_end;
    gf_logisim_mul64_low_full_retime u_mul (
        .clk_i(pll_216mhz), .rst_i(core_reset),
        .a_bit_i(a_stream_q[0]), .b_bit_i(b_stream_q[0]),
        .product_bit_o(product_bit),
        .product_word_end_o(product_word_end)
    );

    /* Capture the LSB-first stream after bit 63, with no arithmetic stall. */
    reg [63:0] product_shift_q;
    reg [63:0] product_word_q;
    always @(posedge pll_216mhz or posedge core_reset) begin
        if (core_reset) begin
            product_shift_q <= 64'd0;
            product_word_q  <= 64'd0;
        end else begin
            product_shift_q <= {product_bit, product_shift_q[63:1]};
            if (product_word_end)
                product_word_q <= {product_bit, product_shift_q[63:1]};
        end
    end

    always @(posedge MPSSE_SCLK) begin
        product_sync1_q <= product_word_q;
        product_sync2_q <= product_sync1_q;
    end

    wire mpsse_miso_data = mpsse_product_word_q[word_bit_q];
    SB_IO #(
        .PIN_TYPE(6'b101000), .IO_STANDARD("SB_LVCMOS"), .PULLUP(1'b0)
    ) mpsse_miso_io (
        .PACKAGE_PIN(MPSSE_MISO), .D_OUT_0(mpsse_miso_data),
        .OUTPUT_ENABLE(!MPSSE_CS_N)
    );

    assign LED[0] = pll_lock;
    assign LED[1] = serializer_phase_q[0];
    assign LED[7:2] = 6'd0;
endmodule

`default_nettype wire
