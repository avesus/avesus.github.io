`timescale 1ns/1ps
module tb_gf_e310_async_fifo #(
    parameter integer USE_BLOCK_RAM=0, ADDRESS_WIDTH=4,
    parameter integer WRITE_HALF=13, READ_HALF=5
);
    localparam integer DEPTH=1<<ADDRESS_WIDTH;
    reg write_clk=0,read_clk=0,reset=1,write_enable=0,read_pop=0;
    always #(WRITE_HALF) write_clk=~write_clk;
    always #(READ_HALF) read_clk=~read_clk;
    reg [9:0] write_data=0;
    wire [9:0] read_data;
    wire write_ready,write_overflow,read_valid;
    gf_e310_async_fifo #(.WIDTH(10),.ADDRESS_WIDTH(ADDRESS_WIDTH),.USE_BLOCK_RAM(USE_BLOCK_RAM)) dut
       (write_clk,reset,write_data,write_enable,write_ready,write_overflow,
        read_clk,reset,read_data,read_valid,read_pop);
    reg [9:0] expected [0:100000];
    integer written=0,consumed=0,overflows=0,held_cycles=0;
    reg held=0;
    reg [9:0] held_word=0;
    always @(posedge write_clk) begin
        if(!reset) begin
            if(write_enable && write_ready) begin
                expected[written]=write_data; written=written+1;
            end
            if(write_overflow) overflows=overflows+1;
        end
    end
    always @(posedge read_clk) begin
        if(reset) held=0;
        else begin
            if(held && (!read_valid || read_data!==held_word)) $fatal(1,"stalled output changed");
            if(read_valid && read_pop) begin
                if(consumed>=written || read_data!==expected[consumed])
                    $fatal(1,"FIFO ordering bram=%0d index=%0d got=%h expected=%h",USE_BLOCK_RAM,consumed,read_data,expected[consumed]);
                consumed=consumed+1;
            end
            held=read_valid&&!read_pop; held_word=read_data;
            if(held) held_cycles=held_cycles+1;
        end
    end
    integer n,w,r,discarded;
    reg [31:0] wr_random=32'h9abc7654,rd_random=32'h1234defa;
    task automatic drain;
        begin
            @(negedge read_clk);read_pop=1;
            repeat(DEPTH+30) @(negedge read_clk);
            read_pop=0;
            if(consumed!=written || read_valid) $fatal(1,"drain/empty mismatch");
        end
    endtask
    initial begin
        repeat(5) @(negedge write_clk); reset=0;
        for(n=0;n<DEPTH+4;n=n+1) begin
            @(negedge write_clk); write_enable=1;write_data=n;
        end
        @(negedge write_clk);write_enable=0;
        if(written!=DEPTH || overflows!=4 || write_ready) $fatal(1,"capacity/overflow mismatch");
        // The full stalled output must remain valid and identical.
        repeat(15) @(negedge read_clk);
        drain();
        fork
            begin
                for(w=0;w<20000;w=w+1) begin
                    @(negedge write_clk);
                    wr_random=wr_random^(wr_random<<13);wr_random=wr_random^(wr_random>>17);wr_random=wr_random^(wr_random<<5);
                    write_enable=wr_random[0]|wr_random[1];write_data=wr_random[11:2];
                end
                @(negedge write_clk);write_enable=0;
            end
            begin
                for(r=0;r<60000;r=r+1) begin
                    @(negedge read_clk);
                    rd_random=rd_random^(rd_random<<13);rd_random=rd_random^(rd_random>>17);rd_random=rd_random^(rd_random<<5);
                    read_pop=rd_random[0]|rd_random[1];
                end
                @(negedge read_clk);read_pop=0;
            end
        join
        drain();
        // Reset while data is present must not expose an old word afterward.
        repeat(10) @(negedge write_clk);
        for(n=0;n<3;n=n+1) begin
            @(negedge write_clk);write_enable=1;write_data=10'h155+n;
        end
        @(negedge write_clk);write_enable=0;
        repeat(10) @(negedge read_clk);
        discarded=written-consumed;reset=1;
        repeat(5) @(negedge write_clk);
        consumed=written;reset=0;
        repeat(10) @(negedge read_clk);
        if(read_valid) $fatal(1,"reset leaked stale data");
        @(negedge write_clk);write_enable=1;write_data=10'h2ab;
        @(negedge write_clk);write_enable=0;
        drain();
        if(held_cycles<10 || discarded!=3) $fatal(1,"test coverage incomplete");
        $display("FIFO_TEST_PASS bram=%0d depth=%0d writes=%0d checked=%0d overflows=%0d stalled=%0d reset_discarded=%0d",USE_BLOCK_RAM,DEPTH,written,consumed-discarded,overflows,held_cycles,discarded);
        $finish;
    end
    initial begin #10000000; $fatal(1,"timeout"); end
endmodule
