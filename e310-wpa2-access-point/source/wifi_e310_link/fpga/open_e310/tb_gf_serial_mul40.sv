`timescale 1ns/1ps
module tb_gf_serial_mul40;
    reg clk=0, reset=1,a_bit=0,b_bit=0;
    always #5 clk=~clk;
    wire product_bit,word_end;
    gf_serial_mul40 dut(.clk(clk),.reset(reset),.a_bit(a_bit),.b_bit(b_bit),
        .product_bit(product_bit),.product_word_end(word_end));
    localparam WORDS=2048;
    reg [39:0] av[0:WORDS-1],bv[0:WORDS-1],expected[0:WORDS-1];
    reg signed [17:0] asigned,bsigned;
    reg [39:0] actual;
    integer i,cycle,outbit,outword,checks=0;
    initial begin
        for(i=0;i<WORDS;i=i+1) begin
            asigned=$random; bsigned=$random;
            case(i)
              0: begin asigned=0; bsigned=0; end
              1: begin asigned=-131072; bsigned=-131072; end
              2: begin asigned=-131072; bsigned=131071; end
              3: begin asigned=131071; bsigned=131071; end
              4: begin asigned=-1; bsigned=-1; end
            endcase
            av[i]={{22{asigned[17]}},asigned};
            bv[i]={{22{bsigned[17]}},bsigned};
            if(i>=1024) begin av[i]={$random,$random}; bv[i]={$random,$random}; end
            // Independent testbench arithmetic, not synthesizable DSP RTL.
            expected[i]=av[i]*bv[i];
        end
        repeat(3) @(negedge clk);
        reset=0;
        actual=0;
        for(cycle=0;cycle<WORDS*40+13;cycle=cycle+1) begin
            if(cycle<WORDS*40) begin
                a_bit=av[cycle/40][cycle%40]; b_bit=bv[cycle/40][cycle%40];
            end else begin a_bit=0; b_bit=0; end
            @(posedge clk); #1;
            if(cycle>=13) begin
                outbit=(cycle-13)%40; outword=(cycle-13)/40;
                actual[outbit]=product_bit;
                if(word_end !== (outbit==39)) $fatal(1,"word alignment cycle=%0d",cycle);
                if(outbit==39) begin
                    if(actual!==expected[outword]) $fatal(1,"product word=%0d a=%h b=%h got=%h want=%h",outword,av[outword],bv[outword],actual,expected[outword]);
                    checks=checks+1;
                end
            end
            @(negedge clk);
        end
        if(checks!=WORDS) $fatal(1,"missing products");
        $display("SERIAL_MUL40_PASS words=%0d bits=40 input_ii=40 latency=13 full_signed_18x18=true physical_rf=false",checks);
        $finish;
    end
endmodule
