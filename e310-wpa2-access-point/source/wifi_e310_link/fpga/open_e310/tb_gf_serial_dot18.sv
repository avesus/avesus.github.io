`timescale 1ns/1ps
module tb_gf_serial_dot18 #(parameter integer COMPACT_FANOUT=0);
    reg clk=0,reset=1,ai=0,bi=0,aq=0,bq=0;
    always #5 clk=~clk;
    wire sum_bit,word_end;
    gf_serial_dot18 #(.COMPACT_FANOUT(COMPACT_FANOUT)) dut(.clk(clk),.reset(reset),.ai(ai),.bi(bi),.aq(aq),.bq(bq),
        .sum_bit(sum_bit),.sum_word_end(word_end));
    localparam WORDS=1024;
    reg signed [17:0] aiv[0:WORDS-1],biv[0:WORDS-1],aqv[0:WORDS-1],bqv[0:WORDS-1];
    reg signed [39:0] expected[0:WORDS-1];
    reg signed [39:0] aext,bext,qext,rext,actual;
    integer i,cycle,outbit,outword,checks=0;
    initial begin
        for(i=0;i<WORDS;i=i+1) begin
            aiv[i]=$random; biv[i]=$random; aqv[i]=$random; bqv[i]=$random;
            case(i)
              0: begin aiv[i]=0; biv[i]=0; aqv[i]=0; bqv[i]=0; end
              1: begin aiv[i]=-131072; biv[i]=-131072; aqv[i]=-131072; bqv[i]=-131072; end
              2: begin aiv[i]=-131072; biv[i]=131071; aqv[i]=-131072; bqv[i]=131071; end
              3: begin aiv[i]=131071; biv[i]=131071; aqv[i]=-131071; bqv[i]=131071; end
            endcase
            aext=aiv[i]; bext=biv[i]; qext=aqv[i]; rext=bqv[i];
            expected[i]=aext*bext+qext*rext;
        end
        repeat(3) @(negedge clk);
        reset=0; actual=0;
        for(cycle=0;cycle<WORDS*40+14;cycle=cycle+1) begin
            if(cycle<WORDS*40) begin
                i=cycle/40;
                aext=aiv[i]; bext=biv[i]; qext=aqv[i]; rext=bqv[i];
                ai=aext[cycle%40]; bi=bext[cycle%40]; aq=qext[cycle%40]; bq=rext[cycle%40];
            end else begin ai=0; bi=0; aq=0; bq=0; end
            @(posedge clk); #1;
            if(cycle>=14) begin
                outbit=(cycle-14)%40; outword=(cycle-14)/40;
                actual[outbit]=sum_bit;
                if(word_end !== (outbit==39)) $fatal(1,"dot word alignment cycle=%0d",cycle);
                if(outbit==39) begin
                    if(actual!==expected[outword]) $fatal(1,"dot word=%0d got=%h want=%h",outword,actual,expected[outword]);
                    checks=checks+1;
                end
            end
            @(negedge clk);
        end
        if(checks!=WORDS) $fatal(1,"missing dot products");
        $display("SERIAL_DOT18_PASS words=%0d full_signed_sum=true input_ii=40 latency=14 physical_rf=false",checks);
        $finish;
    end
endmodule
