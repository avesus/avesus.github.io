`timescale 1ns/1ps
module tb_gf_barker_recurrence;
    reg clk=0,clear=1,valid=0;
    always #5 clk=~clk;
    reg signed [15:0] sample=0;
    wire signed [23:0] correlation;
    wire result_valid;
    reg signed [15:0] history[0:19];
    localparam integer LATENCY=12;
    reg signed [23:0] expected[0:LATENCY-1];
    reg [LATENCY-1:0] expected_valid=0;
    reg [31:0] rng=32'hde123abc;
    integer sum,n,k,cycle,checks=0;
    gf_dsss_barker_recurrence dut(.clk(clk),.clear(clear),.sample_valid(valid),
        .sample(sample),.correlation(correlation),.result_valid(result_valid));
    always @(posedge clk)begin
        if(clear)begin
            for(n=0;n<20;n=n+1)history[n]=0;
            for(n=0;n<LATENCY;n=n+1)expected[n]<=0;
            expected_valid<=0;
        end else begin
            expected_valid<={expected_valid[LATENCY-2:0],valid};
            for(n=1;n<LATENCY;n=n+1)expected[n]<=expected[n-1];
            if(valid)begin
                for(n=19;n>0;n=n-1)history[n]=history[n-1];
                history[0]=sample;
                sum=0;
                // Independent original oldest-to-newest 20-term definition.
                for(n=0;n<20;n=n+1)begin
                    case(n)
                        2,3,8,9,15,16,17,18,19:sum=sum-$signed(history[19-n]);
                        default:sum=sum+$signed(history[19-n]);
                    endcase
                end
                expected[0]<=sum;
            end
        end
    end
    always @(negedge clk)if(!clear)begin
        if(result_valid!==expected_valid[LATENCY-1])$fatal(1,"valid latency mismatch");
        if(result_valid)begin
            if(correlation!==expected[LATENCY-1])$fatal(1,"correlation mismatch actual=%0d expected=%0d cycle=%0d",correlation,expected[LATENCY-1],cycle);
            checks=checks+1;
        end
    end
    initial begin
        repeat(4)@(negedge clk);#1;clear=0;
        for(cycle=0;cycle<200000;cycle=cycle+1)begin
            @(negedge clk);#1;
            rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);
            clear=(cycle%997==0);
            // Consecutive inputs, regular 20-MS/s and irregular sample gaps.
            valid=cycle<1000 ? 1 : cycle<2000 ? !cycle[0] : rng[0]||rng[1];
            if(cycle<40)sample=cycle==1 ? 16'sh8000 : cycle==22 ? 16'sh7fff : 0;
            else if(cycle<250)sample=16'sh7fff;
            else if(cycle<500)sample=16'sh8000;
            else if(cycle<1000)sample=cycle[0]?16'sh8000:16'sh7fff;
            else sample=rng[31:16];
        end
        @(negedge clk);#1;clear=0;valid=0;
        repeat(LATENCY+4)@(negedge clk);
        $display("BARKER_RECURRENCE_PASS checks=%0d full_signed_width=24 sample_gaps=true reset_flush=true physical_rf=false",checks);
        $finish;
    end
endmodule
