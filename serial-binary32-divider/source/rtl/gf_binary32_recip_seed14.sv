/*
 * Fourteen-digit scalar, non-restoring reciprocal-prefix seed for a
 * controlled-domain IEEE-754 binary32 divider.
 *
 * Input record, LSB first, 32 clocks forever:
 *   denominator_significand_bit_i[0..23] = unsigned M = 2^23 + fraction
 *   denominator_significand_bit_i[24..31] must be zero.
 *
 * Output record, also LSB first and delayed exactly 485 clocks:
 *   q_prefix_bit_o[27..14] = Q, with every other position zero
 *   remainder_bit_o[0..23] = restored unsigned P
 *   denominator_significand_bit_o[0..23] = the corresponding input M
 * record_start_o and record_end_o mark positions zero and 31 exactly.
 *
 * For every record the spatial recurrence is
 *
 *   R0 = 2^23
 *   Rj = 2*R(j-1) - M, when R(j-1) >= 0
 *        2*R(j-1) + M, otherwise
 *   qj = (Rj >= 0)
 *
 * A final conditional restore emits P = R14, or R14+M when R14<0.
 * The retained exact relation is
 *
 *   2^37 = Q*M + P,  Q = q1...q14,
 *
 * except at M=2^23 where Q is deliberately saturated to 2^14-1 and P=M.
 * Thus x0=Q/2^14 and rho=P/2^37 satisfy rho=1-D*x0 exactly.
 *
 * There is no behavioral wide arithmetic, table, ROM, transaction load,
 * ready/valid, step, clock enable, or stall.  Every numeric operation is a
 * one-bit LUT/DFF recurrence.  Record-start/prestart tokens are delayed with
 * the data and every carry/borrow is cleared on the local prestart token.
 */

