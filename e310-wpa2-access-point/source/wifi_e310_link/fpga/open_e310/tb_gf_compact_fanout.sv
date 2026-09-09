`timescale 1ns/1ps
module tb_gf_compact_fanout;
    reg clk=0,reset=1,ai=0,bi=0,aq=0,bq=0;
    always #5 clk=~clk;
    wire old_bit,new_bit,old_end,new_end;
    gf_serial_dot18 #(.COMPACT_FANOUT(0)) reference_graph(
        .clk(clk),.reset(reset),.ai(ai),.bi(bi),.aq(aq),.bq(bq),
        .sum_bit(old_bit),.sum_word_end(old_end));
    gf_serial_dot18 #(.COMPACT_FANOUT(1)) candidate_graph(
        .clk(clk),.reset(reset),.ai(ai),.bi(bi),.aq(aq),.bq(bq),
        .sum_bit(new_bit),.sum_word_end(new_end));
    integer phase,cycle,checks=0;
    // Arbitrary input bits challenge graph equivalence even outside the
    // signed-input protocol. Reset at each of the forty possible word phases.
    initial begin
        repeat(3) @(negedge clk);
        for(phase=0;phase<40;phase=phase+1)begin
            reset=0;
            for(cycle=0;cycle<4000+phase;cycle=cycle+1)begin
                ai=$random;bi=$random;aq=$random;bq=$random;
                @(posedge clk);#1;
                if({old_bit,old_end} !== {new_bit,new_end})
                    $fatal(1,"compact mismatch phase=%0d cycle=%0d",phase,cycle);
                checks=checks+1;
                @(negedge clk);
            end
            #2;reset=1;#1;
            if({old_bit,old_end} !== {new_bit,new_end}) $fatal(1,"async reset mismatch");
            repeat(2) @(negedge clk);
        end
        $display("COMPACT_FANOUT_EQUIVALENCE_PASS clocks=%0d reset_phases=40 latency_unchanged=true physical_rf=false",checks);
        $finish;
    end
endmodule
