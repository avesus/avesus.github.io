/* FM Radio SDR receiver PoC
(C) Brian Greenforest 2024
*/
module top (
  // 12MHz
  input CLK_PIN,
  output LED_R,
  output LED_G,
  output LED_B,
  input PIN4,
  // input PIN31,
  input PIN32,

  output PIN2,
  output PIN42,
  output PIN43
);

  // Reserve all MAC DSP so it doesn't randomly infer them
  wire [31:0] m1;
  wire [31:0] m2;
  wire [31:0] m3;
  wire [31:0] m4;
  wire [31:0] m5;
  wire [31:0] m6;
  wire [31:0] m7;
  wire [31:0] m8;
  SB_MAC16 #() mac1 (.CLK(CLK), .O(m1));
  SB_MAC16 #() mac2 (.CLK(CLK), .O(m2));
  SB_MAC16 #() mac3 (.CLK(CLK), .O(m3));
  SB_MAC16 #() mac4 (.CLK(CLK), .O(m4));
  SB_MAC16 #() mac5 (.CLK(CLK), .O(m5));
  SB_MAC16 #() mac6 (.CLK(CLK), .O(m6));
  SB_MAC16 #() mac7 (.CLK(CLK), .O(m7));
  SB_MAC16 #() mac8 (.CLK(CLK), .O(m8));

  assign LED_R = m1[31]
    | m2[31]
    | m3[31]
    | m4[31]
    | m5[31]
    | m6[31]
    | m7[31]
    | m8[31];

  wire rf;
  wire rf90;

  // DDR sampler 1
  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) ddr_sampler_1 (
      .PACKAGE_PIN(PIN4),
      .INPUT_CLK(rf2x),
      .D_IN_0(rf),
      .D_IN_1(rf90)
  );

  wire rf2;
  wire rf902;

  // DDR sampler 1
  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) ddr_sampler_2 (
      .PACKAGE_PIN(PIN32),
      .INPUT_CLK(rf2x_90),
      .D_IN_0(rf2),
      .D_IN_1(rf902)
  );

  // Half-clock DDR transfer
  reg hc1;
  reg hc2;
  always @(negedge rf2x) hc1 <= rf;
  always @(negedge rf2x_90) hc2 <= rf2;

  // Target 8 samples at rf/2
  reg [7:0] sample0;
  always @(posedge CLK) begin
    sample0[4] <= hc1;
    sample0[5] <= hc2;
    sample0[6] <= rf90;
    sample0[7] <= rf902;
  end

  always @(negedge CLK) begin
    sample0[0] <= hc1;
    sample0[2] <= rf90;
    sample0[1] <= hc2;
    sample0[3] <= rf902;
  end

  // 1/2 clock transfer
  reg [7:0] sample;
  always @(negedge CLK) sample <= sample0;

