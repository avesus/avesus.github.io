`timescale 1ns/1fs
module tb_gf_barker_radio_bridge #(parameter integer FAST_PHASE_PS=0);
    localparam integer SAMPLES=1024;
    reg clk=0,fast=0,resetn=0,enable=0,locked=1,valid=0;
    always #12.5 clk=~clk;
    initial begin #(FAST_PHASE_PS*0.001);forever #1.5625 fast=~fast;end
    reg signed [15:0] i=0,q=0;
    wire receiver_resetn,result_valid,fault;
    wire signed [23:0] ci,cq;
    gf_barker_radio_bridge dut(clk,fast,resetn,enable,locked,valid,i,q,receiver_resetn,result_valid,fault,ci,cq);
    integer iv[0:SAMPLES+31],qv[0:SAMPLES+31],ei[0:SAMPLES+31],eq[0:SAMPLES+31];
    integer epoch,n,k,c,index,count=0,fault_clock=-1;
    reg wanted;
    function automatic integer coefficient(input integer lag);
        coefficient=(lag<5 || (lag>=10 && lag<12) || (lag>=16 && lag<18))?-1:1;
    endfunction
    initial begin
        for(epoch=0;epoch<4;epoch=epoch+1)begin
            @(negedge clk);resetn=0;enable=0;valid=0;
            repeat(5+epoch)@(negedge clk);
            for(n=0;n<SAMPLES+32;n=n+1)begin
                iv[n]=n<SAMPLES?$signed(16'($random)):0;qv[n]=n<SAMPLES?$signed(16'($random)):0;
                if(n%19==0)begin iv[n]=-32768;qv[n]=32767;end
                ei[n]=0;eq[n]=0;
                for(k=0;k<20;k=k+1)if(n>=k)begin
                    ei[n]=ei[n]+coefficient(k)*iv[n-k];eq[n]=eq[n]+coefficient(k)*qv[n-k];
                end
            end
            resetn=1;enable=1;fault_clock=-1;
            for(c=0;c<2*SAMPLES+18;c=c+1)begin
                valid=c%2==0;i=valid?iv[c/2]:$random;q=valid?qv[c/2]:$random;
                if(epoch==2 && c==600)valid=0;
                if(epoch==3 && c==601)valid=1;
                @(posedge clk);#0.1;
                if(fault && fault_clock<0)fault_clock=c;
                if(epoch<2 || c<600)begin
                    if(fault)$fatal(1,"unexpected bridge fault phase=%0d epoch=%0d cycle=%0d",FAST_PHASE_PS,epoch,c);
                    wanted=c>=45 && (c-7)%2==0;
                    if(result_valid!==wanted)$fatal(1,"bridge valid/age phase=%0d epoch=%0d cycle=%0d got=%b expected=%b",FAST_PHASE_PS,epoch,c,result_valid,wanted);
                end
                if(result_valid)begin
                    index=(c-7)/2;
                    if(ci!==24'(ei[index]) || cq!==24'(eq[index]))$fatal(1,"bridge IQ phase=%0d epoch=%0d cycle=%0d sample=%0d",FAST_PHASE_PS,epoch,c,index);
                    if(index<SAMPLES)count=count+1;
                end
                if(fault && result_valid)$fatal(1,"fault failed to veto result");
                if(epoch>=2 && c>=605 && !fault)$fatal(1,"missing cadence fault");
                @(negedge clk);
            end
            // Lock loss must veto outputs immediately without fast-clock work.
            locked=0;#0.1;
            if(result_valid || receiver_resetn)$fatal(1,"clock-loss veto failed");
            locked=1;
        end
        $display("BARKER_RADIO_BRIDGE_PASS phase_ps=%0d comparisons=%0d latency_radio_clocks=7 cadence_faults=2 reset_epochs=4 physical_rf=false",FAST_PHASE_PS,count);
        $finish;
    end
    initial begin #1000000;$fatal(1,"timeout");end
endmodule
