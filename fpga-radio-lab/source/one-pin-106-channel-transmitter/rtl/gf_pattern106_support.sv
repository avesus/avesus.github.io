/* Compact support cells used by Pattern106.  Keeping this compilation unit
 * focused prevents the build from parsing unrelated 120/240-lane top levels. */
`default_nettype none

module gf_serial_add_cell_lean (
    input wire clk_i,input wire run_i,input wire word_start_i,
    input wire x_bit_i,input wire y_bit_i,output reg sum_bit_o
);
    reg carry_q;
    initial begin carry_q=1'b0; sum_bit_o=1'b0; end
    wire carry_in=word_start_i?1'b0:carry_q;
    wire sum_d=x_bit_i^y_bit_i^carry_in;
    wire carry_d=(x_bit_i&y_bit_i)|(x_bit_i&carry_in)|(y_bit_i&carry_in);
    always @(posedge clk_i) if(run_i) begin carry_q<=carry_d; sum_bit_o<=sum_d; end
endmodule

module gf_one_shot_burst_gate #(
    parameter integer BURST_CYCLES_108=324000000
) (
    input wire clk_108_i,input wire rst_i,input wire arm_i,
    input wire datapath_ready_i,output reg burst_active_o,
    output reg burst_done_o
);
    localparam integer COUNT_BITS=(BURST_CYCLES_108<=1)?1:$clog2(BURST_CYCLES_108);
    reg [COUNT_BITS-1:0] cycle_q;
    reg started_q=1'b0;
    initial begin cycle_q=0; burst_active_o=0; burst_done_o=0; end
    always @(posedge clk_108_i) begin
        if(rst_i) begin
            cycle_q<=0; burst_active_o<=0;
            if(started_q) burst_done_o<=1;
        end else if(!started_q) begin
            burst_done_o<=0;
            if(arm_i&&datapath_ready_i) begin
                started_q<=1; cycle_q<=0; burst_active_o<=1;
            end
        end else if(burst_active_o) begin
            if((BURST_CYCLES_108<=1)||(cycle_q==BURST_CYCLES_108-1)) begin
                burst_active_o<=0; burst_done_o<=1;
            end else cycle_q<=cycle_q+1'b1;
        end else burst_done_o<=1;
    end
endmodule

module gf_gray_quadrant_dds_lean (
    input wire clk_216_i,input wire rst_i,input wire i_sdm_bit_i,
    input wire q_sdm_bit_i,output reg selector_i_o,output reg selector_q_o,
    output wire [7:0] dds_phase_o
);
    reg [7:0] dds_phase_q;
    always @(posedge clk_216_i) begin
        if(rst_i) dds_phase_q<=0;
        else dds_phase_q<=(dds_phase_q>=8'd139)?dds_phase_q-8'd139:dds_phase_q+8'd5;
    end
    always @* begin
        if(dds_phase_q<8'd36) begin selector_i_o=i_sdm_bit_i; selector_q_o=q_sdm_bit_i; end
        else if(dds_phase_q<8'd72) begin selector_i_o=q_sdm_bit_i; selector_q_o=~i_sdm_bit_i; end
        else if(dds_phase_q<8'd108) begin selector_i_o=~i_sdm_bit_i; selector_q_o=~q_sdm_bit_i; end
        else begin selector_i_o=~q_sdm_bit_i; selector_q_o=i_sdm_bit_i; end
    end
    assign dds_phase_o=dds_phase_q;
endmodule

module gf_published_four_phase_selector (
    input wire pll_216mhz_i,input wire pll_216mhz_90_i,
    input wire selector_i_i,input wire selector_q_i,
    output wire modulated_rf_o
);
    wire p1=pll_216mhz_i;
    wire p2=pll_216mhz_90_i;
    wire p3=~pll_216mhz_i;
    wire p4=~pll_216mhz_90_i;
    assign modulated_rf_o=selector_i_i?(selector_q_i?p1:p4):(selector_q_i?p2:p3);
endmodule

`default_nettype wire