`default_nettype none

module gf_b32_seed_delay_bit #(
    parameter integer DELAY = 1
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    output wire bit_o
);
    generate
        if (DELAY == 0) begin : g_zero
            assign bit_o = bit_i;
        end else begin : g_delay
            wire [DELAY:0] d;
            assign d[0] = bit_i;
            for (genvar n = 0; n < DELAY; n = n + 1) begin : g_dff
                (* keep = "true" *) SB_DFFR delay_dff (
                    .C(clk_i), .R(rst_i), .D(d[n]), .Q(d[n+1])
                );
            end
            assign bit_o = d[DELAY];
        end
    endgenerate
endmodule

module gf_b32_seed_delay32_taps (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        bit_i,
    output wire [32:0] tap_o
);
    assign tap_o[0] = bit_i;
    generate
        for (genvar n = 0; n < 32; n = n + 1) begin : g_dff
            (* keep = "true" *) SB_DFFR delay_dff (
                .C(clk_i), .R(rst_i), .D(tap_o[n]), .Q(tap_o[n+1])
            );
        end
    endgenerate
endmodule

module gf_b32_seed_phase_ring32 (
    input  wire        clk_i,
    input  wire        rst_i,
    output wire [31:0] phase_o
);
    (* keep = "true" *) SB_DFFS phase_zero (
        .C(clk_i), .S(rst_i), .D(phase_o[31]), .Q(phase_o[0])
    );
    generate
        for (genvar p = 1; p < 32; p = p + 1) begin : g_phase
            (* keep = "true" *) SB_DFFR phase_step (
                .C(clk_i), .R(rst_i), .D(phase_o[p-1]), .Q(phase_o[p])
            );
        end
    endgenerate
endmodule

/*
 * One non-restoring digit stage.
 *
 * remainder_bit_i is a signed 25-bit two's-complement stream in positions
 * 0..24, followed by seven zeros.  denominator_bit_i is unsigned in positions
 * 0..23, followed by eight zeros.  The one-clock remainder delay forms 2R;
 * the guaranteed zero at input position 31 injects numeric bit zero exactly.
 *
 * Both R+D and R-D are evaluated as independent scalar recurrences.  This
 * keeps every strict-timing state path to one LUT.  The prior-remainder sign
 * is sampled on record_prestart_i and selects the result for the whole record.
 */
module gf_b32_seed_nonrestoring_digit_stage (
    input  wire clk_i,
    input  wire rst_i,
    input  wire remainder_bit_i,
    input  wire denominator_bit_i,
    input  wire remainder_nonnegative_i,
    input  wire record_start_i,
    input  wire record_prestart_i,
    output wire remainder_bit_o,
    output wire denominator_bit_o,
    output wire remainder_nonnegative_o,
    output wire record_start_o,
    output wire record_prestart_o
);
    wire shifted_remainder_q;
    (* keep = "true" *) SB_DFFR remainder_shift (
        .C(clk_i), .R(rst_i), .D(remainder_bit_i),
        .Q(shifted_remainder_q)
    );

    /* Stable operation select: nonnegative prior R means subtract M. */
    wire subtract_select_next;
    wire subtract_select_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) select_lut (
        .I0(subtract_select_q), .I1(remainder_nonnegative_i),
        .I2(record_prestart_i), .I3(1'b0), .O(subtract_select_next)
    );
    (* keep = "true" *) SB_DFFS select_dff (
        .C(clk_i), .S(rst_i), .D(subtract_select_next),
        .Q(subtract_select_q)
    );

    /* R+D: ordinary serial full adder, cleared one clock before bit zero. */
    wire plus_sum_next;
    wire plus_carry_next;
    wire plus_sum_q;
    wire plus_carry_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h9696)) plus_sum_lut (
        .I0(shifted_remainder_q), .I1(denominator_bit_i),
        .I2(plus_carry_q), .I3(record_prestart_i), .O(plus_sum_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h00e8)) plus_carry_lut (
        .I0(shifted_remainder_q), .I1(denominator_bit_i),
        .I2(plus_carry_q), .I3(record_prestart_i), .O(plus_carry_next)
    );
    (* keep = "true" *) SB_DFFR plus_sum_dff (
        .C(clk_i), .R(rst_i), .D(plus_sum_next), .Q(plus_sum_q)
    );
    (* keep = "true" *) SB_DFFR plus_carry_dff (
        .C(clk_i), .R(rst_i), .D(plus_carry_next), .Q(plus_carry_q)
    );

    /* R-D: serial difference/borrow, also cleared before numeric bit zero. */
    wire minus_sum_next;
    wire minus_borrow_next;
    wire minus_sum_q;
    wire minus_borrow_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h9696)) minus_sum_lut (
        .I0(shifted_remainder_q), .I1(denominator_bit_i),
        .I2(minus_borrow_q), .I3(record_prestart_i), .O(minus_sum_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h00d4)) minus_borrow_lut (
        .I0(shifted_remainder_q), .I1(denominator_bit_i),
        .I2(minus_borrow_q), .I3(record_prestart_i), .O(minus_borrow_next)
    );
    (* keep = "true" *) SB_DFFR minus_sum_dff (
        .C(clk_i), .R(rst_i), .D(minus_sum_next), .Q(minus_sum_q)
    );
    (* keep = "true" *) SB_DFFR minus_borrow_dff (
        .C(clk_i), .R(rst_i), .D(minus_borrow_next), .Q(minus_borrow_q)
    );

    /*
     * The registered arithmetic result is one clock late.  start_tap[25]
     * is therefore the capture edge following numeric result bit 24.
     */
    wire [32:0] start_tap;
    gf_b32_seed_delay32_taps u_start_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(record_start_i),
        .tap_o(start_tap)
    );

    wire active_next;
    wire active_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h0e0e)) active_lut (
        .I0(active_q), .I1(record_start_i), .I2(start_tap[25]),
        .I3(1'b0), .O(active_next)
    );
    (* keep = "true" *) SB_DFFR active_dff (
        .C(clk_i), .R(rst_i), .D(active_next), .Q(active_q)
    );

    /* Select the operation and force output padding positions 25..31 low. */
    wire selected_result;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hca00)) result_select_lut (
        .I0(plus_sum_q), .I1(minus_sum_q), .I2(subtract_select_q),
        .I3(active_q), .O(selected_result)
    );

    /*
     * Give the selection LUT one dedicated packed DFF.  Its registered value
     * fans out to both the sign capture and reframe chain; exposing the LUT's
     * combinational output to both prevented that pack and inserted a full
     * extra route on the strict-clock path.
     */
    wire selected_result_q;
    (* keep = "true" *) SB_DFFR selected_result_dff (
        .C(clk_i), .R(rst_i), .D(selected_result), .Q(selected_result_q)
    );

    wire result_nonnegative_next;
    wire result_nonnegative_q;
    /*
     * Capture the useful polarity directly.  Besides removing a redundant
     * inverter, this keeps the digit-sideband path to one LUT before its
     * record-delay DFF at the strict clock gate.
     */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h3a3a)) nonnegative_capture_lut (
        .I0(result_nonnegative_q), .I1(selected_result_q),
        .I2(start_tap[26]), .I3(1'b0), .O(result_nonnegative_next)
    );
    (* keep = "true" *) SB_DFFS nonnegative_capture_dff (
        .C(clk_i), .S(rst_i), .D(result_nonnegative_next),
        .Q(result_nonnegative_q)
    );
    assign remainder_nonnegative_o = result_nonnegative_q;

    /* Registered sum, selected-result DFF, and 30 DFFs total one record. */
    gf_b32_seed_delay_bit #(.DELAY(30)) u_result_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(selected_result_q),
        .bit_o(remainder_bit_o)
    );
    gf_b32_seed_delay_bit #(.DELAY(32)) u_denominator_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(denominator_bit_i),
        .bit_o(denominator_bit_o)
    );
    assign record_start_o = start_tap[32];
    /* tap 31 is exactly one clock before the retimed start at tap 32. */
    assign record_prestart_o = start_tap[31];
endmodule

/* Final conditional restore: negative R14 becomes R14+M; otherwise pass R14. */
module gf_b32_seed_remainder_restore_stage (
    input  wire clk_i,
    input  wire rst_i,
    input  wire remainder_bit_i,
    input  wire denominator_bit_i,
    input  wire remainder_nonnegative_i,
    input  wire record_start_i,
    input  wire record_prestart_i,
    output wire remainder_bit_o,
    output wire denominator_bit_o,
    output wire record_start_o,
    output wire record_prestart_o
);
    wire restore_select_next;
    wire restore_select_q;
    /* On prestart select addition exactly when the incoming remainder is low. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h3a3a)) restore_select_lut (
        .I0(restore_select_q), .I1(remainder_nonnegative_i),
        .I2(record_prestart_i), .I3(1'b0), .O(restore_select_next)
    );
    (* keep = "true" *) SB_DFFR restore_select_dff (
        .C(clk_i), .R(rst_i), .D(restore_select_next),
        .Q(restore_select_q)
    );

    wire pass_q;
    (* keep = "true" *) SB_DFFR pass_dff (
        .C(clk_i), .R(rst_i), .D(remainder_bit_i), .Q(pass_q)
    );

    wire plus_sum_next;
    wire plus_carry_next;
    wire plus_sum_q;
    wire plus_carry_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h9696)) plus_sum_lut (
        .I0(remainder_bit_i), .I1(denominator_bit_i),
        .I2(plus_carry_q), .I3(record_prestart_i), .O(plus_sum_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h00e8)) plus_carry_lut (
        .I0(remainder_bit_i), .I1(denominator_bit_i),
        .I2(plus_carry_q), .I3(record_prestart_i), .O(plus_carry_next)
    );
    (* keep = "true" *) SB_DFFR plus_sum_dff (
        .C(clk_i), .R(rst_i), .D(plus_sum_next), .Q(plus_sum_q)
    );
    (* keep = "true" *) SB_DFFR plus_carry_dff (
        .C(clk_i), .R(rst_i), .D(plus_carry_next), .Q(plus_carry_q)
    );

    wire [32:0] start_tap;
    gf_b32_seed_delay32_taps u_start_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(record_start_i),
        .tap_o(start_tap)
    );

    /* P is unsigned 24-bit, so clear immediately after numeric bit 23. */
    wire active_next;
    wire active_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h0e0e)) active_lut (
        .I0(active_q), .I1(record_start_i), .I2(start_tap[24]),
        .I3(1'b0), .O(active_next)
    );
    (* keep = "true" *) SB_DFFR active_dff (
        .C(clk_i), .R(rst_i), .D(active_next), .Q(active_q)
    );

    wire selected_result;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hca00)) result_select_lut (
        .I0(pass_q), .I1(plus_sum_q), .I2(restore_select_q),
        .I3(active_q), .O(selected_result)
    );

    gf_b32_seed_delay_bit #(.DELAY(31)) u_result_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(selected_result),
        .bit_o(remainder_bit_o)
    );
    gf_b32_seed_delay_bit #(.DELAY(32)) u_denominator_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(denominator_bit_i),
        .bit_o(denominator_bit_o)
    );
    assign record_start_o = start_tap[32];
    assign record_prestart_o = start_tap[31];
endmodule

/* Stable one-bit sideband delay, advanced on the record-end/prestart pulse. */
module gf_b32_seed_flag_record_delay #(
    parameter integer RECORDS = 1
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire capture_i,
    input  wire flag_i,
    output wire flag_o
);
    generate
        if (RECORDS == 0) begin : g_zero
            assign flag_o = flag_i;
        end else begin : g_records
            wire [RECORDS-1:0] q;
            for (genvar n = 0; n < RECORDS; n = n + 1) begin : g_flag
                wire source = (n == 0) ? flag_i : q[n-1];
                wire next_q;
                (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) hold_mux (
                    .I0(q[n]), .I1(source), .I2(capture_i), .I3(1'b0),
                    .O(next_q)
                );
                (* keep = "true" *) SB_DFFR flag_dff (
                    .C(clk_i), .R(rst_i), .D(next_q), .Q(q[n])
                );
            end
            assign flag_o = q[RECORDS-1];
        end
    endgenerate
endmodule

/*
 * Serialize fourteen stable quotient digits into Q0.28 positions 27..14.
 * A four-level registered LUT tree limits every path to one LUT.  Two local
 * branch relays add a fifth registered level before the final fold so the
 * widely separated upper and lower digit groups never require a long direct
 * route into the same LUT.  The caller delays P and the record tokens by the
 * same five clocks.
 */
module gf_b32_seed_qprefix14_serializer (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [13:0] digit_i,
    input  wire [32:0] phase_tap_i,
    output wire        bit_o
);
    wire [6:0] level0_q;
    generate
        for (genvar pair = 0; pair < 7; pair = pair + 1) begin : g_pair
            wire pair_next;
            localparam integer D0 = 2*pair;
            localparam integer D1 = 2*pair + 1;
            localparam integer P0 = 27 - D0;
            localparam integer P1 = 27 - D1;
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hf888)) pair_lut (
                .I0(digit_i[D0]), .I1(phase_tap_i[P0]),
                .I2(digit_i[D1]), .I3(phase_tap_i[P1]),
                .O(pair_next)
            );
            (* keep = "true" *) SB_DFFR pair_dff (
                .C(clk_i), .R(rst_i), .D(pair_next), .Q(level0_q[pair])
            );
        end
    endgenerate

    wire [3:0] level1_q;
    wire level1_next0;
    wire level1_next1;
    wire level1_next2;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'heeee)) level1_lut0 (
        .I0(level0_q[0]), .I1(level0_q[1]), .I2(1'b0), .I3(1'b0),
        .O(level1_next0)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'heeee)) level1_lut1 (
        .I0(level0_q[2]), .I1(level0_q[3]), .I2(1'b0), .I3(1'b0),
        .O(level1_next1)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'heeee)) level1_lut2 (
        .I0(level0_q[4]), .I1(level0_q[5]), .I2(1'b0), .I3(1'b0),
        .O(level1_next2)
    );
    (* keep = "true" *) SB_DFFR level1_dff0 (
        .C(clk_i), .R(rst_i), .D(level1_next0), .Q(level1_q[0])
    );
    (* keep = "true" *) SB_DFFR level1_dff1 (
        .C(clk_i), .R(rst_i), .D(level1_next1), .Q(level1_q[1])
    );
    (* keep = "true" *) SB_DFFR level1_dff2 (
        .C(clk_i), .R(rst_i), .D(level1_next2), .Q(level1_q[2])
    );
    (* keep = "true" *) SB_DFFR level1_dff3 (
        .C(clk_i), .R(rst_i), .D(level0_q[6]), .Q(level1_q[3])
    );

    wire [1:0] level2_q;
    wire level2_next0;
    wire level2_next1;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'heeee)) level2_lut0 (
        .I0(level1_q[0]), .I1(level1_q[1]), .I2(1'b0), .I3(1'b0),
        .O(level2_next0)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'heeee)) level2_lut1 (
        .I0(level1_q[2]), .I1(level1_q[3]), .I2(1'b0), .I3(1'b0),
        .O(level2_next1)
    );
    (* keep = "true" *) SB_DFFR level2_dff0 (
        .C(clk_i), .R(rst_i), .D(level2_next0), .Q(level2_q[0])
    );
    (* keep = "true" *) SB_DFFR level2_dff1 (
        .C(clk_i), .R(rst_i), .D(level2_next1), .Q(level2_q[1])
    );

    wire [1:0] level2_relay_q;
    (* keep = "true" *) SB_DFFR level2_relay0_dff (
        .C(clk_i), .R(rst_i), .D(level2_q[0]), .Q(level2_relay_q[0])
    );
    (* keep = "true" *) SB_DFFR level2_relay1_dff (
        .C(clk_i), .R(rst_i), .D(level2_q[1]), .Q(level2_relay_q[1])
    );

    wire level3_next;
    wire level3_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'heeee)) level3_lut (
        .I0(level2_relay_q[0]), .I1(level2_relay_q[1]),
        .I2(1'b0), .I3(1'b0),
        .O(level3_next)
    );
    (* keep = "true" *) SB_DFFR level3_dff (
        .C(clk_i), .R(rst_i), .D(level3_next), .Q(level3_q)
    );
    assign bit_o = level3_q;
endmodule

module gf_binary32_recip_seed14 (
    input  wire clk_i,
    input  wire rst_i,
    input  wire denominator_significand_bit_i,
    output wire q_prefix_bit_o,
    output wire remainder_bit_o,
    output wire denominator_significand_bit_o,
    output wire record_start_o,
    output wire record_end_o
);
    wire [31:0] input_phase;
    gf_b32_seed_phase_ring32 u_input_phase (
        .clk_i(clk_i), .rst_i(rst_i), .phase_o(input_phase)
    );

    wire [14:0] remainder_stream;
    wire [14:0] denominator_stream;
    wire [14:0] nonnegative_flag;
    wire [14:0] start_token;
    wire [14:0] prestart_token;
    wire [13:0] digit_flag;

    /* R0=2^23, with signed bit 24 and padding positions 25..31 low. */
    assign remainder_stream[0] = input_phase[23];
    assign denominator_stream[0] = denominator_significand_bit_i;
    assign nonnegative_flag[0] = 1'b1;
    assign start_token[0] = input_phase[0];
    assign prestart_token[0] = input_phase[31];

    generate
        for (genvar digit = 0; digit < 14; digit = digit + 1) begin : g_digit
            gf_b32_seed_nonrestoring_digit_stage u_stage (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .remainder_bit_i(remainder_stream[digit]),
                .denominator_bit_i(denominator_stream[digit]),
                .remainder_nonnegative_i(nonnegative_flag[digit]),
                .record_start_i(start_token[digit]),
                .record_prestart_i(prestart_token[digit]),
                .remainder_bit_o(remainder_stream[digit+1]),
                .denominator_bit_o(denominator_stream[digit+1]),
                .remainder_nonnegative_o(nonnegative_flag[digit+1]),
                .record_start_o(start_token[digit+1]),
                .record_prestart_o(prestart_token[digit+1])
            );
            assign digit_flag[digit] = nonnegative_flag[digit+1];
        end
    endgenerate

    wire restored_remainder;
    wire restored_denominator;
    wire restored_start;
    wire restored_prestart;
    gf_b32_seed_remainder_restore_stage u_restore (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .remainder_bit_i(remainder_stream[14]),
        .denominator_bit_i(denominator_stream[14]),
        .remainder_nonnegative_i(nonnegative_flag[14]),
        .record_start_i(start_token[14]),
        .record_prestart_i(prestart_token[14]),
        .remainder_bit_o(restored_remainder),
        .denominator_bit_o(restored_denominator),
        .record_start_o(restored_start),
        .record_prestart_o(restored_prestart)
    );

    /* Delay qj by 15-j records so every digit accompanies restored P. */
    wire [13:0] aligned_digit;
    generate
        for (genvar digit = 0; digit < 14; digit = digit + 1) begin : g_align
            localparam integer RECORD_DELAY = 14 - digit;
            gf_b32_seed_flag_record_delay #(.RECORDS(RECORD_DELAY)) u_digit_delay (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .capture_i(prestart_token[digit+1]),
                .flag_i(digit_flag[digit]),
                .flag_o(aligned_digit[digit])
            );
        end
    endgenerate

    wire [32:0] restored_phase;
    gf_b32_seed_delay32_taps u_restored_phase (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(restored_start),
        .tap_o(restored_phase)
    );

    wire q_prefix_before_output_delay;
    gf_b32_seed_qprefix14_serializer u_q_serializer (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .digit_i(aligned_digit),
        .phase_tap_i(restored_phase),
        .bit_o(q_prefix_before_output_delay)
    );
    assign q_prefix_bit_o = q_prefix_before_output_delay;

    /* Match the five registered serializer levels on P, M, and both tokens. */
    gf_b32_seed_delay_bit #(.DELAY(5)) u_remainder_output_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(restored_remainder),
        .bit_o(remainder_bit_o)
    );
    gf_b32_seed_delay_bit #(.DELAY(5)) u_denominator_output_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(restored_denominator),
        .bit_o(denominator_significand_bit_o)
    );
    gf_b32_seed_delay_bit #(.DELAY(5)) u_start_output_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(restored_start),
        .bit_o(record_start_o)
    );
    gf_b32_seed_delay_bit #(.DELAY(5)) u_end_output_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(restored_phase[31]),
        .bit_o(record_end_o)
    );

    /* Keep the exact prestart association live for synthesis-phase review. */
    wire unused_restored_prestart = restored_prestart;
endmodule

/* Standalone complete seed fit shell for a strict 432 MHz place/route gate. */
module gf_binary32_recip_seed14_fit_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire denominator_significand_bit_i,
    output wire q_prefix_bit_o,
    output wire remainder_bit_o,
    output wire denominator_significand_bit_o,
    output wire record_start_o,
    output wire record_end_o
);
    gf_binary32_recip_seed14 u_seed (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .denominator_significand_bit_i(denominator_significand_bit_i),
        .q_prefix_bit_o(q_prefix_bit_o),
        .remainder_bit_o(remainder_bit_o),
        .denominator_significand_bit_o(denominator_significand_bit_o),
        .record_start_o(record_start_o),
        .record_end_o(record_end_o)
    );
endmodule

`default_nettype wire
