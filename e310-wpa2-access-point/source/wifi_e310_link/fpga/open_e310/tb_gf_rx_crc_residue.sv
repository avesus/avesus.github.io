`timescale 1ns/1ps
module tb_gf_rx_crc_residue;
    reg clk=0,clear=1,valid=0,data=0;
    always #5 clk=~clk;
    wire [31:0] fcs;
    wire good;
    reg [31:0] reference_crc,rng=32'h01234567,transmit_fcs;
    integer frame,n,k,checks=0;
    gf_control_crc_bitserial crc(.clk(clk),.clear(clear),.bit_valid(valid),.data_bit(data),.fcs(fcs));
    gf_rx_crc_residue residue(.clk(clk),.clear(clear),.fcs(fcs),.good(good));
    task send_bit(input bit value);
        begin
            valid=1;data=value;
            reference_crc=(reference_crc>>1)^((reference_crc[0]^value)?32'hedb88320:0);
            @(negedge clk);valid=0;
            repeat(39)@(negedge clk);
            if(fcs!==~reference_crc || good!==(reference_crc==32'hdebb20e3))
                $fatal(1,"RX CRC/residue mismatch frame=%0d bit=%0d",frame,n);
            checks=checks+1;
        end
    endtask
    initial begin
        repeat(3)@(negedge clk);
        for(frame=0;frame<66;frame=frame+1)begin
            clear=1;valid=0;@(negedge clk);clear=0;reference_crc=32'hffffffff;
            // Include long-frame state and all 32 independently flipped FCS bits.
            for(n=0;n<(frame==65?32728:8*(1+frame*7));n=n+1)begin
                rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);
                send_bit(rng[0]);
            end
            transmit_fcs=~reference_crc;
            if(frame<32)transmit_fcs=transmit_fcs^(32'h1<<frame);
            for(n=0;n<32;n=n+1)send_bit(transmit_fcs[n]);
            if(good!==(frame>=32))$fatal(1,"final residue acceptance mismatch");
            // Cancel at each in-flight stage; a later packet must start fresh.
            valid=1;data=1;@(negedge clk);valid=0;
            repeat(frame%10)@(negedge clk);
            clear=1;@(negedge clk);clear=0;
            repeat(12)@(negedge clk);
            if(fcs!==0 || good!==0)$fatal(1,"stale CRC/residue escaped clear");
        end
        $display("RX_CRC_RESIDUE_PASS checks=%0d frames=66 corrupt_fcs_bits=32 maximum_psdu=4095 clear_flush=true physical_rf=false",checks);
        $finish;
    end
endmodule
