`timescale 1ns/1ps

module cd4029b_counter_tb;
    reg        clk;
    reg        load;
    reg        enable;
    reg        binary_mode;
    reg        up;
    reg  [3:0] jam;
    wire [3:0] q;
    wire       carry_out_n;

    cd4029b_counter dut (
        .clk(clk),
        .load(load),
        .enable(enable),
        .binary_mode(binary_mode),
        .up(up),
        .jam(jam),
        .q(q),
        .carry_out_n(carry_out_n)
    );

    always #5 clk = ~clk;

    task expect_q;
        input [3:0] expected;
        begin
            if (q !== expected) begin
                $fatal(1, "expected q=%0d, observed q=%0d", expected, q);
            end
        end
    endtask

    task expect_carry;
        input expected_n;
        begin
            if (carry_out_n !== expected_n) begin
                $fatal(
                    1,
                    "expected carry_out_n=%b, observed carry_out_n=%b at q=%0d",
                    expected_n,
                    carry_out_n,
                    q
                );
            end
        end
    endtask

    task tick_and_expect;
        input [3:0] expected;
        begin
            @(posedge clk);
            #1;
            expect_q(expected);
        end
    endtask

    task load_and_expect;
        input [3:0] value;
        begin
            @(negedge clk);
            jam = value;
            load = 1'b1;
            tick_and_expect(value);
            @(negedge clk);
            load = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        load = 1'b0;
        enable = 1'b0;
        binary_mode = 1'b1;
        up = 1'b1;
        jam = 4'd0;

        $dumpfile("cd4029b_counter.vcd");
        $dumpvars(0, cd4029b_counter_tb);

        load_and_expect(4'd5);
        tick_and_expect(4'd5);
        tick_and_expect(4'd5);

        enable = 1'b1;
        binary_mode = 1'b1;
        up = 1'b1;
        load_and_expect(4'd14);
        tick_and_expect(4'd15);
        expect_carry(1'b0);
        tick_and_expect(4'd0);
        expect_carry(1'b1);

        up = 1'b0;
        load_and_expect(4'd1);
        tick_and_expect(4'd0);
        expect_carry(1'b0);
        tick_and_expect(4'd15);
        expect_carry(1'b1);

        binary_mode = 1'b0;
        up = 1'b1;
        load_and_expect(4'd8);
        tick_and_expect(4'd9);
        expect_carry(1'b0);
        tick_and_expect(4'd0);
        expect_carry(1'b1);

        up = 1'b0;
        load_and_expect(4'd1);
        tick_and_expect(4'd0);
        expect_carry(1'b0);
        tick_and_expect(4'd9);
        expect_carry(1'b1);

        if (q > 4'd9) begin
            $fatal(1, "invalid decade state: %0d", q);
        end

        $display(
            "PASS: load, hold, binary up/down, decade up/down, wrap, and carry verified"
        );
        $finish;
    end
endmodule
