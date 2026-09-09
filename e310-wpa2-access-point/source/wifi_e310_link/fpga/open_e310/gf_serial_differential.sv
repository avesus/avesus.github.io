// Scheduled adapter for the bubbles-free scalar differential graph.
// One request per 40 clocks, at any fixed phase. A phase change must flush
// pending metadata before starting the new phase. Arithmetic never stalls.
`timescale 1ns/1ps
module gf_serial_differential(
    input wire clk,resetn,enable,flush,
    input wire request_valid,
    input wire signed [17:0] ai,bi,aq,bq,
    input wire [4:0] request_phase,
    input wire [7:0] request_age,
    output wire request_ready,
    output reg result_valid,result_sign,
    output reg [4:0] result_phase,
    output reg [15:0] result_age,
    output reg overflow
);
    reg [39:0] slot;
    reg [7:0] tick;
    reg pending,current_valid,previous_valid;
    reg signed [17:0] pending_ai,pending_bi,pending_aq,pending_bq;
    reg signed [17:0] shift_ai,shift_bi,shift_aq,shift_bq;
    reg [4:0] pending_phase,current_phase,previous_phase;
    reg [7:0] pending_tick,current_tick,previous_tick;
    reg [7:0] pending_age,current_age,previous_age;
    wire boundary=slot[39];
    wire sum_bit,sum_end;
    wire [7:0] elapsed=tick-previous_tick;
    assign request_ready=!pending || boundary;
`ifdef GF_COMPACT_SERIAL_FANOUT
    localparam integer COMPACT_FANOUT=1;
`else
    localparam integer COMPACT_FANOUT=0;
`endif
    gf_serial_dot18 #(.COMPACT_FANOUT(COMPACT_FANOUT)) graph(.clk(clk),.reset(!resetn || !enable),
        .ai(shift_ai[0]),.bi(shift_bi[0]),.aq(shift_aq[0]),.bq(shift_bq[0]),
        .sum_bit(sum_bit),.sum_word_end(sum_end));

    always @(posedge clk) begin
        if(!resetn || !enable) begin
            slot<=40'd1;tick<=0;
            pending<=0;current_valid<=0;previous_valid<=0;
            pending_ai<=0;pending_bi<=0;pending_aq<=0;pending_bq<=0;
            shift_ai<=0;shift_bi<=0;shift_aq<=0;shift_bq<=0;
            pending_phase<=0;current_phase<=0;previous_phase<=0;
            pending_tick<=0;current_tick<=0;previous_tick<=0;
            pending_age<=0;current_age<=0;previous_age<=0;
            result_valid<=0;result_sign<=0;result_phase<=0;result_age<=0;
            overflow<=0;
        end else begin
            slot<={slot[38:0],slot[39]};
            // Clock age must advance every clock; these are eight-bit timing
            // counters, not sample arithmetic or a wide multiply/add datapath.
            tick<=tick+1'b1;
            result_valid<=0;
            shift_ai<={shift_ai[17],shift_ai[17:1]};
            shift_bi<={shift_bi[17],shift_bi[17:1]};
            shift_aq<={shift_aq[17],shift_aq[17:1]};
            shift_bq<={shift_bq[17],shift_bq[17:1]};
            if(boundary) begin
                // Next core word starts on the following clock. Its last
                // sum bit is consumed 55 clocks after this boundary, after
                // one further boundary has advanced its metadata.
                shift_ai<=pending ? pending_ai : 18'sd0;
                shift_bi<=pending ? pending_bi : 18'sd0;
                shift_aq<=pending ? pending_aq : 18'sd0;
                shift_bq<=pending ? pending_bq : 18'sd0;
                previous_valid<=current_valid;
                previous_phase<=current_phase;
                previous_tick<=current_tick;
                previous_age<=current_age;
                current_valid<=pending;
                current_phase<=pending_phase;
                current_tick<=pending_tick;
                current_age<=pending_age;
                pending<=0;
            end
            if(sum_end && previous_valid && !overflow) begin
                result_valid<=1;
                result_sign<=sum_bit;
                result_phase<=previous_phase;
                result_age<={8'd0,previous_age}+{8'd0,elapsed};
            end
            if(request_valid && request_ready) begin
                pending<=1;
                pending_ai<=ai;pending_bi<=bi;pending_aq<=aq;pending_bq<=bq;
                pending_phase<=request_phase;
                pending_tick<=tick;
                pending_age<=request_age;
            end else if(request_valid) begin
                overflow<=1;
                result_valid<=0;
            end
            if(flush) begin
                // Core words may keep flowing, but no old-phase result can
                // acquire meaning in the next descrambler context.
                pending<=0;current_valid<=0;previous_valid<=0;result_valid<=0;
            end
        end
    end
endmodule
