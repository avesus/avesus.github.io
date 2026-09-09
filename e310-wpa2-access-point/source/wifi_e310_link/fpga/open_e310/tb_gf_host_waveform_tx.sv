`timescale 1ns/1ps
module tb_gf_host_waveform_tx #(parameter integer MEMORY_READ_LATENCY=0);
    reg clk=0; always #12.5 clk=~clk;
    reg resetn=0, arm=0, kill=1, frame_commit=0;
    reg [11:0] frame_length_bytes=0;
    wire [11:0] frame_read_address;
    reg [7:0] memory[0:4095];
    reg [7:0] synchronous_read_data;
    always @(posedge clk) synchronous_read_data<=memory[frame_read_address];
    wire [7:0] frame_read_data=MEMORY_READ_LATENCY ? synchronous_read_data : memory[frame_read_address];
    reg tx_channel_available=1, tx_sample_tick=0, tx_sink_ready=1;
    always @(negedge clk) tx_sample_tick<=!tx_sample_tick;
    wire ready,busy,tx_rf_claim,tx_valid,frame_done,frame_error;
    wire [31:0] tx_iq;
    gf_host_waveform_tx #(.MEMORY_READ_LATENCY(MEMORY_READ_LATENCY)) dut(.*);
    reg [31:0] expected[0:653279];
    integer length, count=0, errors=0, dones=0, limit, j;
    reg check_iq=0;
    string base, path;
    always @(posedge clk) begin
        if(frame_done) dones=dones+1;
        if(frame_error) errors=errors+1;
        if(tx_valid && tx_sample_tick && tx_sink_ready) begin
            if(check_iq && (count>=limit || tx_iq!==expected[count]))
                $fatal(1,"IQ mismatch sample=%0d got=%h want=%h",count,tx_iq,expected[count]);
            count=count+1;
        end
    end
    task commit;
        begin
            @(negedge clk); frame_commit=1;
            @(negedge clk); frame_commit=0;
        end
    endtask
    task settle;
        begin repeat(5) @(negedge clk); end
    endtask
    initial begin
        if(!$value$plusargs("BASE=%s",base) || !$value$plusargs("LENGTH=%d",length)) $fatal(1,"args");
        path={base,".hex"}; $readmemh(path,memory,0,length+35);
        path={base,"-iq.hex"}; limit=(length+24)*160;
        $readmemh(path,expected,0,limit-1);
        settle(); resetn=1; arm=1; kill=0; frame_length_bytes=length+36;
        check_iq=1; commit(); wait(frame_done); settle();
        if(count!=limit || errors || dones!=1) $fatal(1,"completion %0d %0d %0d",count,errors,dones);
        // A second exact frame catches stale increment/header state.
        count=0; commit(); wait(frame_done); settle();
        if(count!=limit || errors || dones!=2) $fatal(1,"repeat completion");
        check_iq=0; count=0;
        tx_channel_available=0; commit(); repeat(800) @(negedge clk);
        if(tx_rf_claim || tx_valid || count) $fatal(1,"transmitted while SIFS path claimed channel");
        tx_channel_available=1; wait(tx_valid); repeat(10) @(negedge clk);
        kill=1; #1; if(tx_valid || tx_rf_claim) $fatal(1,"asynchronous kill gating");
        settle(); if(busy || errors!=1) $fatal(1,"kill completion"); kill=0;
        commit(); wait(tx_valid); @(negedge clk); tx_sink_ready=0;
        settle(); if(busy || tx_rf_claim || errors!=2) $fatal(1,"sink failure gating");
        tx_sink_ready=1;
        memory[3]=19; commit(); wait(frame_error); settle();
        if(busy || tx_rf_claim || errors!=3) $fatal(1,"malformed format accepted");
        memory[3]=20; memory[2]=8'hff; commit(); wait(frame_error); settle();
        if(busy || errors!=4) $fatal(1,"reserved pattern bits accepted");
        frame_length_bytes=12; commit(); settle();
        if(busy || errors!=5) $fatal(1,"empty phases accepted");
        $display("HOST_WAVEFORM_RTL_PASS psdu=%0d samples=%0d read_latency=%0d repeat=true kill=true sink=true malformed=true",length,limit,MEMORY_READ_LATENCY);
        $finish;
    end
    initial begin #100000000; $fatal(1,"waveform timeout"); end
endmodule

module tb_gf_serial_increment12;
    reg clk=0; always #1 clk=~clk;
    reg resetn=0; reg [11:0] value=0;
    wire [11:0] source,result; wire valid;
    gf_serial_increment12 dut(.*);
    integer n;
    initial begin
        repeat(3) @(negedge clk); resetn=1;
        for(n=0;n<4096;n=n+1) begin
            value=n;
            repeat(25) @(negedge clk);
            if(!valid || source!==value || result!==12'(n+1)) $fatal(1,"serial increment mismatch %0d",n);
        end
        $display("SERIAL_INCREMENT12_PASS inputs=4096 continuous=true"); $finish;
    end
endmodule
