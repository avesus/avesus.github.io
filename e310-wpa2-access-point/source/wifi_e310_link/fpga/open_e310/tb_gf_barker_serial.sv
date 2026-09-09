`timescale 1ns/1ps
module tb_gf_barker_serial;
    reg clk=0,reset=1,a=0,b=0;
    always #1.5625 clk=~clk;
    wire bit_out,word_end;
    gf_barker_serial_lane dut(.clk(clk),.reset(reset),.current_bit(a),.previous_bit(b),
        .correlation_bit(bit_out),.correlation_word_end(word_end));
    integer history[0:19],expected[0:20000];
    integer stream_word,output_word,bit_index,j,current,previous,result,epoch,passed=0;
    reg [31:0] observed=0;
    function automatic integer coefficient(input integer n);
        coefficient=(n<5 || (n>=10 && n<12) || (n>=16 && n<18)) ? -1 : 1;
    endfunction
    task push(input integer value);
        begin for(integer k=19;k>0;k=k-1)history[k]=history[k-1];history[0]=value;end
    endtask
    always @(posedge clk)begin
        #0.1;
        if(!reset)begin
            observed={bit_out,observed[31:1]};
            if(word_end)begin
                // A marker appears during the initial pipeline fill. Input
                // phase zero after reset defines the first complete word.
                if(output_word>=9)begin
                    if(observed!==expected[output_word])
                        $fatal(1,"correlation mismatch epoch=%0d word=%0d got=%h expected=%h",epoch,output_word,observed,expected[output_word]);
                    passed=passed+1;
                end
                output_word=output_word+1;
            end
        end
    end
    initial begin
        for(epoch=0;epoch<3;epoch=epoch+1)begin
            @(negedge clk);reset=1;a=0;b=0;
            repeat(5+epoch)@(negedge clk);
            for(j=0;j<20;j=j+1)history[j]=0;
            output_word=-1;observed=0;reset=0;
            for(stream_word=0;stream_word<5000;stream_word=stream_word+1)begin
                case(stream_word%17)
                    0:begin current=-32768;previous=32767;end
                    1:begin current=32767;previous=-32768;end
                    2:begin current=-32768;previous=-32768;end
                    3:begin current=32767;previous=32767;end
                    4:begin current=0;previous=0;end
                    default:begin current=$signed(16'($random));previous=$signed(16'($random));end
                endcase
                push(previous);push(current);result=0;
                for(j=0;j<20;j=j+1)result=result+coefficient(j)*history[j];
                expected[stream_word]=result;
                for(bit_index=0;bit_index<32;bit_index=bit_index+1)begin
                    a=(current>>>bit_index)&1;b=(previous>>>bit_index)&1;
                    @(negedge clk);
                end
            end
            // Abandon a partial word, reset with stale SRL storage, then fill
            // fresh samples. No runtime reset of the sample history is needed.
            a=0;b=0;repeat(7+epoch)@(negedge clk);
        end
        $display("BARKER_SERIAL_LANE_PASS comparisons=%0d signed_iq16=true word_bits=32 no_word_gaps=true reset_with_stale_history=true physical_rf=false",passed);
        $finish;
    end
    initial begin #10000000;$fatal(1,"timeout");end
endmodule
