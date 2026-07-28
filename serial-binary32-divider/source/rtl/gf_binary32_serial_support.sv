/*
 * Scalar, continuously advancing support cells for the binary32 divider.
 *
 * A record is 32 clocks only at the IEEE-754 boundary and at aligned graph
 * cuts.  Arithmetic data ports remain one bit wide.  Vectors below are banks
 * of physical phase or delay flip-flops; no vector is an arithmetic operand.
 * There is no request, transaction load, ready, valid, wait, stall, step, or
 * clock-enable input in this file.
 */

`default_nettype none

module gf_b32_phase32 (
    input  wire        clk_i,
    input  wire        rst_i,
    output wire [31:0] phase_o
);
    (* keep = "true" *) SB_DFFS phase0 (
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
 * A local 16-DFF Johnson counter has exactly 32 states.  Support cells that
 * need only one or two phase events use this instead of paying for a full
 * 32-DFF one-hot ring.  Each requested event is decoded into its own DFF, so
 * arithmetic still sees a registered phase signal and never a decode LUT in
 * series with an arithmetic LUT.
 */
module gf_b32_johnson32_state (
    input  wire        clk_i,
    input  wire        rst_i,
    output wire [15:0] state_o
);
    wire feedback_d;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h5555)) feedback_lut (
        .I0(state_o[15]), .I1(1'b0), .I2(1'b0), .I3(1'b0),
        .O(feedback_d)
    );
    (* keep = "true" *) SB_DFFR state0_dff (
        .C(clk_i), .R(rst_i), .D(feedback_d), .Q(state_o[0])
    );
    generate
        for (genvar n = 1; n < 16; n = n + 1) begin : g_state
            (* keep = "true" *) SB_DFFR state_dff (
                .C(clk_i), .R(rst_i), .D(state_o[n-1]), .Q(state_o[n])
            );
        end
    endgenerate
endmodule

module gf_b32_johnson32_event #(
    parameter integer PHASE = 0
) (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [15:0] state_i,
    output wire        event_o
);
    localparam integer PREVIOUS_PHASE = (PHASE + 31) % 32;
    wire event_d;
    generate
        if (PREVIOUS_PHASE == 0) begin : g_decode_zero
            /* all-zero Johnson state */
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h1111)) event_lut (
                .I0(state_i[15]), .I1(state_i[0]),
                .I2(1'b0), .I3(1'b0), .O(event_d)
            );
        end else if (PREVIOUS_PHASE < 16) begin : g_decode_fill
            /* rising fill boundary: state[k-1]=1, state[k]=0 */
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h2222)) event_lut (
                .I0(state_i[PREVIOUS_PHASE-1]),
                .I1(state_i[PREVIOUS_PHASE]),
                .I2(1'b0), .I3(1'b0), .O(event_d)
            );
        end else if (PREVIOUS_PHASE == 16) begin : g_decode_full
            /* all-one Johnson state */
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h8888)) event_lut (
                .I0(state_i[15]), .I1(state_i[0]),
                .I2(1'b0), .I3(1'b0), .O(event_d)
            );
        end else begin : g_decode_drain
            localparam integer BOUNDARY = PREVIOUS_PHASE - 16;
            /* falling drain boundary: state[k-1]=0, state[k]=1 */
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h4444)) event_lut (
                .I0(state_i[BOUNDARY-1]), .I1(state_i[BOUNDARY]),
                .I2(1'b0), .I3(1'b0), .O(event_d)
            );
        end

        if (PHASE == 0) begin : g_phase_zero
            (* keep = "true" *) SB_DFFS event_dff (
                .C(clk_i), .S(rst_i), .D(event_d), .Q(event_o)
            );
        end else begin : g_other_phase
            (* keep = "true" *) SB_DFFR event_dff (
                .C(clk_i), .R(rst_i), .D(event_d), .Q(event_o)
            );
        end
    endgenerate
endmodule

/* Balanced registered fanout used for fixed local phase pulses. */
module gf_b32_registered_fanout #(
    parameter integer LEAVES = 32
) (
    input  wire              clk_i,
    input  wire              rst_i,
    input  wire              bit_i,
    output wire [LEAVES-1:0] bit_o
);
    localparam integer NODES = (2 * LEAVES) - 1;
    wire [NODES-1:0] node;
    (* keep = "true" *) SB_DFFR root_dff (
        .C(clk_i), .R(rst_i), .D(bit_i), .Q(node[0])
    );
    generate
        for (genvar n = 1; n < NODES; n = n + 1) begin : g_node
            (* keep = "true" *) SB_DFFR branch_dff (
                .C(clk_i), .R(rst_i), .D(node[(n-1)/2]), .Q(node[n])
            );
        end
        for (genvar leaf = 0; leaf < LEAVES; leaf = leaf + 1) begin : g_leaf
            assign bit_o[leaf] = node[(LEAVES-1)+leaf];
        end
    endgenerate
endmodule

module gf_b32_delay_bit #(
    parameter integer CLOCKS = 1
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    output wire bit_o
);
    generate
        if (CLOCKS == 0) begin : g_no_delay
            assign bit_o = bit_i;
        end else begin : g_delay
            wire [CLOCKS:0] d;
            assign d[0] = bit_i;
            for (genvar n = 0; n < CLOCKS; n = n + 1) begin : g_dff
                (* keep = "true" *) SB_DFFR delay_dff (
                    .C(clk_i), .R(rst_i), .D(d[n]), .Q(d[n+1])
                );
            end
            assign bit_o = d[CLOCKS];
        end
    endgenerate
endmodule

module gf_b32_delay_taps #(
    parameter integer CLOCKS = 32
) (
    input  wire              clk_i,
    input  wire              rst_i,
    input  wire              bit_i,
    output wire [CLOCKS:0]   tap_o
);
    assign tap_o[0] = bit_i;
    generate
        for (genvar n = 0; n < CLOCKS; n = n + 1) begin : g_tap
            (* keep = "true" *) SB_DFFR delay_dff (
                .C(clk_i), .R(rst_i), .D(tap_o[n]), .Q(tap_o[n+1])
            );
        end
    endgenerate
endmodule

/*
 * Delay only the active low SERIAL_BITS positions by a fixed number of
 * 32-clock records.  Each state bit advances on its compile-time phase; the
 * interface remains a single uninterrupted LSB-first stream.  The final
 * eight/24/25-bit state is serialized by a phase-fixed shift bank, so no
 * transaction control or clock enable is exposed.
 */
module gf_b32_record_stream_delay #(
    parameter integer RECORDS = 1,
    parameter integer SERIAL_BITS = 8
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    output wire bit_o
);
    localparam integer HISTORY_RECORDS = (RECORDS > 1) ? RECORDS - 1 : 0;
    localparam integer BOUNDARY_LEAVES =
        (RECORDS <= 1)  ? 1  :
        (RECORDS <= 2)  ? 2  :
        (RECORDS <= 4)  ? 4  :
        (RECORDS <= 8)  ? 8  :
        (RECORDS <= 16) ? 16 : 32;
    localparam integer BOUNDARY_DEPTH = $clog2(BOUNDARY_LEAVES) + 1;
    wire [31:0] phase;
    wire [SERIAL_BITS-1:0] capture_q;
    wire [SERIAL_BITS-1:0] delayed_parallel;
    wire [SERIAL_BITS-1:0] serializer_q;
    wire [BOUNDARY_LEAVES-1:0] boundary_q;

    gf_b32_phase32 u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .phase_o(phase)
    );

    /* The tree leaves become high in phase 31 without a high-fanout root. */
    gf_b32_registered_fanout #(.LEAVES(BOUNDARY_LEAVES)) u_boundary_fanout (
        .clk_i(clk_i), .rst_i(rst_i),
        .bit_i(phase[31-BOUNDARY_DEPTH]), .bit_o(boundary_q)
    );

    generate
        for (genvar b = 0; b < SERIAL_BITS; b = b + 1) begin : g_capture
            wire capture_next;
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) capture_mux (
                .I0(capture_q[b]), .I1(bit_i), .I2(phase[b]), .I3(1'b0),
                .O(capture_next)
            );
            (* keep = "true" *) SB_DFFR capture_dff (
                .C(clk_i), .R(rst_i), .D(capture_next), .Q(capture_q[b])
            );
        end

        if (HISTORY_RECORDS == 0) begin : g_no_history
            assign delayed_parallel = capture_q;
        end else begin : g_history
            wire [(HISTORY_RECORDS*SERIAL_BITS)-1:0] history_q;
            for (genvar r = 0; r < HISTORY_RECORDS; r = r + 1) begin : g_record
                for (genvar b = 0; b < SERIAL_BITS; b = b + 1) begin : g_bit
                    localparam integer INDEX = (r * SERIAL_BITS) + b;
                    wire source_bit = (r == 0) ? capture_q[b] :
                        history_q[((r-1) * SERIAL_BITS) + b];
                    wire history_next;
                    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) history_mux (
                        .I0(history_q[INDEX]), .I1(source_bit),
                        .I2(boundary_q[r]), .I3(1'b0),
                        .O(history_next)
                    );
                    (* keep = "true" *) SB_DFFR history_dff (
                        .C(clk_i), .R(rst_i), .D(history_next),
                        .Q(history_q[INDEX])
                    );
                end
            end
            for (genvar b = 0; b < SERIAL_BITS; b = b + 1) begin : g_history_out
                assign delayed_parallel[b] =
                    history_q[((HISTORY_RECORDS-1) * SERIAL_BITS) + b];
            end
        end

        /* At phase 31 the next record enters; otherwise zeros shift in. */
        for (genvar b = 0; b < SERIAL_BITS; b = b + 1) begin : g_serialize
            wire shift_source = (b == SERIAL_BITS-1) ? 1'b0 : serializer_q[b+1];
            wire serializer_next;
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) serializer_mux (
                .I0(shift_source), .I1(delayed_parallel[b]),
                .I2(boundary_q[HISTORY_RECORDS]), .I3(1'b0),
                .O(serializer_next)
            );
            (* keep = "true" *) SB_DFFR serializer_dff (
                .C(clk_i), .R(rst_i), .D(serializer_next),
                .Q(serializer_q[b])
            );
        end
    endgenerate

    assign bit_o = serializer_q[0];
endmodule

/* Fixed record-rate sideband delay; phase 31 is the only update instant. */
module gf_b32_record_flag_delay #(
    parameter integer RECORDS = 1
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire flag_i,
    output wire flag_o
);
    generate
        if (RECORDS == 0) begin : g_no_delay
            assign flag_o = flag_i;
        end else begin : g_delay
            localparam integer BOUNDARY_LEAVES =
                (RECORDS <= 1)  ? 1  :
                (RECORDS <= 2)  ? 2  :
                (RECORDS <= 4)  ? 4  :
                (RECORDS <= 8)  ? 8  :
                (RECORDS <= 16) ? 16 : 32;
            localparam integer BOUNDARY_DEPTH = $clog2(BOUNDARY_LEAVES) + 1;
            wire [15:0] phase_state;
            wire boundary_source;
            wire [RECORDS-1:0] q;
            wire [BOUNDARY_LEAVES-1:0] boundary_q;
            gf_b32_johnson32_state u_phase (
                .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
            );
            gf_b32_johnson32_event #(
                .PHASE(31-BOUNDARY_DEPTH)
            ) u_boundary_source (
                .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
                .event_o(boundary_source)
            );
            gf_b32_registered_fanout #(.LEAVES(BOUNDARY_LEAVES))
                u_boundary_fanout (
                    .clk_i(clk_i), .rst_i(rst_i),
                    .bit_i(boundary_source), .bit_o(boundary_q)
                );
            for (genvar r = 0; r < RECORDS; r = r + 1) begin : g_record
                wire source_flag = (r == 0) ? flag_i : q[r-1];
                wire next_flag;
                (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) delay_mux (
                    .I0(q[r]), .I1(source_flag), .I2(boundary_q[r]), .I3(1'b0),
                    .O(next_flag)
                );
                (* keep = "true" *) SB_DFFR delay_dff (
                    .C(clk_i), .R(rst_i), .D(next_flag), .Q(q[r])
                );
            end
            assign flag_o = q[RECORDS-1];
        end
    endgenerate
endmodule

/* A compile-time constant emitted LSB-first forever, one bit per clock. */
module gf_b32_constant_stream #(
    parameter [31:0] VALUE = 32'h00000000
) (
    input  wire clk_i,
    input  wire rst_i,
    output wire bit_o
);
    wire [31:0] q;
    generate
        for (genvar b = 0; b < 32; b = b + 1) begin : g_constant_bit
            localparam integer NEXT_POSITION = (b + 1) % 32;
            if (VALUE[b]) begin : g_one
                (* keep = "true" *) SB_DFFS constant_dff (
                    .C(clk_i), .S(rst_i), .D(q[NEXT_POSITION]), .Q(q[b])
                );
            end else begin : g_zero
                (* keep = "true" *) SB_DFFR constant_dff (
                    .C(clk_i), .R(rst_i), .D(q[NEXT_POSITION]), .Q(q[b])
                );
            end
        end
    endgenerate
    assign bit_o = q[0];
endmodule

/* Split raw F/E/S once.  Outputs are aligned at the following phase zero. */
module gf_b32_unpack_boundary (
    input  wire clk_i,
    input  wire rst_i,
    input  wire raw_bit_i,
    output wire significand_bit_o,
    output wire exponent_bit_o,
    output wire sign_o
);
    wire [15:0] phase_state;
    wire phase31;
    wire phase22;
    wire phase23;
    wire phase7;
    wire raw_delayed9;
    wire significand_unaligned;
    wire exponent_unaligned;
    wire significand_aligned;
    wire fraction_active_next;
    wire exponent_active_next;
    wire fraction_active_q;
    wire exponent_active_q;
    wire sign_next;
    wire sign_q;

    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(31)) u_phase31 (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase31)
    );
    gf_b32_johnson32_event #(.PHASE(22)) u_phase22 (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase22)
    );
    gf_b32_johnson32_event #(.PHASE(23)) u_phase23 (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase23)
    );
    gf_b32_johnson32_event #(.PHASE(7)) u_phase7 (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase7)
    );

    /* Active on raw positions 0..22; the implicit one occupies position 23. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcece)) fraction_active_lut (
        .I0(fraction_active_q), .I1(phase31), .I2(phase22), .I3(1'b0),
        .O(fraction_active_next)
    );
    (* keep = "true" *) SB_DFFS fraction_active_dff (
        .C(clk_i), .S(rst_i), .D(fraction_active_next),
        .Q(fraction_active_q)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hf8f8)) significand_lut (
        .I0(raw_bit_i), .I1(fraction_active_q), .I2(phase23), .I3(1'b0),
        .O(significand_unaligned)
    );

    /* Raw exponent bit zero is at phase 23; nine DFFs reframe it at phase 0. */
    gf_b32_delay_bit #(.CLOCKS(9)) u_raw_exp_align (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_bit_i),
        .bit_o(raw_delayed9)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcece)) exponent_active_lut (
        .I0(exponent_active_q), .I1(phase31), .I2(phase7), .I3(1'b0),
        .O(exponent_active_next)
    );
    (* keep = "true" *) SB_DFFS exponent_active_dff (
        .C(clk_i), .S(rst_i), .D(exponent_active_next),
        .Q(exponent_active_q)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h8888)) exponent_gate (
        .I0(raw_delayed9), .I1(exponent_active_q), .I2(1'b0), .I3(1'b0),
        .O(exponent_unaligned)
    );

    /* The fraction starts at phase zero, so one full record aligns it. */
    gf_b32_delay_bit #(.CLOCKS(32)) u_sig_preload (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(significand_unaligned),
        .bit_o(significand_aligned)
    );

    /* Capture raw sign at phase 31 and hold it beside the numeric streams. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) sign_hold_lut (
        .I0(sign_q), .I1(raw_bit_i), .I2(phase31), .I3(1'b0), .O(sign_next)
    );
    (* keep = "true" *) SB_DFFR sign_hold_dff (
        .C(clk_i), .R(rst_i), .D(sign_next), .Q(sign_q)
    );

    assign significand_bit_o = significand_aligned;
    /* The nine-clock exponent shift already lands in that same next record. */
    assign exponent_bit_o = exponent_unaligned;
    assign sign_o = sign_q;
endmodule

/* Fixed modulo-2^32 serial add/subtract, with one-record registered latency. */
module gf_b32_serial_addsub #(
    parameter integer SUBTRACT = 0,
    parameter integer RELAY_CLOCKS = 0
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire x_bit_i,
    input  wire y_bit_i,
    output wire sum_bit_o
);
    localparam [15:0] SUM_INIT   = SUBTRACT ? 16'h6669 : 16'h6696;
    localparam [15:0] CARRY_INIT = SUBTRACT ? 16'hbbb2 : 16'h88e8;
    wire [15:0] phase_state;
    wire phase_start;
    wire sum_next;
    wire carry_next;
    wire sum_q;
    wire carry_q;
    wire x_relay;
    wire y_relay;

    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(RELAY_CLOCKS)) u_phase_start (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase_start)
    );
    gf_b32_delay_bit #(.CLOCKS(RELAY_CLOCKS)) u_x_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(x_bit_i), .bit_o(x_relay)
    );
    gf_b32_delay_bit #(.CLOCKS(RELAY_CLOCKS)) u_y_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(y_bit_i), .bit_o(y_relay)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(SUM_INIT)) sum_lut (
        .I0(x_relay), .I1(y_relay), .I2(carry_q),
        .I3(phase_start), .O(sum_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(CARRY_INIT)) carry_lut (
        .I0(x_relay), .I1(y_relay), .I2(carry_q),
        .I3(phase_start), .O(carry_next)
    );
    (* keep = "true" *) SB_DFFR sum_dff (
        .C(clk_i), .R(rst_i), .D(sum_next), .Q(sum_q)
    );
    (* keep = "true" *) SB_DFFR carry_dff (
        .C(clk_i), .R(rst_i), .D(carry_next), .Q(carry_q)
    );
    gf_b32_delay_bit #(.CLOCKS(31-RELAY_CLOCKS)) u_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(sum_q), .bit_o(sum_bit_o)
    );
endmodule

/* Add/subtract a stable one-bit condition at numeric position zero. */
module gf_b32_serial_cond_one #(
    parameter integer SUBTRACT = 0
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire x_bit_i,
    input  wire condition_i,
    output wire sum_bit_o
);
    localparam [15:0] SUM_INIT   = SUBTRACT ? 16'h66a5 : 16'h665a;
    localparam [15:0] CARRY_INIT = SUBTRACT ? 16'hbbfa : 16'h88a0;
    wire [15:0] phase_state;
    wire phase_zero;
    wire sum_next;
    wire carry_next;
    wire sum_q;
    wire carry_q;

    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(0)) u_phase_zero (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase_zero)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(SUM_INIT)) sum_lut (
        .I0(x_bit_i), .I1(condition_i), .I2(carry_q), .I3(phase_zero),
        .O(sum_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(CARRY_INIT)) carry_lut (
        .I0(x_bit_i), .I1(condition_i), .I2(carry_q), .I3(phase_zero),
        .O(carry_next)
    );
    (* keep = "true" *) SB_DFFR sum_dff (
        .C(clk_i), .R(rst_i), .D(sum_next), .Q(sum_q)
    );
    (* keep = "true" *) SB_DFFR carry_dff (
        .C(clk_i), .R(rst_i), .D(carry_next), .Q(carry_q)
    );
    gf_b32_delay_bit #(.CLOCKS(31)) u_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(sum_q), .bit_o(sum_bit_o)
    );
endmodule

/*
 * Emit X+1 when correction_gt_i|correction_eq_i is low, or X+2 when it is
 * high.  The comparison flags are already stable before phase 31.  A tiny
 * two-DFF stream captures 01 or 10 on that fixed boundary, so the following
 * full adder still has exactly one LUT between state registers.
 */
module gf_b32_serial_add_one_or_two #(
    parameter integer RELAY_CLOCKS = 4
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire x_bit_i,
    input  wire correction_gt_i,
    input  wire correction_eq_i,
    output wire sum_bit_o
);
    wire [15:0] phase_state;
    wire phase31;
    wire phase_start;
    wire amount0_next;
    wire amount1_next;
    wire amount0_q;
    wire amount1_q;
    wire sum_next;
    wire carry_next;
    wire sum_q;
    wire carry_q;
    wire x_relay;
    wire amount_relay;

    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(31)) u_phase31 (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase31)
    );
    gf_b32_johnson32_event #(.PHASE(RELAY_CLOCKS)) u_phase_start (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase_start)
    );

    /* At phase zero amount0 is !correction; at phase one it is correction. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h03aa)) amount0_lut (
        .I0(amount1_q), .I1(correction_gt_i), .I2(correction_eq_i),
        .I3(phase31), .O(amount0_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h00e0)) amount1_lut (
        .I0(correction_gt_i), .I1(correction_eq_i), .I2(phase31),
        .I3(1'b0), .O(amount1_next)
    );
    (* keep = "true" *) SB_DFFR amount0_dff (
        .C(clk_i), .R(rst_i), .D(amount0_next), .Q(amount0_q)
    );
    (* keep = "true" *) SB_DFFR amount1_dff (
        .C(clk_i), .R(rst_i), .D(amount1_next), .Q(amount1_q)
    );

    /* Fixed relay latency gives both operand branches a local route. */
    gf_b32_delay_bit #(.CLOCKS(RELAY_CLOCKS)) u_x_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(x_bit_i), .bit_o(x_relay)
    );
    gf_b32_delay_bit #(.CLOCKS(RELAY_CLOCKS)) u_amount_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(amount0_q),
        .bit_o(amount_relay)
    );

    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h6696)) sum_lut (
        .I0(x_relay), .I1(amount_relay), .I2(carry_q),
        .I3(phase_start),
        .O(sum_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h88e8)) carry_lut (
        .I0(x_relay), .I1(amount_relay), .I2(carry_q),
        .I3(phase_start),
        .O(carry_next)
    );
    (* keep = "true" *) SB_DFFR sum_dff (
        .C(clk_i), .R(rst_i), .D(sum_next), .Q(sum_q)
    );
    (* keep = "true" *) SB_DFFR carry_dff (
        .C(clk_i), .R(rst_i), .D(carry_next), .Q(carry_q)
    );
    gf_b32_delay_bit #(.CLOCKS(31-RELAY_CLOCKS)) u_reframe (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(sum_q), .bit_o(sum_bit_o)
    );
endmodule

/* Unsigned LSB-first compare of the low SERIAL_BITS positions. */
module gf_b32_serial_compare #(
    parameter integer SERIAL_BITS = 24
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire x_bit_i,
    input  wire y_bit_i,
    output wire gt_o,
    output wire eq_o,
    output wire ge_o
);
    wire [15:0] phase_state;
    wire gt_candidate;
    wire eq_candidate;
    wire gt_work_next;
    wire eq_work_next;
    wire gt_result_next;
    wire eq_result_next;
    wire gt_work_q;
    wire eq_work_q;
    wire gt_result_q;
    wire eq_result_q;
    wire first_position;
    /*
     * The work DFF contains the complete comparison one phase after the last
     * numeric bit.  Capture that registered value instead of feeding the
     * final candidate LUT directly into a second result-mux LUT.
     */
    wire final_position;

    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(0)) u_first_position (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(first_position)
    );
    gf_b32_johnson32_event #(.PHASE(SERIAL_BITS)) u_final_position (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(final_position)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h22b2)) gt_lut (
        .I0(x_bit_i), .I1(y_bit_i), .I2(gt_work_q), .I3(first_position),
        .O(gt_candidate)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h9990)) eq_lut (
        .I0(x_bit_i), .I1(y_bit_i), .I2(eq_work_q), .I3(first_position),
        .O(eq_candidate)
    );
    assign gt_work_next = gt_candidate;
    assign eq_work_next = eq_candidate;
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) gt_result_mux (
        .I0(gt_result_q), .I1(gt_work_q), .I2(final_position), .I3(1'b0),
        .O(gt_result_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) eq_result_mux (
        .I0(eq_result_q), .I1(eq_work_q), .I2(final_position), .I3(1'b0),
        .O(eq_result_next)
    );
    (* keep = "true" *) SB_DFFR gt_work_dff (
        .C(clk_i), .R(rst_i), .D(gt_work_next), .Q(gt_work_q)
    );
    (* keep = "true" *) SB_DFFS eq_work_dff (
        .C(clk_i), .S(rst_i), .D(eq_work_next), .Q(eq_work_q)
    );
    (* keep = "true" *) SB_DFFR gt_result_dff (
        .C(clk_i), .R(rst_i), .D(gt_result_next), .Q(gt_result_q)
    );
    (* keep = "true" *) SB_DFFR eq_result_dff (
        .C(clk_i), .R(rst_i), .D(eq_result_next), .Q(eq_result_q)
    );

    assign gt_o = gt_result_q;
    assign eq_o = eq_result_q;
    assign ge_o = gt_result_q | eq_result_q;
endmodule

/* Compare 2X with Y directly; the left shift is absorbed into the LUTs. */
module gf_b32_serial_compare_shifted_x #(
    parameter integer SERIAL_BITS = 25
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire x_bit_i,
    input  wire y_bit_i,
    output wire gt_o,
    output wire eq_o,
    output wire ge_o
);
    wire [15:0] phase_state;
    wire previous_x_q;
    wire gt_candidate;
    wire eq_candidate;
    wire gt_result_next;
    wire eq_result_next;
    wire gt_work_q;
    wire eq_work_q;
    wire gt_result_q;
    wire eq_result_q;
    wire first_position;
    /* Capture only the already-registered complete comparison. */
    wire final_position;

    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(0)) u_first_position (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(first_position)
    );
    gf_b32_johnson32_event #(.PHASE(SERIAL_BITS)) u_final_position (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(final_position)
    );
    (* keep = "true" *) SB_DFFR x_shift_dff (
        .C(clk_i), .R(rst_i), .D(x_bit_i), .Q(previous_x_q)
    );
    /* At numeric position zero X is forced low; later positions use X[n-1]. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h00b2)) gt_lut (
        .I0(previous_x_q), .I1(y_bit_i), .I2(gt_work_q),
        .I3(first_position), .O(gt_candidate)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h3390)) eq_lut (
        .I0(previous_x_q), .I1(y_bit_i), .I2(eq_work_q),
        .I3(first_position), .O(eq_candidate)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) gt_result_mux (
        .I0(gt_result_q), .I1(gt_work_q), .I2(final_position),
        .I3(1'b0), .O(gt_result_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) eq_result_mux (
        .I0(eq_result_q), .I1(eq_work_q), .I2(final_position),
        .I3(1'b0), .O(eq_result_next)
    );
    (* keep = "true" *) SB_DFFR gt_work_dff (
        .C(clk_i), .R(rst_i), .D(gt_candidate), .Q(gt_work_q)
    );
    (* keep = "true" *) SB_DFFS eq_work_dff (
        .C(clk_i), .S(rst_i), .D(eq_candidate), .Q(eq_work_q)
    );
    (* keep = "true" *) SB_DFFR gt_result_dff (
        .C(clk_i), .R(rst_i), .D(gt_result_next), .Q(gt_result_q)
    );
    (* keep = "true" *) SB_DFFR eq_result_dff (
        .C(clk_i), .R(rst_i), .D(eq_result_next), .Q(eq_result_q)
    );

    assign gt_o = gt_result_q;
    assign eq_o = eq_result_q;
    assign ge_o = gt_result_q | eq_result_q;
endmodule

/* Delay a scalar stream one clock, forcing numeric position zero to zero. */
module gf_b32_shift_left_one (
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    output wire bit_o
);
    wire [31:0] phase;
    wire delayed_q;
    gf_b32_phase32 u_phase (.clk_i(clk_i), .rst_i(rst_i), .phase_o(phase));
    (* keep = "true" *) SB_DFFR shift_dff (
        .C(clk_i), .R(rst_i), .D(bit_i), .Q(delayed_q)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h0c0c)) zero_position_lut (
        .I0(1'b0), .I1(delayed_q), .I2(phase[0]), .I3(1'b0), .O(bit_o)
    );
endmodule

/* Select X or 2X without a barrel shifter or a parallel arithmetic value. */
module gf_b32_select_shift0_or1 (
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    input  wire shift_one_i,
    output wire bit_o
);
    wire [15:0] phase_state;
    wire phase_zero;
    wire previous_bit_q;
    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(0)) u_phase_zero (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase_zero)
    );
    (* keep = "true" *) SB_DFFR previous_bit_dff (
        .C(clk_i), .R(rst_i), .D(bit_i), .Q(previous_bit_q)
    );
    /* I3=phase zero: shifted selection injects zero at numeric bit zero. */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h0aca)) select_shift_lut (
        .I0(bit_i), .I1(previous_bit_q), .I2(shift_one_i), .I3(phase_zero),
        .O(bit_o)
    );
endmodule

/* Sample a transaction flag at the record boundary and hold it for 32 clocks. */
module gf_b32_capture_record_flag (
    input  wire clk_i,
    input  wire rst_i,
    input  wire flag_i,
    output wire flag_o
);
    wire [15:0] phase_state;
    wire phase31;
    wire next_flag;
    wire flag_q;
    gf_b32_johnson32_state u_phase (
        .clk_i(clk_i), .rst_i(rst_i), .state_o(phase_state)
    );
    gf_b32_johnson32_event #(.PHASE(31)) u_phase31 (
        .clk_i(clk_i), .rst_i(rst_i), .state_i(phase_state),
        .event_o(phase31)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) capture_mux (
        .I0(flag_q), .I1(flag_i), .I2(phase31), .I3(1'b0), .O(next_flag)
    );
    (* keep = "true" *) SB_DFFR capture_dff (
        .C(clk_i), .R(rst_i), .D(next_flag), .Q(flag_q)
    );
    assign flag_o = flag_q;
endmodule

module gf_b32_mux_bit (
    input  wire a_bit_i,
    input  wire b_bit_i,
    input  wire select_b_i,
    output wire bit_o
);
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) mux_lut (
        .I0(a_bit_i), .I1(b_bit_i), .I2(select_b_i), .I3(1'b0), .O(bit_o)
    );
endmodule

module gf_b32_and_flag (
    input  wire bit_i,
    input  wire flag_i,
    output wire bit_o
);
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h8888)) and_lut (
        .I0(bit_i), .I1(flag_i), .I2(1'b0), .I3(1'b0), .O(bit_o)
    );
endmodule

`default_nettype wire
