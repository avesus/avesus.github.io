/* ITCNet Radio SDR receiver
(C) Ivan Borisenko 2024 and Meteorcomm LLC
All rights reserved. This product is NOT open source.
*/

module DESER1_2_POSEDGE (input wire D, input C, output reg [1:0] O);
  reg deser_reg = 1'b0;
  always @(posedge C) begin
    deser_reg <= ~deser_reg;
    O[0] <= deser_reg ? O[0] : D;
    O[1] <= deser_reg ? D : O[0];
  end
endmodule

module DESER1_2_NEGEDGE (input wire D, input C, output reg [1:0] O);
  reg deser_reg = 1'b0;
  always @(negedge C) begin
    deser_reg <= ~deser_reg;
    O[0] <= deser_reg ? O[0] : D;
    O[1] <= deser_reg ? D : O[0];
  end
endmodule

/*
Warning: Wire top.\clk_54mhz_reg_a is used but has no driver.
Warning: Wire top.\clk_27mhz_reg_a is used but has no driver.
Warning: Wire top.\clk_108mhz_reg_d is used but has no driver.
Warning: Wire top.\clk_108mhz_reg_c is used but has no driver.

./itcnet_nov4.sv:106: Warning: Identifier `\clk_108mhz_reg_c' is implicitly declared.
./itcnet_nov4.sv:107: Warning: Identifier `\clk_108mhz_reg_d' is implicitly declared.
./itcnet_nov4.sv:108: Warning: Identifier `\clk_27mhz_reg_a' is implicitly declared.
./itcnet_nov4.sv:109: Warning: Identifier `\clk_54mhz_reg_a' is implicitly declared.
./itcnet_nov4.sv:248: Warning: Identifier `\rf2x_0_and_4.O' is implicitly declared.
./itcnet_nov4.sv:248: Warning: Range select out of bounds on signal `\rf2x_0_and_4.O': Setting result bit to undef.
./itcnet_nov4.sv:249: Warning: Identifier `\rf2x_1_and_5.O' is implicitly declared.
./itcnet_nov4.sv:249: Warning: Range select out of bounds on signal `\rf2x_1_and_5.O': Setting result bit to undef.
./itcnet_nov4.sv:250: Warning: Identifier `\rf2x_2_and_6.O' is implicitly declared.
./itcnet_nov4.sv:250: Warning: Range select out of bounds on signal `\rf2x_2_and_6.O': Setting result bit to undef.
./itcnet_nov4.sv:251: Warning: Identifier `\rf2x_3_and_7.O' is implicitly declared.
./itcnet_nov4.sv:251: Warning: Range select out of bounds on signal `\rf2x_3_and_7.O': Setting result bit to undef.
./itcnet_nov4.sv:255: Warning: Range select out of bounds on signal `\rf2x_0_and_4.O': Setting result bit to undef.
./itcnet_nov4.sv:256: Warning: Range select out of bounds on signal `\rf2x_1_and_5.O': Setting result bit to undef.
./itcnet_nov4.sv:257: Warning: Range select out of bounds on signal `\rf2x_2_and_6.O': Setting result bit to undef.
./itcnet_nov4.sv:258: Warning: Range select out of bounds on signal `\rf2x_3_and_7.O': Setting result bit to undef.

*/

