`timescale 1ns/1ps
module tb_gf_e310_rx_capture #(parameter integer COUNTERS_TO_SOFTWARE=0,
                              parameter integer PEAKS_TO_SOFTWARE=0);
    reg bus_clk=0, radio_clk=0;
    always #5 bus_clk=~bus_clk;
    always #12.5 radio_clk=~radio_clk;
    reg reset=1, wr=0, sample_valid=0, veto=0;
    reg [11:0] addr=0, rdaddr=0;
    reg [31:0] wdata=0, iq=0;
    wire [31:0] rdata;
    reg [31:0] sfd_input=7;
    gf_e310_rx_capture #(.ADDRESS_BITS(4),.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE),
                        .PEAKS_TO_SOFTWARE(PEAKS_TO_SOFTWARE)) dut (
        .bus_clk(bus_clk), .bus_reset(reset), .bus_write(wr),
        .bus_address(addr), .bus_read_address(rdaddr), .bus_write_data(wdata),
        .bus_read_data(rdata), .radio_clk(radio_clk), .radio_reset(reset),
        .sample_valid(sample_valid), .sample_iq(iq), .capture_veto(veto),
        .sfd_count(sfd_input), .plcp_ok_count(32'd3), .plcp_error_count(32'd4)
    );
    task write_reg(input [11:0] address, input [31:0] value);
        begin
            @(negedge bus_clk); addr=address; wdata=value; wr=1;
            @(negedge bus_clk); wr=0;
            repeat(4) @(negedge bus_clk);
        end
    endtask
    task sample(input [31:0] value);
        begin
            @(negedge radio_clk); iq=value; sample_valid=1;
            @(negedge radio_clk); sample_valid=0;
        end
    endtask
    integer n;
    reg [31:0] expected;
    initial begin
        repeat(6) @(negedge radio_clk); reset=0;
        write_reg(12'h254, 256);
        write_reg(12'h250, 32'h52584341);
        repeat(6) @(negedge radio_clk);
        sample(32'd128);
        if (!dut.armed || dut.capturing) $fatal(1,"threshold gate");
        veto=1; sample(32'd1000);
        if (dut.capturing) $fatal(1,"own TX veto");
        veto=0;
        sample(32'd1000);
        if (dut.capturing) $fatal(1,"post TX guard");
        repeat(810) @(negedge radio_clk);
        for(n=0;n<16;n=n+1) sample(((65536-100-n)<<16)|(300+n));
        repeat(20) @(negedge bus_clk);
        rdaddr=12'h250; #1;
        if(rdata!==32'h404) $fatal(1,"complete status %h",rdata);
        for(n=0;n<16;n=n+1) begin
            write_reg(12'h258,n); rdaddr=12'h25c; #1;
            expected=((65536-100-n)<<16)|(300+n);
            if(rdata!==expected) $fatal(1,"retained IQ index=%d got=%h expected=%h",n,rdata,expected);
        end
        sample(32'h12345678);
        write_reg(12'h258,15); rdaddr=12'h25c; #1;
        if(rdata!==32'hff8d013b) $fatal(1,"frozen record changed");
        rdaddr=12'h270; #1;
        if(rdata!==(PEAKS_TO_SOFTWARE ? 32'd0 : 32'h0073013b)) $fatal(1,"captured peaks %h",rdata);
        repeat(20) @(negedge bus_clk); // settle both legacy and raw-Gray CDC latency
        rdaddr=12'h260; #1;
        if(rdata!==(COUNTERS_TO_SOFTWARE ? 32'd4 : 32'd7)) $fatal(1,"SFD counter CDC");
        rdaddr=12'h264; #1;
        if(rdata!==(COUNTERS_TO_SOFTWARE ? 32'd2 : 32'd3)) $fatal(1,"PLCP good counter CDC");
        rdaddr=12'h268; #1;
        if(rdata!==(COUNTERS_TO_SOFTWARE ? 32'd6 : 32'd4)) $fatal(1,"PLCP bad counter CDC");
        rdaddr=12'h26c; #1;
        if(rdata!==(COUNTERS_TO_SOFTWARE ? 32'd30 : 32'd20)) $fatal(1,"sample counter CDC");
        write_reg(12'h254,0); write_reg(12'h250,32'h52584341);
        repeat(6) @(negedge radio_clk);
        rdaddr=12'h25c; #1;
        if(rdata!==0) $fatal(1,"incomplete record exposed");
        for(n=0;n<16;n=n+1) sample(n);
        repeat(6) @(negedge bus_clk);
        write_reg(12'h258,15); rdaddr=12'h25c; #1;
        if(rdata!==15) $fatal(1,"rearm record");
        write_reg(12'h278,1); write_reg(12'h250,32'h52584341);
        repeat(6) @(negedge radio_clk);
        for(n=0;n<20;n=n+1) sample(100+n);
        if(dut.capturing || dut.done) $fatal(1,"SFD mode triggered on amplitude");
        sfd_input=8;
        for(n=0;n<12;n=n+1) sample(200+n);
        repeat(10) @(negedge bus_clk);
        rdaddr=12'h250; #1;
        if(rdata!==(PEAKS_TO_SOFTWARE ? 32'h40c : 32'h404)) $fatal(1,"SFD completion %h",rdata);
        for(n=0;n<16;n=n+1) begin
            write_reg(12'h258,n); rdaddr=12'h25c; #1;
            expected=n<4 ? 116+n : 200+n-4;
            if(rdata!==expected) $fatal(1,"SFD pretrigger order index=%0d got=%h expected=%h",n,rdata,expected);
        end
        $display("E310_RX_CAPTURE_TB_PASS retained_order=true own_tx_veto=true frozen_until_rearm=true sfd_pretrigger=true software_peaks=%0d",PEAKS_TO_SOFTWARE);
        $finish;
    end
    initial begin #200000; $fatal(1,"timeout"); end
endmodule
