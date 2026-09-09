`timescale 1ns/1ps
module tb_gf_control_crc;
    reg clk=0,clear=1,valid=0,data=0;
    always #5 clk=~clk;
    wire [31:0] fcs;
    reg [31:0] reference_crc=32'hffffffff,rng=32'h4320cfe1;
    integer n,k,checks=0;
    gf_control_crc_bitserial dut(.clk(clk),.clear(clear),.bit_valid(valid),.data_bit(data),.fcs(fcs));
    initial begin
        repeat(3)@(negedge clk);clear=0;
        for(n=0;n<2048;n=n+1)begin
            rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);
            valid=1;data=rng[0];
            reference_crc=(reference_crc>>1)^((reference_crc[0]^data)?32'hedb88320:0);
            @(negedge clk);valid=0;
            repeat(5)@(negedge clk);
            if(fcs!==~reference_crc)$fatal(1,"serial CRC mismatch bit=%0d",n);
            checks=checks+1;
            repeat(n%4)@(negedge clk);
            if(n%37==0)begin
                // Cancel a sampled bit at each of the five in-flight ages.
                valid=1;data=1;@(negedge clk);valid=0;
                repeat(n%5)@(negedge clk);
                clear=1;@(negedge clk);clear=0;
                reference_crc=32'hffffffff;
                repeat(6)@(negedge clk);
                if(fcs!==0)$fatal(1,"CRC stale bit escaped clear");
                checks=checks+1;
            end
        end
        $display("CONTROL_CRC_SERIAL_PASS checks=%0d full_crc32=true minimum_interval=6 clear_flush=true physical_rf=false",checks);
        $finish;
    end
endmodule
