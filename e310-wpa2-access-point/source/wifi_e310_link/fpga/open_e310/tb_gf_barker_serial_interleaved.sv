`timescale 1ns/1fs
// Four scalar lanes: even/odd for each of I and Q. Serialization here is an
// independent TESTBENCH source, not a claimed implemented ADC interface.
module tb_gf_barker_serial_interleaved;
    localparam integer SAMPLES=2048;
    reg clk=0,reset_a=1,reset_b=1;
    always #1.5625 clk=~clk; // 320 MHz: one new complex sample per 16 clocks.
    reg ai=0,ap_i=0,aq=0,ap_q=0,bi=0,bp_i=0,bq=0,bp_q=0;
    wire asi,asq,bsi,bsq,ae,aqe,be,bqe;
    gf_barker_serial_lane ia(clk,reset_a,ai,ap_i,asi,ae);
    gf_barker_serial_lane qa(clk,reset_a,aq,ap_q,asq,aqe);
    gf_barker_serial_lane ib(clk,reset_b,bi,bp_i,bsi,be);
    gf_barker_serial_lane qb(clk,reset_b,bq,bp_q,bsq,bqe);
    integer samples_i[0:SAMPLES-1],samples_q[0:SAMPLES-1];
    integer expected_i[0:SAMPLES-1],expected_q[0:SAMPLES-1];
    integer epoch,cycle,n,k,a_index,b_index,word_a,word_b,pos_a,pos_b;
    integer count=0,last_cycle=-1,qualified_cycle=0;
    reg [31:0] ia_word=0,qa_word=0,ib_word=0,qb_word=0;
    function automatic integer value(input integer index,input integer quadrature);
        if(index<0 || index>=SAMPLES)value=0;
        else value=quadrature ? samples_q[index] : samples_i[index];
    endfunction
    function automatic integer coefficient(input integer lag);
        coefficient=(lag<5 || (lag>=10 && lag<12) || (lag>=16 && lag<18)) ? -1 : 1;
    endfunction
    task check(input integer index,input [31:0] iv,input [31:0] qv);
        begin
            if(index>=19 && index<SAMPLES)begin
                if(iv!==expected_i[index] || qv!==expected_q[index])
                    $fatal(1,"interleaved mismatch epoch=%0d sample=%0d I=%h/%h Q=%h/%h",epoch,index,iv,expected_i[index],qv,expected_q[index]);
                if(last_cycle>=0 && qualified_cycle-last_cycle!=16)
                    $fatal(1,"interleaved result gap clocks=%0d",qualified_cycle-last_cycle);
                last_cycle=qualified_cycle;count=count+1;
            end
        end
    endtask
    always @(posedge clk)begin
        #0.1;
        if(!reset_a)begin
            qualified_cycle=qualified_cycle+1;
            ia_word={asi,ia_word[31:1]};qa_word={asq,qa_word[31:1]};
            if(ae!==aqe)$fatal(1,"even IQ marker alignment");
            if(ae)begin check(a_index,ia_word,qa_word);a_index=a_index+2;end
        end
        if(!reset_b)begin
            ib_word={bsi,ib_word[31:1]};qb_word={bsq,qb_word[31:1]};
            if(be!==bqe)$fatal(1,"odd IQ marker alignment");
            if(be)begin check(b_index,ib_word,qb_word);b_index=b_index+2;end
        end
    end
    initial begin
        for(epoch=0;epoch<3;epoch=epoch+1)begin
            @(negedge clk);reset_a=1;reset_b=1;
            ai=0;ap_i=0;aq=0;ap_q=0;bi=0;bp_i=0;bq=0;bp_q=0;
            repeat(7+epoch)@(negedge clk);
            for(n=0;n<SAMPLES;n=n+1)begin
                samples_i[n]=$signed(16'($random));samples_q[n]=$signed(16'($random));
                if(n%19==0)begin samples_i[n]=-32768;samples_q[n]=32767;end
                if(n%19==1)begin samples_i[n]=32767;samples_q[n]=-32768;end
                expected_i[n]=0;expected_q[n]=0;
                for(k=0;k<20;k=k+1)begin
                    expected_i[n]=expected_i[n]+coefficient(k)*value(n-k,0);
                    expected_q[n]=expected_q[n]+coefficient(k)*value(n-k,1);
                end
            end
            a_index=-2;b_index=-1;last_cycle=-1;qualified_cycle=0;
            ia_word=0;qa_word=0;ib_word=0;qb_word=0;
            reset_a=0;
            for(cycle=0;cycle<SAMPLES*16+64;cycle=cycle+1)begin
                if(cycle==16)reset_b=0;
                word_a=(cycle/32)*2;pos_a=cycle%32;
                word_b=cycle<16 ? -1 : ((cycle-16)/32)*2+1;pos_b=(cycle+16)%32;
                ai=(value(word_a,0)>>>pos_a)&1;ap_i=(value(word_a-1,0)>>>pos_a)&1;
                aq=(value(word_a,1)>>>pos_a)&1;ap_q=(value(word_a-1,1)>>>pos_a)&1;
                bi=(value(word_b,0)>>>pos_b)&1;bp_i=(value(word_b-1,0)>>>pos_b)&1;
                bq=(value(word_b,1)>>>pos_b)&1;bp_q=(value(word_b-1,1)>>>pos_b)&1;
                @(negedge clk);
            end
        end
        if(count!=3*(SAMPLES-19))$fatal(1,"comparison coverage %0d",count);
        $display("BARKER_SERIAL_INTERLEAVED_PASS complex_results=%0d interval_clocks=16 clock_mhz=320 precision=full_iq16 reset_epochs=3 adc_interface=testbench physical_rf=false",count);
        $finish;
    end
    initial begin #10000000;$fatal(1,"timeout");end
endmodule
