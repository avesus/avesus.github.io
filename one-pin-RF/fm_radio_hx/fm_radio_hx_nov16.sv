/* FM Radio SDR receiver
(C) Brian Greenforest 2024
MIT License.
*/

module top (
  (* clkbuf_inhibit *) input CRYSTAL_12MHZ,

  input DIFF_PINS_32P_31N,

  // Measurement & Debug pins
  // RC-filtered audio Sigma-Delta Ready
  output PIN2
);

  // Reserve all global buffers so that some intermediate short and small fast clock wires
  // do not drive the whole chip's H-tree with all its power consumption and capacitance
  // at super high clock frequency accidentally. Verilog compilers love to waste global buffers.



  // Note: we must use multiple core 4 clock phases of 108MHz with extremely high resolution compute
  wire CLK;
  reg r42m0 = 1'b0;
  (* keep *) SB_GB htree1 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r42m0), .GLOBAL_BUFFER_OUTPUT (CLK));

  always @(negedge  RF_LO_X4_PHASES_90_270_DDR) r42m0 <= ~r42m0;


  wire CLK_90;
  wire CLK_180;
  wire CLK_270;
  reg r108m90 = 1'b0;
  reg r108m180 = 1'b0;
  reg r108m270 = 1'b0;
  (* keep *) SB_GB htree2 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r108m90), .GLOBAL_BUFFER_OUTPUT (CLK_90));
  (* keep *) SB_GB htree3 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r108m180), .GLOBAL_BUFFER_OUTPUT (CLK_180));
  (* keep *) SB_GB htree4 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r108m270), .GLOBAL_BUFFER_OUTPUT (CLK_270));

  //always @(negedge  RF_LO_X4_PHASES_0_180_DDR) r108m180 <= ~r108m180;
  //always @(posedge  RF_LO_X4_PHASES_90_270_DDR) r108m90 <= ~r108m90;
  //always @(negedge  RF_LO_X4_PHASES_90_270_DDR) r108m270 <= ~r108m270;




  // Automatic clock is 21MHz allows to drive most of synthesized hyper-slow carry-propagate adder chains.
  // Standard Verilog compilers do not add pipeline registers nor they use Wallace trees, Carry Save Adders,
  // Nor they use Han-Carlson adders, unless you have Synopsis/Cadence license to tape out your TI-designed chips.
  (* keep *) SB_GB htree5 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M));
  

  // Reserve goes into PLL
  //(* keep *) SB_GB htree6 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M2));
  //(* keep *) SB_GB htree7 (.USER_SIGNAL_TO_GLOBAL_BUFFER (clk_54mhz_reg_a), .GLOBAL_BUFFER_OUTPUT (CLK_54M3));

  // Core DDR samplers are the heart of the radio representing
  // an ADC that samples binary values at RF_LO_X4, where f is the target RF LO frequency.
  // The first DDR sampler is driven without phase offset
  (* clkbuf_inhibit, keep *) wire CLK_168_MHZ;

  // The second DDR samples is driven from PLL-produced 90 degrees phase offset.
  (* clkbuf_inhibit, keep *) wire CLK_168_MHZ_270;

  // In BYPASS, this applied to only ONE of the outputs, PLLOUTCOREA
  //reg [3:0] pll_out_delay_a = 4'd15; // 0..15 in 150ps increments (applied even in BYPASS mode)
  reg [3:0] pll_out_delay_a = 4'd0; // 0..15 in 150ps increments (applied even in BYPASS mode)

  reg disable_pll = 1'b0;

  SB_PLL40_2F_PAD #(
    .FEEDBACK_PATH("PHASE_AND_DELAY"),
    // Feedback multiplier 0..63 => REF_CLK * 1..64
    // This value plus 1 is the output clock multiplier, i.e. 13 => 14 * 12MHz = 168MHz
    .DIVF(7'd35), // 216MHz*2 // feedback multiplier 0..63 => REF_CLK * 1..64
    //.DIVF(7'd13), // 168MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
    .FILTER_RANGE(3'd1), // low-pass filter before VCO 0..7

    // !!! Must be kept fixed at 2 sharp for low frequencies
    //.DIVQ(3'd2), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64
    .DIVQ(3'd1), // VCO divider 1..6 => "1": 2, "2": 4, "3": 8, "4": 16, "5": 32, "6" = 64
    .DELAY_ADJUSTMENT_MODE_RELATIVE("DYNAMIC"), // output delay

    // 10MHz post-divided is the minimum input; 0 = 12MHz
    .DIVR(4'd0), // input divider 0..15 => 1..16. Because our clock is so low, we should keep it 1 always.
    .SHIFTREG_DIV_MODE(0), // 0 -> divide by 4; 1: divide by 7 => causes non-50% duty cycle
    .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"), // feedback delay does nothing
    .FDA_FEEDBACK(4'b0000), // => not used
    .PLLOUT_SELECT_PORTA("SHIFTREG_90deg"),
    .PLLOUT_SELECT_PORTB("SHIFTREG_0deg"),
    .ENABLE_ICEGATE_PORTA(0),
    .ENABLE_ICEGATE_PORTB(0)
  ) the_pll (
    .PACKAGEPIN(CRYSTAL_12MHZ),
    .PLLOUTGLOBALA(CLK_168_MHZ), // H-tree
    //.PLLOUTGLOBALB(RF_LO_X4_PHASES_0_180_DDR), // H-tree
    //.PLLOUTCOREA(RF_LO_X4_PHASES_90_270_DDR),
    .PLLOUTCOREB(CLK_168_MHZ_270),
    .DYNAMICDELAY({ pll_out_delay_a, 4'b0 }),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    //.BYPASS(1'b1), // test path!
    .LATCHINPUTVALUE(disable_pll),
    .LOCK(),
    .SDI(1'b0),
    .SDO(),
    .SCLK(1'b0)
  );

  wire [1:0] RF4X_SAMPLES;

  // DDR sampler
  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) ddr_sampler_2 (
      .PACKAGE_PIN(DIFF_PINS_32P_31N),
      .INPUT_CLK(CLK_168_MHZ),
      .D_IN_0(RF4X_SAMPLES[0]),
      .D_IN_1(RF4X_SAMPLES[1])
  );

  reg [7:0] samples_even;
  always @(posedge CLK_168_MHZ) begin
    samples_even <= {samples_even[n-1:0], RF4X_SAMPLES[0]};
  end
  reg [7:0] samples_odd;
  always @(negedge CLK_168_MHZ) begin
    samples_odd <= {samples_odd[n-1:0], RF4X_SAMPLES[1]};
  end

  wire CLK_21_MHZ;
  reg [3:0] r21m0 = 8'd0;
  (* keep *) SB_GB htree8 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r21m0[0]), .GLOBAL_BUFFER_OUTPUT (CLK_21_MHZ));
  always @(posedge CLK_168_MHZ) r21m0 <= {r21m0[2:0], ~r21m0[3]};

  reg [15:0] samples_i;
  reg [15:0] samples_q;
  always @(posedge CLK_21_MHZ) begin
    samples_i <= {
      samples_even[7],
      samples_odd [7],
      ~samples_even[6],
      ~samples_odd [6],
      samples_even[5],
      samples_odd [5],
      ~samples_even[4],
      ~samples_odd [4],
      samples_even[3],
      samples_odd [3],
      ~samples_even[2],
      ~samples_odd [2],
      samples_even[1],
      samples_odd [1],
      ~samples_even[0],
      ~samples_odd [0] };
    samples_q <= {
      ~samples_even[7],
      samples_odd [7],
      samples_even[6],
      ~samples_odd [6],
      ~samples_even[5],
      samples_odd [5],
      samples_even[4],
      ~samples_odd [4],
      ~samples_even[3],
      samples_odd [3],
      samples_even[2],
      ~samples_odd [2],
      ~samples_even[1],
      samples_odd [1],
      samples_even[0],
      ~samples_odd [0] };
  end

  localparam CH1_MSB = 48;

  // f / f_clk * 2^bits
  // 88.1MHz
  //reg [CH1_MSB:0] ch1_tune = 49'd109909276620351;
  // 88.097160MHz
  //reg [CH1_MSB:0] ch1_tune = 49'd109833144340936;
  // 88.124555MHz
  reg [CH1_MSB:0] ch1_tune = 49'd110567525958745;
  // 104.1+
  //reg [CH1_MSB:0] ch1_tune = 49'd539572196669882;
  //reg [CH1_MSB:0] ch1_tune = 49'd538823526846113;
  // 84.904MHz
  //reg [CH1_MSB:0] ch1_tune = 49'd24233655137755;
  // 90.233470MHz
  //reg [CH1_MSB:0] ch1_tune = 49'd167101506959674;
  // 92.953952
  //reg [CH1_MSB:0] ch1_tune = 49'd240029850539841;

  reg [CH1_MSB:0] dds_ch1_90;
  reg [CH1_MSB:0] dds_ch1 = 49'd140737488355328; // 2^(bits-2)
  
  always @(posedge CLK_21_MHZ) dds_ch1 <= dds_ch1 + ch1_tune;
  always @(posedge CLK_21_MHZ) dds_ch1_90 <= dds_ch1_90 + ch1_tune;

  // Accumulate every 55 samples of 16 RF points
  //localparam DECIMATOR_INIT = 7'd9;
  localparam DECIMATOR_INIT = 8'd48;
  //localparam DECIMATOR_INIT = 8'd0;
  localparam DECIMATOR_MSB = 7;
  reg [DECIMATOR_MSB:0] decimator = DECIMATOR_INIT;
  always @(posedge CLK_21_MHZ) decimator <= decimator[DECIMATOR_MSB] ? DECIMATOR_INIT : (decimator + 8'd1);

  reg [4:0] sum;
  reg [4:0] sum_iq;
  reg [4:0] sum_qi;
  reg [4:0] sum_qq;
  reg [31:0] samples;
  reg [31:0] samples_q_bb;

  reg [31:0] samples_bb;
  reg [31:0] samples_bb_q;

  localparam SD_DAC_MSB = 34;
  //localparam SD_DAC_MSB = 6;
  localparam SD_DAC_BITS_MINUS_ONE = 33'd0;
  reg [SD_DAC_MSB:0] sd_dac;

  wire [31:0] baseband_i = (
    samples
    - { 27'd0, sum }
    + { 27'd0, sum_qq }
  );

  wire [31:0] baseband_q = (
    samples_q_bb
    //- { 27'd0, sum }
    + { 27'd0, sum_iq }
    + { 27'd0, sum_qi }
    //- { 27'd0, sum }
    //+ { 27'd0, sum_qq }
  );

  always @(posedge CLK_21_MHZ) begin

    samples      <= decimator[DECIMATOR_MSB] ? 32'd0 : baseband_i;
    samples_q_bb <= decimator[DECIMATOR_MSB] ? 32'd0 : baseband_q;
   
    // Once per aggregation, transfer to the bb register
    // (we have tons of time to compute arctan2 approximation)
    samples_bb   <= decimator[DECIMATOR_MSB] ? samples      : samples_bb;
    samples_bb_q <= decimator[DECIMATOR_MSB] ? samples_q_bb : samples_bb_q;

    sum <=
        { 4'd0, samples_i[ 0] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 1] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 2] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 3] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 4] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 5] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 6] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 7] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 8] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[ 9] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[10] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[11] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[12] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[13] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[14] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_i[15] ^ dds_ch1[CH1_MSB] };

    sum_qq <=
        { 4'd0, samples_q[ 0] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 1] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 2] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 3] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 4] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 5] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 6] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 7] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 8] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[ 9] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[10] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[11] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[12] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[13] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[14] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_q[15] ^ dds_ch1_90[CH1_MSB] };

    sum_iq <=
        { 4'd0, samples_i[ 0] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 1] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 2] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 3] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 4] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 5] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 6] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 7] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 8] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[ 9] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[10] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[11] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[12] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[13] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[14] ^ dds_ch1_90[CH1_MSB] }
      + { 4'd0, samples_i[15] ^ dds_ch1_90[CH1_MSB] };

    sum_qi <=
        { 4'd0, samples_q[ 0] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 1] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 2] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 3] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 4] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 5] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 6] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 7] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 8] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[ 9] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[10] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[11] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[12] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[13] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[14] ^ dds_ch1[CH1_MSB] }
      + { 4'd0, samples_q[15] ^ dds_ch1[CH1_MSB] };

  end

  reg [15:0] phase_delta;

  // TODO: 50% duty cycle for arctan2 clock off the BB decimator
  always @(posedge CLK_21_MHZ) begin
    phase_delta <= decimator[DECIMATOR_MSB] ? (
      samples_bb[25:10] * samples_q_bb[25:10]
      -
      samples_bb_q[25:10] * samples[25:10]
    ) : phase_delta;

  end

  reg dac_out;

  always @(posedge CLK_21_MHZ) begin

    //sd_dac <= {2'd0, phase_delta, 16'd0} + 34'd6442450944 +
    //  (dac_out ? 34'd8589934592 : 34'd8589934591);

    sd_dac <= {2'd0, samples_bb} + 34'd6442450944 +
      (dac_out ? 34'd8589934592 : 34'd8589934591);

    dac_out <= sd_dac[SD_DAC_MSB];
       
  end

  assign PIN2 = ~dac_out;

endmodule
