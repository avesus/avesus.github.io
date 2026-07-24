`timescale 1ns/1ps

module counter_tb;
    reg clk;
    reg reset;
    wire [3:0] count;

    counter #(
        .WIDTH(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .count(count)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        $dumpfile("counter.vcd");
        $dumpvars(0, counter_tb);

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (5) @(posedge clk);
        #1;
        if (count !== 4'd5) begin
            $fatal(1, "expected count=5, observed count=%0d", count);
        end

        repeat (11) @(posedge clk);
        #1;
        if (count !== 4'd0) begin
            $fatal(1, "expected four-bit wrap to 0, observed count=%0d", count);
        end

        $display("PASS: reset, five updates, and four-bit wrap verified");
        $finish;
    end
endmodule
