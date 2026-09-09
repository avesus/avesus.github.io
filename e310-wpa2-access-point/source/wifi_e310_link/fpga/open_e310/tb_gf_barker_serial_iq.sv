`timescale 1ns/1fs
// Independent parallel sample source, not a testbench serial word generator.
module tb_gf_barker_serial_iq;
    localparam integer SAMPLES=2048;
    reg clk=0,reset=1,sample_valid=0;
    always #1.5625 clk=~clk;
    reg signed [15:0] sample_i=0,sample_q=0;
    wire slot,fault,valid;
    wire signed [31:0] ci,cq;
    gf_barker_serial_iq dut(clk,reset,sample_valid,sample_i,sample_q,slot,fault,valid,ci,cq);
    integer iv[0:SAMPLES+7],qv[0:SAMPLES+7],ei[0:SAMPLES+7],eq[0:SAMPLES+7];
    integer epoch,n,k,cycle,index,count=0,fault_checks=0,qualified=0;
    reg expected_fault,wanted;
    function automatic integer coefficient(input integer lag);
        coefficient=(lag<5 || (lag>=10 && lag<12) || (lag>=16 && lag<18))?-1:1;
    endfunction
    initial begin
        for(epoch=0;epoch<5;epoch=epoch+1)begin
            @(negedge clk);reset=1;sample_valid=0;
            repeat(7+epoch)@(negedge clk);
            for(n=0;n<SAMPLES+8;n=n+1)begin
                iv[n]=n<SAMPLES?$signed(16'($random)):0;
                qv[n]=n<SAMPLES?$signed(16'($random)):0;
                if(n<SAMPLES && n%19==0)begin iv[n]=-32768;qv[n]=32767;end
                if(n<SAMPLES && n%19==1)begin iv[n]=32767;qv[n]=-32768;end
                ei[n]=0;eq[n]=0;
                for(k=0;k<20;k=k+1)if(n>=k)begin
                    ei[n]=ei[n]+coefficient(k)*iv[n-k];
                    eq[n]=eq[n]+coefficient(k)*qv[n-k];
                end
            end
            expected_fault=0;reset=0;
            for(cycle=0;cycle<SAMPLES*16+53;cycle=cycle+1)begin
                sample_valid=cycle%16==0;
                // Change parallel inputs even between sample slots, proving
                // that the implemented PISO only consumes scheduled words.
                sample_i=sample_valid?iv[cycle/16]:$random;
                sample_q=sample_valid?qv[cycle/16]:$random;
                if(epoch==3 && cycle==611)sample_valid=1; // unexpected sample
                if(epoch==4 && cycle==608)sample_valid=0; // missing sample
                #0.1;
                if(slot!==(cycle%16==0))$fatal(1,"slot mismatch epoch=%0d cycle=%0d",epoch,cycle);
                if(sample_valid!=(cycle%16==0))expected_fault=1;
                @(posedge clk);#0.1;
                if($test$plusargs("TRACE") && epoch==0 && cycle<350 && cycle%16==8)
                    $display("IQ_TRACE cycle=%0d phase=%h load=%h/%h cur=%b/%b prev=%b/%b words=%h/%h out=%h ready=%b",cycle,dut.phase,dut.load[0],dut.load[1],dut.current[0],dut.current[1],dut.previous[0],dut.previous[1],dut.words[0][0],dut.words[1][0],ci,dut.ready);
                if($test$plusargs("TRACE") && epoch==0 && cycle<350 && cycle%16==8)
                    $display("CORE_TRACE phase=%h taps=%h positive=%h negative=%h clear=%b diff=%b hist=%b/%b",dut.g_parity[0].g_iq[0].core.phase,dut.g_parity[0].g_iq[0].core.taps,dut.g_parity[0].g_iq[0].core.positive[4],dut.g_parity[0].g_iq[0].core.negative[4],dut.g_parity[0].g_iq[0].core.clear_difference,dut.g_parity[0].g_iq[0].correlation_bit,dut.g_parity[0].g_iq[0].core.current_history,dut.g_parity[0].g_iq[0].core.previous_history);
                if(fault!==expected_fault)$fatal(1,"cadence fault mismatch cycle=%0d",cycle);
                wanted=cycle>=344 && (cycle-40)%16==0 && !expected_fault;
                if(valid!==wanted)$fatal(1,"valid mismatch epoch=%0d cycle=%0d got=%b wanted=%b",epoch,cycle,valid,wanted);
                if(valid)begin
                    index=(cycle-40)/16;
                    if(ci!==ei[index] || cq!==eq[index])
                        $fatal(1,"parallel IQ mismatch epoch=%0d cycle=%0d sample=%0d I=%h/%h Q=%h/%h",epoch,cycle,index,ci,ei[index],cq,eq[index]);
                    qualified=qualified+1;
                    if(epoch<3 && index<SAMPLES)count=count+1;
                end
                if(expected_fault)fault_checks=fault_checks+1;
                @(negedge clk);
            end
        end
        if(count!=3*(SAMPLES-19))$fatal(1,"coverage mismatch %0d",count);
        $display("BARKER_SERIAL_IQ_PASS complete_complex_results=%0d comparisons=%0d latency_clocks=40 interval_clocks=16 clock_mhz=320 precision=full_iq16 reset_epochs=5 fault_suppression_clocks=%0d serializer=rtl clock_crossing=not_integrated physical_rf=false",count,qualified,fault_checks);
        $finish;
    end
    initial begin #10000000;$fatal(1,"timeout");end
endmodule
