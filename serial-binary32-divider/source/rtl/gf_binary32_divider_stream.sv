/*
 * Bubble-free scalar-stream IEEE-754 binary32 divider.
 *
 * IEEE encoding exists only at the two input pins and the output pin.  After
 * the boundary split, significand, exponent, and sign histories remain
 * separate fixed-phase streams until the single final pack.  The controlled
 * application domain is finite, nonzero, normal inputs with a finite normal
 * result; no overflow, exceptional-value, ready, valid, wait, load, or stall
 * machinery is present.
 *
 * Internal record schedule (each arrow is 32 uninterrupted clocks):
 *
 *   U0  split operands; compare A and B; seed B
 *   U1  A' = A << (A<B)
 *   U16 phase-reframed Q/P/B seed result
 *   U17 Q(integer) and P enter Q*P
 *   U21 registered C=floor(Q*P/2^23), then X1=(Q<<14)+C
 *   U22 A'*X1
 *   U26 registered q0=floor(A'*X1/2^28), then q0*B
 *   U27 Nlow-q0*B (mod 2^32, exact residual by the proven bound)
 *   U28 compare residual with B; form both correction choices
 *   U29 exact floor quotient/remainder; form both RNE choices
 *   U30 rounded significand plus delayed exponent/sign
 *   U31 one-LUT-per-stage registered IEEE boundary pack
 *
 * Every arithmetic data port is one bit wide.  Vectors are only physical
 * delay/phase banks.  No behavioral +, -, *, /, or % is used.
 */

