`default_nettype none

/* Minimal simulation-only models for the iCE40 primitives used by the core. */
module SB_DFFR (
    input  wire C,
    input  wire R,
    input  wire D,
    output reg  Q
);
    always @(posedge C) begin
        if (R)
            Q <= 1'b0;
        else
            Q <= D;
    end
endmodule

module SB_DFFS (
    input  wire C,
    input  wire S,
    input  wire D,
    output reg  Q
);
    always @(posedge C) begin
        if (S)
            Q <= 1'b1;
        else
            Q <= D;
    end
endmodule

module SB_LUT4 #(
    parameter [15:0] LUT_INIT = 16'h0000
) (
    input  wire I0,
    input  wire I1,
    input  wire I2,
    input  wire I3,
    output wire O
);
    assign O = LUT_INIT[{I3, I2, I1, I0}];
endmodule

`default_nettype wire
