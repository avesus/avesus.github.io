`default_nettype none

/* Independent observability bank: every core retains its own phase and clear trees. */
module gf_mul64_low_full_retime_bank #(
    parameter integer CORES = 1
) (
    input  wire             clk_i,
    input  wire             rst_i,
    input  wire [CORES-1:0] a_bit_i,
    input  wire [CORES-1:0] b_bit_i,
    output wire [CORES-1:0] product_bit_o
);
    wire [CORES-1:0] unused_word_end;

    generate
        for (genvar core = 0; core < CORES; core = core + 1) begin : g_core
            (* keep_hierarchy = "yes" *)
            gf_logisim_mul64_low_full_retime u_mul (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .a_bit_i(a_bit_i[core]),
                .b_bit_i(b_bit_i[core]),
                .product_bit_o(product_bit_o[core]),
                .product_word_end_o(unused_word_end[core])
            );
        end
    endgenerate
endmodule

`default_nettype wire
