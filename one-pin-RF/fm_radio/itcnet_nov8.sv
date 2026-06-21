/* ITCNet Radio SDR receiver
(C) Ivan Borisenko 2024 and Meteorcomm LLC
All rights reserved. This product is NOT open source.
*/

// Double buffer deserializer
module DBDESER (input wire DDR_CLK, // 228MHz max
  input wire CLK, // 1/2 DDR_CLK
  input wire DDR_D,
  output wire [1:0] OUT);

  reg p = 1'b1;
  reg np = 1'b0;

  wire [1:0] b1w;
  SB_DFFE b1(.D(DDR_D), .E(p), .C(DDR_CLK), .Q(b1w[0]));
  SB_DFFE b2(.D(b1w[0]), .E(p), .C(DDR_CLK), .Q(b1w[1]));

  wire [1:0] b2w;
  SB_DFFE b3(.D(DDR_D), .E(np), .C(DDR_CLK), .Q(b2w[0]));
  SB_DFFE b4(.D(b2w[0]), .E(np), .C(DDR_CLK), .Q(b2w[1]));

  reg [1:0] r1;
  always @(posedge CLK) begin
    r1 <= p ? b2w : b1w;
    p <= ~p;
    np <= ~np;
  end

  assign OUT = r1;

endmodule

// Double buffer deserializer
module DBDESER_N (input wire DDR_CLK, // 228MHz max
  input wire CLK, // 1/2 DDR_CLK
  input wire DDR_D,
  output wire [1:0] OUT);

  reg p = 1'b1;
  reg np = 1'b0;

  wire [1:0] b1w;
  SB_DFFNE b1(.D(DDR_D), .E(p), .C(DDR_CLK), .Q(b1w[0]));
  SB_DFFNE b2(.D(b1w[0]), .E(p), .C(DDR_CLK), .Q(b1w[1]));

  wire [1:0] b2w;
  SB_DFFNE b3(.D(DDR_D), .E(np), .C(DDR_CLK), .Q(b2w[0]));
  SB_DFFNE b4(.D(b2w[0]), .E(np), .C(DDR_CLK), .Q(b2w[1]));

  reg [1:0] r1;
  always @(posedge CLK) begin
    r1 <= p ? b2w : b1w;
    p <= ~p;
    np <= ~np;
  end

  assign OUT = r1;

