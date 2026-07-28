/*
 * Physical USB snapshot boundary for a continuously advancing binary32
 * divider.  Raw IEEE-754 encodings are consumed LSB-first, one scalar bit
 * from each operand on every 216 MHz clock.  USB records are deliberately
 * held and repeated; they never pause or qualify the arithmetic graph.
 */

`default_nettype none

/*
 * Exact five-bit enabled modulo-32 counter for the USB record position.
 * The transition is expressed entirely as fixed LUT equations followed by
 * resettable DFFs; synthesis therefore cannot replace `count + 1` with an
 * inferred arithmetic cell.
 */
module gf_usb_record_counter5 (
    input  wire       clk_i,
    input  wire       reset_i,
    input  wire       advance_i,
    output wire [4:0] count_o
);
    wire [4:0] count_d;
    wire carry_to_bit3;
    wire carry_to_bit4;

    /* bit 0: count[0] XOR advance */
    SB_LUT4 #(.LUT_INIT(16'h6666)) count_d0_lut (
        .I0(count_o[0]), .I1(advance_i), .I2(1'b0), .I3(1'b0),
        .O(count_d[0])
    );

    /* bit 1: count[1] XOR (advance AND count[0]) */
    SB_LUT4 #(.LUT_INIT(16'h6a6a)) count_d1_lut (
        .I0(count_o[1]), .I1(count_o[0]), .I2(advance_i), .I3(1'b0),
        .O(count_d[1])
    );

    /* bit 2: count[2] XOR (advance AND count[0] AND count[1]) */
    SB_LUT4 #(.LUT_INIT(16'h6aaa)) count_d2_lut (
        .I0(count_o[2]), .I1(count_o[0]),
        .I2(count_o[1]), .I3(advance_i),
        .O(count_d[2])
    );

    SB_LUT4 #(.LUT_INIT(16'h8000)) carry_to_bit3_lut (
        .I0(count_o[0]), .I1(count_o[1]),
        .I2(count_o[2]), .I3(advance_i),
        .O(carry_to_bit3)
    );
    SB_LUT4 #(.LUT_INIT(16'h6666)) count_d3_lut (
        .I0(count_o[3]), .I1(carry_to_bit3), .I2(1'b0), .I3(1'b0),
        .O(count_d[3])
    );

    SB_LUT4 #(.LUT_INIT(16'h8888)) carry_to_bit4_lut (
        .I0(carry_to_bit3), .I1(count_o[3]), .I2(1'b0), .I3(1'b0),
        .O(carry_to_bit4)
    );
    SB_LUT4 #(.LUT_INIT(16'h6666)) count_d4_lut (
        .I0(count_o[4]), .I1(carry_to_bit4), .I2(1'b0), .I3(1'b0),
        .O(count_d[4])
    );

    SB_DFFR count_bit0_dff (
        .C(clk_i), .R(reset_i), .D(count_d[0]), .Q(count_o[0])
    );
    SB_DFFR count_bit1_dff (
        .C(clk_i), .R(reset_i), .D(count_d[1]), .Q(count_o[1])
    );
    SB_DFFR count_bit2_dff (
        .C(clk_i), .R(reset_i), .D(count_d[2]), .Q(count_o[2])
    );
    SB_DFFR count_bit3_dff (
        .C(clk_i), .R(reset_i), .D(count_d[3]), .Q(count_o[3])
    );
    SB_DFFR count_bit4_dff (
        .C(clk_i), .R(reset_i), .D(count_d[4]), .Q(count_o[4])
    );
endmodule

module hx8k_mpsse_binary32_div_216_top (
    (* clkbuf_inhibit *) input wire CRYSTAL_12MHZ,
    input  wire MPSSE_SCLK,
    input  wire MPSSE_MOSI,
    inout  wire MPSSE_MISO,
    input  wire MPSSE_CS_N,
    inout  wire RF_OUT,
    output wire [7:0] LED
);
    localparam [31:0] BINARY32_ONE = 32'h3f800000;

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

    /* RF is outside this experiment: N16 is unconditionally high impedance. */
    SB_IO #(
        .PIN_TYPE(6'b101000), .IO_STANDARD("SB_LVCMOS"), .PULLUP(1'b0)
    ) rf_out_always_highz (
        .PACKAGE_PIN(RF_OUT), .D_OUT_0(1'b0), .OUTPUT_ENABLE(1'b0)
    );

    /*
     * One USB record contains numerator bit then denominator bit for each raw
     * binary32 position 0..31.  MPSSE shifts each byte MSB-first, so four
     * operand-bit pairs occupy each byte.
    */
    reg pair_slot_q;
    wire [4:0] record_bit_q;
    reg [31:0] numerator_shift_q;
    reg [31:0] denominator_shift_q;
    reg [31:0] usb_numerator_record_q;
    reg [31:0] usb_denominator_record_q;
    reg usb_record_epoch_q;
    (* async_reg = "true" *) reg usb_record_epoch_sync1_q;
    (* async_reg = "true" *) reg usb_record_epoch_sync2_q;
    reg input_epoch_seen_q;
    reg result_request_seen_q;
    wire result_capture_request;
    wire [3:0] result_capture_fanout_q;
    (* async_reg = "true" *) reg result_ack_sync1_q;
    (* async_reg = "true" *) reg result_ack_sync2_q;
    wire [31:0] result_record_q;
    reg [31:0] mpsse_result_record_q;

    gf_usb_record_counter5 usb_record_position (
        .clk_i(MPSSE_SCLK),
        .reset_i(MPSSE_CS_N),
        .advance_i(pair_slot_q),
        .count_o(record_bit_q)
    );

    always @(posedge MPSSE_SCLK or posedge MPSSE_CS_N) begin
        if (MPSSE_CS_N) begin
            pair_slot_q             <= 1'b0;
            numerator_shift_q       <= BINARY32_ONE;
            denominator_shift_q     <= BINARY32_ONE;
            usb_numerator_record_q  <= BINARY32_ONE;
            usb_denominator_record_q <= BINARY32_ONE;
            usb_record_epoch_q      <= 1'b0;
        end else begin
            if (!pair_slot_q) begin
                numerator_shift_q <= {
                    MPSSE_MOSI, numerator_shift_q[31:1]
                };
            end else begin
                denominator_shift_q <= {
                    MPSSE_MOSI, denominator_shift_q[31:1]
                };
                if (record_bit_q == 5'd31) begin
                    usb_numerator_record_q <= numerator_shift_q;
                    usb_denominator_record_q <= {
                        MPSSE_MOSI, denominator_shift_q[31:1]
                    };
                    usb_record_epoch_q <= !usb_record_epoch_q;
                end
            end
            pair_slot_q <= !pair_slot_q;
        end
    end

    /*
     * The core changes result_request_seen_q only after it has frozen a full
     * completed result into result_record_q.  Synchronizing that one-bit
     * acknowledgement makes result_record_q a bundled-data mailbox: by the
     * next 64-edge USB boundary it has been stable for many MPSSE clocks.
     */
    always @(posedge MPSSE_SCLK or posedge MPSSE_CS_N) begin
        if (MPSSE_CS_N) begin
            result_ack_sync1_q <= 1'b0;
            result_ack_sync2_q <= 1'b0;
        end else begin
            result_ack_sync1_q <= result_request_seen_q;
            result_ack_sync2_q <= result_ack_sync1_q;
        end
    end

    /* Freeze one coherent returned snapshot for the following USB record. */
    always @(posedge MPSSE_SCLK or posedge MPSSE_CS_N) begin
        if (MPSSE_CS_N)
            mpsse_result_record_q <= BINARY32_ONE;
        else if (
            pair_slot_q && (record_bit_q == 5'd31) &&
            (result_ack_sync2_q == usb_record_epoch_q)
        )
            mpsse_result_record_q <= result_record_q;
    end

    /* PLL lock is the only run/reset authority for the arithmetic graph. */
    reg [7:0] startup_q;
    always @(posedge pll_216mhz) begin
        if (!pll_lock)
            startup_q <= 8'd0;
        else
            startup_q <= {startup_q[6:0], 1'b1};
    end

    /* Register reset before its global distribution; deassert at 216 MHz. */
    reg core_reset_q;
    always @(posedge pll_216mhz or negedge pll_lock) begin
        if (!pll_lock)
            core_reset_q <= 1'b1;
        else
            core_reset_q <= !startup_q[7];
    end
    wire core_reset = core_reset_q;

    /*
     * Bundled-data input CDC.  The 64 data bits are committed before the
     * epoch toggles and remain unchanged for a complete 64-edge USB record.
     * Two scalar synchronizer flops therefore provide more than two 216 MHz
     * clocks of settling before the serializers are permitted to reload.
     */
    always @(posedge pll_216mhz or posedge core_reset) begin
        if (core_reset) begin
            usb_record_epoch_sync1_q <= 1'b0;
            usb_record_epoch_sync2_q <= 1'b0;
        end else begin
            usb_record_epoch_sync1_q <= usb_record_epoch_q;
            usb_record_epoch_sync2_q <= usb_record_epoch_sync1_q;
        end
    end

    /*
     * Local phase zero is the raw encoding's bit zero.  Reload on phase 31 so
     * the newly selected bit zero is present for the following phase-zero edge.
     */
    reg [31:0] serializer_phase_q;
    reg [31:0] numerator_stream_q;
    reg [31:0] denominator_stream_q;
    always @(posedge pll_216mhz or posedge core_reset) begin
        if (core_reset) begin
            serializer_phase_q  <= 32'd1;
            numerator_stream_q   <= BINARY32_ONE;
            denominator_stream_q <= BINARY32_ONE;
            input_epoch_seen_q   <= 1'b0;
        end else begin
            serializer_phase_q <= {
                serializer_phase_q[30:0], serializer_phase_q[31]
            };
            if (
                serializer_phase_q[31] &&
                (usb_record_epoch_sync2_q != input_epoch_seen_q)
            ) begin
                numerator_stream_q   <= usb_numerator_record_q;
                denominator_stream_q <= usb_denominator_record_q;
                input_epoch_seen_q   <= usb_record_epoch_sync2_q;
            end else begin
                /* Rotate forever: an unchanged USB record is repeated. */
                numerator_stream_q <= {
                    numerator_stream_q[0], numerator_stream_q[31:1]
                };
                denominator_stream_q <= {
                    denominator_stream_q[0], denominator_stream_q[31:1]
                };
            end
        end
    end

    wire result_bit;
    wire result_record_end;
    gf_binary32_divider_stream u_divider (
        .clk_i(pll_216mhz),
        .rst_i(core_reset),
        .numerator_bit_i(numerator_stream_q[0]),
        .denominator_bit_i(denominator_stream_q[0]),
        .result_bit_o(result_bit),
        .result_record_end_o(result_record_end)
    );

    /*
     * Capture one exact completed result for each committed USB input record.
     * This mailbox sampling never qualifies, stalls, or feeds back into the
     * continuously advancing divider graph.
     */
    reg [31:0] result_shift_q;

    /* end AND (new epoch != acknowledged epoch), registered four ways */
    SB_LUT4 #(.LUT_INIT(16'h2828)) result_capture_request_lut (
        .I0(result_record_end),
        .I1(usb_record_epoch_sync2_q),
        .I2(result_request_seen_q),
        .I3(1'b0),
        .O(result_capture_request)
    );
    for (genvar capture_lane = 0; capture_lane < 4;
         capture_lane = capture_lane + 1) begin : g_result_capture_fanout
        SB_DFFR capture_request_dff (
            .C(pll_216mhz), .R(core_reset),
            .D(result_capture_request),
            .Q(result_capture_fanout_q[capture_lane])
        );
    end

    /*
     * Each registered request drives only eight mailbox bits.  Explicit
     * retain/capture LUTs keep the select on the data path, preventing a
     * high-fanout inferred clock-enable from becoming a timing bottleneck.
     */
    for (genvar result_mailbox_bit = 0; result_mailbox_bit < 32;
         result_mailbox_bit = result_mailbox_bit + 1) begin : g_result_mailbox
        wire result_record_d;
        SB_LUT4 #(.LUT_INIT(16'hcaca)) result_record_mux (
            .I0(result_record_q[result_mailbox_bit]),
            .I1(result_shift_q[result_mailbox_bit]),
            .I2(result_capture_fanout_q[result_mailbox_bit / 8]),
            .I3(1'b0),
            .O(result_record_d)
        );
        if ((result_mailbox_bit >= 23) && (result_mailbox_bit <= 29)) begin
            SB_DFFS result_record_dff (
                .C(pll_216mhz), .S(core_reset), .D(result_record_d),
                .Q(result_record_q[result_mailbox_bit])
            );
        end else begin
            SB_DFFR result_record_dff (
                .C(pll_216mhz), .R(core_reset), .D(result_record_d),
                .Q(result_record_q[result_mailbox_bit])
            );
        end
    end

    always @(posedge pll_216mhz or posedge core_reset) begin
        if (core_reset) begin
            result_shift_q        <= BINARY32_ONE;
            result_request_seen_q <= 1'b0;
        end else begin
            result_shift_q <= {result_bit, result_shift_q[31:1]};
            if (result_capture_fanout_q[0]) begin
                /* The seen value itself is the return acknowledgement. */
                result_request_seen_q <= usb_record_epoch_sync2_q;
            end
        end
    end

    /* Both slots return the same result bit; disagreement detects incoherence. */
    wire mpsse_miso_data = mpsse_result_record_q[record_bit_q];
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
