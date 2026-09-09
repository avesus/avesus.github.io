// 40-MHz IQ16 sample clock <-> phase-related 320-MHz serial correlator.
// Input toggle synchronizer qualifies a bundled word held for 50 ns. Output
// capture uses the FALLING radio edge, away from the qualified fast-word edge.
// See constrain_barker_radio_bridge.tcl for the explicit settling budgets.
`timescale 1ns/1ps
module gf_barker_radio_bridge(
    input wire radio_clk,fast_clk,resetn,enable,clock_locked,
    input wire sample_valid,input wire signed [15:0] sample_i,sample_q,
    output wire receiver_resetn,result_valid,fault,
    output reg signed [23:0] correlation_i=0,correlation_q=0
);
    wire clear=!resetn || !enable || !clock_locked;
    reg [31:0] sample_hold=0;
    reg sample_toggle=0;
    always @(posedge radio_clk or posedge clear)begin
        if(clear)begin sample_hold<=0;sample_toggle<=0;end
        else if(sample_valid)begin sample_hold<={sample_q,sample_i};sample_toggle<=~sample_toggle;end
    end
    (* ASYNC_REG="TRUE" *) reg [1:0] fast_reset_pipe=2'b11;
    always @(posedge fast_clk or posedge clear)begin
        if(clear)fast_reset_pipe<=2'b11;else fast_reset_pipe<={fast_reset_pipe[0],1'b0};
    end
    wire fast_reset=fast_reset_pipe[1];
    (* ASYNC_REG="TRUE" *) reg [1:0] sample_sync=0;
    reg sample_seen=0,arrival_delayed=0,started=0;
    wire arrival=sample_sync[1]^sample_seen;
    always @(posedge fast_clk or posedge fast_reset)begin
        if(fast_reset)begin sample_sync<=0;sample_seen<=0;arrival_delayed<=0;started<=0;end
        else begin
            sample_sync<={sample_sync[0],sample_toggle};sample_seen<=sample_sync[1];
            arrival_delayed<=arrival;
            if(arrival)started<=1;
        end
    end
    // These registers may see a transitioning word early. Only the PISO load
    // qualified by the synchronized toggle consumes it, after the settling
    // interval. Each source bit has one crossing load; each fast bit has two
    // PISO loads. No wide fast-domain sample-enable fanout is introduced.
    wire [31:0] sample_fast;
    generate for(genvar b=0;b<32;b=b+1)begin:g_sample
        gf_serial_reg capture(fast_clk,fast_reset,sample_hold[b],sample_fast[b]);
    end endgenerate
    wire graph_reset=fast_reset || !started;
    wire unused_slot,graph_fault,word_valid;
    wire signed [31:0] ci,cq;
    gf_barker_serial_iq graph(fast_clk,graph_reset,arrival_delayed,
        $signed(sample_fast[15:0]),$signed(sample_fast[31:16]),unused_slot,graph_fault,word_valid,ci,cq);
    wire word_toggle;
    gf_serial_reg event_toggle(fast_clk,graph_reset,word_toggle^word_valid,word_toggle);
    wire word_toggle_crossing;
    gf_serial_reg event_copy(fast_clk,graph_reset,word_toggle,word_toggle_crossing);
    reg word_seen=0,captured_valid=0;
    always @(negedge radio_clk or posedge clear)begin
        if(clear)begin word_seen<=0;captured_valid<=0;correlation_i<=0;correlation_q<=0;end
        else begin
            word_seen<=word_toggle_crossing;
            captured_valid<=word_seen!=word_toggle_crossing;
            if(word_seen!=word_toggle_crossing)begin correlation_i<=ci[23:0];correlation_q<=cq[23:0];end
        end
    end
    // Shift the serial detector's reset/word epoch with the seven-radio-clock
    // input path. Hold this reset on disable/clock loss, even if fast_clk stops.
    reg [6:0] receiver_reset_pipe=0;
    always @(posedge radio_clk or posedge clear)begin
        if(clear)receiver_reset_pipe<=0;else receiver_reset_pipe<={receiver_reset_pipe[5:0],1'b1};
    end
    gf_serial_reg fault_copy(fast_clk,fast_reset,graph_fault,fault);
    assign receiver_resetn=receiver_reset_pipe[6] && !clear && !graph_fault;
    assign result_valid=captured_valid && receiver_resetn;
endmodule