endmodule

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

  // assign PIN2 = 1'b0;

  // Reserve all MAC DSP so that the compiler doesn't randomly infer them
  wire [31:0] m1;
  wire [31:0] m2;
  wire [31:0] m3;
  wire [31:0] m4;
  wire [31:0] m5;
  wire [31:0] m6;
  wire [31:0] m7;
  wire [31:0] m8;
  wire CLK2;
  (* keep *) SB_MAC16 #() mac1 (.CLK(CLK2), .O(m1));
  (* keep *) SB_MAC16 #() mac2 (.CLK(CLK2), .O(m2));
  (* keep *) SB_MAC16 #() mac3 (.CLK(CLK2), .O(m3));
  (* keep *) SB_MAC16 #() mac4 (.CLK(CLK2), .O(m4));
  (* keep *) SB_MAC16 #() mac5 (.CLK(CLK2), .O(m5));
  (* keep *) SB_MAC16 #() mac6 (.CLK(CLK2), .O(m6));
  (* keep *) SB_MAC16 #() mac7 (.CLK(CLK2), .O(m7));
  (* keep *) SB_MAC16 #() mac8 (.CLK(CLK2), .O(m8));

  // Reserve all global buffers so that some intermediate short and small fast clock wires
  // do not drive the whole chip's H-tree with all its power consumption and capacitance
  // at super high clock frequency accidentally. Verilog compilers love to waste global buffers.



  // Note: we must use multiple core 4 clock phases of 108MHz with extremely high resolution compute
  wire CLK;
  wire CLK_90;
  wire CLK_180;
  wire CLK_270;

  reg r108m0 = 1'b0;
  reg r108m90 = 1'b0;
  reg r108m180 = 1'b0;
  reg r108m270 = 1'b0;
  (* keep *) SB_GB htree1 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r108m0), .GLOBAL_BUFFER_OUTPUT (CLK));
  (* keep *) SB_GB htree2 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r108m90), .GLOBAL_BUFFER_OUTPUT (CLK_90));
  (* keep *) SB_GB htree3 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r108m180), .GLOBAL_BUFFER_OUTPUT (CLK_180));
  (* keep *) SB_GB htree4 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r108m270), .GLOBAL_BUFFER_OUTPUT (CLK_270));

  always @(posedge  RF_LO_X4_PHASES_0_180_DDR) r108m0 <= ~r108m0;
  always @(negedge  RF_LO_X4_PHASES_0_180_DDR) r108m180 <= ~r108m180;
  always @(posedge  RF_LO_X4_PHASES_90_270_DDR) r108m90 <= ~r108m90;
  always @(negedge  RF_LO_X4_PHASES_90_270_DDR) r108m270 <= ~r108m270;




  // Automatic clock is 27MHz allows to drive most of synthesized hyper-slow carry-propagate adder chains.
  // Standard Verilog compilers do not add pipeline registers nor they use Wallace trees, Carry Save Adders,
  // Nor they use Han-Carlson adders, unless you have Synopsis/Cadence license to tape out your TI-designed chips.
  wire CLK_27M;
  wire CLK_54M;
  wire CLK_54M2;
  wire CLK_54M3;

  //(* keep *) wire SLOW_AUTO_CLK;
  //(* keep *) reg [3:0] johnson_ctr_27mhz = 4'd0;
  // This closes @ 215.15 MHz
  // (* keep *) SB_GB htree2 (.USER_SIGNAL_TO_GLOBAL_BUFFER (johnson_ctr_27mhz[0]), .GLOBAL_BUFFER_OUTPUT (SLOW_AUTO_CLK));
  //(* keep *) wire SLOW_AUTO_CLK2;

  //reg o5;
  // (* keep *) SB_GB htree2 (.USER_SIGNAL_TO_GLOBAL_BUFFER (~johnson_ctr_27mhz[2]), .GLOBAL_BUFFER_OUTPUT (SLOW_AUTO_CLK2));

  //(* keep *) SB_GB htree5 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_27mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_27M));
  (* keep *) SB_GB htree6 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M));
  

  (* keep *) SB_GB htree7 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M2));
  (* keep *) SB_GB htree8 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M3));

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
    //.DIVF(7'd17), // 216MHz // feedback multiplier 0..63 => REF_CLK * 1..64
    .DIVF(7'd7), // 96MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
    .FILTER_RANGE(3'd1), // low-pass filter before VCO 0..7
    // .DIVQ(3'd5), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64

    // !!! Must be kept fixed at 2 sharp for low frequencies
    //.DIVQ(3'd2), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64
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
    //.PLLOUTGLOBALA(RF_LO_X4_PHASES_90_270_DDR), // H-tree
    //.PLLOUTGLOBALB(RF_LO_X4_PHASES_0_180_DDR), // H-tree
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

  wire [7:0] samples100m;
  DBDESER deser1(.DDR_CLK(RF_LO_X4_PHASES_0_180_DDR), .CLK(CLK),
    .DDR_D(RF4X_SAMPLES[0]), .OUT({samples100m[4], samples100m[0]}));
  DBDESER_N deser2(.DDR_CLK(RF_LO_X4_PHASES_0_180_DDR), .CLK(CLK_180),
    .DDR_D(RF4X_SAMPLES[2]), .OUT({samples100m[6], samples100m[2]}));
  DBDESER deser3(.DDR_CLK(RF_LO_X4_PHASES_90_270_DDR), .CLK(CLK_90),
    .DDR_D(RF4X_SAMPLES[1]), .OUT({samples100m[5], samples100m[1]}));
  DBDESER_N deser4(.DDR_CLK(RF_LO_X4_PHASES_90_270_DDR), .CLK(CLK_270),
    .DDR_D(RF4X_SAMPLES[3]), .OUT({samples100m[7], samples100m[3]}));

  wire CLK27;
  /*
  wire CLK27_90;
  wire CLK27_180;
  wire CLK27_270;
*/
  reg [1:0] r27m0 = 2'd3;
  //reg [1:0] r27m90 = 2'd0;
  //reg [1:0] r27m180 = 2'd0;
  //reg [1:0] r27m270 = 2'd0;
  (* keep *) SB_GB htree5 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r27m0[0]), .GLOBAL_BUFFER_OUTPUT (CLK27));
  //(* keep *) SB_GB htree6 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r27m90), .GLOBAL_BUFFER_OUTPUT (CLK27_90));
  //(* keep *) SB_GB htree7 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r27m180), .GLOBAL_BUFFER_OUTPUT (CLK27_180));
  //(* keep *) SB_GB htree8 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r27m270), .GLOBAL_BUFFER_OUTPUT (CLK27_270));

  always @(posedge CLK) r27m0 <= {r27m0[0], ~r27m0[1]};
  //always @(posedge CLK_180) r27m180 <= {r27m180[0], ~r27m180[1]};
  //always @(posedge CLK_90) r27m90 <= {r27m90[0], ~r27m90[1]};
  //always @(posedge CLK_270) r27m270 <= {r27m270[0], ~r27m270[1]};

  reg [7:0] samples100m0;
  reg [7:0] samples100m1;
  reg [7:0] samples100m2;
  reg [7:0] samples100m3;

  always @(posedge CLK_90) begin
    //samples100m0 <= samples100m;
    
    samples100m0 <= {
      ~samples100m[7],
      samples100m[6],
      samples100m[5],
      ~samples100m[4],
      ~samples100m[3],
      samples100m[2],
      samples100m[1],
      ~samples100m[0]
    };
    
    samples100m1 <= samples100m0;
    samples100m2 <= samples100m1;
    samples100m3 <= samples100m2;
  end

  reg [31:0] samples27m;

  // Wallace tree
  reg [1:0] s0;
  reg [1:0] s1;
  reg [1:0] s2;
  reg [1:0] s3;
  reg [1:0] s4;
  reg [1:0] s5;

  reg [13:0] dds_ch1;
  always @(posedge CLK27) dds_ch1 <= dds_ch1 + 14'd143;

  // reg [15:0] bb_window;
  reg [10:0] decimator = 11'd212;
  always @(posedge CLK27) decimator <= decimator[10] ? 11'd212 : (decimator + 11'd1);

  reg [31:0] sum;
  reg [31:0] samples;

  always @(posedge CLK27) begin
    samples27m[7:0] <= samples100m0;
    samples27m[15:8] <= samples100m1;
    samples27m[23:16] <= samples100m2;
    samples27m[31:24] <= samples100m3;

    // bb_window <= bb_window[15] ? 16'd0 : bb_window + 16'd17;

    samples <= decimator[10] ? 32'd0 : samples + sum // [4])

      //+ { 31'd0, samples[14] }
    ; //[4];

    sum <= { 31'd0, samples27m[0] ^ dds_ch1[13]}
      + { 31'd0, samples27m[1] ^ dds_ch1[13] }
      + { 31'd0, samples27m[2] ^ dds_ch1[13] }
      + { 31'd0, samples27m[3] ^ dds_ch1[13] }
      + { 31'd0, samples27m[4] ^ dds_ch1[13] }
      + { 31'd0, samples27m[5] ^ dds_ch1[13] }
      + { 31'd0, samples27m[6] ^ dds_ch1[13] }
      + { 31'd0, samples27m[7] ^ dds_ch1[13] }
      + { 31'd0, samples27m[8] ^ dds_ch1[13] }
      + { 31'd0, samples27m[9] ^ dds_ch1[13] }
      + { 31'd0, samples27m[10] ^ dds_ch1[13] }
      + { 31'd0, samples27m[11] ^ dds_ch1[13] }
      + { 31'd0, samples27m[12] ^ dds_ch1[13] }
      + { 31'd0, samples27m[13] ^ dds_ch1[13] }
      + { 31'd0, samples27m[14] ^ dds_ch1[13] }
      + { 31'd0, samples27m[15] ^ dds_ch1[13] }
      + { 31'd0, samples27m[16] ^ dds_ch1[13] }
      + { 31'd0, samples27m[17] ^ dds_ch1[13] }
      + { 31'd0, samples27m[18] ^ dds_ch1[13] }
      + { 31'd0, samples27m[19] ^ dds_ch1[13] }
      + { 31'd0, samples27m[20] ^ dds_ch1[13] }
      + { 31'd0, samples27m[21] ^ dds_ch1[13] }
      + { 31'd0, samples27m[22] ^ dds_ch1[13] }
      + { 31'd0, samples27m[23] ^ dds_ch1[13] }
      + { 31'd0, samples27m[24] ^ dds_ch1[13] }
      + { 31'd0, samples27m[25] ^ dds_ch1[13] }
      + { 31'd0, samples27m[26] ^ dds_ch1[13] }
      + { 31'd0, samples27m[27] ^ dds_ch1[13] }
      + { 31'd0, samples27m[28] ^ dds_ch1[13] }
      + { 31'd0, samples27m[29] ^ dds_ch1[13] }
      + { 31'd0, samples27m[30] ^ dds_ch1[13] }
      + { 31'd0, samples27m[31] ^ dds_ch1[13] };
  end

  // assign PIN42 = 1'b0; //samples[20];
  assign PIN42 = 1'b0;//samples[31];
  //assign PIN43 = samples100m[0];
  assign PIN43 = 1'b0; //samples[19];
  // assign PIN43 = samples[21];
  //assign PIN43 = samples27m[0];
  //assign PIN43 = RF4X_SAMPLES[0];
  //assign PIN2 = samples[15];
  //assign PIN2 = RF4X_SAMPLES[2];
  // assign PIN2 = samples[21];
  // assign PIN2 = samples[21];
  assign PIN2 = samples[15];
  //assign PIN2 = samples[4];

endmodule
