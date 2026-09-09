`timescale 1ns/1ps
module tb_gf_serial_differential;
    reg clk=0,resetn=0,enable=1,flush=0,request=0;
    always #12.5 clk=~clk;
    reg signed [17:0] ai=0,bi=0,aq=0,bq=0;
    reg [4:0] phase=0;
    reg [7:0] age=3;
    wire ready,valid,sign_bit,overflow;
    wire [4:0] result_phase;
    wire [15:0] result_age;
    gf_serial_differential dut(.clk(clk),.resetn(resetn),.enable(enable),.flush(flush),
        .request_valid(request),.ai(ai),.bi(bi),.aq(aq),.bq(bq),
        .request_phase(phase),.request_age(age),.request_ready(ready),
        .result_valid(valid),.result_sign(sign_bit),.result_phase(result_phase),
        .result_age(result_age),.overflow(overflow));
    integer clock_count=0,wr=0,rd=0,offset,k,cycle,checks=0;
    reg expected_sign[0:4095];
    reg [4:0] expected_phase[0:4095];
    integer request_tick[0:4095];
    reg signed [39:0] ae,be,qe,re,expected;
    always @(posedge clk) begin
        clock_count=clock_count+1;
        if(resetn && enable) begin
            if(flush) rd=wr;
            else if(request) begin
                if(!ready)$fatal(1,"unexpected backpressure");
                ae=ai;be=bi;qe=aq;re=bq;
                expected=ae*be+qe*re;
                expected_sign[wr]=expected[39];
                expected_phase[wr]=phase;
                request_tick[wr]=clock_count;
                wr=wr+1;
            end
        end
        #1;
        if(overflow)$fatal(1,"serial adapter overflow");
        if(valid) begin
            if(rd>=wr)$fatal(1,"unsolicited/stale result");
            if(sign_bit!==expected_sign[rd] || result_phase!==expected_phase[rd])
                $fatal(1,"tagged differential mismatch request=%0d sign=%b want=%b phase=%0d want=%0d",rd,sign_bit,expected_sign[rd],result_phase,expected_phase[rd]);
            if(result_age !== 3+clock_count-request_tick[rd])
                $fatal(1,"age mismatch got=%0d want=%0d",result_age,3+clock_count-request_tick[rd]);
            if(result_age>100)$fatal(1,"unexpectedly old decision");
            rd=rd+1;checks=checks+1;
        end
    end
    initial begin
        repeat(5)@(negedge clk);resetn=1;
        for(offset=0;offset<40;offset=offset+1) begin
            flush=1;@(negedge clk);flush=0;
            repeat(offset)@(negedge clk);
            for(k=0;k<24;k=k+1) begin
                ai=$random;bi=$random;aq=$random;bq=$random;phase=offset%20;
                request=1;@(negedge clk);request=0;
                repeat(39)@(negedge clk);
            end
            repeat(120)@(negedge clk);
            if(rd!=wr)$fatal(1,"missing results");
        end
        // Flush with requests in flight, then immediately use another phase.
        request=1;ai=-131072;bi=131071;aq=0;bq=0;phase=2;
        @(negedge clk);request=0;repeat(10)@(negedge clk);
        flush=1;@(negedge clk);flush=0;
        request=1;ai=131071;bi=131071;phase=7;
        @(negedge clk);request=0;repeat(120)@(negedge clk);
        if(rd!=wr)$fatal(1,"flush lost the new request");
        $display("SERIAL_DIFFERENTIAL_ADAPTER_PASS checks=%0d offsets=40 exact_age=true stale_phase_discard=true physical_rf=false",checks);
        $finish;
    end
endmodule
