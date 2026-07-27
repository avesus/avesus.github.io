/*
 * Brian Greenforest's positive, LSB-first, bubbles-free serial multiplier.
 * One new operand word follows the previous word without a drain bubble.
 * Only the low WORD_BITS product bits are emitted.
 */

`default_nettype none

module gf_bubbles_free_mul #(
    parameter integer WORD_BITS = 8
) (
    input  wire clk_i,
    input  wire rst_i,
    input  wire a_bit_i,
    input  wire b_bit_i,
    output wire product_bit_o,
    output wire word_start_o
);
    localparam integer TREE_LEVELS = (WORD_BITS <= 1) ? 0 : $clog2(WORD_BITS);
    localparam integer TREE_LEAVES = 1 << TREE_LEVELS;

    reg [WORD_BITS-1:0] phase_q;
    reg [WORD_BITS-1:0] a_word_q;
    reg [WORD_BITS-1:0] b_word_q;
    reg [WORD_BITS-1:0] a_now;
    reg [WORD_BITS-1:0] b_now;
    reg [WORD_BITS-1:0] partial_bits;

    wire [TREE_LEAVES-1:0] tree_bits [0:TREE_LEVELS];
    wire [TREE_LEAVES-1:0] tree_starts [0:TREE_LEVELS];

    integer phase_index;
    integer coefficient;
    integer a_index;
    always @* begin
        a_now = a_word_q;
        b_now = b_word_q;
        for (phase_index = 0; phase_index < WORD_BITS; phase_index = phase_index + 1) begin
            if (phase_q[phase_index]) begin
                a_now[phase_index] = a_bit_i;
                b_now[phase_index] = b_bit_i;
            end
        end
        partial_bits = {WORD_BITS{1'b0}};
        for (coefficient = 0; coefficient < WORD_BITS; coefficient = coefficient + 1) begin
            if (phase_q[coefficient]) begin
                for (a_index = 0; a_index < WORD_BITS; a_index = a_index + 1) begin
                    if (a_index <= coefficient)
                        partial_bits[a_index] = a_now[a_index]
                            & b_now[coefficient-a_index];
                end
            end
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            phase_q  <= {{(WORD_BITS-1){1'b0}}, 1'b1};
            a_word_q <= {WORD_BITS{1'b0}};
            b_word_q <= {WORD_BITS{1'b0}};
        end else begin
            for (phase_index = 0; phase_index < WORD_BITS; phase_index = phase_index + 1) begin
                if (phase_q[phase_index]) begin
                    a_word_q[phase_index] <= a_bit_i;
                    b_word_q[phase_index] <= b_bit_i;
                end
            end
            phase_q <= {phase_q[WORD_BITS-2:0], phase_q[WORD_BITS-1]};
        end
    end

    genvar leaf;
    generate
        for (leaf = 0; leaf < TREE_LEAVES; leaf = leaf + 1) begin : g_leaves
            if (leaf < WORD_BITS)
                assign tree_bits[0][leaf] = partial_bits[leaf];
            else
                assign tree_bits[0][leaf] = 1'b0;
            assign tree_starts[0][leaf] = phase_q[0];
        end
    endgenerate

    genvar level;
    genvar node;
    generate
        for (level = 0; level < TREE_LEVELS; level = level + 1) begin : g_tree_level
            for (node = 0; node < TREE_LEAVES; node = node + 1) begin : g_tree_node
                if (node < (TREE_LEAVES >> (level + 1))) begin : g_active_node
                    gf_serial_add_cell u_reduce (
                        .clk_i(clk_i), .rst_i(rst_i),
                        .word_start_i(tree_starts[level][node << 1]),
                        .x_bit_i(tree_bits[level][node << 1]),
                        .y_bit_i(tree_bits[level][(node << 1) | 1]),
                        .sum_bit_o(tree_bits[level+1][node]),
                        .word_start_o(tree_starts[level+1][node])
                    );
                end else begin : g_inactive_node
                    assign tree_bits[level+1][node] = 1'b0;
                    assign tree_starts[level+1][node] = 1'b0;
                end
            end
        end
    endgenerate

    assign product_bit_o = tree_bits[TREE_LEVELS][0];
    assign word_start_o = tree_starts[TREE_LEVELS][0];
endmodule

`default_nettype wire
