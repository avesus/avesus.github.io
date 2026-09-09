`timescale 1ns/1ps
module tb_gf_serial_mul18 #(parameter integer WORDS=1024);
    reg clk=0,reset=1,a_bit=0,b_bit=0;
    always #5 clk=~clk;
    wire actual_bit,actual_end,reference_bit,reference_end;
    wire padded_bit,padded_end;
    gf_serial_mul18_to40 candidate(.clk(clk),.reset(reset),.a_bit(a_bit),.b_bit(b_bit),
        .product_bit(actual_bit),.product_word_end(actual_end));
    gf_serial_mul40 reference(.clk(clk),.reset(reset),.a_bit(a_bit),.b_bit(b_bit),
        .product_bit(reference_bit),.product_word_end(reference_end));
    gf_serial_mul18_to40 #(.PRUNE_ZERO_ROWS(0)) padded(.clk(clk),.reset(reset),.a_bit(a_bit),.b_bit(b_bit),
        .product_bit(padded_bit),.product_word_end(padded_end));
    reg signed [39:0] expected[0:WORDS-1];
    reg signed [17:0] a18,b18;
    reg signed [39:0] a,b,actual;
    reg [31:0] rng=32'h91e18267;
    integer cycle,word_index,bit_index,checks=0;
    initial begin
        repeat(3)@(negedge clk); reset=0; actual=0;
        for(cycle=0;cycle<WORDS*40+13;cycle=cycle+1)begin
            if(cycle<WORDS*40)begin
                word_index=cycle/40;
                if(cycle%40==0)begin
                    rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);
                    a18=word_index-16-131072; b18=rng[17:0];
                    a=a18; b=b18;
                    // Consecutive extreme sign changes and all sign bit patterns.
                    if(word_index<16)begin
                        case(word_index%4)
                            0: begin a=-131072;b=-131072;end
                            1: begin a=131071;b=131071;end
                            2: begin a=-1;b=1;end
                            3: begin a=0;b=-1;end
                        endcase
                    end
                    // Also cover B outside signed-18: the identity is exact
                    // for arbitrary B modulo 2^40, not merely the lab operands.
                    if(word_index>=262160) b={rng[7:0],rng};
                    expected[word_index]=a*b;
                end
                a_bit=a[cycle%40];b_bit=b[cycle%40];
            end else begin a_bit=0;b_bit=0;end
            @(posedge clk);#1;
            if(cycle>=13)begin
                word_index=(cycle-13)/40;bit_index=(cycle-13)%40;
                if(actual_bit!==reference_bit || actual_end!==reference_end ||
                   actual_bit!==padded_bit || actual_end!==padded_end)
                    $fatal(1,"SIGNED_ROW_BIT_MISMATCH cycle=%0d word=%0d bit=%0d got=%b reference=%b",cycle,word_index,bit_index,actual_bit,reference_bit);
                if(actual_end!==(bit_index==39))$fatal(1,"word marker moved");
                actual[bit_index]=actual_bit;
                if(bit_index==39)begin
                    if(actual!==expected[word_index])$fatal(1,"SIGNED_ROW_PRODUCT_MISMATCH word=%0d actual=%h expected=%h",word_index,actual,expected[word_index]);
                    checks=checks+1;
                end
            end
            @(negedge clk);
        end
        if(checks!=WORDS)$fatal(1,"missing products");
        $display("SIGNED_ROW_MULTIPLIER_PASS words=%0d full_result_bits=40 latency=13 input_ii=40 physical_rf=false",checks);
        $finish;
    end
endmodule
