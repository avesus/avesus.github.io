
module top (
  // 12MHz
  input CLK_PIN,
  output LED_R,
  output LED_G,
  output LED_B,
  input PIN4,
  input PIN31,
  output PIN2,
  output PIN42,
  output PIN43
);


    localparam N = 27;

    reg [N-1:0] counter;

    always @(posedge CLK_27M) begin
        counter <= counter + 1;
    end

    // assign LED_R = counter[N - 3];
    // assign LED_G = counter[N - 1];
    assign LED_B = counter[N - 2];

    wire rf2x;
    wire rf2x_90;

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

    // This does nothing
    //reg [3:0] pll_feedback_delay = 4'd15; // 0..15 in 150ps increments
    //reg [3:0] pll_feedback_delay = 4'd0; // 0..15 in 150ps increments

    reg disable_pll = 1'b0;

    SB_PLL40_2F_PAD #(
    // SB_PLL40_2F_CORE #(
      .FEEDBACK_PATH("PHASE_AND_DELAY"),

      // 12MHz * 45 is the minimum 88 is the maximum.
      // VCO: 630MHz is stable
      //.DIVF(7'd45), // feedback multiplier 0..63 => REF_CLK * 1..64
      // .DIVF(7'd83), // feedback multiplier 0..63 => REF_CLK * 1..64
      // .DIVF(7'd83), // feedback multiplier 0..63 => REF_CLK * 1..64
      .DIVF(7'd17), // feedback multiplier 0..63 => REF_CLK * 1..64
      //.DIVF(7'd0), // feedback multiplier 0..63 => REF_CLK * 1..64
      //.DIVF(7'd53), // feedback multiplier 0..63 => REF_CLK * 1..64
      //.DIVF(7'd70), // feedback multiplier 0..63 => REF_CLK * 1..64

      //.FILTER_RANGE(3'd7), // low-pass filter before VCO 0..7
      .FILTER_RANGE(3'd1), // low-pass filter before VCO 0..7
      // .DIVQ(3'd5), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64

      // !!! Must be kept fixed at 2 sharp
      // .DIVQ(3'd2), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64
      .DIVQ(3'd1), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64

      // 10MHz post-divided is the minimum input
      .DIVR(4'd0), // input divider 0..15 => 1..16. Because our clock is so low, we should keep it 1 always.
      // .SHIFTREG_DIV_MODE(0), // 0 -> divide by 4; 1: divide by 7 => causes non-50% duty cycle
      .SHIFTREG_DIV_MODE(0), // 0 -> divide by 4; 1: divide by 7 => causes non-50% duty cycle

      // .DELAY_ADJUSTMENT_MODE_FEEDBACK("DYNAMIC"), // feedback delay does nothing
      .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"), // feedback delay
      .DELAY_ADJUSTMENT_MODE_RELATIVE("DYNAMIC"), // output delay
      // .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"), // output delay

      .FDA_FEEDBACK(4'b0000), // => not used
      // .FDA_RELATIVE(4'b0000), => dynamic, not used

      // .PLLOUT_SELECT_PORTA("SHIFTREG_0deg"),
      .PLLOUT_SELECT_PORTA("SHIFTREG_90deg"),
      .PLLOUT_SELECT_PORTB("SHIFTREG_0deg")
      // .ENABLE_ICEGATE_PORTA(0),
      // .ENABLE_ICEGATE_PORTB(0)
    ) the_pll (
      // .REFERENCECLK(1'b0), // INTERNAL_48MHZ_OSC),
      .PACKAGEPIN(CLK_PIN),
      .PLLOUTCOREA(rf2x),
      // .PLLOUTGLOBALA(), // H-tree
      .PLLOUTCOREB(rf2x_90),
      // .PLLOUTGLOBALB(), // H-tree
      // .EXTFEEDBACK(1'b0), // not used
      // .DYNAMICDELAY({ pll_out_delay_a, pll_feedback_delay }),
      .DYNAMICDELAY({ pll_out_delay_a, 4'b0 }),
      .RESETB(1'b1),
      .BYPASS(1'b0), // test path!
      // .LATCHINPUTVALUE(disable_pll),
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
  SB_GB htree1 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK)
  );

  SB_GB htree2 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_b),
    .GLOBAL_BUFFER_OUTPUT (CLK_180)
  );

  SB_GB htree3 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_108mhz_reg_c),
    .GLOBAL_BUFFER_OUTPUT (CLK_90)
  );

  SB_GB htree4 (
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
  SB_GB htree5 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_27mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK_27M)
  );

  wire CLK_54M;
  SB_GB htree6 (
    .USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a),
    .GLOBAL_BUFFER_OUTPUT (CLK_54M)
  );


  // reg [44:0] harmonic_7_9625_mhz = 45'b0;


  //reg [26:0] harmonic_7_9625_mhz = 27'b0;
  //always @(posedge clk_54mhz_reg_a) harmonic_7_9625_mhz <= harmonic_7_9625_mhz + 27'd19790901;
  //assign PIN42 = harmonic_7_9625_mhz[26];

  //reg [10:0] harmonic_7_9625_mhz = 11'b0;
  // always @(posedge clk_54mhz_reg_a) harmonic_7_9625_mhz <= harmonic_7_9625_mhz + 10'd151;
  //always @(posedge CLK) harmonic_7_9625_mhz <= harmonic_7_9625_mhz + 11'd151;
  //assign PIN42 = harmonic_7_9625_mhz[10];
  //assign PIN43 = harmonic_7_9625_mhz[10];


  //reg [23:0] offset_4_7375_mhz = 24'b0; // = 220.7375 - 216MHz
  //always @(posedge CLK) offset_4_7375_mhz <= offset_4_7375_mhz + 24'd735945;
  //assign PIN42 = offset_4_7375_mhz[23];
  //assign PIN43 = offset_4_7375_mhz[23];

  reg [22:0] offset_4_7375_mhz = 23'b0; // = 220.7375 - 216MHz
  always @(posedge CLK_54M) offset_4_7375_mhz <= offset_4_7375_mhz + 23'd735945;
  //assign PIN42 = offset_4_7375_mhz[22];
  //assign PIN43 = offset_4_7375_mhz[22] ^ offset_4_7375_mhz[21];

  wire lo_4_7375 = offset_4_7375_mhz[22];
  wire lo_4_7375_90 = offset_4_7375_mhz[22] ^ offset_4_7375_mhz[21];
  // assign LED_R = offset_4_7375_mhz[22];
  // assign LED_G = offset_4_7375_mhz[22] ^ offset_4_7375_mhz[21];

  reg ro22 = 1'b0;
  reg ro23 = 1'b0;
  always @(posedge lo_4_7375) ro22 <= ~ro22;
  always @(posedge lo_4_7375_90) ro23 <= ~ro23;
  assign PIN42 = ro22;
  assign PIN43 = ro23;



  // always @(posedge CLK_27M) harmonic_7_9625_mhz <= harmonic_7_9625_mhz + 24'd992274;
  //always @(posedge CLK_27M) harmonic_7_9625_mhz <= harmonic_7_9625_mhz + 24'd985830;
  //assign PIN42 = harmonic_7_9625_mhz[23];

  //assign PIN42 = harmonic_7_9625_mhz[26];
  //assign PIN43 = harmonic_7_9625_mhz[26];

  //assign PIN42 = clk_27mhz_reg_a;
  //assign PIN43 = clk_27mhz_reg_b;
  //assign PIN42 = harmonic_7_9625_mhz[23];
  //assign PIN43 = ~harmonic_7_9625_mhz[23];


  // 2 phases of 27MHz
  //reg clk_27mhz_reg_a = 1'b0;
  //reg clk_27mhz_reg_b = 1'b0;
  //always @(posedge clk_54mhz_reg_a) clk_27mhz_reg_a <= ~clk_27mhz_reg_a;
  //always @(negedge clk_54mhz_reg_a) clk_27mhz_reg_b <= ~clk_27mhz_reg_b;

  //assign PIN42 = clk_27mhz_reg_a;
  //assign PIN43 = clk_27mhz_reg_b;

  // clk 108MHz divide by 4
  /*
  reg [1:0] johnson_ctr_0;
  always @(posedge CLK) johnson_ctr_0 <= { johnson_ctr_0[0], ~johnson_ctr_0[1] };
  assign PIN42 = johnson_ctr_0[1];

  reg o1 = 1'b0;
  reg o2 = 1'b1;
  always @(posedge CLK) o1 <= ~o1;
  always @(posedge CLK_90) o2 <= ~o2;
  
  assign PIN42 = o1;
  assign PIN43 = o2;
  */

  // clk divide by 16
  //reg [7:0] johnson_ctr_1;
  //always @(posedge rf2x) johnson_ctr_1 <= { johnson_ctr_1[6:0], ~johnson_ctr_1[7] };
  //assign PIN42 = johnson_ctr_1[7];

  //reg [7:0] johnson_ctr_2;
  //always @(posedge rf2x_90) johnson_ctr_2 <= { johnson_ctr_2[6:0], ~johnson_ctr_2[7] };
  //assign PIN43 = johnson_ctr_2[7];


  wire rf;
  wire rf90;

/*
  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) io_blk_1 (
      .PACKAGE_PIN(PIN4),
      .INPUT_CLK(rf2x),
      .D_IN_0(rf),
      .D_IN_1(rf90)
  );

  wire rf2;
  wire rf902;

  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) io_blk_2 (
      .PACKAGE_PIN(PIN31),
      .INPUT_CLK(rf2x_90),
      .D_IN_0(rf2),
      .D_IN_1(rf902)
  );
*/

  //assign LED_R = rf;
  //assign LED_G = rf90;

    reg [26:0] accum1;
    reg [26:0] accum2;
    reg [26:0] total;

    // reg flip = 1'b0;

    always @(posedge CLK_27M) begin
        accum1 <= accum1 + {25'b0, rf};
        // flip <= ~flip;
    end

    always @(negedge CLK_27M) begin
        accum2 <= accum2 + {25'b0, ~rf};
        // flip <= ~flip;
    end

    always @(posedge counter[1]) begin
        total <= accum1 + accum2;
    end

  // assign PIN2 = 1'b0; //rf; // CLK; //rf;
  //assign PIN2 = total[8]; //rf; // CLK; //rf;
  //assign PIN2 = total[9]; //rf; // CLK; //rf;





   // assign PIN2 = total[12]; //rf; // CLK; //rf;

endmodule
