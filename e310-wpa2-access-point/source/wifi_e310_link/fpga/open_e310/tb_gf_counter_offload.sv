`timescale 1ns/1ps
module tb_gf_counter_offload;
    reg source_clk=0, destination_clk=0, reset=1;
    always #12.5 source_clk=~source_clk;
    always #5 destination_clk=~destination_clk;
    reg [31:0] count=0;
    wire [31:0] binary, gray;
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(0)) legacy
        (source_clk,reset,count,destination_clk,reset,binary);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(1)) offloaded
        (source_clk,reset,count,destination_clk,reset,gray);
    function automatic [31:0] decode(input [31:0] g);
        integer bit_index;
        begin
            decode[31]=g[31];
            for(bit_index=30;bit_index>=0;bit_index=bit_index-1)
                decode[bit_index]=decode[bit_index+1]^g[bit_index];
        end
    endfunction
    task automatic settle_check(input [31:0] n);
        begin
            @(negedge source_clk); count=n;
            repeat(15) @(posedge destination_clk);
            #1;
            if(binary!==n || decode(gray)!==n || gray!==(n^(n>>1)))
                $fatal(1,"settled CDC mismatch n=%h binary=%h gray=%h",n,binary,gray);
        end
    endtask
    integer n;
    reg [31:0] last;
    initial begin
        repeat(5) @(negedge destination_clk); reset=0;
        last=0;
        // Real monotonic source transitions, no multibit binary sampling.
        for(n=1;n<4096;n=n+1) begin
            @(negedge source_clk); count=n;
            @(negedge destination_clk);
            if(decode(gray)<last || decode(gray)>count) $fatal(1,"nonmonotonic coherent counter");
            last=decode(gray);
        end
        for(n=0;n<32;n=n+1) begin
            settle_check((32'd1<<n)-1);
            settle_check(32'd1<<n);
            settle_check((32'd1<<n)+1);
        end
        settle_check(32'hffffffff); settle_check(0);
        @(negedge destination_clk); reset=1;
        repeat(5) @(negedge source_clk);
        if(binary!==0 || gray!==0) $fatal(1,"reset mismatch");
        $display("COUNTER_CDC_TEST_PASS binary_gray=true boundaries=32 monotonic=4095 reset=true");
        $finish;
    end
endmodule
