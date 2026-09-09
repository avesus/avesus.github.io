// Fit-only boundary; the deployed graph consumes the RX descrambler bitstream.
module gf_rx_crc_fit_top (
    input wire clk,reset,bit_valid,data_bit,
    output wire good
);
    wire valid_r,data_r,matched;
    wire [31:0] fcs;
    gf_serial_reg input_valid(.clk(clk),.reset(reset),.d(bit_valid),.q(valid_r));
    gf_serial_reg input_data(.clk(clk),.reset(reset),.d(data_bit),.q(data_r));
    gf_control_crc_bitserial crc(.clk(clk),.clear(reset),.bit_valid(valid_r),.data_bit(data_r),.fcs(fcs));
    gf_rx_crc_residue residue(.clk(clk),.clear(reset),.fcs(fcs),.good(matched));
    gf_serial_reg output_good(.clk(clk),.reset(reset),.d(matched),.q(good));
endmodule
