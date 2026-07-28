/*
 * Fully retimed, bubbles-free low-64 form of the published multiplier.
 *
 * Every data/control dependency has bounded fan-out:
 *   - A enters a registered binary fan-out tree before the 64 phase holds.
 *   - B receives the identical fixed latency.
 *   - all 64 partial-product ANDs are registered.
 *   - every serial-adder reduction level is registered.
 *   - each carry-clear pulse has its own registered binary distribution tree.
 *
 * The added stages change only latency.  A new A/B bit is consumed on every
 * clock and a new low-64 product starts every 64 clocks with no clock enable.
 */

`default_nettype none

module gf_registered_binary_fanout #(
    parameter integer LEAVES = 32,
    parameter integer DEPTH = $clog2(LEAVES)
) (
    input  wire              clk_i,
    input  wire              rst_i,
    input  wire              bit_i,
    output wire [LEAVES-1:0] leaves_o
);
    /* Explicit kept cells prevent synthesis from collapsing duplicate leaves. */
    wire [LEAVES-1:0] stage_q [0:DEPTH];
    (* keep = "true" *) SB_DFFR root_buffer (
        .C(clk_i), .R(rst_i), .D(bit_i), .Q(stage_q[0][0])
    );

    generate
        for (genvar level = 1; level <= DEPTH; level = level + 1) begin : g_level
            localparam integer NODES = 1 << level;
            for (genvar node = 0; node < NODES; node = node + 1) begin : g_node
                (* keep = "true" *) SB_DFFR branch_buffer (
                    .C(clk_i), .R(rst_i),
                    .D(stage_q[level-1][node >> 1]),
                    .Q(stage_q[level][node])
                );
            end
        end
    endgenerate

    assign leaves_o = stage_q[DEPTH][LEAVES-1:0];
endmodule

module gf_serial_add_pipe_full_retime (
    input  wire clk_i,
    input  wire rst_i,
    input  wire clear_carry_i,
    input  wire x_i,
    input  wire y_i,
    output wire sum_o
);
    reg carry_q;
    reg sum_q;
    wire sum_next;
    wire carry_next;

    /*
     * Exact full-adder truth tables.  Keeping the two physical LUTs separate
     * prevents synthesis from introducing a shared propagate LUT and a second
     * combinational LUT level.  I3 is ignored by sum; I3=1 clears carry.
     */
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h9696)) sum_lut (
        .I0(x_i), .I1(y_i), .I2(carry_q), .I3(clear_carry_i), .O(sum_next)
    );
    (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'h00e8)) carry_lut (
        .I0(x_i), .I1(y_i), .I2(carry_q), .I3(clear_carry_i), .O(carry_next)
    );

    assign sum_o = sum_q;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            carry_q <= 1'b0;
            sum_q   <= 1'b0;
        end else begin
            sum_q   <= sum_next;
            carry_q <= carry_next;
        end
    end
endmodule

module gf_logisim_mul64_low_full_retime (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_bit_o,
    output wire product_word_end_o
);
    localparam integer TREE_LEVELS = 6;

    /* A input: 1-2-4-8-16-32 registered tree; each leaf drives two holds. */
    wire [31:0] a_fanout_leaf;
    gf_registered_binary_fanout #(.LEAVES(32)) u_a_fanout (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(a_bit_i),
        .leaves_o(a_fanout_leaf)
    );

    /* Self-contained local word phase: every phase tap has small fixed fan-out. */
    wire [63:0] phase_onehot_q;
    (* keep = "true" *) SB_DFFS phase_zero (
        .C(clk_i), .S(rst_i),
        .D(phase_onehot_q[63]), .Q(phase_onehot_q[0])
    );
    generate
        for (genvar phase = 1; phase < 64; phase = phase + 1) begin : g_phase
            (* keep = "true" *) SB_DFFR phase_step (
                .C(clk_i), .R(rst_i),
                .D(phase_onehot_q[phase-1]), .Q(phase_onehot_q[phase])
            );
        end
    endgenerate

    wire [63:0] a_load_pulse_q;
    wire [63:0] a_hold_q;
    wire [63:0] a_hold_next;
    generate
        for (genvar lane = 0; lane < 64; lane = lane + 1) begin : g_a_hold
            /*
             * A fan-out is consumer-visible six edges after its input bit:
             * root DFF plus five binary levels.  A separate local phase DFF
             * samples phase N+5, then enables lane N at N+6.  This preserves
             * arithmetic alignment while breaking the phase-ring-to-hold
             * route into two registered, fixed-fanout paths.
             */
            localparam integer LOAD_SOURCE_PHASE = (lane + 5) % 64;
            (* keep = "true" *) SB_DFFR load_phase_buffer (
                .C(clk_i), .R(rst_i),
                .D(phase_onehot_q[LOAD_SOURCE_PHASE]),
                .Q(a_load_pulse_q[lane])
            );
            /* Literal Logisim hold MUX followed by an ordinary reset DFF. */
            (* keep = "true" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) hold_mux (
                .I0(a_hold_q[lane]),
                .I1(a_fanout_leaf[lane >> 1]),
                .I2(a_load_pulse_q[lane]), .I3(1'b0),
                .O(a_hold_next[lane])
            );
            (* keep = "true" *) SB_DFFR hold_register (
                .C(clk_i), .R(rst_i),
                .D(a_hold_next[lane]), .Q(a_hold_q[lane])
            );
        end
    endgenerate

    /* Six matching input-delay DFFs feed the published 64-stage B delay. */
    reg [5:0] b_input_delay_q;
    reg [63:0] b_delay_q;
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            b_input_delay_q <= 6'd0;
            b_delay_q <= 64'd0;
        end else begin
            b_input_delay_q <= {b_input_delay_q[4:0], b_bit_i};
            b_delay_q <= {b_delay_q[62:0], b_input_delay_q[5]};
        end
    end

    /* The partial-product register removes the only two-LUT reduction path. */
    reg [63:0] partial_q;
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            partial_q <= 64'd0;
        else
            partial_q <= a_hold_q & b_delay_q;
    end

    /*
     * Partial-product bit zero is registered after edge 7.  Tree level L
     * computes its bit zero at edge 8+L, so its carry must already be clear at
     * edge 7+L.  The clear-tree consumer delays are 6,5,...,1 edges; therefore
     * the local one-hot sources are phases 1,3,5,7,9,11.
     */
    wire [31:0] clear_level0;
    wire [15:0] clear_level1;
    wire [7:0]  clear_level2;
    wire [3:0]  clear_level3;
    wire [1:0]  clear_level4;
    wire [0:0]  clear_level5;
    wire [31:0] clear_by_level [0:5];

    gf_registered_binary_fanout #(.LEAVES(32)) u_clear0 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_onehot_q[1]),
        .leaves_o(clear_level0)
    );
    gf_registered_binary_fanout #(.LEAVES(16)) u_clear1 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_onehot_q[3]),
        .leaves_o(clear_level1)
    );
    gf_registered_binary_fanout #(.LEAVES(8)) u_clear2 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_onehot_q[5]),
        .leaves_o(clear_level2)
    );
    gf_registered_binary_fanout #(.LEAVES(4)) u_clear3 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_onehot_q[7]),
        .leaves_o(clear_level3)
    );
    gf_registered_binary_fanout #(.LEAVES(2)) u_clear4 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_onehot_q[9]),
        .leaves_o(clear_level4)
    );
    gf_registered_binary_fanout #(.LEAVES(1), .DEPTH(0)) u_clear5 (
        .clk_i(clk_i), .rst_i(rst_i), .bit_i(phase_onehot_q[11]),
        .leaves_o(clear_level5)
    );
    assign clear_by_level[0] = clear_level0;
    assign clear_by_level[1] = {{16{1'b0}}, clear_level1};
    assign clear_by_level[2] = {{24{1'b0}}, clear_level2};
    assign clear_by_level[3] = {{28{1'b0}}, clear_level3};
    assign clear_by_level[4] = {{30{1'b0}}, clear_level4};
    assign clear_by_level[5] = {{31{1'b0}}, clear_level5};

    wire [63:0] tree_bits [0:TREE_LEVELS];
    assign tree_bits[0] = partial_q;
    generate
        for (genvar level = 0; level < TREE_LEVELS; level = level + 1) begin : g_level
            localparam integer ACTIVE_NODES = 64 >> (level + 1);
            for (genvar node = 0; node < 64; node = node + 1) begin : g_node
                if (node < ACTIVE_NODES) begin : g_active
                    gf_serial_add_pipe_full_retime u_add (
                        .clk_i(clk_i), .rst_i(rst_i),
                        .clear_carry_i(clear_by_level[level][node]),
                        .x_i(tree_bits[level][2*node]),
                        .y_i(tree_bits[level][2*node+1]),
                        .sum_o(tree_bits[level+1][node])
                    );
                end else begin : g_inactive
                    assign tree_bits[level+1][node] = 1'b0;
                end
            end
        end
    endgenerate

    assign product_bit_o = tree_bits[TREE_LEVELS][0];
    /* Product bit 63 is visible while phase 13 is asserted. */
    assign product_word_end_o = phase_onehot_q[13];
endmodule

module gf_mul64_low_full_retime_fit_top (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_bit_o
);
    wire unused_word_end;
    gf_logisim_mul64_low_full_retime u_mul (
        .clk_i(clk_i), .rst_i(rst_i),
        .a_bit_i(a_bit_i), .b_bit_i(b_bit_i),
        .product_bit_o(product_bit_o),
        .product_word_end_o(unused_word_end)
    );
endmodule

`default_nettype wire
