// Original audio SDM -> CIC2 /16384 -> signed 24-bit mono PCM, 21MHz nominal.
module fm_uart_stream #(parameter integer BYTE_GAP=50, parameter integer BAUD_DIV=221)(input wire clk, input wire sdm,
 input wire [23:0] bias_telemetry, output reg bias_arm=0, output reg [2:0] bias_target=4, input wire [15:0] discriminator, input wire [15:0] raw_rf, input wire rx, output wire tx);
 // No unsolicited traffic. S renews a 250ms stream lease; P stops after this packet.
 reg rx_meta=1,rx_sync=1,rx_busy=0;
 reg [7:0] rx_div=0;
 reg [3:0] rx_bit=0;
 reg [7:0] rx_byte=0;
 reg [9:0] stream_lease=0;
 reg [2:0] pc0=0,pc1=0,pc2=0,pc3=0;
 reg [3:0] pc4=0,pc5=0;
 reg [4:0] pc6=0;
 reg raw_previous=0;
 wire [15:0] raw_changes={raw_previous ^ raw_rf[15],raw_rf[15:1] ^ raw_rf[14:0]};
 reg [2:0] tc0=0,tc1=0,tc2=0,tc3=0;
 reg [3:0] tc4=0,tc5=0;
 reg [4:0] tc6=0;
 function [2:0] pop4(input [3:0] x);
 begin pop4={2'b0,x[0]}+{2'b0,x[1]}+{2'b0,x[2]}+{2'b0,x[3]};end
 endfunction
 always @(posedge clk) begin
 rx_meta<=rx;rx_sync<=rx_meta;
 pc0<=pop4(raw_rf[3:0]);pc1<=pop4(raw_rf[7:4]);pc2<=pop4(raw_rf[11:8]);pc3<=pop4(raw_rf[15:12]);
 pc4<=pc0+pc1;pc5<=pc2+pc3;pc6<=explicit_result_0;
 raw_previous<=raw_rf[0];
 tc0<=pop4(raw_changes[3:0]);tc1<=pop4(raw_changes[7:4]);tc2<=pop4(raw_changes[11:8]);tc3<=pop4(raw_changes[15:12]);
 tc4<=tc0+tc1;tc5<=tc2+tc3;tc6<=explicit_result_1;
 end
 // Full precision modulo arithmetic: 24 input bits + 26 bits CIC growth.
 // P4: 24-bit PCM; replace SDM count with raw adjacent-bit transition count /4.
 // 2563.4766 samples/s: voice-band diagnostic at unchanged 115200 baud.
 reg signed [51:0] integ1=0,integ2=0,delay1=0,delay2=0,comb1=0,comb2=0;
 reg [13:0] phase=0;
 reg valid1=0,valid2=0;
 reg [18:0] rf_sum=0;
 reg [15:0] rf_latch=0,sdm_latch=0;
 reg [18:0] transition_sum=0;
 wire [18:0] transition_total=explicit_result_2;
 wire [18:0] rf_total=explicit_result_3;
 reg [31:0] clocks=0,seq=0,pending_seq=0,pending_clock=0;
 reg [3:0] sample_index=0;
 reg [23:0] pcm_mem[0:15];

 reg [383:0] pending_pcm=0;
 reg [15:0] pending_rf=0;
 reg [15:0] pending_sdm=0;
 wire [15:0] checksum;reg checksum_clear=0,checksum_start=0;reg [7:0] checksum_byte=0;
 gf_serial_checksum16 serial_checksum(clk,checksum_clear,checksum_start,checksum_byte,checksum);
 reg [7:0] byte_value;
 reg [6:0] byte_index=0;
 reg sending=0;
 reg [9:0] uart_shift=10'h3ff;
 reg [3:0] uart_bits=0;
 reg [7:0] baud_counter=0;
 reg [9:0] tx_gap=0;
 integer j;
 assign tx=uart_shift[0];
 always @* begin
 byte_value=0;
 case(byte_index)
 0:byte_value=8'ha5;1:byte_value=8'h5a;2:byte_value=8'h50;3:byte_value=8'h34;
 4:byte_value=pending_seq[7:0];5:byte_value=pending_seq[15:8];6:byte_value=pending_seq[23:16];7:byte_value=pending_seq[31:24];
 8:byte_value=pending_clock[7:0];9:byte_value=pending_clock[15:8];10:byte_value=pending_clock[23:16];11:byte_value=pending_clock[31:24];
 60:byte_value=pending_rf[7:0];61:byte_value=pending_rf[15:8];
 62:byte_value=pending_sdm[7:0];63:byte_value=pending_sdm[15:8];64:byte_value=checksum[7:0];65:byte_value=checksum[15:8];
 default:begin
 if(byte_index>=12 && byte_index<60) byte_value=pending_pcm[7:0];

 end
 endcase
 end
 always @(posedge clk) begin
 checksum_clear<=0;checksum_start<=0;clocks<=explicit_result_4;phase<=explicit_result_6;
 // Numeric SDR mode: these zero-initialized audio registers remain zero.
 valid1<=&phase;valid2<=valid1;
 rf_sum<=explicit_result_3;transition_sum<=explicit_result_2;
 if(&phase) begin
 comb1<=0;delay1<=integ2;rf_latch<=rf_total[18:3];rf_sum<=0;sdm_latch<=transition_total[18:3];transition_sum<=0;
 end
 if(valid1) begin comb2<=0;delay2<=comb1;end
 if(valid2) begin
 pcm_mem[sample_index]<=comb2[51:28];sample_index<=sample_index+1'b1;
 if(&sample_index) begin
 seq<=explicit_result_5;
 if(stream_lease!=0) stream_lease<=explicit_result_7;
 if(!sending && uart_bits==0 && stream_lease!=0) begin
 for(j=0;j<15;j=j+1) begin
 pending_pcm[24*j+:24]<=(j==0)?bias_telemetry:24'd0;
 end
 pending_pcm[360+:24]<=comb2[51:28];pending_rf<=rf_latch;
 pending_seq<=seq;pending_clock<=clocks;pending_sdm<=sdm_latch;
 byte_index<=0;checksum_clear<=1;sending<=1;
 end
 end
 end
 if(uart_bits!=0) begin
 if(baud_counter==BAUD_DIV-1) begin
 baud_counter<=0;uart_shift<={1'b1,uart_shift[9:1]};uart_bits<=uart_bits-1'b1;
 if(uart_bits==1) tx_gap<=BYTE_GAP;
 end else baud_counter<=explicit_result_8;
 end else if(tx_gap!=0) tx_gap<=explicit_result_9;
 else if(sending) begin
 uart_shift<={1'b1,byte_value,1'b0};uart_bits<=10;baud_counter<=0;
 if(byte_index<64)begin checksum_start<=1;checksum_byte<=byte_value;end
 if(byte_index>=12 && byte_index<60) pending_pcm<={8'd0,pending_pcm[383:8]};

 if(byte_index==65) sending<=0;else byte_index<=explicit_result_10;
 end
 if(!rx_busy) begin
   if(!rx_sync) begin rx_busy<=1;rx_div<=BAUD_DIV/2-1;rx_bit<=0;end
 end else if(rx_div!=0) rx_div<=explicit_result_11;
 else begin
   rx_div<=BAUD_DIV-1;rx_bit<=rx_bit+1'b1;
   if(rx_bit==0 && rx_sync) rx_busy<=0;
   else if(rx_bit>=1 && rx_bit<=8) rx_byte[rx_bit-1'b1]<=rx_sync;
   else if(rx_bit==9) begin
     rx_busy<=0;
     if(rx_sync && rx_byte==8'h53) stream_lease<=40;
     if(rx_sync && rx_byte[7:3]==5'b00110) bias_target<=rx_byte[2:0]; // ASCII0..7
     if(rx_sync && rx_byte==8'h47) bias_arm<=1; // G: standalone control, no host renewal
     if(rx_sync && rx_byte==8'h48) bias_arm<=0; // H: stop sinking

     if(rx_sync && (rx_byte==8'h50 || rx_byte==8'h52 || rx_byte==8'h44)) stream_lease<=0;
   end
 end
 end
 wire [4:0] explicit_result_0;
 gf_resolve #(.W(5)) explicit_add_0({1'b0,pc4},{1'b0,pc5},1'b0,explicit_result_0,);
 wire [4:0] explicit_result_1;
 gf_resolve #(.W(5)) explicit_add_1({1'b0,tc4},{1'b0,tc5},1'b0,explicit_result_1,);
 wire [18:0] explicit_result_2;
 gf_resolve #(.W(19)) explicit_add_2(transition_sum,{14'd0,tc6},1'b0,explicit_result_2,);
 wire [18:0] explicit_result_3;
 gf_resolve #(.W(19)) explicit_add_3(rf_sum,{14'd0,pc6},1'b0,explicit_result_3,);
 wire [31:0] explicit_result_4;
 gf_resolve #(.W(32)) explicit_add_4(clocks,32'd1,1'b0,explicit_result_4,);
 wire [31:0] explicit_result_5;
 gf_resolve #(.W(32)) explicit_add_5(seq,32'd1,1'b0,explicit_result_5,);
 wire [13:0] explicit_result_6;
 gf_resolve #(.W(14)) explicit_add_6(phase,14'd1,1'b0,explicit_result_6,);
 wire [9:0] explicit_result_7;
 gf_resolve #(.W(10)) explicit_add_7(stream_lease,10'h3ff,1'b0,explicit_result_7,);
 wire [7:0] explicit_result_8;
 gf_resolve #(.W(8)) explicit_add_8(baud_counter,8'd1,1'b0,explicit_result_8,);
 wire [9:0] explicit_result_9;
 gf_resolve #(.W(10)) explicit_add_9(tx_gap,10'h3ff,1'b0,explicit_result_9,);
 wire [6:0] explicit_result_10;
 gf_resolve #(.W(7)) explicit_add_10(byte_index,7'd1,1'b0,explicit_result_10,);
 wire [7:0] explicit_result_11;
 gf_resolve #(.W(8)) explicit_add_11(rx_div,8'hff,1'b0,explicit_result_11,);
endmodule
