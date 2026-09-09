`timescale 1ns/1ps
module tb_gf_timing_score_ram;
    reg clk=0,clear=1,we=0;
    always #5 clk=~clk;
    reg [4:0] address=0;
    reg [28:0] data=0;
    wire [28:0] result;
    reg [28:0] reference [0:19];
    reg [31:0] rng=32'h132904ab;
    integer n,k,checks=0;
    gf_dsss_timing_score_ram dut(.clk(clk),.clear(clear),.write_enable(we),
        .address(address),.write_data(data),.read_data(result));
    task check_all;
        begin
            for(k=0;k<32;k=k+1) begin
                address=k; #0.01;
                if(result !== ((k<20) ? reference[k] : 29'd0))
                    $fatal(1,"score bank mismatch cycle=%0d address=%0d",n,k);
                checks=checks+1;
            end
        end
    endtask
    initial begin
        for(k=0;k<20;k=k+1)reference[k]=0;
        @(posedge clk);#1;check_all();
        for(n=0;n<5000;n=n+1) begin
            @(negedge clk);
            rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);
            address=rng[4:0];data=rng[28:0];
            clear=(n%37==0);we=(rng[31:30]!=0);
            @(posedge clk);
            if(clear)for(k=0;k<20;k=k+1)reference[k]=0;
            else if(we && address<20)reference[address]=data;
            #1;check_all();
        end
        $display("TIMING_SCORE_RAM_PASS checks=%0d clear_write_priority=true full_width=29 physical_rf=false",checks);
        $finish;
    end
endmodule
