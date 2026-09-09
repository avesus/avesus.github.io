// Full-precision scalar Barker correlation, one parity lane of an interleaved
// stream. Two sign-extended IQ16 words enter LSB-first every 32 clocks:
// current=x[n], previous=x[n-1]; successive words advance n by two.
// A pair of phase-offset lanes can cover all samples. This module alone is
// NOT a complete 20-MS/s radio or clock-domain crossing implementation.
`timescale 1ns/1ps
module gf_serial_delay32(input wire clk,d,output wire q);
    // No runtime reset or masking. Every consumer must flush ten input words
    // after reset before treating a correlation as valid. SRL retains stale
    // data across reset; the arithmetic regression explicitly exercises this.
    (* shreg_extract="yes", srl_style="srl" *) reg [31:0] storage=0;
    always @(posedge clk) storage<={storage[30:0],d};
    assign q=storage[31];
endmodule

// Brian Greenforest registered serial full-adder topology, expressed as its
// subtract/borrow dual. sum=x^y^borrow; borrow'=(~x&(y|borrow))|(y&borrow).
// Clear the borrow while consuming the MSB so the next LSB starts a new word.
module gf_serial_sub_retimed(
    input wire clk,reset,clear_borrow,x,y,output wire difference
);
    wire borrow,next_borrow,next_difference;
    gf_serial_lut #(.INIT(16'h9696)) s(.a(x),.b(y),.c(borrow),.d(1'b0),.q(next_difference));
    gf_serial_lut #(.INIT(16'h00d4)) b(.a(x),.b(y),.c(borrow),.d(clear_borrow),.q(next_borrow));
    gf_serial_reg rs(.clk(clk),.reset(reset),.d(next_difference),.q(difference));
    gf_serial_reg rb(.clk(clk),.reset(reset),.d(next_borrow),.q(borrow));
endmodule

module gf_barker_serial_lane #(parameter integer INITIAL_PHASE=0)(
    input wire clk,reset,current_bit,previous_bit,
    output wire correlation_bit,correlation_word_end
);
    wire [31:0] phase;
    gf_serial_reg #(.INIT(INITIAL_PHASE==0)) p0(.clk(clk),.reset(reset),.d(phase[31]),.q(phase[0]));
    generate for(genvar p=1;p<32;p=p+1)begin:g_phase
        gf_serial_reg #(.INIT(INITIAL_PHASE==p)) r(.clk(clk),.reset(reset),.d(phase[p-1]),.q(phase[p]));
    end endgenerate
    wire [9:0] current_history,previous_history;
    assign current_history[0]=current_bit;
    assign previous_history[0]=previous_bit;
    generate for(genvar t=1;t<10;t=t+1)begin:g_history
        gf_serial_delay32 a(.clk(clk),.d(current_history[t-1]),.q(current_history[t]));
        gf_serial_delay32 b(.clk(clk),.d(previous_history[t-1]),.q(previous_history[t]));
    end endgenerate
    wire [19:0] taps;
    generate for(genvar t=0;t<20;t=t+1)begin:g_tap
        wire source=t%2 ? previous_history[t/2] : current_history[t/2];
        // History successor plus registered tap are exactly two loads.
        gf_serial_reg r(.clk(clk),.reset(reset),.d(source),.q(taps[t]));
    end endgenerate
    function automatic integer positive_index(input integer n);
        case(n)
            0:positive_index=5;1:positive_index=6;2:positive_index=7;
            3:positive_index=8;4:positive_index=9;5:positive_index=12;
            6:positive_index=13;7:positive_index=14;8:positive_index=15;
            9:positive_index=18;default:positive_index=19;
        endcase
    endfunction
    function automatic integer negative_index(input integer n);
        case(n)
            0:negative_index=0;1:negative_index=1;2:negative_index=2;
            3:negative_index=3;4:negative_index=4;5:negative_index=10;
            6:negative_index=11;7:negative_index=16;default:negative_index=17;
        endcase
    endfunction
    wire [15:0] positive[0:4],negative[0:4];
    generate for(genvar n=0;n<16;n=n+1)begin:g_groups
        if(n<11)assign positive[0][n]=taps[positive_index(n)];
        else assign positive[0][n]=1'b0;
        if(n<9)assign negative[0][n]=taps[negative_index(n)];
        else assign negative[0][n]=1'b0;
    end
    for(genvar level=0;level<4;level=level+1)begin:g_reduce
        localparam integer N=8>>level,PC=(11+(1<<level)-1)>>level,NC=(9+(1<<level)-1)>>level;
        wire [2*N-1:0] clear;
        // First tap adds one clock. Every tree level adds one more. Advance
        // the ring source to compensate the registered binary clear tree.
        gf_serial_fanout #(.N(2*N),.D(4-level)) distribution(.clk(clk),.reset(reset),
            .bit_in(phase[(27+2*level)%32]),.leaves(clear));
        for(genvar n=0;n<N;n=n+1)begin:g_node
            if(2*n+1<PC)begin:g_positive_pair
                gf_serial_add_retimed a(.clk(clk),.reset(reset),.clear_carry(clear[2*n]),
                    .x(positive[level][2*n]),.y(positive[level][2*n+1]),.sum(positive[level+1][n]));
            end else if(2*n<PC)begin:g_positive_single
                gf_serial_reg r(.clk(clk),.reset(reset),.d(positive[level][2*n]),.q(positive[level+1][n]));
            end else assign positive[level+1][n]=1'b0;
            if(2*n+1<NC)begin:g_negative_pair
                gf_serial_add_retimed a(.clk(clk),.reset(reset),.clear_carry(clear[2*n+1]),
                    .x(negative[level][2*n]),.y(negative[level][2*n+1]),.sum(negative[level+1][n]));
            end else if(2*n<NC)begin:g_negative_single
                gf_serial_reg r(.clk(clk),.reset(reset),.d(negative[level][2*n]),.q(negative[level+1][n]));
            end else assign negative[level+1][n]=1'b0;
        end
        assign positive[level+1][15:N]=0;
        assign negative[level+1][15:N]=0;
    end endgenerate
    wire clear_difference;
    gf_serial_reg borrow_marker(.clk(clk),.reset(reset),.d(phase[3]),.q(clear_difference));
    gf_serial_sub_retimed difference(.clk(clk),.reset(reset),.clear_borrow(clear_difference),
        .x(positive[4][0]),.y(negative[4][0]),.difference(correlation_bit));
    gf_serial_reg end_marker(.clk(clk),.reset(reset),.d(phase[4]),.q(correlation_word_end));
endmodule

// Fit-only registered serial boundary, not the ADC serializer or radio top.
module gf_barker_serial_fit_top(
    input wire clk,reset,current_bit,previous_bit,
    output wire correlation_bit,correlation_word_end
);
    wire a,b,s,e;
    gf_serial_reg ia(.clk(clk),.reset(reset),.d(current_bit),.q(a));
    gf_serial_reg ib(.clk(clk),.reset(reset),.d(previous_bit),.q(b));
    gf_barker_serial_lane core(.clk(clk),.reset(reset),.current_bit(a),.previous_bit(b),
        .correlation_bit(s),.correlation_word_end(e));
    gf_serial_reg os(.clk(clk),.reset(reset),.d(s),.q(correlation_bit));
    gf_serial_reg oe(.clk(clk),.reset(reset),.d(e),.q(correlation_word_end));
endmodule
