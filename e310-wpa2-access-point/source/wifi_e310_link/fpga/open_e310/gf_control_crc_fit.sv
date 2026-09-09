// Fit-only 333-MHz registered boundary, never used as the radio top.
module gf_control_crc_fit_top (
    input wire clk,reset,bit_valid,data_bit,
    output wire [31:0] fcs
);
    wire valid_r,data_r;
    wire [31:0] result;
    gf_serial_reg input_valid(.clk(clk),.reset(reset),.d(bit_valid),.q(valid_r));
    gf_serial_reg input_data(.clk(clk),.reset(reset),.d(data_bit),.q(data_r));
    gf_control_crc_bitserial graph(.clk(clk),.clear(reset),.bit_valid(valid_r),.data_bit(data_r),.fcs(result));
    generate for(genvar n=0;n<32;n=n+1)begin:g_output
        gf_serial_reg boundary(.clk(clk),.reset(reset),.d(result[n]),.q(fcs[n]));
    end endgenerate
endmodule
