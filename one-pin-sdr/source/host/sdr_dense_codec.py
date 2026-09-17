"""E3: lossless RF word prediction and canonical nibble Huffman coding.

The predictor is an exact XOR with the RF word seventeen words earlier.
It removes no spectrum: decoding restores every input word before its CRC.
Lengths were chosen from the retained 20260917 balanced-bias capture.
"""
import numpy as np

LENGTHS = (1,3,4,5,4,6,5,6,4,6,6,7,5,7,7,7)

def codebook():
    result = {}; code = 0; prior = 0
    for n in sorted(range(16), key=lambda i: (LENGTHS[i], i)):
        length = LENGTHS[n]
        code <<= length-prior
        result[n] = (int(f'{code:0{length}b}'[::-1], 2), length)
        code += 1; prior = length
    return result

CODES = codebook()
LOOKUP = [None]*128
for n,(code,length) in CODES.items():
    for suffix in range(1 << (7-length)):
        LOOKUP[code | (suffix << length)] = (n,length)
assert all(x is not None for x in LOOKUP)

def encode(words):
    pool=used=0;out=bytearray();history=[0]*17;index=0
    for original in words:
        original=int(original);difference=original^history[index]
        history[index]=original;index=(index+1)%17
        for shift in (0,4,8,12):
            code,length=CODES[(difference>>shift)&15]
            pool |= code << used;used += length
            while used>=8:
                out.append(pool&255);pool >>= 8;used -= 8
    if used:out.append(pool)
    return bytes(out)

def decode(payload,word_count):
    # Constant-time lookup per symbol; no statistical reconstruction or fits.
    data=memoryview(payload);pool=used=cursor=0;words=np.empty(word_count,dtype=np.uint16)
    history=[0]*17;index=0
    for i in range(word_count):
        difference=0
        for shift in (0,4,8,12):
            while used<7:
                if cursor<len(data):pool |= data[cursor]<<used;cursor+=1;used+=8
                else:
                    if used==0:raise ValueError('Truncated E3 bit stream')
                    break
            value,length=LOOKUP[pool&127]
            if length>used:raise ValueError('Truncated E3 code')
            difference |= value<<shift;pool >>= length;used -= length
        original=difference^history[index];words[i]=original
        history[index]=original;index=(index+1)%17
    if pool or any(data[cursor:]):raise ValueError('Nonzero E3 tail padding')
    return words

def rtl():
    cases='\n'.join(f"   4'd{n}:huff=10'b{length:03b}{code:07b};" for n,(code,length) in sorted(CODES.items()))
    return '''
// E3 restores every RF sample exactly; no filtering, decimation or audio stage.
module gf_rf_dense_encoder(input clk,clear,valid,input [15:0] raw_rf,
 output emit,output [31:0] encoded,output idle);
 integer h;
 reg [4:0] history_pointer=0,history_fill=0;
 wire [4:0] history_next,history_read,fill_next;
 gf_resolve #(.W(5)) hp(history_pointer,5'd1,1'b0,history_next,);
 gf_resolve #(.W(5)) hr(history_pointer,5'd15,1'b0,history_read,);
 gf_resolve #(.W(5)) hf(history_fill,5'd1,1'b0,fill_next,);
 wire [15:0] old_word;
 reg [15:0] delayed_raw=0;reg delayed_valid=0,history_ready=0;
 SB_RAM40_4K #(.READ_MODE(0),.WRITE_MODE(0)) history(
  .RCLK(clk),.RCLKE(1'b1),.RE(valid),.RADDR({6'd0,history_read}),.RDATA(old_word),
  .WCLK(clk),.WCLKE(1'b1),.WE(valid&&!clear),.WADDR({6'd0,history_pointer}),.MASK(16'd0),.WDATA(raw_rf));
 reg [15:0] difference=0;reg v0=0,v1=0,v2=0,v3=0;
 function [9:0] huff(input [3:0] n);
 begin case(n)
'''+cases+'''
 endcase end endfunction
 reg [9:0] symbols[0:3];
 wire [13:0] joined0={7'd0,symbols[0][6:0]} | ({7'd0,symbols[1][6:0]}<<symbols[0][9:7]);
 wire [13:0] joined1={7'd0,symbols[2][6:0]} | ({7'd0,symbols[3][6:0]}<<symbols[2][9:7]);
 wire [3:0] length0={1'b0,symbols[0][9:7]}+{1'b0,symbols[1][9:7]};
 wire [3:0] length1={1'b0,symbols[2][9:7]}+{1'b0,symbols[3][9:7]};
 reg [13:0] pair0=0,pair1=0;reg [3:0] size0=0,size1=0;
 wire [4:0] joined_length;
 gf_resolve #(.W(5)) combine_lengths({1'b0,size0},{1'b0,size1},1'b0,joined_length,);
 reg [27:0] code=0;reg [4:0] size=0;
 reg [31:0] pool=0;reg [4:0] used=0;
 wire [59:0] combined={28'd0,pool}|({32'd0,code}<<used);
 wire [5:0] total;
 gf_resolve #(.W(6)) count_bits({1'b0,used},{1'b0,size},1'b0,total,);
 wire flush=!valid&&!delayed_valid&&!v0&&!v1&&!v2&&!v3&&used!=0;
 assign emit=!clear&&((v3&&total[5])||flush);
 assign encoded=flush?pool:combined[31:0];
 assign idle=!valid&&!delayed_valid&&!v0&&!v1&&!v2&&!v3&&used==0;
 always @(posedge clk)begin
  delayed_valid<=valid;v0<=delayed_valid;v1<=v0;v2<=v1;v3<=v2;
  if(valid)begin
   delayed_raw<=raw_rf;history_ready<=history_fill==17;history_pointer<=history_next;
   if(history_fill!=17)history_fill<=fill_next;
  end
  difference<=delayed_raw^(history_ready?old_word:16'd0);
  for(h=0;h<4;h=h+1)symbols[h]<=huff(difference[h*4+:4]);
  pair0<=joined0;pair1<=joined1;size0<=length0;size1<=length1;
  code<={14'd0,pair0}|({14'd0,pair1}<<size0);size<=joined_length;
  if(v3)begin pool<=total[5]?{4'd0,combined[59:32]}:combined[31:0];used<=total[4:0];end
  if(flush)begin pool<=0;used<=0;end
  if(clear)begin
   history_pointer<=0;history_fill<=0;history_ready<=0;delayed_valid<=0;
   v0<=0;v1<=0;v2<=0;v3<=0;pool<=0;used<=0;
  end
 end
endmodule
'''
