`default_nettype none

// Bubble-free bit-serial product engines for a 32-clock binary32 word slot.
//
// Bit order is LSB first.  There are deliberately no load, enable, ready, or
// valid controls: every clock belongs to the next fixed phase of the stream.
// LANES=24 is the binary32 significand product.  LANES=32 is the padded
// A'[24:0] * X1[27:0] estimate product used by the reciprocal pipeline.
//
// The parity-tail engine assigns alternating input words to two independent
// serial-adder trees.  During the following word slot each tree finishes the
// upper half of its product while the opposite tree starts a new product.
// Carries are consequently cleared every 64 clocks, at each tree's own phase.

module gf_b32_mul_delay_bit #(
    parameter integer DELAY = 1
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    output wire bit_o
);
    wire [DELAY:0] stage;
    assign stage[0] = bit_i;

    genvar gd;
    generate
        for (gd = 0; gd < DELAY; gd = gd + 1) begin : g_delay
            (* keep *) SB_DFFR delay_ff (
                .C(clk_i), .R(rst_i), .D(stage[gd]), .Q(stage[gd+1])
            );
        end
    endgenerate

    assign bit_o = stage[DELAY];
endmodule


// Registered binary fanout tree.  LEAVES must be a power of two.  The path
// depth is INPUT_PIPE+log2(LEAVES)+1+OUTPUT_PIPE because the root and leaf
// relays are also registered.
// Optional input/leaf relays are compile-time route experiments.  Divider
// product sites use zero: ineffective route-only state must not consume HX8K.
module gf_b32_mul_registered_fanout #(
    parameter integer LEAVES = 16,
    parameter integer INPUT_PIPE = 0,
    parameter integer OUTPUT_PIPE = 0
) (
    input  wire              clk_i,
    input  wire              rst_i,
    input  wire              bit_i,
    output wire [LEAVES-1:0] bit_o
);
    localparam integer NODES = (2 * LEAVES) - 1;
    wire [NODES-1:0] node;
    wire [INPUT_PIPE:0] input_pipe;
    assign input_pipe[0] = bit_i;

    genvar gi;
    generate
        for (gi = 0; gi < INPUT_PIPE; gi = gi + 1) begin : g_input_pipe
            (* keep *) SB_DFFR input_ff (
                .C(clk_i), .R(rst_i),
                .D(input_pipe[gi]), .Q(input_pipe[gi+1])
            );
        end
    endgenerate

    (* keep *) SB_DFFR root_ff (
        .C(clk_i), .R(rst_i), .D(input_pipe[INPUT_PIPE]), .Q(node[0])
    );

    genvar gf;
    generate
        for (gf = 1; gf < NODES; gf = gf + 1) begin : g_branch
            (* keep *) SB_DFFR branch_ff (
                .C(clk_i),
                .R(rst_i),
                .D(node[(gf-1)/2]),
                .Q(node[gf])
            );
        end
        for (gf = 0; gf < LEAVES; gf = gf + 1) begin : g_leaf
            wire [OUTPUT_PIPE:0] leaf_pipe;
            assign leaf_pipe[0] = node[(LEAVES-1)+gf];
            for (genvar go = 0; go < OUTPUT_PIPE; go = go + 1) begin : g_output_pipe
                (* keep *) SB_DFFR output_ff (
                    .C(clk_i), .R(rst_i),
                    .D(leaf_pipe[go]), .Q(leaf_pipe[go+1])
                );
            end
            assign bit_o[gf] = leaf_pipe[OUTPUT_PIPE];
        end
    endgenerate
endmodule


// One-hot 64-clock phase ring.  Reset establishes phase zero directly; there
// is no decoded binary counter on the maximum-frequency path.
module gf_b32_mul_phase64 (
    input  wire        clk_i,
    input  wire        rst_i,
    output wire [63:0] phase_o
);
    (* keep *) SB_DFFS phase0_ff (
        .C(clk_i), .S(rst_i), .D(phase_o[63]), .Q(phase_o[0])
    );

    genvar gp;
    generate
        for (gp = 1; gp < 64; gp = gp + 1) begin : g_phase
            (* keep *) SB_DFFR phase_ff (
                .C(clk_i), .R(rst_i), .D(phase_o[gp-1]), .Q(phase_o[gp])
            );
        end
    endgenerate
endmodule


module gf_b32_mul_phase32 (
    input  wire        clk_i,
    input  wire        rst_i,
    output wire [31:0] phase_o
);
    (* keep *) SB_DFFS phase0_ff (
        .C(clk_i), .S(rst_i), .D(phase_o[31]), .Q(phase_o[0])
    );
    genvar gp;
    generate
        for (gp = 1; gp < 32; gp = gp + 1) begin : g_phase
            (* keep *) SB_DFFR phase_ff (
                .C(clk_i), .R(rst_i), .D(phase_o[gp-1]), .Q(phase_o[gp])
            );
        end
    endgenerate
endmodule


// Mask that is high in output phases 0..LAST_PHASE and low afterward.  The
// global one-hot phase already defines the fixed stream schedule, so a single
// state bit replaces a duplicated 32-DFF constant ring.
module gf_b32_mul_phase_window_mask #(
    parameter integer LAST_PHASE = 24
) (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [63:0] phase_i,
    output wire        mask_o
);
    wire event_d;
    wire event_q;
    wire mask_d;
    // Register four one-cycle-advanced boundaries, avoiding a two-LUT path
    // while repeating the mask in both halves of the 64-phase epoch.
    (* keep *) SB_LUT4 #(.LUT_INIT(16'hfffe)) event_lut (
        .I0(phase_i[LAST_PHASE-1]), .I1(phase_i[LAST_PHASE+31]),
        .I2(phase_i[30]), .I3(phase_i[62]), .O(event_d)
    );
    (* keep *) SB_DFFR event_ff (
        .C(clk_i), .R(rst_i), .D(event_d), .Q(event_q)
    );
    (* keep *) SB_LUT4 #(.LUT_INIT(16'h6666)) toggle_lut (
        .I0(mask_o), .I1(event_q), .I2(1'b0), .I3(1'b0),
        .O(mask_d)
    );
    (* keep *) SB_DFFS mask_ff (
        .C(clk_i), .S(rst_i), .D(mask_d), .Q(mask_o)
    );
endmodule


// A 32-clock constant bit stream.  VALUE[0] is present in phase zero.
module gf_b32_mul_const_stream32 #(
    parameter [31:0] VALUE = 32'h00000000
) (
    input  wire clk_i,
    input  wire rst_i,
    output wire bit_o
);
    wire [31:0] q;
    genvar gc;
    generate
        for (gc = 0; gc < 32; gc = gc + 1) begin : g_const
            if (VALUE[gc]) begin : g_one
                (* keep *) SB_DFFS const_ff (
                    .C(clk_i), .S(rst_i), .D(q[(gc+1)%32]), .Q(q[gc])
                );
            end else begin : g_zero
                (* keep *) SB_DFFR const_ff (
                    .C(clk_i), .R(rst_i), .D(q[(gc+1)%32]), .Q(q[gc])
                );
            end
        end
    endgenerate
    assign bit_o = q[0];
endmodule


// Registered full adder.  clear_i is asserted in the idle cycle immediately
// before bit zero reaches this level.  The 00e8 carry LUT both computes the
// majority function and suppresses carry on that clear cycle.
module gf_b32_mul_serial_add_pipe (
    input  wire clk_i,
    input  wire rst_i,
    input  wire clear_i,
    input  wire x_i,
    input  wire y_i,
    output wire sum_o
);
    wire carry_q;
    wire sum_d;
    wire carry_d;

    (* keep *) SB_LUT4 #(.LUT_INIT(16'h9696)) sum_lut (
        .I0(x_i), .I1(y_i), .I2(carry_q), .I3(1'b0), .O(sum_d)
    );
    (* keep *) SB_LUT4 #(.LUT_INIT(16'h00e8)) carry_lut (
        .I0(x_i), .I1(y_i), .I2(carry_q), .I3(clear_i), .O(carry_d)
    );
    (* keep *) SB_DFFR sum_ff (
        .C(clk_i), .R(rst_i), .D(sum_d), .Q(sum_o)
    );
    (* keep *) SB_DFFR carry_ff (
        .C(clk_i), .R(rst_i), .D(carry_d), .Q(carry_q)
    );
endmodule


// Fixed, balanced, five-register-level 32-input serial-adder tree.
module gf_b32_mul_serial_tree32 (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [31:0] in_i,
    input  wire [15:0] clear_l0_i,
    input  wire [7:0]  clear_l1_i,
    input  wire [3:0]  clear_l2_i,
    input  wire [1:0]  clear_l3_i,
    input  wire        clear_l4_i,
    output wire        bit_o
);
    wire [15:0] level0;
    wire [7:0]  level1;
    wire [3:0]  level2;
    wire [1:0]  level3;

    genvar gt;
    generate
        for (gt = 0; gt < 16; gt = gt + 1) begin : g_l0
            gf_b32_mul_serial_add_pipe add (
                .clk_i(clk_i), .rst_i(rst_i), .clear_i(clear_l0_i[gt]),
                .x_i(in_i[2*gt]), .y_i(in_i[(2*gt)+1]), .sum_o(level0[gt])
            );
        end
        for (gt = 0; gt < 8; gt = gt + 1) begin : g_l1
            gf_b32_mul_serial_add_pipe add (
                .clk_i(clk_i), .rst_i(rst_i), .clear_i(clear_l1_i[gt]),
                .x_i(level0[2*gt]), .y_i(level0[(2*gt)+1]), .sum_o(level1[gt])
            );
        end
        for (gt = 0; gt < 4; gt = gt + 1) begin : g_l2
            gf_b32_mul_serial_add_pipe add (
                .clk_i(clk_i), .rst_i(rst_i), .clear_i(clear_l2_i[gt]),
                .x_i(level1[2*gt]), .y_i(level1[(2*gt)+1]), .sum_o(level2[gt])
            );
        end
        for (gt = 0; gt < 2; gt = gt + 1) begin : g_l3
            gf_b32_mul_serial_add_pipe add (
                .clk_i(clk_i), .rst_i(rst_i), .clear_i(clear_l3_i[gt]),
                .x_i(level2[2*gt]), .y_i(level2[(2*gt)+1]), .sum_o(level3[gt])
            );
        end
    endgenerate

    gf_b32_mul_serial_add_pipe add_l4 (
        .clk_i(clk_i), .rst_i(rst_i), .clear_i(clear_l4_i),
        .x_i(level3[0]), .y_i(level3[1]), .sum_o(bit_o)
    );
endmodule


// Shared phase-hold / B-delay bank.  The data and word-parity tags traverse
// identical paths.  A partial product is admitted only when both tags match,
// preventing the old-B/new-A cross terms present during the 32-clock overlap.
module gf_b32_mul_product_bank #(
    parameter integer LANES = 24
) (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [63:0] phase_i,
    input  wire        a_bit_i,
    input  wire        b_bit_i,
    output wire [31:0] partial_even_o,
    output wire [31:0] partial_odd_o,
    output wire        word_parity_o
);
    wire a_slot;
    wire b_slot;
    wire boundary31_d4;
    wire boundary63_d4;
    wire parity_d;
    wire parity_q;
    wire [15:0] a_fan;
    wire [15:0] atag_fan;
    wire b_delay7;
    wire btag_delay7;
    wire [31:0] b_lane;
    wire [31:0] btag_lane;
    wire [31:0] a_hold;
    wire [31:0] atag_hold;

    // LANES=24 callers provide zero padding in phases 24..31.  This is part
    // of the fixed stream format, not a run-time condition, and avoids a
    // redundant 32-DFF mask ring on every multiplier site.
    assign a_slot = a_bit_i;
    assign b_slot = b_bit_i;

    // Advance both boundary tokens by four phases, then relay them locally.
    // Their consumer-visible events remain exactly phases 31 and 63 while
    // avoiding a long phase-ring-to-parity route at 432 MHz.
    gf_b32_mul_delay_bit #(.DELAY(4)) boundary31_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_i[27]),
        .bit_o(boundary31_d4)
    );
    gf_b32_mul_delay_bit #(.DELAY(4)) boundary63_relay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_i[59]),
        .bit_o(boundary63_d4)
    );
    // Toggle at either word boundary in one LUT.  A separate boundary-OR
    // followed by XOR is a two-LUT path and cannot close the 432 MHz gate.
    (* keep *) SB_LUT4 #(.LUT_INIT(16'h9696)) parity_lut (
        .I0(parity_q), .I1(boundary31_d4), .I2(boundary63_d4), .I3(1'b0),
        .O(parity_d)
    );
    (* keep *) SB_DFFR parity_ff (
        .C(clk_i), .R(rst_i), .D(parity_d), .Q(parity_q)
    );
    assign word_parity_o = parity_q;

    // A and its tag reach the lane-local leaf after six registered fanout
    // edges, then enter the hold DFF on the seventh edge.  B and its tag must
    // therefore carry seven matching edges.  Six exposed B[1] as numeric bit
    // zero: a physical X1 probe caught that exact one-bit displacement.
    gf_b32_mul_registered_fanout #(
        .LEAVES(16), .OUTPUT_PIPE(1)
    ) a_fanout (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(a_slot), .bit_o(a_fan)
    );
    gf_b32_mul_registered_fanout #(
        .LEAVES(16), .OUTPUT_PIPE(1)
    ) atag_fanout (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(parity_q), .bit_o(atag_fan)
    );
    gf_b32_mul_delay_bit #(.DELAY(7)) b_input_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(b_slot), .bit_o(b_delay7)
    );
    gf_b32_mul_delay_bit #(.DELAY(7)) btag_input_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(parity_q), .bit_o(btag_delay7)
    );

    assign b_lane[0] = b_delay7;
    assign btag_lane[0] = btag_delay7;

    genvar gb;
    generate
        for (gb = 1; gb < 32; gb = gb + 1) begin : g_b_shift
            (* keep *) SB_DFFR b_ff (
                .C(clk_i), .R(rst_i), .D(b_lane[gb-1]), .Q(b_lane[gb])
            );
            (* keep *) SB_DFFR btag_ff (
                .C(clk_i), .R(rst_i), .D(btag_lane[gb-1]), .Q(btag_lane[gb])
            );
        end
    endgenerate

    genvar gl;
    generate
        for (gl = 0; gl < 32; gl = gl + 1) begin : g_lane
            if (gl < LANES) begin : g_used
                wire load_src;
                wire load_q;
                wire a_next;
                wire atag_next;
                wire partial_even_d;
                wire partial_odd_d;

                // A fanout has six registered stages.  Registering this
                // phase pulse makes the lane hold sample the corresponding A
                // bit on the same edge on which the leaf is available.
                (* keep *) SB_LUT4 #(.LUT_INIT(16'heeee)) load_src_lut (
                    .I0(phase_i[(gl+5)%64]),
                    .I1(phase_i[(gl+37)%64]),
                    .I2(1'b0), .I3(1'b0), .O(load_src)
                );
                (* keep *) SB_DFFR load_ff (
                    .C(clk_i), .R(rst_i), .D(load_src), .Q(load_q)
                );
                (* keep *) SB_LUT4 #(.LUT_INIT(16'hcaca)) a_hold_lut (
                    .I0(a_hold[gl]), .I1(a_fan[gl/2]), .I2(load_q), .I3(1'b0),
                    .O(a_next)
                );
                (* keep *) SB_LUT4 #(.LUT_INIT(16'hcaca)) atag_hold_lut (
                    .I0(atag_hold[gl]), .I1(atag_fan[gl/2]), .I2(load_q), .I3(1'b0),
                    .O(atag_next)
                );
                (* keep *) SB_DFFR a_hold_ff (
                    .C(clk_i), .R(rst_i), .D(a_next), .Q(a_hold[gl])
                );
                (* keep *) SB_DFFR atag_hold_ff (
                    .C(clk_i), .R(rst_i), .D(atag_next), .Q(atag_hold[gl])
                );

                // I3:I2 are B/A word tags.  0008 accepts tag 00; 8000
                // accepts tag 11.  Both also require A=B=1.
                (* keep *) SB_LUT4 #(.LUT_INIT(16'h0008)) partial_even_lut (
                    .I0(a_hold[gl]), .I1(b_lane[gl]),
                    .I2(atag_hold[gl]), .I3(btag_lane[gl]),
                    .O(partial_even_d)
                );
                (* keep *) SB_LUT4 #(.LUT_INIT(16'h8000)) partial_odd_lut (
                    .I0(a_hold[gl]), .I1(b_lane[gl]),
                    .I2(atag_hold[gl]), .I3(btag_lane[gl]),
                    .O(partial_odd_d)
                );
                (* keep *) SB_DFFR partial_even_ff (
                    .C(clk_i), .R(rst_i), .D(partial_even_d),
                    .Q(partial_even_o[gl])
                );
                (* keep *) SB_DFFR partial_odd_ff (
                    .C(clk_i), .R(rst_i), .D(partial_odd_d),
                    .Q(partial_odd_o[gl])
                );
            end else begin : g_pad
                assign a_hold[gl] = 1'b0;
                assign atag_hold[gl] = 1'b0;
                assign partial_even_o[gl] = 1'b0;
                assign partial_odd_o[gl] = 1'b0;
            end
        end
    endgenerate
endmodule


module gf_binary32_mul24_ii32 #(
    parameter integer LANES = 24,
    parameter integer EMIT_LOW32 = 1,
    parameter integer EMIT_HIGH16 = 1,
    parameter integer EMIT_SHIFT23 = 1,
    parameter integer EMIT_SHIFT24 = 1,
    parameter integer EMIT_SHIFT28 = 1
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_low32_bit_o,
    output wire product_high16_bit_o,
    output wire window_shift23_25_bit_o,
    output wire window_shift24_24_bit_o,
    output wire window_shift28_25_bit_o
);
    // Fixed record origins relative to the sampled operand bit zero:
    // low32/high16 = +64, shift24 = +96, shift23/shift28 = +128.
    wire [63:0] phase;
    wire [31:0] partial_even;
    wire [31:0] partial_odd;
    wire [31:0] partial_even_tree;
    wire [31:0] partial_odd_tree;
    wire word_parity;

    wire [15:0] clear_even_l0;
    wire [7:0]  clear_even_l1;
    wire [3:0]  clear_even_l2;
    wire [1:0]  clear_even_l3;
    wire        clear_even_l4;
    wire [15:0] clear_odd_l0;
    wire [7:0]  clear_odd_l1;
    wire [3:0]  clear_odd_l2;
    wire [1:0]  clear_odd_l3;
    wire        clear_odd_l4;
    wire raw_even;
    wire raw_odd;

    gf_b32_mul_phase64 phase_ring (
        .clk_i(clk_i), .rst_i(rst_i), .phase_o(phase)
    );
    gf_b32_mul_product_bank #(.LANES(LANES)) bank (
        .clk_i(clk_i), .rst_i(rst_i), .phase_i(phase),
        .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .partial_even_o(partial_even), .partial_odd_o(partial_odd),
        .word_parity_o(word_parity)
    );

    genvar gr;
    generate
        for (gr = 0; gr < 32; gr = gr + 1) begin : g_partial_route
            // One fixed route register isolates each product-bank terminal
            // from its local tree input.  It is permanent stream pipeline
            // state, never an enable, wait, or ready stage.
            (* keep *) SB_DFFR even_relay (
                .C(clk_i), .R(rst_i), .D(partial_even[gr]),
                .Q(partial_even_tree[gr])
            );
            (* keep *) SB_DFFR odd_relay (
                .C(clk_i), .R(rst_i), .D(partial_odd[gr]),
                .Q(partial_odd_tree[gr])
            );
        end
    endgenerate

    // Tree-level clear pulses are two clocks apart because each serial adder
    // level adds one registered sum stage and one carry-history stage.
    gf_b32_mul_registered_fanout #(.LEAVES(16)) ce0 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[3]), .bit_o(clear_even_l0)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(8)) ce1 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[5]), .bit_o(clear_even_l1)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(4)) ce2 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[7]), .bit_o(clear_even_l2)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(2)) ce3 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[9]), .bit_o(clear_even_l3)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(1)) ce4 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[11]), .bit_o(clear_even_l4)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(16)) co0 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[35]), .bit_o(clear_odd_l0)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(8)) co1 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[37]), .bit_o(clear_odd_l1)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(4)) co2 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[39]), .bit_o(clear_odd_l2)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(2)) co3 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[41]), .bit_o(clear_odd_l3)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(1)) co4 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[43]), .bit_o(clear_odd_l4)
    );

    gf_b32_mul_serial_tree32 even_tree (
        .clk_i(clk_i), .rst_i(rst_i), .in_i(partial_even_tree),
        .clear_l0_i(clear_even_l0), .clear_l1_i(clear_even_l1),
        .clear_l2_i(clear_even_l2), .clear_l3_i(clear_even_l3),
        .clear_l4_i(clear_even_l4), .bit_o(raw_even)
    );
    gf_b32_mul_serial_tree32 odd_tree (
        .clk_i(clk_i), .rst_i(rst_i), .in_i(partial_odd_tree),
        .clear_l0_i(clear_odd_l0), .clear_l1_i(clear_odd_l1),
        .clear_l2_i(clear_odd_l2), .clear_l3_i(clear_odd_l3),
        .clear_l4_i(clear_odd_l4), .bit_o(raw_odd)
    );

    // Raw P[0] occurs 14 clocks after an input word origin; raw P[32]
    // occurs at origin+46.  These delays align both limbs to a phase-zero
    // record at origin+64.  Generate guards are essential: the divider's
    // specialized product sites pay only for the one window they consume.
    localparam integer NEED_LOW_ALIGN = EMIT_LOW32;
    localparam integer NEED_HIGH_ALIGN = EMIT_HIGH16;

    wire even_low_aligned;
    wire odd_low_aligned;
    wire even_high_aligned;
    wire odd_high_aligned;
    wire parity_aligned;

    generate
        if (NEED_LOW_ALIGN) begin : g_low_align
            gf_b32_mul_delay_bit #(.DELAY(50)) even_low_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_even),
                .bit_o(even_low_aligned)
            );
            gf_b32_mul_delay_bit #(.DELAY(50)) odd_low_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_odd),
                .bit_o(odd_low_aligned)
            );
        end else begin : g_no_low_align
            assign even_low_aligned = 1'b0;
            assign odd_low_aligned = 1'b0;
        end
        if (NEED_HIGH_ALIGN) begin : g_high_align
            gf_b32_mul_delay_bit #(.DELAY(18)) even_high_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_even),
                .bit_o(even_high_aligned)
            );
            gf_b32_mul_delay_bit #(.DELAY(18)) odd_high_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_odd),
                .bit_o(odd_high_aligned)
            );
        end else begin : g_no_high_align
            assign even_high_aligned = 1'b0;
            assign odd_high_aligned = 1'b0;
        end
        // Origin+64 is exactly two 32-clock frames later, so its live word
        // parity is already the owning product parity.  No delay bank exists.
        assign parity_aligned = word_parity;

        if (EMIT_LOW32) begin : g_emit_low32
            (* keep *) SB_LUT4 #(.LUT_INIT(16'hcaca)) low_select_lut (
                .I0(even_low_aligned), .I1(odd_low_aligned),
                .I2(parity_aligned), .I3(1'b0), .O(product_low32_bit_o)
            );
        end else begin : g_no_low32
            assign product_low32_bit_o = 1'b0;
        end

        if (EMIT_HIGH16) begin : g_emit_high16
            wire high16_mask;
            gf_b32_mul_phase_window_mask #(.LAST_PHASE(15)) mask (
                .clk_i(clk_i), .rst_i(rst_i), .phase_i(phase),
                .mask_o(high16_mask)
            );
            (* keep *) SB_LUT4 #(.LUT_INIT(16'hca00)) gate (
                .I0(even_high_aligned), .I1(odd_high_aligned),
                .I2(parity_aligned), .I3(high16_mask),
                .O(product_high16_bit_o)
            );
        end else begin : g_no_high16
            assign product_high16_bit_o = 1'b0;
        end

        // ca00 = I3 & (I2 ? I1 : I0).  Selection and phase masking share
        // one LUT, so every registered path remains one LUT deep.
        if (EMIT_SHIFT23) begin : g_emit_shift23
            wire even_window;
            wire odd_window;
            wire output_mask;
            wire window_pre;
            // Raw P23 is at origin+37; delay 59 places it at origin+96.
            // The following P24..P47 bits are already contiguous.  The
            // seventh B relay above is what makes the first raw bit P0.
            gf_b32_mul_delay_bit #(.DELAY(59)) even_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_even),
                .bit_o(even_window)
            );
            gf_b32_mul_delay_bit #(.DELAY(59)) odd_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_odd),
                .bit_o(odd_window)
            );
            gf_b32_mul_phase_window_mask #(.LAST_PHASE(24)) mask (
                .clk_i(clk_i), .rst_i(rst_i), .phase_i(phase),
                .mask_o(output_mask)
            );
            // Origin+96 is three word frames later, hence live parity is the
            // inverse of the owning product.  I0=odd, I1=even implements it.
            (* keep *) SB_LUT4 #(.LUT_INIT(16'hca00)) output_gate (
                .I0(odd_window), .I1(even_window),
                .I2(word_parity), .I3(output_mask),
                .O(window_pre)
            );
            // One registered gate output plus 31 reframe DFFs moves the
            // phase-zero record from origin+96 to origin+128 and prevents a
            // composed product-LUT -> serial-carry-LUT path.
            gf_b32_mul_delay_bit #(.DELAY(32)) output_reframe (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(window_pre),
                .bit_o(window_shift23_25_bit_o)
            );
        end else begin : g_no_shift23
            assign window_shift23_25_bit_o = 1'b0;
        end

        if (EMIT_SHIFT24) begin : g_emit_shift24
            wire even_window;
            wire odd_window;
            wire output_mask;
            gf_b32_mul_delay_bit #(.DELAY(58)) even_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_even),
                .bit_o(even_window)
            );
            gf_b32_mul_delay_bit #(.DELAY(58)) odd_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_odd),
                .bit_o(odd_window)
            );
            gf_b32_mul_phase_window_mask #(.LAST_PHASE(23)) mask (
                .clk_i(clk_i), .rst_i(rst_i), .phase_i(phase),
                .mask_o(output_mask)
            );
            (* keep *) SB_LUT4 #(.LUT_INIT(16'hca00)) output_gate (
                .I0(odd_window), .I1(even_window),
                .I2(word_parity), .I3(output_mask),
                .O(window_shift24_24_bit_o)
            );
        end else begin : g_no_shift24
            assign window_shift24_24_bit_o = 1'b0;
        end

        if (EMIT_SHIFT28) begin : g_emit_shift28
            wire even_window;
            wire odd_window;
            wire output_mask;
            wire window_pre;
            gf_b32_mul_delay_bit #(.DELAY(54)) even_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_even),
                .bit_o(even_window)
            );
            gf_b32_mul_delay_bit #(.DELAY(54)) odd_delay (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_odd),
                .bit_o(odd_window)
            );
            gf_b32_mul_phase_window_mask #(.LAST_PHASE(24)) mask (
                .clk_i(clk_i), .rst_i(rst_i), .phase_i(phase),
                .mask_o(output_mask)
            );
            (* keep *) SB_LUT4 #(.LUT_INIT(16'hca00)) output_gate (
                .I0(odd_window), .I1(even_window),
                .I2(word_parity), .I3(output_mask),
                .O(window_pre)
            );
            gf_b32_mul_delay_bit #(.DELAY(32)) output_reframe (
                .clk_i(clk_i), .rst_i(rst_i), .bit_i(window_pre),
                .bit_o(window_shift28_25_bit_o)
            );
        end else begin : g_no_shift28
            assign window_shift28_25_bit_o = 1'b0;
        end
    endgenerate
endmodule


// Resource-specialized divider product sites.  The disabled output branches
// are absent at elaboration time even though the remaining scalar cells carry
// keep attributes.
module gf_binary32_mul24_shift23_ii32 (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire window_shift23_25_bit_o
);
    // P[23]..P[47], LSB first in phases 0..24 at input origin+128.
    gf_binary32_mul24_ii32 #(
        .LANES(24),
        .EMIT_LOW32(0), .EMIT_HIGH16(0),
        .EMIT_SHIFT23(1), .EMIT_SHIFT24(0), .EMIT_SHIFT28(0)
    ) core (
        .clk_i(clk_i), .rst_i(rst_i), .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .product_low32_bit_o(), .product_high16_bit_o(),
        .window_shift23_25_bit_o(window_shift23_25_bit_o),
        .window_shift24_24_bit_o(), .window_shift28_25_bit_o()
    );
endmodule

module gf_binary32_mul32_shift28_ii32 (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire window_shift28_25_bit_o
);
    // P[28]..P[52], LSB first in phases 0..24 at input origin+128.
    gf_binary32_mul24_ii32 #(
        .LANES(32),
        .EMIT_LOW32(0), .EMIT_HIGH16(0),
        .EMIT_SHIFT23(0), .EMIT_SHIFT24(0), .EMIT_SHIFT28(1)
    ) core (
        .clk_i(clk_i), .rst_i(rst_i), .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .product_low32_bit_o(), .product_high16_bit_o(),
        .window_shift23_25_bit_o(), .window_shift24_24_bit_o(),
        .window_shift28_25_bit_o(window_shift28_25_bit_o)
    );
endmodule


// q*b correction product: q is deliberately one-sided low, making the
// residual nonnegative and below 2B.  Only product[31:0] is consumed.  This
// literal single-context tree therefore clears carry every 32 clocks and does
// not pay for a parity-tail high limb.
module gf_binary32_mul24_low32_ii32 (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_low32_bit_o
);
    // P[0]..P[31], LSB first, exactly one record late at origin+32.
    wire [31:0] phase;
    wire [15:0] a_fan;
    wire b_delay6;
    wire [23:0] b_lane;
    wire [23:0] a_hold;
    wire [31:0] partial;
    wire [15:0] clear_l0_pre;
    wire [15:0] clear_l0;
    wire [7:0]  clear_l1;
    wire [3:0]  clear_l2;
    wire [1:0]  clear_l3;
    wire        clear_l4;
    wire raw_low;

    gf_b32_mul_phase32 phase_ring (
        .clk_i(clk_i), .rst_i(rst_i), .phase_o(phase)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(16)) a_fanout (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(a_bit_i), .bit_o(a_fan)
    );
    // Five fanout edges plus the lane-hold edge require six matching B edges.
    gf_b32_mul_delay_bit #(.DELAY(6)) b_input_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(b_bit_i), .bit_o(b_delay6)
    );
    assign b_lane[0] = b_delay6;

    genvar gs;
    generate
        for (gs = 1; gs < 24; gs = gs + 1) begin : g_b_shift
            (* keep *) SB_DFFR b_ff (
                .C(clk_i), .R(rst_i), .D(b_lane[gs-1]), .Q(b_lane[gs])
            );
        end
        for (gs = 0; gs < 24; gs = gs + 1) begin : g_lane
            wire load_q;
            wire a_next;
            wire partial_d;
            (* keep *) SB_DFFR load_ff (
                .C(clk_i), .R(rst_i), .D(phase[(gs+4)%32]), .Q(load_q)
            );
            (* keep *) SB_LUT4 #(.LUT_INIT(16'hcaca)) hold_lut (
                .I0(a_hold[gs]), .I1(a_fan[gs/2]), .I2(load_q), .I3(1'b0),
                .O(a_next)
            );
            (* keep *) SB_DFFR hold_ff (
                .C(clk_i), .R(rst_i), .D(a_next), .Q(a_hold[gs])
            );

            // This single-context tree emits only product[31:0].  Lanes
            // 0..8 cannot exceed bit 31 because B has only 24 live bits.
            // For lane i>=9, admit product positions i..31 and suppress
            // positions 32..i+23 before they can wrap into the next record.
            if (gs < 9) begin : g_no_low32_truncate
                (* keep *) SB_LUT4 #(.LUT_INIT(16'h8888)) partial_lut (
                    .I0(a_hold[gs]), .I1(b_lane[gs]),
                    .I2(1'b0), .I3(1'b0), .O(partial_d)
                );
            end else begin : g_low32_truncate
                wire active_q;
                wire active_next;
                // The partial LUT evaluates position k in phase k+6.
                // Set one phase before i+6; clear after the legal k=31
                // sample in phase five, before the aliased k=32 sample.
                (* keep *) SB_LUT4 #(.LUT_INIT(16'h0e0e)) active_lut (
                    .I0(active_q), .I1(phase[(gs+5)%32]),
                    .I2(clear_l0_pre[gs-9]), .I3(1'b0),
                    .O(active_next)
                );
                (* keep *) SB_DFFR active_dff (
                    .C(clk_i), .R(rst_i), .D(active_next), .Q(active_q)
                );
                (* keep *) SB_LUT4 #(.LUT_INIT(16'h8080)) partial_lut (
                    .I0(a_hold[gs]), .I1(b_lane[gs]), .I2(active_q),
                    .I3(1'b0), .O(partial_d)
                );
            end
            (* keep *) SB_DFFR partial_ff (
                .C(clk_i), .R(rst_i), .D(partial_d), .Q(partial[gs])
            );
        end
        for (gs = 24; gs < 32; gs = gs + 1) begin : g_pad
            assign partial[gs] = 1'b0;
        end
    endgenerate

    // The phase-five fanout leaves serve both truncation windows and one
    // local relay per level-zero adder.  The relays preserve the original
    // phase-six carry clear while keeping every leaf fanout at two or less.
    gf_b32_mul_registered_fanout #(.LEAVES(16)) c0 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[0]),
        .bit_o(clear_l0_pre)
    );
    generate
        for (genvar gc0 = 0; gc0 < 16; gc0 = gc0 + 1) begin : g_clear_l0_relay
            (* keep *) SB_DFFR clear_relay (
                .C(clk_i), .R(rst_i), .D(clear_l0_pre[gc0]),
                .Q(clear_l0[gc0])
            );
        end
    endgenerate
    gf_b32_mul_registered_fanout #(.LEAVES(8)) c1 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[3]), .bit_o(clear_l1)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(4)) c2 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[5]), .bit_o(clear_l2)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(2)) c3 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[7]), .bit_o(clear_l3)
    );
    gf_b32_mul_registered_fanout #(.LEAVES(1)) c4 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase[9]), .bit_o(clear_l4)
    );
    gf_b32_mul_serial_tree32 tree (
        .clk_i(clk_i), .rst_i(rst_i), .in_i(partial),
        .clear_l0_i(clear_l0), .clear_l1_i(clear_l1),
        .clear_l2_i(clear_l2), .clear_l3_i(clear_l3),
        .clear_l4_i(clear_l4), .bit_o(raw_low)
    );
    gf_b32_mul_delay_bit #(.DELAY(20)) output_delay (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(raw_low),
        .bit_o(product_low32_bit_o)
    );
endmodule


// Standalone tops used only for strict HX8K-CT256 fit/timing gates.
module gf_binary32_mul24_shift23_ii32_fit_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire window_shift23_25_bit_o
);
    gf_binary32_mul24_shift23_ii32 dut (
        .clk_i(clk_i), .rst_i(rst_i), .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .window_shift23_25_bit_o(window_shift23_25_bit_o)
    );
endmodule

module gf_binary32_mul32_shift28_ii32_fit_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire window_shift28_25_bit_o
);
    gf_binary32_mul32_shift28_ii32 dut (
        .clk_i(clk_i), .rst_i(rst_i), .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .window_shift28_25_bit_o(window_shift28_25_bit_o)
    );
endmodule

module gf_binary32_mul24_ii32_fit_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_low32_bit_o,
    output wire product_high16_bit_o,
    output wire window_shift23_25_bit_o,
    output wire window_shift24_24_bit_o,
    output wire window_shift28_25_bit_o
);
    gf_binary32_mul24_ii32 #(.LANES(24)) dut (
        .clk_i(clk_i), .rst_i(rst_i), .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .product_low32_bit_o(product_low32_bit_o),
        .product_high16_bit_o(product_high16_bit_o),
        .window_shift23_25_bit_o(window_shift23_25_bit_o),
        .window_shift24_24_bit_o(window_shift24_24_bit_o),
        .window_shift28_25_bit_o(window_shift28_25_bit_o)
    );
endmodule

module gf_binary32_mul32_ii32_fit_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_low32_bit_o,
    output wire product_high16_bit_o,
    output wire window_shift23_25_bit_o,
    output wire window_shift24_24_bit_o,
    output wire window_shift28_25_bit_o
);
    gf_binary32_mul24_ii32 #(.LANES(32)) dut (
        .clk_i(clk_i), .rst_i(rst_i), .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .product_low32_bit_o(product_low32_bit_o),
        .product_high16_bit_o(product_high16_bit_o),
        .window_shift23_25_bit_o(window_shift23_25_bit_o),
        .window_shift24_24_bit_o(window_shift24_24_bit_o),
        .window_shift28_25_bit_o(window_shift28_25_bit_o)
    );
endmodule

module gf_binary32_mul24_low32_ii32_fit_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_low32_bit_o
);
    gf_binary32_mul24_low32_ii32 dut (
        .clk_i(clk_i), .rst_i(rst_i), .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .product_low32_bit_o(product_low32_bit_o)
    );
endmodule

`default_nettype wire
