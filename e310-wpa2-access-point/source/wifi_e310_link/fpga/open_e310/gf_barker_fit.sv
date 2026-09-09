// Fit-only registered boundary; not the hardware radio top.
module gf_barker_fit_top(
    input wire clk,reset,sample_valid,
    input wire [15:0] sample,
    output wire [23:0] correlation,
    output wire result_valid
);
    wire valid_r,next_valid;
    wire [15:0] sample_r;
    wire [23:0] next_correlation;
    gf_serial_reg v(.clk(clk),.reset(reset),.d(sample_valid),.q(valid_r));
    generate for(genvar n=0;n<16;n=n+1)begin:g_input
        gf_serial_reg r(.clk(clk),.reset(reset),.d(sample[n]),.q(sample_r[n]));
    end endgenerate
    gf_dsss_barker_recurrence graph(.clk(clk),.clear(reset),.sample_valid(valid_r),
        .sample(sample_r),.correlation(next_correlation),.result_valid(next_valid));
    generate for(genvar n=0;n<24;n=n+1)begin:g_output
        gf_serial_reg r(.clk(clk),.reset(reset),.d(next_correlation[n]),.q(correlation[n]));
    end endgenerate
    gf_serial_reg out_v(.clk(clk),.reset(reset),.d(next_valid),.q(result_valid));
endmodule
