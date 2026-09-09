// Streaming serial carry is the constant +1 specialization of Brian
// Greenforest's LSB-first serial full adder: sum=x^carry, carry=x&carry.
// Continuous 12-clock words; no start/busy/drain bubble or parallel '+' cell.
// This is control arithmetic, not a claim that the receiver DSP is converted.
`timescale 1ns/1ps
module gf_serial_increment12 (
    input wire clk, input wire resetn, input wire [11:0] value,
    output reg [11:0] source, output reg [11:0] result,
    output reg valid
);
    reg [11:0] phase=12'b1, x=0, partial=0, snapshot=0;
    reg carry=0;
    wire bit_x = phase[0] ? value[0] : x[0];
    wire bit_c = phase[0] ? 1'b1 : carry;
    wire bit_sum = bit_x ^ bit_c;
    always @(posedge clk) begin
        if (!resetn) begin
            phase<=12'b1; x<=0; partial<=0; snapshot<=0;
            carry<=0; source<=0; result<=0; valid<=0;
        end else begin
            phase<={phase[10:0],phase[11]};
            x<=phase[0] ? {1'b0,value[11:1]} : {1'b0,x[11:1]};
            if (phase[0]) snapshot<=value;
            carry<=bit_x & bit_c;
            partial<={bit_sum,partial[11:1]};
            if (phase[11]) begin
                source<=snapshot; result<={bit_sum,partial[11:1]}; valid<=1;
            end
        end
    end
endmodule

// Generic two-IQ-level pattern player. No knowledge of Wi-Fi framing, CRC,
// scrambler, differential encoding or Barker sequence exists in this module.
// Format: 20-bit polarity pattern LE, byte 3=20, two packed IQ16 words LE,
// followed by LSB-first phase selections. Every phase uses 20 sample ticks.
module gf_host_waveform_tx #(
    parameter integer MEMORY_READ_LATENCY = 0
) (
    input wire clk, input wire resetn, input wire arm, input wire kill,
    input wire frame_commit, input wire [11:0] frame_length_bytes,
    output reg [11:0] frame_read_address, input wire [7:0] frame_read_data,
    input wire tx_channel_available, input wire tx_sample_tick,
    input wire tx_sink_ready,
    output wire ready, output wire busy, output wire tx_rf_claim,
    output wire tx_valid, output wire [31:0] tx_iq,
    output reg frame_done, output reg frame_error
);
    localparam [2:0] IDLE=0, HEADER=1, PRELOAD=2, LEAD=3, ACTIVE=4, READ_WAIT=5;
    initial if(MEMORY_READ_LATENCY<0 || MEMORY_READ_LATENCY>1)
        $error("Supported memory read latency is zero or one clock");
    reg [2:0] state=IDLE;
    reg [11:0] length_bytes=0;
    reg [19:0] pattern=0, sample_phase=20'b1;
    reg [7:0] phase_byte=0, bit_phase=8'b1;
    reg [31:0] level_a=0, level_b=0;
    // A local one-hot delay replaces an inferred parallel decrementer.
    reg [79:0] lead=80'b1;
    wire [11:0] increment_source, increment_result;
    wire increment_valid;
    gf_serial_increment12 next_address (
        .clk(clk), .resetn(resetn), .value(frame_read_address),
        .source(increment_source), .result(increment_result), .valid(increment_valid)
    );
    wire increment_matches = increment_valid && increment_source==frame_read_address;
    assign ready = state==IDLE && resetn && arm && !kill;
    assign busy = state!=IDLE;
    assign tx_rf_claim = resetn && arm && !kill &&
        (state==ACTIVE || (state==LEAD && tx_channel_available));
    assign tx_valid = state==ACTIVE && resetn && arm && !kill;
    assign tx_iq = (pattern[0] ^ phase_byte[0]) ? level_b : level_a;
    always @(posedge clk) begin
        if (!resetn) begin
            state<=IDLE; frame_read_address<=0; length_bytes<=0;
            pattern<=0; sample_phase<=20'b1; phase_byte<=0; bit_phase<=8'b1;
            level_a<=0; level_b<=0; lead<=80'b1;
            frame_done<=0; frame_error<=0;
        end else begin
            frame_done<=0; frame_error<=0;
            if(kill || !arm) begin
                if(state!=IDLE) frame_error<=1;
                state<=IDLE;
            end else case(state)
                IDLE: if(frame_commit) begin
                    if(frame_length_bytes<=12) frame_error<=1;
                    else begin
                        length_bytes<=frame_length_bytes; frame_read_address<=0;
                        state<=HEADER;
                    end
                end
                HEADER: if(increment_matches) begin
                    case(frame_read_address)
                        0: pattern[7:0]<=frame_read_data;
                        1: pattern[15:8]<=frame_read_data;
                        2: pattern[19:16]<=frame_read_data[3:0];
                        4: level_a[7:0]<=frame_read_data;
                        5: level_a[15:8]<=frame_read_data;
                        6: level_a[23:16]<=frame_read_data;
                        7: level_a[31:24]<=frame_read_data;
                        8: level_b[7:0]<=frame_read_data;
                        9: level_b[15:8]<=frame_read_data;
                        10: level_b[23:16]<=frame_read_data;
                        11: level_b[31:24]<=frame_read_data;
                        default: begin end
                    endcase
                    if((frame_read_address==2 && frame_read_data[7:4]!=0) ||
                       (frame_read_address==3 && frame_read_data!=20)) begin
                        frame_error<=1; state<=IDLE;
                    end else begin
                        frame_read_address<=increment_result;
                        if(frame_read_address==11)
                            state<=MEMORY_READ_LATENCY ? READ_WAIT : PRELOAD;
                    end
                end
                READ_WAIT: state<=PRELOAD;
                PRELOAD: begin
                    phase_byte<=frame_read_data; frame_read_address<=13;
                    sample_phase<=20'b1; bit_phase<=8'b1; lead<=80'b1;
                    state<=LEAD;
                end
                LEAD: begin
                    if(!tx_channel_available) lead<=80'b1;
                    else if(!lead[79]) lead<={lead[78:0],1'b0};
                    else if(tx_sample_tick && tx_sink_ready) state<=ACTIVE;
                end
                ACTIVE: if(tx_sample_tick) begin
                    if(!tx_sink_ready) begin frame_error<=1; state<=IDLE; end
                    else begin
                        pattern<={pattern[0],pattern[19:1]};
                        sample_phase<={sample_phase[18:0],sample_phase[19]};
                        if(sample_phase[19]) begin
                            bit_phase<={bit_phase[6:0],bit_phase[7]};
                            if(bit_phase[7]) begin
                                if(frame_read_address==length_bytes) begin
                                    frame_done<=1; state<=IDLE;
                                end else if(!increment_matches) begin
                                    frame_error<=1; state<=IDLE;
                                end else begin
                                    phase_byte<=frame_read_data;
                                    frame_read_address<=increment_result;
                                end
                            end else phase_byte<={1'b0,phase_byte[7:1]};
                        end
                    end
                end
                default: begin frame_error<=1; state<=IDLE; end
            endcase
        end
    end
endmodule
