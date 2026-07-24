`timescale 1ns/1ps

module cd4029b_counter (
    input  wire       clk,
    input  wire       load,
    input  wire       enable,
    input  wire       binary_mode,
    input  wire       up,
    input  wire [3:0] jam,
    output reg  [3:0] q,
    output wire       carry_out_n
);
    wire [3:0] maximum;
    wire       terminal;

    assign maximum = binary_mode ? 4'd15 : 4'd9;
    assign terminal = up ? (q == maximum) : (q == 4'd0);
    assign carry_out_n = ~(enable && terminal);

    always @(posedge clk) begin
        if (load) begin
            q <= jam;
        end else if (enable) begin
            if (up) begin
                q <= terminal ? 4'd0 : q + 1'b1;
            end else begin
                q <= terminal ? maximum : q - 1'b1;
            end
        end
    end
endmodule