///*
  reg [3:0] suum;
  always @(posedge CLK) begin
    suum <= { 3'b0, ~sample[0] ^ dds_100k[16] } + 
            { 3'b0, sample[1] ^ dds_100k[16] } + 
            { 3'b0, sample[2] ^ dds_100k[16] } + 
            { 3'b0, ~sample[3] ^ dds_100k[16] } + 
            { 3'b0, ~sample[4] ^ dds_100k[16] } + 
            { 3'b0, sample[5] ^ dds_100k[16] } + 
            { 3'b0, sample[6] ^ dds_100k[16] } + 
            { 3'b0, ~sample[7] ^ dds_100k[16] };
  end
//  */
  //assign PIN42 = rf2x; // sample[0];
  //assign PIN42 = sample[0];
  reg oop;
  reg [16:0] dds_100k;
  // always @(posedge CLK) dds_100k <= dds_100k + 17'd4645;
  //always @(posedge CLK) dds_100k <= dds_100k + 17'd2419;
  //always @(posedge CLK) dds_100k <= dds_100k + 17'd2413; // 13
  always @(posedge CLK) dds_100k <= dds_100k + 17'd2414; // 13
  //always @(posedge CLK) dds_100k <= dds_100k + 17'd1144; // 13

  reg [11:0] moving_average = 12'd0;
  // always @(posedge CLK) oop <= suum[2] ^ dds_100k[9]; //suum[2] | suum[3]; 
  always @(posedge CLK) moving_average <= decimator[10] ? 12'd0 : moving_average + {8'd0, suum[3:0]}; // suum[2] ^ dds_100k[9]; //suum[2] | suum[3]; 

  reg [10:0] decimator = 11'd212;
  always @(posedge CLK) decimator <= decimator[10] ? 11'd212 : (decimator + 11'd1);
  //always @(posedge CLK) decimator <= decimator[10] ? 11'd20 : (decimator + 11'd1);
  //always @(posedge CLK) decimator <= decimator[10] ? 11'd0 : (decimator + 11'd1);

  reg [11:0] audio;
  always @(posedge decimator[10]) audio <= moving_average;// + { 11'd0, audio[11] } + audio;
  // always @(posedge decimator[9]) moving_average <= 12'd0;



  //assign PIN42 = oop;
  // assign PIN42 = audio[11];
  assign PIN2 = audio[7];// ^ audio[10];
  //assign PIN42 = moving_average[0];
  assign PIN43 = 1'b0; // rf;


    (* clkbuf_inhibit *) wire rf2x; 
    (* clkbuf_inhibit *) wire rf2x_90;

    wire INTERNAL_48MHZ_OSC;
    
    SB_HFOSC #(
      //.CLKHF_DIV("0b00") // 80.7MHz
      // .CLKHF_DIV("0b10") // 12MHz
      .CLKHF_DIV("0b11") // 6MHz => 10MHz
    ) osc48MHz (
      .CLKHFPU(1'b0), // CLK High-Freq Power Up
      .CLKHFEN(1'b0),
      // .CLKHF(INTERNAL_48MHZ_OSC)
      .CLKHF()
    ) /* synthesis ROUTE_THROUGH_FABRIC=0 */ ;

    // 10kHz OSC => 16kHz measured
    SB_LFOSC #(
    ) osc10kHz (
      .CLKLFPU(1'b0), // CLK High-Freq Power Up
      .CLKLFEN(1'b0),
      // .CLKLF(INTERNAL_48MHZ_OSC)
      .CLKLF()
    ) /* synthesis ROUTE_THROUGH_FABRIC=0 */ ;

    // In BYPASS, this applied to only ONE of the outputs, PLLOUTCOREA
    //reg [3:0] pll_out_delay_a = 4'd15; // 0..15 in 150ps increments (applied even in BYPASS mode)
    reg [3:0] pll_out_delay_a = 4'd0; // 0..15 in 150ps increments (applied even in BYPASS mode)

    reg disable_pll = 1'b0;

    SB_PLL40_2F_PAD #(
      .FEEDBACK_PATH("PHASE_AND_DELAY"),
      // Feedback multiplier 0..63 => REF_CLK * 1..64
      // This value plus 1 is the output clock multiplier, i.e. 17 => 18 * 12MHz = 216MHz
      // .DIVF(7'd17), // 216MHz // feedback multiplier 0..63 => REF_CLK * 1..64
      .DIVF(7'd7), // 96MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
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
      .PACKAGEPIN(CLK_PIN),
      .PLLOUTCOREA(rf2x),
      .PLLOUTCOREB(rf2x_90),
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

  // Core 4 clock phases of 108MHz with extremely high resolution compute
  (* keep *) SB_GB htree1 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK)
  );

  (* keep *) SB_GB htree2 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_b),
    .GLOBAL_BUFFER_OUTPUT (CLK_180)
  );

  (* keep *) SB_GB htree3 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_c),
    .GLOBAL_BUFFER_OUTPUT (CLK_90)
  );

  (* keep *) SB_GB htree4 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_d),
    .GLOBAL_BUFFER_OUTPUT (CLK_270)
  );


  // 2 phases of 54MHz
  reg clk_54mhz_reg_a = 1'b0;
  reg clk_54mhz_reg_b = 1'b0;
  always @(posedge CLK) clk_54mhz_reg_a <= ~clk_54mhz_reg_a;
  always @(posedge CLK_90) clk_54mhz_reg_b <= ~clk_54mhz_reg_b;

  reg clk_27mhz_reg_a = 1'b0;
  reg clk_27mhz_reg_b = 1'b0;
  always @(posedge clk_54mhz_reg_a) clk_27mhz_reg_a <= ~clk_27mhz_reg_a;
  always @(negedge clk_54mhz_reg_a) clk_27mhz_reg_b <= ~clk_27mhz_reg_b;

  wire CLK_27M;
  (* keep *) SB_GB htree5 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_27mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK_27M)
  );

  wire CLK_54M;
  (* keep *) SB_GB htree6 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK_54M)
  );

  wire CLK_54M2;
  (* keep *) SB_GB htree7 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK_54M2)
  );

  wire CLK_54M3;
  (* keep *) SB_GB htree8 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK_54M3)
  );


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