module top (
  (* clkbuf_inhibit *) input CRYSTAL_12MHZ,

  output LED_R,
  output LED_G,
  output LED_B,

  input DIFF_PINS_4P_3N,
  input DIFF_PINS_32P_31N,

  // Measurement & Debug pins
  // RC-filtered audio Sigma-Delta Ready
  output PIN2,

  // High-frequency probes
  output PIN42,
  output PIN43
);

  assign LED_R = 1'b0;
  assign LED_G = 1'b0;
  assign LED_B = 1'b0;
  // assign PIN42 = 1'b0;
  // assign PIN43 = 1'b0;

  assign PIN2 = 1'b0;

  // Reserve all MAC DSP so that the compiler doesn't randomly infer them
  wire [31:0] m1;
  wire [31:0] m2;
  wire [31:0] m3;
  wire [31:0] m4;
  wire [31:0] m5;
  wire [31:0] m6;
  wire [31:0] m7;
  wire [31:0] m8;
  wire CLK = 1'b0;
  (* keep *) SB_MAC16 #() mac1 (.CLK(CLK), .O(m1));
  (* keep *) SB_MAC16 #() mac2 (.CLK(CLK), .O(m2));
  (* keep *) SB_MAC16 #() mac3 (.CLK(CLK), .O(m3));
  (* keep *) SB_MAC16 #() mac4 (.CLK(CLK), .O(m4));
  (* keep *) SB_MAC16 #() mac5 (.CLK(CLK), .O(m5));
  (* keep *) SB_MAC16 #() mac6 (.CLK(CLK), .O(m6));
  (* keep *) SB_MAC16 #() mac7 (.CLK(CLK), .O(m7));
  (* keep *) SB_MAC16 #() mac8 (.CLK(CLK), .O(m8));

  // Reserve all global buffers so that some intermediate short and small fast clock wires
  // do not drive the whole chip's H-tree with all its power consumption and capacitance
  // at super high clock frequency accidentally. Verilog compilers love to waste global buffers.
  wire CLK_90;
  wire CLK_180;
  wire CLK_270;
  wire CLK_27M;
  wire CLK_54M;
  wire CLK_54M2;
  wire CLK_54M3;

  // Drive the first clock buffer at 108MHz:
  wire BUF_108MHZ;
  reg reg_108mhz = 1'b0;
  (* keep *) SB_GB htree1 (.USER_SIGNAL_TO_GLOBAL_BUFFER (reg_108mhz), .GLOBAL_BUFFER_OUTPUT (BUF_108MHZ));
  // Automatic clock is 27MHz allows to drive most of synthesized hyper-slow carry-propagate adder chains.
  // Standard Verilog compilers do not add pipeline registers nor they use Wallace trees, Carry Save Adders,
  // Nor they use Han-Carlson adders, unless you have Synopsis/Cadence license to tape out your TI-designed chips.
  (* keep *) wire SLOW_AUTO_CLK;
  (* keep *) reg [1:0] johnson_ctr_27mhz = 2'd0;
  (* keep *) SB_GB htree2 (.USER_SIGNAL_TO_GLOBAL_BUFFER (johnson_ctr_27mhz[1]), .GLOBAL_BUFFER_OUTPUT (SLOW_AUTO_CLK));

  // Note: we can use multiple core 4 clock phases of 108MHz with extremely high resolution compute
  (* keep *) SB_GB htree3 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_c), .GLOBAL_BUFFER_OUTPUT (CLK_90));
  (* keep *) SB_GB htree4 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_d), .GLOBAL_BUFFER_OUTPUT (CLK_270));
  (* keep *) SB_GB htree5 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_27mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_27M));
  (* keep *) SB_GB htree6 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M));

  // (* keep *) SB_GB htree7 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M2));
  // (* keep *) SB_GB htree8 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M3));

  // Reserve and disable the super-slow and CDC-requiring built-in-oscillators. We can use them later.
  (* clkbuf_inhibit *) wire INTERNAL_48MHZ_OSC;
  (* keep, ROUTE_THROUGH_FABRIC=1 *) SB_HFOSC #(
    //.CLKHF_DIV("0b00") // 80.7MHz (?!)
    // .CLKHF_DIV("0b10") // 12MHz
    .CLKHF_DIV("0b11") // 6MHz => 10MHz
  ) osc48MHz (
    .CLKHFPU(1'b0), // CLK High-Freq Power Up
    .CLKHFEN(1'b0),
    .CLKHF(INTERNAL_48MHZ_OSC)
  ) /* synthesis ROUTE_THROUGH_FABRIC=1 */;

  // 10kHz OSC => 16kHz measured
  (* clkbuf_inhibit *) wire INTERNAL_10KHZ_OSC;
  (* keep, ROUTE_THROUGH_FABRIC=1 *) SB_LFOSC #(
  ) osc10kHz (
    .CLKLFPU(1'b0), // CLK High-Freq Power Up
    .CLKLFEN(1'b0),
    .CLKLF(INTERNAL_10KHZ_OSC)
  );

/*
  assign LED_R = m1[31]
    | m2[31]
    | m3[31]
    | m4[31]
    | m5[31]
    | m6[31]
    | m7[31]
    | m8[31];
*/

  // Core DDR samplers are the heart of the radio representing
  // an ADC that samples binary values at RF_LO_X4, where f is the target RF LO frequency.
  // The first DDR sampler is driven without phase offset
  (* clkbuf_inhibit, keep *) wire RF_LO_X4_PHASES_0_180_DDR;

  // The second DDR samples is driven from PLL-produced 90 degrees phase offset.
  (* clkbuf_inhibit, keep *) wire RF_LO_X4_PHASES_90_270_DDR;

  // In BYPASS, this applied to only ONE of the outputs, PLLOUTCOREA
  //reg [3:0] pll_out_delay_a = 4'd15; // 0..15 in 150ps increments (applied even in BYPASS mode)
  reg [3:0] pll_out_delay_a = 4'd0; // 0..15 in 150ps increments (applied even in BYPASS mode)

  reg disable_pll = 1'b0;

  wire RF_LO_X4_PHASES_90_270_DDR_HTREE;
  wire RF_LO_X4_PHASES_0_180_DDR_HTREE;

  SB_PLL40_2F_PAD #(
    .FEEDBACK_PATH("PHASE_AND_DELAY"),
    // Feedback multiplier 0..63 => REF_CLK * 1..64
    // This value plus 1 is the output clock multiplier, i.e. 17 => 18 * 12MHz = 216MHz
    .DIVF(7'd17), // 216MHz // feedback multiplier 0..63 => REF_CLK * 1..64
    //.DIVF(7'd7), // 96MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
    .FILTER_RANGE(3'd1), // low-pass filter before VCO 0..7
    // .DIVQ(3'd5), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64

    // !!! Must be kept fixed at 2 sharp for low frequencies
    // .DIVQ(3'd2), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64
    // This is for 216MHz
    .DIVQ(3'd1), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64
    .DELAY_ADJUSTMENT_MODE_RELATIVE("DYNAMIC"), // output delay

    // 10MHz post-divided is the minimum input; 0 = 12MHz
    .DIVR(4'd0), // input divider 0..15 => 1..16. Because our clock is so low, we should keep it 1 always.
    .SHIFTREG_DIV_MODE(0), // 0 -> divide by 4; 1: divide by 7 => causes non-50% duty cycle
    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"), // feedback delay does nothing
    .FDA_FEEDBACK(4'b0000), // => not used
    .PLLOUT_SELECT_PORTA("SHIFTREG_90deg"),
    .PLLOUT_SELECT_PORTB("SHIFTREG_0deg")
    //.ENABLE_ICEGATE_PORTA(1'b1),
    //.ENABLE_ICEGATE_PORTB(1'b1)
  ) the_pll (
    .PACKAGEPIN(CRYSTAL_12MHZ),
    .PLLOUTGLOBALA(RF_LO_X4_PHASES_90_270_DDR_HTREE), // H-tree
    .PLLOUTGLOBALB(RF_LO_X4_PHASES_0_180_DDR_HTREE), // H-tree
    .PLLOUTCOREA(RF_LO_X4_PHASES_90_270_DDR),
    .PLLOUTCOREB(RF_LO_X4_PHASES_0_180_DDR),
    .DYNAMICDELAY({ pll_out_delay_a, 4'b0 }),
    .RESETB(1'b1),
    .BYPASS(1'b0), // test path!
    //.BYPASS(1'b1), // test path!
    .LATCHINPUTVALUE(disable_pll),
    .LOCK(),
    .SDI(1'b0),
    .SDO(),
    .SCLK(1'b0)
  );

  wire [3:0] RF4X_SAMPLES;

  // DDR sampler 1
  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) ddr_sampler_1 (
      .PACKAGE_PIN(DIFF_PINS_4P_3N),
      .INPUT_CLK(RF_LO_X4_PHASES_0_180_DDR),
      .D_IN_0(RF4X_SAMPLES[0]),
      .D_IN_1(RF4X_SAMPLES[2])
  );

  // DDR sampler 2
  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) ddr_sampler_2 (
      .PACKAGE_PIN(DIFF_PINS_32P_31N),
      .INPUT_CLK(RF_LO_X4_PHASES_90_270_DDR),
      .D_IN_0(RF4X_SAMPLES[1]),
      .D_IN_1(RF4X_SAMPLES[3])
  );

  // Half-clock DDR transfers
  reg [3:0] RF4X = 4'd0;

  // Goal is to output RF4X_SAMPLES[0] somehow
  // assign PIN43 = RF4X[0];

  //(* keep *) DESER1_2_POSEDGE rf2x_0_and_4(.D(RF4X_SAMPLES[0]), .C(RF_LO_X4_PHASES_0_180_DDR), .O({ RF2X[0], RF2X[4] }));

  // (* keep *) DESER1_2_NEGEDGE rf2x_0_and_4(.D(RF4X_SAMPLES[0]), .C(RF_LO_X4_PHASES_90_270_DDR), .O({ RF2X[0], RF2X[4] }));

  //(* keep *) DESER1_2_POSEDGE rf2x_1_and_5(.D(RF4X_SAMPLES[1]), .C(RF_LO_X4_PHASES_90_270_DDR), .O({ RF2X[5], RF2X[1] }));
  //(* keep *) DESER1_2_NEGEDGE rf2x_2_and_6(.D(RF4X_SAMPLES[2]), .C(RF_LO_X4_PHASES_0_180_DDR), .O({ RF2X[6], RF2X[2] }));
  //(* keep *) DESER1_2_NEGEDGE rf2x_3_and_7(.D(RF4X_SAMPLES[3]), .C(RF_LO_X4_PHASES_90_270_DDR), .O({ RF2X[7], RF2X[3] }));


  // Obtain 108MHz from non-buffered 216MHz:
  // always @(posedge RF_LO_X4_PHASES_0_180_DDR) reg_108mhz <= ~reg_108mhz;
  //always @(posedge RF_LO_X4_PHASES_90_270_DDR_HTREE) reg_108mhz <= ~reg_108mhz;
  always @(posedge RF_LO_X4_PHASES_90_270_DDR) reg_108mhz <= ~reg_108mhz;

  // always @(posedge RF_LO_X4_PHASES_90_270_DDR_HTREE) RF2X[0] <= ~RF2X[0] | RF4X_SAMPLES[0];
  // always @(posedge RF_LO_X4_PHASES_90_270_DDR_HTREE) RF2X[0] <= RF4X_SAMPLES[0];
  always @(posedge RF_LO_X4_PHASES_0_180_DDR) RF4X[0] <= RF4X_SAMPLES[0];
  // always @(negedge RF_LO_X4_PHASES_0_180_DDR_HTREE) RF4X[2] <= RF4X_SAMPLES[2];
  always @(posedge RF_LO_X4_PHASES_90_270_DDR_HTREE) RF4X[1] <= RF4X_SAMPLES[1];
  always @(negedge RF_LO_X4_PHASES_90_270_DDR_HTREE) RF4X[3] <= RF4X_SAMPLES[3];

  wire [7:0] RF2X;
  // (* keep *) DESER1_2_POSEDGE rf2x_0_and_4(.D(RF2X[0]), .C(RF_LO_X4_PHASES_0_180_DDR_HTREE), .O({ RF22X[0], RF22X[4] }));
  reg deser_reg1 = 1'b0;
  always @(posedge RF_LO_X4_PHASES_0_180_DDR) begin
    // deser_reg1 <= ~deser_reg1;
    RF2X[0] <= deser_reg1 ? RF2X[0] : RF4X[0];
    RF2X[4] <= deser_reg1 ? RF4X[0] : RF2X[4];
  end

  always @(posedge RF_LO_X4_PHASES_0_180_DDR_HTREE) begin
    deser_reg1 <= ~deser_reg1;
  end

  //reg deser_reg2 = 1'b0;
  //always @(negedge RF_LO_X4_PHASES_0_180_DDR) begin
  //  deser_reg2 <= ~deser_reg2;
  //  RF2X[0] <= deser_reg2 ? RF2X[0] : D;
  //  RF2X[4] <= deser_reg2 ? D : RF2X[0];
  //end

  // Use the 108MHz H-tree to drive clock divider Johnson counters:

  // Divide 108MHz by factor of 4
  always @(posedge BUF_108MHZ) johnson_ctr_27mhz <= { johnson_ctr_27mhz[0], ~johnson_ctr_27mhz[1] };

  reg [7:0] tt = 8'd0;
  always @(negedge SLOW_AUTO_CLK) begin
    tt[0] <= RF2X[0];
    tt[1] <= RF4X[1];
  end

  always @(posedge SLOW_AUTO_CLK) begin
    tt[4] <= RF2X[4];
    tt[2] <= RF4X[2];
    tt[3] <= RF4X[3];
  end

  assign PIN42 = tt[0]
    | tt[1]
    | tt[2]
    | tt[3]
    | tt[4]
    | tt[5]
    | tt[6]
    | tt[7];
  // assign PIN43 = SLOW_AUTO_CLK;
  //assign PIN43 = 1'b0; // SLOW_AUTO_CLK;

  /*

  // Target 8 samples at rf/2
  (* keep *) reg [7:0] sample0;
  always @(posedge BUF_108MHZ) begin
    { sample0[3:0] } <= { RF2X[3:0] };
  end

  always @(negedge BUF_108MHZ) begin
    { sample0[7:4] } <= { RF2X[7:4] };
  end

  // 1/2 clock transfer
  reg [7:0] sample;
  always @(posedge BUF_108MHZ) sample <= sample0;

  reg [16:0] dds_100k;
  always @(posedge SLOW_AUTO_CLK) dds_100k <= dds_100k + 17'd5750;

  reg [3:0] suum;
  // always @(posedge BUF_108MHZ) begin
  always @(negedge SLOW_AUTO_CLK) begin
    suum <= { 3'b0, ~sample[0] ^ dds_100k[16] } + 
            { 3'b0, sample[1] ^ dds_100k[16] } + 
            { 3'b0, sample[2] ^ dds_100k[16] } + 
            { 3'b0, ~sample[3] ^ dds_100k[16] } + 
            { 3'b0, ~sample[4] ^ dds_100k[16] } + 
            { 3'b0, sample[5] ^ dds_100k[16] } + 
            { 3'b0, sample[6] ^ dds_100k[16] } + 
            { 3'b0, ~sample[7] ^ dds_100k[16] };
  end

  // assign PIN42 = suum[3];

  */

endmodule

/*
module commented_out();

  //assign PIN42 = rf2x; // sample[0];
  //assign PIN42 = sample[0];
  reg oop;
  reg [16:0] dds_100k;
  // always @(posedge CLK) dds_100k <= dds_100k + 17'd4645;
  //always @(posedge CLK) dds_100k <= dds_100k + 17'd2419;
  //always @(posedge CLK) dds_100k <= dds_100k + 17'd2413; // 13
  always @(posedge CLK) dds_100k <= dds_100k + 17'd5750;

  reg [12:0] moving_average = 13'd0;
  // always @(posedge CLK) oop <= suum[2] ^ dds_100k[9]; //suum[2] | suum[3]; 
  always @(posedge CLK) moving_average <= decimator[10] ? 12'd0 : moving_average + {9'd0, suum[3:0]}; // suum[2] ^ dds_100k[9]; //suum[2] | suum[3]; 

  // reg [10:0] decimator = 11'd212;
  reg [10:0] decimator = 11'd349; // 108MHz / 0.16MHz = 675  count to 1024
  //always @(posedge CLK) decimator <= decimator[10] ? 11'd212 : (decimator + 11'd1);
  always @(posedge CLK) decimator <= decimator[10] ? 11'd349 : (decimator + 11'd1);
  //always @(posedge CLK) decimator <= decimator[10] ? 11'd20 : (decimator + 11'd1);
  //always @(posedge CLK) decimator <= decimator[10] ? 11'd0 : (decimator + 11'd1);

  reg [12:0] audio;
  always @(posedge decimator[10]) audio <= moving_average;// + { 11'd0, audio[11] } + audio;
  // always @(posedge decimator[9]) moving_average <= 13'd0;



  //assign PIN42 = oop;
  // assign PIN42 = audio[11];
  //assign PIN2 = audio[7];// ^ audio[10];
  assign PIN2 = audio[7];// ^ audio[10];
  //assign PIN42 = moving_average[0];
  assign PIN43 = 1'b0; // rf;


  reg clk_108mhz_reg_a = 1'b0;
  reg clk_108mhz_reg_b = 1'b0;
  reg clk_108mhz_reg_c = 1'b0;
  reg clk_108mhz_reg_d = 1'b0;
  always @(posedge rf2x) clk_108mhz_reg_a <= ~clk_108mhz_reg_a;
  always @(negedge rf2x) clk_108mhz_reg_b <= ~clk_108mhz_reg_b;
  always @(posedge rf2x_90) clk_108mhz_reg_c <= ~clk_108mhz_reg_c;
  always @(negedge rf2x_90) clk_108mhz_reg_d <= ~clk_108mhz_reg_d;

  wire CLK_90;
  wire CLK_180;
  wire CLK_270;


  // 2 phases of 54MHz
  reg clk_54mhz_reg_a = 1'b0;
  reg clk_54mhz_reg_b = 1'b0;
  always @(posedge CLK) clk_54mhz_reg_a <= ~clk_54mhz_reg_a;
  always @(posedge CLK_90) clk_54mhz_reg_b <= ~clk_54mhz_reg_b;

  reg clk_27mhz_reg_a = 1'b0;
  reg clk_27mhz_reg_b = 1'b0;
  always @(posedge clk_54mhz_reg_a) clk_27mhz_reg_a <= ~clk_27mhz_reg_a;
  always @(negedge clk_54mhz_reg_a) clk_27mhz_reg_b <= ~clk_27mhz_reg_b;


  reg [22:0] offset_4_7375_mhz = 23'b0; // = 220.7375 - 216MHz
  always @(posedge CLK_54M) offset_4_7375_mhz <= offset_4_7375_mhz + 23'd735945;

  wire lo_4_7375 = offset_4_7375_mhz[22];
  wire lo_4_7375_90 = offset_4_7375_mhz[22] ^ offset_4_7375_mhz[21];

  reg ro22 = 1'b0;
  reg ro23 = 1'b0;
  always @(posedge lo_4_7375) ro22 <= ~ro22;
  always @(posedge lo_4_7375_90) ro23 <= ~ro23;
  //assign PIN42 = ro22;
  //assign PIN43 = ro23;


endmodule

*/

