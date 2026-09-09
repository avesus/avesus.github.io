// Full parallel IQ16 -> serial Barker graph -> full signed 32-bit correlation.
// SYNCHRONOUS fast-clock boundary, not an asynchronous ADC crossing or PLL.
// At 320 MHz, provide one sample in every sample_slot (16 clocks apart),
// beginning on the first edge after reset. Any missing/extra sample latches
// fault until reset and suppresses result_valid. Never compress a sample gap.
`timescale 1ns/1ps

// Seeded registered duplication of a periodic control. PHASE_MASK describes
// the required LEAF value before each edge of the common 32-clock schedule.
// bit_in must be advanced D+1 clocks. Initial values also populate this
// look-ahead pipeline, so the very first input word is not silently lost.
module gf_serial_periodic_fanout #(
    parameter integer N=32,D=$clog2(N),parameter [31:0] PHASE_MASK=0
)(input wire clk,reset,bit_in,output wire [N-1:0] leaves);
    wire [N-1:0] stage[0:D];
    gf_serial_reg #(.INIT(PHASE_MASK[D])) root(clk,reset,bit_in,stage[0][0]);
    generate for(genvar l=1;l<=D;l=l+1)begin:g_level
        for(genvar n=0;n<(1<<l);n=n+1)begin:g_node
            gf_serial_reg #(.INIT(PHASE_MASK[D-l])) r(clk,reset,stage[l-1][n/2],stage[l][n]);
        end
    end endgenerate
    assign leaves=stage[D];
endmodule

module gf_serial_piso16(
    input wire clk,reset,input wire [15:0] load,parallel_word,output wire serial_bit
);
    wire [15:0] bits;
    generate for(genvar n=0;n<16;n=n+1)begin:g_bit
        wire next_bit;
        // After sixteen shifts, repeat the sign bit for the rest of the
        // 32-bit word. The sign register drives exactly two local muxes.
        gf_serial_lut #(.INIT(16'hcaca)) mux(
            .a(bits[n==15?15:n+1]),.b(parallel_word[n]),.c(load[n]),.d(1'b0),.q(next_bit));
        gf_serial_reg r(clk,reset,next_bit,bits[n]);
    end endgenerate
    assign serial_bit=bits[0];
endmodule

module gf_serial_delay16(input wire clk,d,output wire q);
    (* shreg_extract="yes",srl_style="srl" *) reg [15:0] storage=0;
    always @(posedge clk)storage<={storage[14:0],d};
    assign q=storage[15];
endmodule

module gf_barker_serial_iq(
    input wire clk,reset,sample_valid,
    input wire signed [15:0] sample_i,sample_q,
    output wire sample_slot,fault,result_valid,
    output wire signed [31:0] correlation_i,correlation_q
);
    wire [31:0] phase,tap;
    generate for(genvar p=0;p<32;p=p+1)begin:g_phase
        gf_serial_reg #(.INIT(p==0)) ring(clk,reset,phase[(p+31)%32],phase[p]);
        gf_serial_reg #(.INIT(p==31)) copy(clk,reset,phase[p],tap[p]);
    end endgenerate
    assign sample_slot=tap[31]|tap[15];
    wire internal_fault;
    wire bad_sample=(sample_valid^sample_slot)|internal_fault;
    // Identical registered leaves, not a delayed fault report: the internal
    // latch drives feedback+valid veto, the other drives the public status.
    gf_serial_reg bad_cadence(clk,reset,bad_sample,internal_fault);
    gf_serial_reg fault_report(clk,reset,bad_sample,fault);

    wire [31:0] load[0:1];
    gf_serial_periodic_fanout #(.PHASE_MASK(32'h00000001)) even_load(clk,reset,tap[25],load[0]);
    gf_serial_periodic_fanout #(.PHASE_MASK(32'h00010000)) odd_load(clk,reset,tap[9],load[1]);
    wire [1:0] current[0:1],previous_source[0:1],previous[0:1];
    wire [31:0] words[0:1][0:1];
    generate for(genvar parity=0;parity<2;parity=parity+1)begin:g_parity
        for(genvar iq=0;iq<2;iq=iq+1)begin:g_iq
            wire serial_input,correlation_bit,unused_end;
            wire [15:0] parallel_input=iq==0?sample_i:sample_q;
            gf_serial_piso16 serializer(clk,reset,load[parity][16*iq+:16],
                parallel_input,serial_input);
            // Separate registered copies: current drives history+tap, while
            // the other copy feeds a half-word delay for the opposite parity.
            gf_serial_reg cur(clk,reset,serial_input,current[parity][iq]);
            gf_serial_reg old(clk,reset,serial_input,previous_source[parity][iq]);
            gf_serial_delay16 half_word(clk,previous_source[1-parity][iq],previous[parity][iq]);
            gf_barker_serial_lane #(.INITIAL_PHASE(parity==0?30:14)) core(
                clk,reset,current[parity][iq],previous[parity][iq],correlation_bit,unused_end);
            for(genvar b=0;b<32;b=b+1)begin:g_sipo
                wire next_bit;
                if(b==31)assign next_bit=correlation_bit;
                else assign next_bit=words[parity][iq][b+1];
                gf_serial_reg r(clk,reset,next_bit,words[parity][iq][b]);
            end
        end
    end endgenerate

    // Full words are stable at capture edges 40+16*n. Both the data-select
    // and output-write dependencies use registered binary duplication trees.
    wire [31:0] write_word,select_odd;
    gf_serial_periodic_fanout #(.PHASE_MASK(32'h01000100)) capture(
        clk,reset,tap[1]|tap[17],write_word);
    gf_serial_periodic_fanout #(.PHASE_MASK(32'h01000000)) select_parity(
        clk,reset,tap[17],select_odd);
    wire [31:0] output_words[0:1];
    generate for(genvar b=0;b<32;b=b+1)begin:g_output
        for(genvar iq=0;iq<2;iq=iq+1)begin:g_iq
            wire chosen,next_bit;
            gf_serial_lut #(.INIT(16'hcaca)) mux_parity(
                words[0][iq][b],words[1][iq][b],select_odd[b],1'b0,chosen);
            gf_serial_lut #(.INIT(16'hcaca)) mux_write(
                output_words[iq][b],chosen,write_word[b],1'b0,next_bit);
            gf_serial_reg r(clk,reset,next_bit,output_words[iq][b]);
        end
    end endgenerate
    assign correlation_i=output_words[0];assign correlation_q=output_words[1];

    // Ignore pipeline fragments and twenty-sample history warmup. No reset
    // of the SRLs is assumed; these validity histories ARE reset explicitly.
    wire [1:0] ready;
    generate for(genvar parity=0;parity<2;parity=parity+1)begin:g_warmup
        localparam integer W=parity==0?11:10;
        wire [7:0] advance;
        wire [W-1:0] valid_history;
        gf_serial_periodic_fanout #(.N(8),.D(3),.PHASE_MASK(parity==0?32'h100:32'h1000000)) marker(
            clk,reset,tap[parity==0?3:19],advance);
        for(genvar n=0;n<W;n=n+1)begin:g_valid
            wire next_valid,prior;
            if(n==0)assign prior=1'b1;
            else assign prior=valid_history[n-1];
            gf_serial_lut #(.INIT(16'hcaca)) mux(valid_history[n],prior,
                advance[n/2],1'b0,next_valid);
            gf_serial_reg r(clk,reset,next_valid,valid_history[n]);
        end
        assign ready[parity]=valid_history[W-1];
    end endgenerate
    wire qualified;
    gf_serial_reg valid_word(clk,reset,(tap[7]&ready[0])|(tap[23]&ready[1]),qualified);
    assign result_valid=qualified&~internal_fault;
endmodule
