`timescale 1ns/1ps
module tb_gf_e310_pmu_regs;
    reg clk = 0, reset = 1;
    always #5 clk = ~clk;
    reg ss = 1, mosi = 0, sck = 0, write_enable = 0;
    reg [7:0] write_address = 0, read_address = 0;
    reg [31:0] write_data = 0;
    reg [3:0] write_strobe = 15;
    wire miso, irq, write_error;
    wire [31:0] read_data;
    reg [63:0] received;
    integer index;
    gf_e310_pmu_regs dut (
        .clk(clk), .reset(reset), .spi_ss(ss), .spi_mosi(mosi),
        .spi_sck(sck), .spi_miso(miso), .write_enable(write_enable),
        .write_address(write_address), .write_data(write_data),
        .write_strobe(write_strobe), .write_error(write_error),
        .read_address(read_address), .read_data(read_data), .irq(irq)
    );
    task transfer(input [63:0] value);
        integer bit_index;
        begin
            ss = 1; sck = 0; #100;
            ss = 0; #100; received = 0;
            for (bit_index = 63; bit_index >= 0; bit_index = bit_index - 1) begin
                mosi = value[bit_index]; #100;
                received = {received[62:0], miso}; sck = 1; #100;
                sck = 0; #100;
            end
            ss = 1; #100;
        end
    endtask
    task expect_read(input [7:0] address, input [31:0] expected);
        begin
            read_address = address; #10;
            if (read_data !== expected)
                $fatal(1, "PMU read %h got=%h expected=%h", address, read_data, expected);
        end
    endtask
    task write_register(input [7:0] address, input [31:0] value, input integer error_expected);
        begin
            @(negedge clk); write_address = address; write_data = value; write_enable = 1;
            #1;
            if (write_error !== error_expected[0]) $fatal(1, "PMU write error mismatch");
            @(negedge clk); write_enable = 0;
        end
    endtask
    initial begin
        #40; @(negedge clk); reset = 0;
        expect_read(4, 0);
        transfer(64'h1234_0008_0000_2200);
        if (received !== 0) $fatal(1, "PMU invented a startup command");
        expect_read(4, 32'h22);
        expect_read(8, 32'h00341200);
        expect_read(12, 4);
        transfer(64'h0112_3456_789a_bc01);
        expect_read(16, 32'h7856bc9a);
        expect_read(20, 32'h00013412);
        transfer(64'h0000_0000_03ef_ab02);
        expect_read(24, 32'h0000abef);
        expect_read(28, 3);
        write_register(4, 32'h100, 0); #10;
        if (!irq || dut.command_count != 0) $fatal(1, "PMU IRQ mask became SPI command");
        write_register(28, 3, 0);
        transfer(64'h0000_0000_03ef_ab02);
        if (received !== 0) $fatal(1, "PMU command pipeline changed");
        transfer(64'h0000_0000_03ef_ab02);
        if (received !== 64'h80000000_03001c01) $fatal(1, "PMU setting command format %h", received);
        transfer(0);
        if (received !== 0) $fatal(1, "PMU duplicated command");
        write_strobe = 1;
        write_register(0, 32'h7a, 1);
        write_strobe = 15;
        if (dut.command_count != 0 || dut.shutdown != 0) $fatal(1, "PMU rejected write had side effect");
        for (index = 0; index < 32; index = index + 1)
            write_register(28, index, 0);
        write_register(0, 32'h7a, 1);
        if (dut.command_count != 32 || dut.shutdown != 0) $fatal(1, "PMU queue overflow");
        @(negedge clk); reset = 1; repeat (4) @(negedge clk); reset = 0;
        transfer(0);
        if (received !== 0 || irq || dut.command_count != 0) $fatal(1, "PMU reset did not clear pending commands");
        $display("E310_PMU_SPI_SELFTEST_PASS status_from_serial=true command_format=true queue_full_rejected=true physical_test=false");
        $finish;
    end
    initial begin #1000000; $fatal(1, "PMU test timeout"); end
endmodule
