`timescale 1ns/1ps
`default_nettype none

module tb_full_retime_stream;
`ifdef TEST_WORDS
    localparam integer WORDS = `TEST_WORDS;
`else
    localparam integer WORDS = 80;
`endif
    localparam integer CAPTURE_CYCLES = (WORDS + 3) * 64;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg a_bit = 1'b0;
    reg b_bit = 1'b0;
    wire product_bit;
    wire product_word_end;

    reg [63:0] a_word [0:WORDS-1];
    reg [63:0] b_word [0:WORDS-1];
    reg [63:0] expected [0:WORDS-1];
    reg output_stream [0:CAPTURE_CYCLES-1];
    reg [63:0] rng;
    integer cycle;
    integer word_index;
    integer bit_index;
    integer delay;
    integer errors;
    integer best_errors;
    integer best_delay;

    always #1 clk = ~clk;

    gf_logisim_mul64_low_full_retime dut (
        .clk_i(clk),
        .rst_i(rst),
        .a_bit_i(a_bit),
        .b_bit_i(b_bit),
        .product_bit_o(product_bit),
        .product_word_end_o(product_word_end)
    );

    initial begin
        rng = 64'h243f_6a88_85a3_08d3;
        for (word_index = 0; word_index < WORDS; word_index = word_index + 1) begin
            rng = rng * 64'h5851_f42d_4c95_7f2d + 64'h1405_7b7e_f767_814f;
            a_word[word_index] = {32'd0, (rng[31:0] | 32'h8000_0000)};
            rng = rng * 64'h5851_f42d_4c95_7f2d + 64'h1405_7b7e_f767_814f;
            b_word[word_index] = {32'd0, (rng[63:32] | 32'h8000_0000)};
            expected[word_index] = a_word[word_index] * b_word[word_index];
        end

        /* Boundary and carry-sensitive cases, all with exact products below 2^64. */
        a_word[0] = 64'd0;          b_word[0] = 64'hffff_ffff;
        a_word[1] = 64'd1;          b_word[1] = 64'hffff_ffff;
        a_word[2] = 64'hffff_ffff;  b_word[2] = 64'hffff_ffff;
        a_word[3] = 64'hffff_fffe;  b_word[3] = 64'hffff_fffd;
        a_word[4] = 64'h8000_0001;  b_word[4] = 64'hffff_fff1;
        for (word_index = 0; word_index < 5; word_index = word_index + 1)
            expected[word_index] = a_word[word_index] * b_word[word_index];

        repeat (3) @(negedge clk);
        rst = 1'b0;

        for (cycle = 0; cycle < CAPTURE_CYCLES; cycle = cycle + 1) begin
            if (cycle < WORDS * 64) begin
                word_index = cycle >> 6;
                bit_index = cycle & 63;
                a_bit = a_word[word_index][bit_index];
                b_bit = b_word[word_index][bit_index];
            end else begin
                a_bit = 1'b0;
                b_bit = 1'b0;
            end
            @(posedge clk);
            @(negedge clk);
            output_stream[cycle] = product_bit;
        end

        best_errors = 1 << 30;
        best_delay = -1;
        for (delay = 0; delay < 128; delay = delay + 1) begin
            errors = 0;
            /* Skip initial fill and final drain; score 76 changing back-to-back words. */
            for (word_index = 2; word_index < WORDS-2; word_index = word_index + 1) begin
                for (bit_index = 0; bit_index < 64; bit_index = bit_index + 1) begin
                    if (output_stream[word_index*64 + bit_index + delay] !== expected[word_index][bit_index])
                        errors = errors + 1;
                end
            end
            if (errors < best_errors) begin
                best_errors = errors;
                best_delay = delay;
            end
        end

        if (best_errors != 0) begin
            $display("FAIL: best fixed delay=%0d still has %0d bit errors", best_delay, best_errors);
            $fatal(1);
        end
        $display("PASS: %0d back-to-back nonoverflowing 64x64->64 words, fixed delay=%0d clocks",
                 WORDS-4, best_delay);
        $finish;
    end
endmodule

`default_nettype wire