`default_nettype none

module gf_binary32_divider_stream (
    input  wire clk_i,
    input  wire rst_i,
    input  wire numerator_bit_i,
    input  wire denominator_bit_i,
    output wire result_bit_o,
    output wire result_record_end_o
);
    wire [31:0] core_phase;
    wire pack_phase23_local;
    wire pack_phase31_local;
    gf_b32_phase32 u_core_phase (
        .clk_i(clk_i), .rst_i(rst_i), .phase_o(core_phase)
    );
    /* Two local four-DFF relays replace a duplicate 32-DFF pack phase ring. */
    gf_b32_delay_bit #(.CLOCKS(4)) u_pack_phase23_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(core_phase[19]),
        .bit_o(pack_phase23_local)
    );
    gf_b32_delay_bit #(.CLOCKS(4)) u_pack_phase31_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(core_phase[27]),
        .bit_o(pack_phase31_local)
    );

    /* U0: split IEEE fields exactly once. */
    wire numerator_significand_u0;
    wire denominator_significand_u0;
    wire numerator_exponent_u0;
    wire denominator_exponent_u0;
    wire numerator_sign_u0;
    wire denominator_sign_u0;

    gf_b32_unpack_boundary u_unpack_numerator (
        .clk_i(clk_i), .rst_i(rst_i), .raw_bit_i(numerator_bit_i),
        .significand_bit_o(numerator_significand_u0),
        .exponent_bit_o(numerator_exponent_u0),
        .sign_o(numerator_sign_u0)
    );
    gf_b32_unpack_boundary u_unpack_denominator (
        .clk_i(clk_i), .rst_i(rst_i), .raw_bit_i(denominator_bit_i),
        .significand_bit_o(denominator_significand_u0),
        .exponent_bit_o(denominator_exponent_u0),
        .sign_o(denominator_sign_u0)
    );

    /* U0 -> U1: normalize the numerator ratio into [1,2). */
    wire denominator_gt_numerator_u0;
    wire unused_significands_equal_u0;
    wire unused_denominator_ge_numerator_u0;
    gf_b32_serial_compare #(.SERIAL_BITS(24)) u_significand_compare (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(denominator_significand_u0),
        .y_bit_i(numerator_significand_u0),
        .gt_o(denominator_gt_numerator_u0),
        .eq_o(unused_significands_equal_u0),
        .ge_o(unused_denominator_ge_numerator_u0)
    );

    wire adjust_exponent_u1;
    /* Compare result is registered in phase 25; seven DFFs land at U1/p0. */
    gf_b32_delay_bit #(.CLOCKS(7)) u_capture_adjust (
        .clk_i(clk_i), .rst_i(rst_i),
        .bit_i(denominator_gt_numerator_u0),
        .bit_o(adjust_exponent_u1)
    );

    wire numerator_significand_delayed_u1;
    wire numerator_normalized_u1;
    gf_b32_delay_bit #(.CLOCKS(32)) u_numerator_to_u1 (
        .clk_i(clk_i), .rst_i(rst_i),
        .bit_i(numerator_significand_u0),
        .bit_o(numerator_significand_delayed_u1)
    );
    gf_b32_select_shift0_or1 u_normalize_numerator (
        .clk_i(clk_i), .rst_i(rst_i),
        .bit_i(numerator_significand_delayed_u1),
        .shift_one_i(adjust_exponent_u1),
        .bit_o(numerator_normalized_u1)
    );
    wire numerator_normalized_u2;
    /* Register the normalize-select LUT before the long phase-local history. */
    gf_b32_delay_bit #(.CLOCKS(32)) u_normalized_record_cut (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(numerator_normalized_u1),
        .bit_o(numerator_normalized_u2)
    );

    /*
     * Fourteen exact non-restoring digits retain 2^37=Q*B+P.  Its natural
     * result phase is +5 clocks, so 27 DFFs make the next global phase zero.
     */
    wire seed_q_phase4;
    wire seed_p_phase4;
    wire seed_b_phase4;
    gf_binary32_recip_seed14 u_seed (
        .clk_i(clk_i), .rst_i(rst_i),
        .denominator_significand_bit_i(denominator_significand_u0),
        .q_prefix_bit_o(seed_q_phase4),
        .remainder_bit_o(seed_p_phase4),
        .denominator_significand_bit_o(seed_b_phase4),
        .record_start_o(),
        .record_end_o()
    );

    wire seed_q_u16;
    wire seed_p_u16;
    wire seed_b_u16;
    gf_b32_delay_bit #(.CLOCKS(27)) u_seed_q_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(seed_q_phase4),
        .bit_o(seed_q_u16)
    );
    gf_b32_delay_bit #(.CLOCKS(27)) u_seed_p_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(seed_p_phase4),
        .bit_o(seed_p_u16)
    );
    gf_b32_delay_bit #(.CLOCKS(27)) u_seed_b_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(seed_b_phase4),
        .bit_o(seed_b_u16)
    );
    /* U16 -> U17: causally move Q[27:14] to integer positions [13:0]. */
    wire seed_q_integer_u17;
    wire seed_p_u17;
    gf_b32_delay_bit #(.CLOCKS(18)) u_q_integer_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(seed_q_u16),
        .bit_o(seed_q_integer_u17)
    );
    gf_b32_delay_bit #(.CLOCKS(32)) u_seed_p_to_u17 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(seed_p_u16),
        .bit_o(seed_p_u17)
    );

    /* First NR product: registered C=floor(Q*P/2^23), returned at U21. */
    wire qp_shift23_u20;
    gf_binary32_mul24_shift23_ii32 u_q_times_p (
        .clk_i(clk_i), .rst_i(rst_i),
        .a_bit_i(seed_q_integer_u17), .b_bit_i(seed_p_u17),
        .window_shift23_25_bit_o(qp_shift23_u20)
    );

    wire [160:0] seed_q_history;
    gf_b32_delay_taps #(.CLOCKS(160)) u_q_to_u21 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(seed_q_u16),
        .tap_o(seed_q_history)
    );
    wire x1_u21;
    gf_b32_serial_addsub #(.SUBTRACT(0)) u_form_x1 (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(seed_q_history[160]),
        .y_bit_i(qp_shift23_u20),
        .sum_bit_o(x1_u21)
    );

    /* A plain scalar delay keeps the full stream phase exact to U21. */
    wire numerator_normalized_u21;
    gf_b32_delay_bit #(.CLOCKS(640)) u_numerator_to_u22 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(numerator_normalized_u2),
        .bit_o(numerator_normalized_u21)
    );
    wire [160:0] numerator_history_u21;
    gf_b32_delay_taps #(.CLOCKS(160)) u_numerator_u22_to_u27 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(numerator_normalized_u21),
        .tap_o(numerator_history_u21)
    );

    /* Second product: registered q0=floor(A'*X1/2^28), returned at U26. */
    wire q0_u24;
    gf_binary32_mul32_shift28_ii32 u_a_times_x1 (
        .clk_i(clk_i), .rst_i(rst_i),
        .a_bit_i(numerator_normalized_u21), .b_bit_i(x1_u21),
        .window_shift28_25_bit_o(q0_u24)
    );

    /* The seed already carried B; preserve ten whole records to U24. */
    wire denominator_u24;
    gf_b32_delay_bit #(.CLOCKS(320)) u_denominator_to_u26 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(seed_b_u16),
        .bit_o(denominator_u24)
    );
    wire [96:0] denominator_history_u24;
    gf_b32_delay_taps #(.CLOCKS(96)) u_denominator_u24_to_u27 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(denominator_u24),
        .tap_o(denominator_history_u24)
    );

    /* Third product: only low 32 bits are required by the residual proof. */
    wire q_times_b_low32_u25;
    gf_binary32_mul24_low32_ii32 u_q_times_b (
        .clk_i(clk_i), .rst_i(rst_i),
        .a_bit_i(q0_u24), .b_bit_i(denominator_u24),
        .product_low32_bit_o(q_times_b_low32_u25)
    );

    /* Nlow=(A'<<23) mod 2^32: only A'[8:0] occupies positions 31:23. */
    wire numerator_low9_mask_u25;
    wire numerator_low9_u25;
    wire numerator_low32_u25;
    gf_b32_constant_stream #(.VALUE(32'h000001ff)) u_low9_mask (
        .clk_i(clk_i), .rst_i(rst_i), .bit_o(numerator_low9_mask_u25)
    );
    gf_b32_and_flag u_numerator_low9_gate (
        .bit_i(numerator_history_u21[160]),
        .flag_i(numerator_low9_mask_u25),
        .bit_o(numerator_low9_u25)
    );
    gf_b32_delay_bit #(.CLOCKS(23)) u_numerator_shift23 (
        .clk_i(clk_i), .rst_i(rst_i),
        .bit_i(numerator_low9_u25),
        .bit_o(numerator_low32_u25)
    );

    wire residual_u26;
    gf_b32_serial_addsub #(.SUBTRACT(1)) u_exact_residual (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(numerator_low32_u25),
        .y_bit_i(q_times_b_low32_u25),
        .sum_bit_o(residual_u26)
    );

    /* U26: q0 is at most one low.  Compute both fixed correction branches. */
    wire residual_ge_b_u26;
    wire unused_residual_eq_b_u26;
    wire unused_residual_gt_b_u26;
    gf_b32_serial_compare #(.SERIAL_BITS(25)) u_residual_compare (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(residual_u26), .y_bit_i(denominator_history_u24[64]),
        .gt_o(unused_residual_gt_b_u26),
        .eq_o(unused_residual_eq_b_u26),
        .ge_o(residual_ge_b_u26)
    );
    wire apply_correction_next;
    wire apply_correction_u27;
    /* Fold GT|EQ and the phase-31 hold into one LUT before the flag DFF. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hfcaa)) correction_capture_lut (
        .I0(apply_correction_u27), .I1(unused_residual_gt_b_u26),
        .I2(unused_residual_eq_b_u26), .I3(core_phase[31]),
        .O(apply_correction_next)
    );
    (* keep = "true" *) SB_DFFR correction_capture_dff (
        .C(clk_i), .R(rst_i), .D(apply_correction_next),
        .Q(apply_correction_u27)
    );

    wire residual_minus_b_u27;
    wire residual_delayed_u27;
    gf_b32_serial_addsub #(.SUBTRACT(1)) u_residual_minus_b (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(residual_u26), .y_bit_i(denominator_history_u24[64]),
        .sum_bit_o(residual_minus_b_u27)
    );
    gf_b32_delay_bit #(.CLOCKS(32)) u_residual_to_u27 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(residual_u26),
        .bit_o(residual_delayed_u27)
    );
    wire corrected_residual_u27;
    gf_b32_mux_bit u_select_corrected_residual (
        .a_bit_i(residual_delayed_u27),
        .b_bit_i(residual_minus_b_u27),
        .select_b_i(apply_correction_u27),
        .bit_o(corrected_residual_u27)
    );

    wire [96:0] q0_history;
    gf_b32_delay_taps #(.CLOCKS(96)) u_q0_history (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(q0_u24),
        .tap_o(q0_history)
    );

    /* Capture q0 bit zero at U26 and carry that one sideband to U29. */
    wire q0_lsb_capture_next;
    wire q0_lsb_capture_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) q0_lsb_capture_lut (
        .I0(q0_lsb_capture_q), .I1(q0_u24), .I2(core_phase[0]),
        .I3(1'b0), .O(q0_lsb_capture_next)
    );
    (* keep = "true" *) SB_DFFR q0_lsb_capture_dff (
        .C(clk_i), .R(rst_i), .D(q0_lsb_capture_next),
        .Q(q0_lsb_capture_q)
    );
    wire q0_lsb_boundary_q;
    (* keep = "true" *) SB_DFFR q0_lsb_boundary_dff (
        .C(clk_i), .R(rst_i), .D(core_phase[30]), .Q(q0_lsb_boundary_q)
    );
    wire [2:0] q0_lsb_record_q;
    generate
        for (genvar lsb_record = 0; lsb_record < 3;
             lsb_record = lsb_record + 1) begin : g_q0_lsb_record
            wire lsb_source = (lsb_record == 0) ? q0_lsb_capture_q :
                q0_lsb_record_q[lsb_record-1];
            wire lsb_next;
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) lsb_delay_lut (
                .I0(q0_lsb_record_q[lsb_record]), .I1(lsb_source),
                .I2(q0_lsb_boundary_q), .I3(1'b0), .O(lsb_next)
            );
            (* keep = "true" *) SB_DFFR lsb_delay_dff (
                .C(clk_i), .R(rst_i), .D(lsb_next),
                .Q(q0_lsb_record_q[lsb_record])
            );
        end
    endgenerate
    wire q0_plus_one_u27;
    gf_b32_serial_cond_one #(.SUBTRACT(0)) u_q0_plus_one (
        .clk_i(clk_i), .rst_i(rst_i), .x_bit_i(q0_history[64]),
        .condition_i(1'b1), .sum_bit_o(q0_plus_one_u27)
    );
    wire q0_u27_relay;
    wire q0_plus_one_u27_relay;
    wire correction_u27_relay;
    gf_b32_delay_bit #(.CLOCKS(4)) u_q0_correction_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(q0_history[96]),
        .bit_o(q0_u27_relay)
    );
    gf_b32_delay_bit #(.CLOCKS(4)) u_q0_plus_correction_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(q0_plus_one_u27),
        .bit_o(q0_plus_one_u27_relay)
    );
    gf_b32_delay_bit #(.CLOCKS(4)) u_correction_select_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(apply_correction_u27),
        .bit_o(correction_u27_relay)
    );
    wire corrected_quotient_u27;
    gf_b32_mux_bit u_select_corrected_quotient (
        .a_bit_i(q0_u27_relay), .b_bit_i(q0_plus_one_u27_relay),
        .select_b_i(correction_u27_relay),
        .bit_o(corrected_quotient_u27)
    );

    /* U27: exact round-to-nearest, ties-to-even from the exact remainder. */
    wire twice_residual_gt_b_u27;
    wire twice_residual_eq_b_u27;
    wire unused_twice_residual_ge_b_u27;
    gf_b32_serial_compare_shifted_x #(.SERIAL_BITS(25)) u_round_compare (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(corrected_residual_u27),
        .y_bit_i(denominator_history_u24[96]),
        .gt_o(twice_residual_gt_b_u27),
        .eq_o(twice_residual_eq_b_u27),
        .ge_o(unused_twice_residual_ge_b_u27)
    );

    wire round_candidate_next_u27;
    wire round_candidate_u27;
    /* GT || (EQ && (q0_lsb XOR correction)), fused into one LUT. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'haeea)) round_lut (
        .I0(twice_residual_gt_b_u27), .I1(twice_residual_eq_b_u27),
        .I2(q0_lsb_record_q[2]), .I3(apply_correction_u27),
        .O(round_candidate_next_u27)
    );
    (* keep = "true" *) SB_DFFR round_candidate_dff (
        .C(clk_i), .R(rst_i), .D(round_candidate_next_u27),
        .Q(round_candidate_u27)
    );
    wire round_up_u28;
    /* Registered compare is correct at phase 27; five DFFs land at phase 0. */
    gf_b32_delay_bit #(.CLOCKS(5)) u_round_to_next_record (
        .clk_i(clk_i), .rst_i(rst_i),
        .bit_i(round_candidate_u27), .bit_o(round_up_u28)
    );

    wire quotient_plus_one_u28;
    wire quotient_delayed_u28;
    wire q0_for_round_u27;
    gf_b32_delay_bit #(.CLOCKS(32)) u_q0_round_branch (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(q0_history[64]),
        .bit_o(q0_for_round_u27)
    );
    gf_b32_serial_add_one_or_two u_quotient_plus_one (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(q0_for_round_u27),
        .correction_gt_i(unused_residual_gt_b_u26),
        .correction_eq_i(unused_residual_eq_b_u26),
        .sum_bit_o(quotient_plus_one_u28)
    );
    gf_b32_delay_bit #(.CLOCKS(28)) u_quotient_to_u28 (
        .clk_i(clk_i), .rst_i(rst_i),
        .bit_i(corrected_quotient_u27), .bit_o(quotient_delayed_u28)
    );
    /* Separate exponent stream: Ea-Eb+127-adjust, then record-local delay. */
    wire exponent_difference_u1;
    wire bias127_u1;
    wire biased_exponent_u2;
    wire adjust_exponent_u2;
    wire result_exponent_u3;
    /* One input relay breaks each unpack-gate -> subtract-LUT path. */
    gf_b32_serial_addsub #(.SUBTRACT(1), .RELAY_CLOCKS(1))
        u_exponent_difference (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(numerator_exponent_u0),
        .y_bit_i(denominator_exponent_u0),
        .sum_bit_o(exponent_difference_u1)
    );
    gf_b32_constant_stream #(.VALUE(32'h0000007f)) u_bias127 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_o(bias127_u1)
    );
    gf_b32_serial_addsub #(.SUBTRACT(0)) u_add_bias (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(exponent_difference_u1), .y_bit_i(bias127_u1),
        .sum_bit_o(biased_exponent_u2)
    );
    gf_b32_record_flag_delay #(.RECORDS(1)) u_adjust_to_u2 (
        .clk_i(clk_i), .rst_i(rst_i),
        .flag_i(adjust_exponent_u1), .flag_o(adjust_exponent_u2)
    );
    gf_b32_serial_cond_one #(.SUBTRACT(1)) u_adjust_exponent (
        .clk_i(clk_i), .rst_i(rst_i),
        .x_bit_i(biased_exponent_u2), .condition_i(adjust_exponent_u2),
        .sum_bit_o(result_exponent_u3)
    );
    wire result_exponent_u28;
    gf_b32_record_stream_delay #(.RECORDS(27), .SERIAL_BITS(8))
        u_exponent_to_u28 (
            .clk_i(clk_i), .rst_i(rst_i), .bit_i(result_exponent_u3),
            .bit_o(result_exponent_u28)
        );

    /* Sign is a one-bit record sideband; it never enters significand math. */
    wire result_sign_comb_u0;
    wire result_sign_u0;
    wire result_sign_u28;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h6666)) sign_xor_lut (
        .I0(numerator_sign_u0), .I1(denominator_sign_u0),
        .I2(1'b0), .I3(1'b0), .O(result_sign_comb_u0)
    );
    /* Sign is stable from phase zero; register it before the record hold. */
    (* keep = "true" *) SB_DFFR sign_xor_dff (
        .C(clk_i), .R(rst_i), .D(result_sign_comb_u0), .Q(result_sign_u0)
    );
    gf_b32_record_flag_delay #(.RECORDS(30)) u_sign_to_u30 (
        .clk_i(clk_i), .rst_i(rst_i),
        .flag_i(result_sign_u0), .flag_o(result_sign_u28)
    );

    /* U28 -> U29: the only internal-to-IEEE conversion in the graph. */
    wire exponent_shift23_u28;
    wire result_sign_local_u28;
    gf_b32_delay_bit #(.CLOCKS(23)) u_exponent_shift23 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(result_exponent_u28),
        .bit_o(exponent_shift23_u28)
    );
    /* Sign is record-stable; 16 local DFFs let it cross the crowded die. */
    gf_b32_delay_bit #(.CLOCKS(16)) u_sign_local_retime (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(result_sign_u28),
        .bit_o(result_sign_local_u28)
    );

    wire fraction_stage1_q;
    wire exponent_stage1_q;
    wire sign_stage1_q;
    wire fraction_stage1_d;
    wire sign_stage1_d;
    /* Mask and RNE-select in the same LUT before the boundary DFF. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h00ca)) fraction_gate_lut (
        .I0(quotient_delayed_u28), .I1(quotient_plus_one_u28),
        .I2(round_up_u28), .I3(pack_phase23_local),
        .O(fraction_stage1_d)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h8888)) sign_gate_lut (
        .I0(result_sign_local_u28), .I1(pack_phase31_local),
        .I2(1'b0), .I3(1'b0), .O(sign_stage1_d)
    );
    (* keep = "true" *) SB_DFFR fraction_stage1_dff (
        .C(clk_i), .R(rst_i), .D(fraction_stage1_d), .Q(fraction_stage1_q)
    );
    (* keep = "true" *) SB_DFFR exponent_stage1_dff (
        .C(clk_i), .R(rst_i), .D(exponent_shift23_u28),
        .Q(exponent_stage1_q)
    );
    (* keep = "true" *) SB_DFFR sign_stage1_dff (
        .C(clk_i), .R(rst_i), .D(sign_stage1_d), .Q(sign_stage1_q)
    );

    wire packed_stage2_d;
    wire packed_stage2_q;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hfefe)) pack_or_lut (
        .I0(fraction_stage1_q), .I1(exponent_stage1_q),
        .I2(sign_stage1_q), .I3(1'b0), .O(packed_stage2_d)
    );
    (* keep = "true" *) SB_DFFR pack_or_dff (
        .C(clk_i), .R(rst_i), .D(packed_stage2_d), .Q(packed_stage2_q)
    );
    gf_b32_delay_bit #(.CLOCKS(30)) u_pack_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(packed_stage2_q),
        .bit_o(result_bit_o)
    );

    assign result_record_end_o = pack_phase31_local;
endmodule

`default_nettype wire
