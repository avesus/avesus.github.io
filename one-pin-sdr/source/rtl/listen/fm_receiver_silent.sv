/* FM Radio SDR receiver
(C) Brian Greenforest 2024
MIT License.
*/

// Double buffer deserializer
module DBDESER (input wire DDR_CLK, // 84MHz max
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
module DBDESER_N (input wire DDR_CLK, // 84MHz max
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

  inout DIFF_PINS_4P_3N,
  //output wire PIN4,
  //output wire PIN3,

  //input DIFF_PINS_32P_31N,

  // Measurement & Debug pins
  // RC-filtered audio Sigma-Delta Ready
  inout PIN2,

  // High-frequency probes
  output PIN42,
  output UART_TX,
  input UART_RX,
  inout [3:0] RAM_DATA,
  inout RAM_CLK,RAM_SELECT,
  output PIN43
);

  //assign PIN3 = 1'b0;
  //assign PIN4 = 1'b0;

  assign LED_R = 1'b0;
  assign LED_G = 1'b0;
  assign LED_B = 1'b0;

  // Unconnected historical resource reservations omitted in this working copy.

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
    .DIVF(7'd16), // 204MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
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
  wire bias_sink,bias_arm;wire [2:0] bias_target;wire [23:0] bias_telemetry;wire [12:0] bias_density;

  // DDR sampler
  SB_IO #(
      .PIN_TYPE(6'b101000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) ddr_sampler_2 (
      .PACKAGE_PIN(DIFF_PINS_4P_3N),
      .OUTPUT_ENABLE(bias_sink),.D_OUT_0(1'b0),
      .INPUT_CLK(CLK_168_MHZ),
      .D_IN_0(RF4X_SAMPLES[0]),
      .D_IN_1(RF4X_SAMPLES[1])
  );

  wire [7:0] samples_even;
  (* BEL="X9/Y1/lc0" *) SB_DFF history_even_0(.C(CLK_168_MHZ),.D(RF4X_SAMPLES[0]),.Q(samples_even[0]));
  (* BEL="X9/Y1/lc1" *) SB_DFF history_even_1(.C(CLK_168_MHZ),.D(samples_even[0]),.Q(samples_even[1]));
  (* BEL="X9/Y1/lc2" *) SB_DFF history_even_2(.C(CLK_168_MHZ),.D(samples_even[1]),.Q(samples_even[2]));
  (* BEL="X9/Y1/lc3" *) SB_DFF history_even_3(.C(CLK_168_MHZ),.D(samples_even[2]),.Q(samples_even[3]));
  (* BEL="X9/Y1/lc4" *) SB_DFF history_even_4(.C(CLK_168_MHZ),.D(samples_even[3]),.Q(samples_even[4]));
  (* BEL="X9/Y1/lc5" *) SB_DFF history_even_5(.C(CLK_168_MHZ),.D(samples_even[4]),.Q(samples_even[5]));
  (* BEL="X9/Y1/lc6" *) SB_DFF history_even_6(.C(CLK_168_MHZ),.D(samples_even[5]),.Q(samples_even[6]));
  (* BEL="X9/Y1/lc7" *) SB_DFF history_even_7(.C(CLK_168_MHZ),.D(samples_even[6]),.Q(samples_even[7]));

  wire [7:0] samples_odd;
  (* BEL="X10/Y1/lc0" *) SB_DFFN history_odd_0(.C(CLK_168_MHZ),.D(RF4X_SAMPLES[1]),.Q(samples_odd[0]));
  (* BEL="X10/Y1/lc1" *) SB_DFFN history_odd_1(.C(CLK_168_MHZ),.D(samples_odd[0]),.Q(samples_odd[1]));
  (* BEL="X10/Y1/lc2" *) SB_DFFN history_odd_2(.C(CLK_168_MHZ),.D(samples_odd[1]),.Q(samples_odd[2]));
  (* BEL="X10/Y1/lc3" *) SB_DFFN history_odd_3(.C(CLK_168_MHZ),.D(samples_odd[2]),.Q(samples_odd[3]));
  (* BEL="X10/Y1/lc4" *) SB_DFFN history_odd_4(.C(CLK_168_MHZ),.D(samples_odd[3]),.Q(samples_odd[4]));
  (* BEL="X10/Y1/lc5" *) SB_DFFN history_odd_5(.C(CLK_168_MHZ),.D(samples_odd[4]),.Q(samples_odd[5]));
  (* BEL="X10/Y1/lc6" *) SB_DFFN history_odd_6(.C(CLK_168_MHZ),.D(samples_odd[5]),.Q(samples_odd[6]));
  (* BEL="X10/Y1/lc7" *) SB_DFFN history_odd_7(.C(CLK_168_MHZ),.D(samples_odd[6]),.Q(samples_odd[7]));


  wire CLK_21_MHZ;
  wire [3:0] r21m0;
  (* keep *) SB_GB htree8 (.USER_SIGNAL_TO_GLOBAL_BUFFER (r21m0[3]), .GLOBAL_BUFFER_OUTPUT (CLK_21_MHZ));
  (* keep, BEL="X9/Y5/lc4" *) SB_DFF even_phase_0(.C(CLK_168_MHZ),.D(~r21m0[3]),.Q(r21m0[0]));
(* keep, BEL="X9/Y5/lc5" *) SB_DFF even_phase_1(.C(CLK_168_MHZ),.D(r21m0[0]),.Q(r21m0[1]));
(* keep, BEL="X9/Y5/lc6" *) SB_DFF even_phase_2(.C(CLK_168_MHZ),.D(r21m0[1]),.Q(r21m0[2]));
(* keep, BEL="X9/Y5/lc7" *) SB_DFF even_phase_3(.C(CLK_168_MHZ),.D(r21m0[2]),.Q(r21m0[3]));

  // A word is frozen once per eight RF clocks, on its native edges.
  // The processing-clock rising edge follows three RF clocks later.
  // No periodically cleared accumulator; every RF sample remains in order.
  wire [7:0] even_enable,odd_enable;
  // Same divider sequence on the falling edge, avoiding a half-cycle path
  // from the positive-edge divider through a comparator into the odd bank.
  wire [3:0] odd_phase;
  (* keep, BEL="X10/Y5/lc4" *) SB_DFFN odd_phase_0(.C(CLK_168_MHZ),.D(~odd_phase[3]),.Q(odd_phase[0]));
(* keep, BEL="X10/Y5/lc5" *) SB_DFFN odd_phase_1(.C(CLK_168_MHZ),.D(odd_phase[0]),.Q(odd_phase[1]));
(* keep, BEL="X10/Y5/lc6" *) SB_DFFN odd_phase_2(.C(CLK_168_MHZ),.D(odd_phase[1]),.Q(odd_phase[2]));
(* keep, BEL="X10/Y5/lc7" *) SB_DFFN odd_phase_3(.C(CLK_168_MHZ),.D(odd_phase[2]),.Q(odd_phase[3]));
  gf_capture_enable8 even_en(CLK_168_MHZ,r21m0,even_enable);
  gf_capture_enable8 #(.NEG(1)) odd_en(CLK_168_MHZ,odd_phase,odd_enable);
  wire [7:0] word_even,word_odd;
  wire freeze_even_d0;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux0(.I0(samples_even[0]),.I1(word_even[0]),.I2(even_enable[0]),.I3(1'b0),.O(freeze_even_d0));
  (* keep, BEL="X9/Y2/lc0" *) SB_DFF freeze_even_0(.C(CLK_168_MHZ),.D(freeze_even_d0),.Q(word_even[0]));
  wire freeze_even_d1;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux1(.I0(samples_even[1]),.I1(word_even[1]),.I2(even_enable[1]),.I3(1'b0),.O(freeze_even_d1));
  (* keep, BEL="X9/Y2/lc1" *) SB_DFF freeze_even_1(.C(CLK_168_MHZ),.D(freeze_even_d1),.Q(word_even[1]));
  wire freeze_even_d2;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux2(.I0(samples_even[2]),.I1(word_even[2]),.I2(even_enable[2]),.I3(1'b0),.O(freeze_even_d2));
  (* keep, BEL="X9/Y2/lc2" *) SB_DFF freeze_even_2(.C(CLK_168_MHZ),.D(freeze_even_d2),.Q(word_even[2]));
  wire freeze_even_d3;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux3(.I0(samples_even[3]),.I1(word_even[3]),.I2(even_enable[3]),.I3(1'b0),.O(freeze_even_d3));
  (* keep, BEL="X9/Y2/lc3" *) SB_DFF freeze_even_3(.C(CLK_168_MHZ),.D(freeze_even_d3),.Q(word_even[3]));
  wire freeze_even_d4;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux4(.I0(samples_even[4]),.I1(word_even[4]),.I2(even_enable[4]),.I3(1'b0),.O(freeze_even_d4));
  (* keep, BEL="X9/Y2/lc4" *) SB_DFF freeze_even_4(.C(CLK_168_MHZ),.D(freeze_even_d4),.Q(word_even[4]));
  wire freeze_even_d5;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux5(.I0(samples_even[5]),.I1(word_even[5]),.I2(even_enable[5]),.I3(1'b0),.O(freeze_even_d5));
  (* keep, BEL="X9/Y2/lc5" *) SB_DFF freeze_even_5(.C(CLK_168_MHZ),.D(freeze_even_d5),.Q(word_even[5]));
  wire freeze_even_d6;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux6(.I0(samples_even[6]),.I1(word_even[6]),.I2(even_enable[6]),.I3(1'b0),.O(freeze_even_d6));
  (* keep, BEL="X9/Y2/lc6" *) SB_DFF freeze_even_6(.C(CLK_168_MHZ),.D(freeze_even_d6),.Q(word_even[6]));
  wire freeze_even_d7;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_even_mux7(.I0(samples_even[7]),.I1(word_even[7]),.I2(even_enable[7]),.I3(1'b0),.O(freeze_even_d7));
  (* keep, BEL="X9/Y2/lc7" *) SB_DFF freeze_even_7(.C(CLK_168_MHZ),.D(freeze_even_d7),.Q(word_even[7]));
  wire freeze_odd_d0;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux0(.I0(samples_odd[0]),.I1(word_odd[0]),.I2(odd_enable[0]),.I3(1'b0),.O(freeze_odd_d0));
  (* keep, BEL="X10/Y2/lc0" *) SB_DFFN freeze_odd_0(.C(CLK_168_MHZ),.D(freeze_odd_d0),.Q(word_odd[0]));
  wire freeze_odd_d1;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux1(.I0(samples_odd[1]),.I1(word_odd[1]),.I2(odd_enable[1]),.I3(1'b0),.O(freeze_odd_d1));
  (* keep, BEL="X10/Y2/lc1" *) SB_DFFN freeze_odd_1(.C(CLK_168_MHZ),.D(freeze_odd_d1),.Q(word_odd[1]));
  wire freeze_odd_d2;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux2(.I0(samples_odd[2]),.I1(word_odd[2]),.I2(odd_enable[2]),.I3(1'b0),.O(freeze_odd_d2));
  (* keep, BEL="X10/Y2/lc2" *) SB_DFFN freeze_odd_2(.C(CLK_168_MHZ),.D(freeze_odd_d2),.Q(word_odd[2]));
  wire freeze_odd_d3;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux3(.I0(samples_odd[3]),.I1(word_odd[3]),.I2(odd_enable[3]),.I3(1'b0),.O(freeze_odd_d3));
  (* keep, BEL="X10/Y2/lc3" *) SB_DFFN freeze_odd_3(.C(CLK_168_MHZ),.D(freeze_odd_d3),.Q(word_odd[3]));
  wire freeze_odd_d4;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux4(.I0(samples_odd[4]),.I1(word_odd[4]),.I2(odd_enable[4]),.I3(1'b0),.O(freeze_odd_d4));
  (* keep, BEL="X10/Y2/lc4" *) SB_DFFN freeze_odd_4(.C(CLK_168_MHZ),.D(freeze_odd_d4),.Q(word_odd[4]));
  wire freeze_odd_d5;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux5(.I0(samples_odd[5]),.I1(word_odd[5]),.I2(odd_enable[5]),.I3(1'b0),.O(freeze_odd_d5));
  (* keep, BEL="X10/Y2/lc5" *) SB_DFFN freeze_odd_5(.C(CLK_168_MHZ),.D(freeze_odd_d5),.Q(word_odd[5]));
  wire freeze_odd_d6;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux6(.I0(samples_odd[6]),.I1(word_odd[6]),.I2(odd_enable[6]),.I3(1'b0),.O(freeze_odd_d6));
  (* keep, BEL="X10/Y2/lc6" *) SB_DFFN freeze_odd_6(.C(CLK_168_MHZ),.D(freeze_odd_d6),.Q(word_odd[6]));
  wire freeze_odd_d7;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hacac)) freeze_odd_mux7(.I0(samples_odd[7]),.I1(word_odd[7]),.I2(odd_enable[7]),.I3(1'b0),.O(freeze_odd_d7));
  (* keep, BEL="X10/Y2/lc7" *) SB_DFFN freeze_odd_7(.C(CLK_168_MHZ),.D(freeze_odd_d7),.Q(word_odd[7]));
  reg [15:0] samples_i;
  reg [15:0] samples_q;
  always @(posedge CLK_21_MHZ) begin
    samples_i <= {
      word_even[7],
      word_odd [7],
      ~word_even[6],
      ~word_odd [6],
      word_even[5],
      word_odd [5],
      ~word_even[4],
      ~word_odd [4],
      word_even[3],
      word_odd [3],
      ~word_even[2],
      ~word_odd [2],
      word_even[1],
      word_odd [1],
      ~word_even[0],
      ~word_odd [0] };
    samples_q <= {
      ~word_even[7],
      word_odd [7],
      word_even[6],
      ~word_odd [6],
      ~word_even[5],
      word_odd [5],
      word_even[4],
      ~word_odd [4],
      ~word_even[3],
      word_odd [3],
      word_even[2],
      ~word_odd [2],
      ~word_even[1],
      word_odd [1],
      word_even[0],
      ~word_odd [0] };
  end

  //81 word clocks per full-width complex output sample.
  reg [7:0] decimator=48;
  localparam DECIMATOR_MSB=7;
  wire [7:0] decimator_next;
  gf_resolve #(.W(8)) dec_add(decimator,8'd1,1'b0,decimator_next,);
  always @(posedge CLK_21_MHZ)decimator<=decimator[7]?8'd48:decimator_next;
  assign PIN42 = 1'b0;
  assign PIN43 = 1'b0;

  //assign PIN43 = RF4X_SAMPLES[0];
  //assign PIN43 = RF4X_SAMPLES[1];
  //assign PIN43 = CLK_21_MHZ;
  //assign PIN43 = samples[11];
  // 0 degrees
  //assign PIN43 = dds_ch1[CH1_MSB];
  // 90 degrees
  //assign PIN42 = dds_ch1_90[CH1_MSB];

  // assign PIN2 = samples[11];
  // assign PIN2 = ~sd_dac[SD_DAC_MSB];
  // Output-enable is tied LOW: no sigma-delta signal reaches package pin 2.
  (* keep *) SB_IO #(.PIN_TYPE(6'b101001), .PULLUP(1'b0)) silent_audio_pin (
      .PACKAGE_PIN(PIN2), .OUTPUT_ENABLE(1'b0), .D_OUT_0(1'b0));
  //assign PIN2 = 1'b0;
  //assign PIN43 = ~sd_dac[SD_DAC_MSB];

  wire pcm_tx,sdr_tx,sdr_active;
  reg ram_divide=0;always @(posedge CLK_168_MHZ)ram_divide<=~ram_divide;
  wire RAM_102_MHZ;
  SB_GB ram_clock_buffer(.USER_SIGNAL_TO_GLOBAL_BUFFER(ram_divide),.GLOBAL_BUFFER_OUTPUT(RAM_102_MHZ));
  wire [31:0] listen_i,listen_q;wire listen_valid;
  gf_listen_channel #(.TUNE(49'd99344109427290),.INIT_NIBBLES(52'h14e7227ec9040),.INIT_CARRIES(12'h9c7),.INIT_BIT47(1'b1)) listening(CLK_21_MHZ,samples_i,samples_q,listen_i,listen_q,listen_valid);
  fm_sdr_capture sdr(.clk(CLK_21_MHZ),.fast_clk(RAM_102_MHZ),.rx(UART_RX),.raw_rf(samples_i^16'h3333),
   .i0(listen_i),.q0(listen_q),.i1(32'd0),.q1(32'd0),.boundary(listen_valid),
   .tx(sdr_tx),.active(sdr_active),.RAM_DATA(RAM_DATA),.RAM_CLK(RAM_CLK),.RAM_SELECT(RAM_SELECT));
  assign UART_TX=sdr_active?sdr_tx:pcm_tx;
  //P4 retains transport health counters; its PCM slots are explicit zeros.
  gf_bias_servo bias_controller(CLK_21_MHZ,bias_arm,bias_target,samples_i^16'h3333,bias_sink,bias_telemetry,bias_density);
  fm_uart_stream uart_capture(.bias_target(bias_target),.bias_arm(bias_arm),.bias_telemetry(bias_telemetry),.clk(CLK_21_MHZ),.sdm(1'b0),.discriminator(16'd0),
    .raw_rf(samples_i^16'h3333),.rx(UART_RX),.tx(pcm_tx));
endmodule

// Second simultaneous DDS channel using the published sign/popcount mixer.
// Complete32-bit accumulator outputs are retained. No DSP, LUT waveform ROM,
// sine/cosine arithmetic, or demodulator change. Popcounts are registered trees.
// R:65536 consecutive16-bit raw comparator words. D:8192 simultaneous
// two-channel I/Q snapshots, all four32-bit words preserved per snapshot.
// Each format exports131072 payload bytes after capture at existing115200baud.
module fm_sdr_capture #(parameter BAUD_DIV=221)(
 input wire clk,fast_clk,rx,input wire [15:0] raw_rf,
 input wire [31:0] i0,q0,i1,q1,input wire boundary,
 output wire tx,active,inout [3:0] RAM_DATA,inout RAM_CLK,RAM_SELECT);
 reg rx_meta=1,rx_sync=1,rx_busy=0;
 reg [7:0] rx_div=0,rx_byte=0;reg [3:0] rx_bit=0;
 reg armed=0,capturing=0,sending=0;wire raw_mode=!memory_mode;
 wire compressed_mode=1'b0;reg memory_mode=0;
 wire memory_done;reg memory_next=0;
 wire [13:0] memory_address;wire [31:0] memory_data;wire [3:0] memory_wen;
 wire [31:0] memory_words,memory_events,memory_clock;
 wire [15:0] memory_crc,memory_chunk,memory_chunks,memory_high_water;
 wire memory_pressure;
 gf_psram_rf memory_rf(.clk(clk),.fast_clk(fast_clk),.start(armed&&memory_mode),.next_chunk(memory_next),
  .raw_rf(raw_rf),.listen_i(i0),.listen_q(q0),.listen_valid(boundary),.clocks(clocks),.mem_out({d3,d2,d1,d0}),
  .mem_address(memory_address),.mem_data(memory_data),.mem_wen(memory_wen),
  .chunk_ready(memory_done),.first_clock(memory_clock),.rf_words(memory_words),
  .rf_crc(memory_crc),.events(memory_events),.pressure_stop(memory_pressure),
  .chunk_index(memory_chunk),.chunk_count(memory_chunks),.high_water(memory_high_water),
  .ram_data(RAM_DATA),.ram_clk(RAM_CLK),.ram_select(RAM_SELECT));
 reg [15:0] zero_run=0,compressed_count=0,rf_crc=16'hffff;
 reg [21:0] rf_words=0;
 wire [15:0] zero_next;wire [21:0] rf_words_next;
 gf_resolve #(.W(16)) run_increment(zero_run,16'd1,1'b0,zero_next,);
 gf_resolve #(.W(22)) word_increment(rf_words,22'd1,1'b0,rf_words_next,);
 wire rle_last=rf_words==22'd2097151;
 wire rle_emit=(raw_rf!=0)||(zero_run==16'hffff)||rle_last;
 // CRC over each actual RF input word, before encoding, MSB first.
 function [15:0] crc_word;
  input [15:0] state,data;reg [15:0] c;integer bitno;
  begin c=state;for(bitno=15;bitno>=0;bitno=bitno-1)
   c={c[14:0],1'b0}^((c[15]^data[bitno])?16'h1021:16'd0);
   crc_word=c;end
 endfunction
 wire [31:0] clocks;
 gf_clock_count32 timestamp_count(clk,clocks);
 reg [31:0] sequence=0,packet_sequence=0,first_clock=0;
 reg [15:0] wr_addr=0,rd_addr=0;
 reg [127:0] held=0;reg [1:0] iq_write=0;
 wire writing=capturing&&!memory_mode&&(!compressed_mode||rle_emit);
 reg [1:0] first_phase=0;
 wire second_half=iq_write==1;
 wire [63:0] data_in=compressed_mode?{zero_run,raw_rf,zero_run,raw_rf}:{q0,i0};
 wire [13:0] address=(memory_mode&&capturing)?memory_address:capturing?wr_addr[13:0]:rd_addr[13:0];
 wire [15:0] d0,d1,d2,d3;
 SB_SPRAM256KA ram0(.ADDRESS(address),.DATAIN(memory_mode?memory_data[15:0]:raw_mode?raw_rf:data_in[15:0]),.MASKWREN(4'b1111),.WREN(memory_mode?memory_wen[0]:writing&&(compressed_mode?(wr_addr[14]==1'b0):(!raw_mode||wr_addr[15:14]==0))),.CHIPSELECT(1'b1),.CLOCK(clk),.STANDBY(1'b0),.SLEEP(1'b0),.POWEROFF(1'b1),.DATAOUT(d0));
 SB_SPRAM256KA ram1(.ADDRESS(address),.DATAIN(memory_mode?memory_data[31:16]:raw_mode?raw_rf:data_in[31:16]),.MASKWREN(4'b1111),.WREN(memory_mode?memory_wen[1]:writing&&(compressed_mode?(wr_addr[14]==1'b0):(!raw_mode||wr_addr[15:14]==1))),.CHIPSELECT(1'b1),.CLOCK(clk),.STANDBY(1'b0),.SLEEP(1'b0),.POWEROFF(1'b1),.DATAOUT(d1));
 SB_SPRAM256KA ram2(.ADDRESS(address),.DATAIN(memory_mode?memory_data[15:0]:raw_mode?raw_rf:data_in[47:32]),.MASKWREN(4'b1111),.WREN(memory_mode?memory_wen[2]:writing&&(compressed_mode?(wr_addr[14]==1'b1):(!raw_mode||wr_addr[15:14]==2))),.CHIPSELECT(1'b1),.CLOCK(clk),.STANDBY(1'b0),.SLEEP(1'b0),.POWEROFF(1'b1),.DATAOUT(d2));
 SB_SPRAM256KA ram3(.ADDRESS(address),.DATAIN(memory_mode?memory_data[31:16]:raw_mode?raw_rf:data_in[63:48]),.MASKWREN(4'b1111),.WREN(memory_mode?memory_wen[3]:writing&&(compressed_mode?(wr_addr[14]==1'b1):(!raw_mode||wr_addr[15:14]==3))),.CHIPSELECT(1'b1),.CLOCK(clk),.STANDBY(1'b0),.SLEEP(1'b0),.POWEROFF(1'b1),.DATAOUT(d3));
 wire [15:0] raw_read=rd_addr[15]?(rd_addr[14]?d3:d2):(rd_addr[14]?d1:d0);
 reg [17:0] byte_index=0;reg [7:0] byte_value;
 reg [15:0] checksum=0,sum_shift=0,add_shift=0;
 reg [4:0] add_remaining=0;reg carry=0;
 wire sum_bit=sum_shift[0]^add_shift[0]^carry;
 wire next_carry=(sum_shift[0]&add_shift[0])|(sum_shift[0]&carry)|(add_shift[0]&carry);
 reg [9:0] uart_shift=10'h3ff;reg [3:0] uart_bits=0;reg [7:0] baud_counter=0;
 assign tx=uart_shift[0];assign active=armed||capturing||sending||(uart_bits!=0);
 always @*begin
  byte_value=0;
  case(byte_index)
   0:byte_value=8'ha5;1:byte_value=8'h5a;2:byte_value=memory_mode?8'h4a:compressed_mode?8'h43:raw_mode?8'h52:8'h46;3:byte_value=memory_mode?8'h31:compressed_mode?8'h31:raw_mode?8'h31:8'h32;
   4:byte_value=packet_sequence[7:0];5:byte_value=packet_sequence[15:8];6:byte_value=packet_sequence[23:16];7:byte_value=packet_sequence[31:24];
   8:byte_value=first_clock[7:0];9:byte_value=first_clock[15:8];10:byte_value=first_clock[23:16];11:byte_value=first_clock[31:24];
   12:byte_value=memory_mode?0:compressed_mode?compressed_count[7:0]:0;13:byte_value=memory_mode?0:compressed_mode?compressed_count[15:8]:raw_mode?0:8'h40;14:byte_value=(raw_mode||compressed_mode||memory_mode)?1:2;15:byte_value=memory_mode?32:(raw_mode||compressed_mode)?16:{2'b00,first_phase,4'd3};
   131088:byte_value=memory_mode?memory_words[7:0]:checksum[7:0];
   131089:byte_value=memory_mode?memory_words[15:8]:checksum[15:8];
   131090:byte_value=memory_words[23:16];131091:byte_value=memory_words[31:24];
   131092:byte_value=memory_crc[7:0];131093:byte_value=memory_crc[15:8];
   131094:byte_value={7'd0,memory_pressure};131095:byte_value=0;
   131096:byte_value=memory_events[7:0];131097:byte_value=memory_events[15:8];
   131098:byte_value=memory_events[23:16];131099:byte_value=memory_events[31:24];
   131100:byte_value=memory_chunk[7:0];131101:byte_value=memory_chunk[15:8];
   131102:byte_value=memory_chunks[7:0];131103:byte_value=memory_chunks[15:8];
   131104:byte_value=checksum[7:0];131105:byte_value=checksum[15:8];
   default:if(byte_index>=16&&byte_index<131088)begin
    if(memory_mode)begin
     case({rd_addr[14],byte_index[1:0]})
      0:byte_value=d0[7:0];1:byte_value=d0[15:8];2:byte_value=d1[7:0];3:byte_value=d1[15:8];
      4:byte_value=d2[7:0];5:byte_value=d2[15:8];6:byte_value=d3[7:0];7:byte_value=d3[15:8];
     endcase
    end else if(compressed_mode)begin
     if(byte_index>=131080)case(byte_index[2:0])
      0:byte_value=rf_words[7:0];1:byte_value=rf_words[15:8];2:byte_value={2'd0,rf_words[21:16]};3:byte_value=0;
      4:byte_value=rf_crc[7:0];5:byte_value=rf_crc[15:8];6:byte_value=0;7:byte_value=0;
     endcase
     else if(rd_addr<compressed_count)case({rd_addr[14],byte_index[1:0]})
      0:byte_value=d0[7:0];1:byte_value=d0[15:8];2:byte_value=d1[7:0];3:byte_value=d1[15:8];
      4:byte_value=d2[7:0];5:byte_value=d2[15:8];6:byte_value=d3[7:0];7:byte_value=d3[15:8];
     endcase
    end else if(raw_mode)byte_value=byte_index[0]?raw_read[15:8]:raw_read[7:0];
    else case(byte_index[2:0])
     0:byte_value=d0[7:0];1:byte_value=d0[15:8];2:byte_value=d1[7:0];3:byte_value=d1[15:8];
     4:byte_value=d2[7:0];5:byte_value=d2[15:8];6:byte_value=d3[7:0];7:byte_value=d3[15:8];
    endcase
   end
  endcase
 end
 always @(posedge clk)begin
  rx_meta<=rx;rx_sync<=rx_meta;memory_next<=0;
  if(armed&&(raw_mode||boundary))begin
   armed<=0;capturing<=1;wr_addr<=0;packet_sequence<=sequence;sequence<=explicit_result_1;zero_run<=0;rf_words<=0;rf_crc<=16'hffff;compressed_count<=0;
   first_clock<=explicit_result_2;
  end
  if(capturing)begin
   if(memory_mode)begin
    if(memory_done)begin first_clock<=memory_clock;capturing<=0;sending<=1;rd_addr<=0;byte_index<=0;checksum<=0;end
   end else if(compressed_mode)begin
    rf_words<=rf_words_next;rf_crc<=crc_word(rf_crc,raw_rf);
    if(rle_emit)begin
     zero_run<=0;wr_addr<=explicit_result_3;
     if(wr_addr==32765||rle_last)begin
      compressed_count<=explicit_result_3;capturing<=0;sending<=1;rd_addr<=0;byte_index<=0;checksum<=0;
     end
    end else zero_run<=zero_next;
   end else begin
    if(wr_addr==0)first_phase<=i1[1:0];
    wr_addr<=explicit_result_3;
    if(raw_mode?(wr_addr==65535):(wr_addr==16383))begin
     capturing<=0;sending<=1;rd_addr<=0;byte_index<=0;checksum<=0;
    end
   end
  end
  if(add_remaining!=0)begin
   sum_shift<={sum_bit,sum_shift[15:1]};add_shift<=add_shift>>1;carry<=next_carry;add_remaining<=explicit_result_5;
   if(add_remaining==1)checksum<={sum_bit,sum_shift[15:1]};
  end
  if(uart_bits!=0)begin
   if(baud_counter==BAUD_DIV-1)begin baud_counter<=0;uart_shift<={1'b1,uart_shift[9:1]};uart_bits<=uart_bits-1'b1;end
   else baud_counter<=explicit_result_6;
  end else if(sending)begin
   uart_shift<={1'b1,byte_value,1'b0};uart_bits<=10;baud_counter<=0;
   if(byte_index<(memory_mode?131104:131088))begin sum_shift<=checksum;add_shift<={8'd0,byte_value};add_remaining<=16;carry<=0;end
   if(byte_index>=16&&byte_index<131088&&((compressed_mode||memory_mode)?(byte_index[1:0]==3):raw_mode?byte_index[0]:(byte_index[2:0]==7)))rd_addr<=explicit_result_4;
   if(byte_index==(memory_mode?131105:131089))sending<=0;else byte_index<=explicit_result_7;
  end
  if(!rx_busy)begin if(!rx_sync)begin rx_busy<=1;rx_div<=BAUD_DIV/2-1;rx_bit<=0;end end
  else if(rx_div!=0)rx_div<=explicit_result_8;
  else begin
   rx_div<=BAUD_DIV-1;rx_bit<=rx_bit+1'b1;
   if(rx_bit==0&&rx_sync)rx_busy<=0;
   else if(rx_bit>=1&&rx_bit<=8)rx_byte[rx_bit-1'b1]<=rx_sync;
   else if(rx_bit==9)begin
    rx_busy<=0;
    if(rx_sync&&!active&&(rx_byte==8'h52||rx_byte==8'h45))begin armed<=1;memory_mode<=rx_byte==8'h45;end
    if(rx_sync&&!active&&memory_mode&&rx_byte==8'h4e)begin memory_next<=1;capturing<=1;end
    if(rx_sync&&rx_byte==8'h50)armed<=0;
   end
  end
 end
 wire [31:0] explicit_result_0;
 gf_resolve #(.W(32)) explicit_add_0(clocks,32'd1,1'b0,explicit_result_0,);
 wire [31:0] explicit_result_1;
 gf_resolve #(.W(32)) explicit_add_1(sequence,32'd1,1'b0,explicit_result_1,);
 wire [31:0] explicit_result_2;
 gf_resolve #(.W(32)) explicit_add_2(clocks,32'd1,1'b0,explicit_result_2,);
 wire [15:0] explicit_result_3;
 gf_resolve #(.W(16)) explicit_add_3(wr_addr,16'd1,1'b0,explicit_result_3,);
 wire [15:0] explicit_result_4;
 gf_resolve #(.W(16)) explicit_add_4(rd_addr,16'd1,1'b0,explicit_result_4,);
 wire [4:0] explicit_result_5;
 gf_resolve #(.W(5)) explicit_add_5(add_remaining,5'b11111,1'b0,explicit_result_5,);
 wire [7:0] explicit_result_6;
 gf_resolve #(.W(8)) explicit_add_6(baud_counter,8'd1,1'b0,explicit_result_6,);
 wire [17:0] explicit_result_7;
 gf_resolve #(.W(18)) explicit_add_7(byte_index,18'd1,1'b0,explicit_result_7,);
 wire [7:0] explicit_result_8;
 gf_resolve #(.W(8)) explicit_add_8(rx_div,8'hff,1'b0,explicit_result_8,);
endmodule

// Explicit arithmetic boundary for the numeric receiver. No inferred adders.
// A 3:2 compressor has no carry propagation; carry resolution is separate.
module gf_csa #(parameter W=4)(input wire [W-1:0] a,b,c,
 output wire [W-1:0] s,k);
 assign s=a^b^c;
 assign k=((a&b)|(a&c)|(b&c))<<1;
endmodule

// A UART byte takes >2200 processing clocks. Sixteen serial full-adder
// steps finish its checksum long before the next byte, with no wide path.
module gf_serial_checksum16(input wire clk,clear,start,input wire [7:0] byte_in,
 output reg [15:0] checksum=0);
 reg [15:0] sum=0,valid=0;reg [7:0] addend=0;reg carry=0;
 wire bit_sum=sum[0]^addend[0]^carry;
 wire bit_carry=(sum[0]&addend[0])|(sum[0]&carry)|(addend[0]&carry);
 always @(posedge clk)begin
  if(clear)begin checksum<=0;valid<=0;end
  else if(start)begin sum<=checksum;addend<=byte_in;carry<=0;valid<=16'hffff;end
  else if(valid[0])begin
   sum<={bit_sum,sum[15:1]};addend<=addend>>1;carry<=bit_carry;valid<=valid>>1;
   if(!valid[1])checksum<={bit_sum,sum[15:1]};
  end
 end
endmodule

// Constant DDS: one registered carry boundary per nibble. Host computes the
// initial time skew exactly, so the two output phase bits equal an ordinary
// 49-bit accumulator, with four clocks of advance for the sign fanout tree.
module gf_dds49 #(parameter [48:0] TUNE=0,
 parameter [51:0] INIT_NIBBLES=0,parameter [11:0] INIT_CARRIES=0,
 parameter INIT_BIT47=0)(input wire clk,output wire si,sq);
 reg [51:0] state=INIT_NIBBLES;reg [11:0] carry=INIT_CARRIES;
 reg bit47=INIT_BIT47;
 wire [51:0] tune={3'b0,TUNE};wire [51:0] next_state;wire [12:0] next_carry;
 genvar j;
 generate for(j=0;j<13;j=j+1)begin:nibble
  wire ci;
  if(j==0)assign ci=1'b0;else assign ci=carry[j-1];
  gf_resolve4 step(state[j*4+:4],tune[j*4+:4],ci,next_state[j*4+:4],next_carry[j]);
 end endgenerate
 always @(posedge clk)begin state<=next_state;carry<=next_carry[11:0];bit47<=state[47];end
 assign si=state[48];assign sq=~(state[48]^bit47);
endmodule

// Each registered sign only drives two next-stage registers. Four clocks.
module gf_sign_fanout16(input wire clk,sign_in,output wire [15:0] copies);
 wire [1:0] a;wire [3:0] b;wire [7:0] c;
 genvar j;
 // Keep the physical cells: keep on reg nets alone does not stop opt_merge
 // from merging identical replication registers back into a high-fanout net.
 generate for(j=0;j<2;j=j+1)begin:l0
  (* keep *) SB_DFF ff(.C(clk),.D(sign_in),.Q(a[j]));
 end
 for(j=0;j<4;j=j+1)begin:l1
  (* keep *) SB_DFF ff(.C(clk),.D(a[j/2]),.Q(b[j]));
 end
 for(j=0;j<8;j=j+1)begin:l2
  (* keep *) SB_DFF ff(.C(clk),.D(b[j/2]),.Q(c[j]));
 end
 for(j=0;j<16;j=j+1)begin:l3
  (* keep *) SB_DFF ff(.C(clk),.D(c[j/2]),.Q(copies[j]));
 end endgenerate
endmodule

// Four-bit terminal carry resolver, expressed as full-adder boolean cells.
module gf_resolve4(input wire [3:0] a,b,input wire ci,
 output wire [3:0] s,output wire co);
 wire [4:0] c;assign c[0]=ci;assign co=c[4];
 genvar j;
 generate for(j=0;j<4;j=j+1)begin:bit_cell
  assign s[j]=a[j]^b[j]^c[j];
  assign c[j+1]=(a[j]&b[j])|((a[j]^b[j])&c[j]);
 end endgenerate
endmodule

// Combinational terminal resolver for nonrecursive control/mixer arithmetic.
// Prefix hierarchy operates on four-bit groups, never on an inferred wide +.
module gf_resolve #(parameter W=32)(input wire [W-1:0] a,b,
 input wire ci,output wire [W-1:0] s,output wire co);
 localparam G=(W+3)/4,L=$clog2(G);
 wire [G*4-1:0] aa={{(G*4-W){1'b0}},a},bb={{(G*4-W){1'b0}},b};
 wire [G-1:0] p[0:L],g[0:L];wire [G*4-1:0] result;
 genvar j,k;
 generate for(j=0;j<G;j=j+1)begin:group4
  wire [3:0] pp=aa[j*4+:4]^bb[j*4+:4];wire dummy;
  gf_resolve4 make_g(aa[j*4+:4],bb[j*4+:4],1'b0,,g[0][j]);
  assign p[0][j]=pp[0]&pp[1]&pp[2]&pp[3];
  wire carry_in;
  if(j==0)assign carry_in=ci;
  else assign carry_in=g[L][j-1]|(p[L][j-1]&ci);
  gf_resolve4 finish(aa[j*4+:4],bb[j*4+:4],carry_in,result[j*4+:4],dummy);
 end
 for(k=0;k<L;k=k+1)begin:prefix
  for(j=0;j<G;j=j+1)begin:node
   if(j>=(1<<k))begin
    assign g[k+1][j]=g[k][j]|(p[k][j]&g[k][j-(1<<k)]);
    assign p[k+1][j]=p[k][j]&p[k][j-(1<<k)];
   end else begin assign g[k+1][j]=g[k][j];assign p[k+1][j]=p[k][j];end
  end
 end endgenerate
 assign s=result[W-1:0];
 assign co=(a[W-1]&b[W-1])|((a[W-1]|b[W-1])&~s[W-1]);
endmodule

// Six-cycle population counter: five registered Wallace compression levels
// followed by one registered terminal resolver. Both rows retain all carries.
module gf_pop16_wallace(input wire clk,input wire [15:0] x,
 output reg [4:0] total=0);
 reg [5:0] l10=0;reg [4:0] l11=0;
 reg [1:0] l20=0;reg [4:0] l21=0;reg l22=0;
 reg [1:0] l30=0;reg [2:0] l31=0;reg [1:0] l32=0;
 reg [1:0] l40=0;reg l41=0;reg [2:0] l42=0;
 reg [1:0] l50=0;reg l51=0,l52=0,l53=0;
 wire [4:0] rowa={1'b0,l53,l52,l51,l50[0]},rowb={4'b0,l50[1]};wire [4:0] resolved;
 gf_resolve #(.W(5)) finish(rowa,rowb,1'b0,resolved,);
 genvar j;
 generate for(j=0;j<5;j=j+1)begin:first_level
  always @(posedge clk)begin
   l10[j]<=x[j*3]^x[j*3+1]^x[j*3+2];
   l11[j]<=(x[j*3]&x[j*3+1])|(x[j*3]&x[j*3+2])|(x[j*3+1]&x[j*3+2]);
  end
 end endgenerate
 always @(posedge clk)begin
  l10[5]<=x[15];
  l20<={l10[3]^l10[4]^l10[5],l10[0]^l10[1]^l10[2]};
  l21<={l11[4:3],l11[0]^l11[1]^l11[2],
   (l10[3]&l10[4])|(l10[3]&l10[5])|(l10[4]&l10[5]),
   (l10[0]&l10[1])|(l10[0]&l10[2])|(l10[1]&l10[2])};
  l22<=(l11[0]&l11[1])|(l11[0]&l11[2])|(l11[1]&l11[2]);
  l30<=l20;l31<={l21[4:3],l21[0]^l21[1]^l21[2]};
  l32<={l22,(l21[0]&l21[1])|(l21[0]&l21[2])|(l21[1]&l21[2])};
  l40<=l30;l41<=l31[0]^l31[1]^l31[2];
  l42<={l32,(l31[0]&l31[1])|(l31[0]&l31[2])|(l31[1]&l31[2])};
  l50<=l40;l51<=l41;l52<=l42[0]^l42[1]^l42[2];
  l53<=(l42[0]&l42[1])|(l42[0]&l42[2])|(l42[1]&l42[2]);
  total<=resolved;
 end
endmodule

// Full-width numeric SDR channel. No waveform ROM, DSP or audio SDM.
// 32-bit modulo CIC arithmetic; R=81, N=3, gain=531441. Input is -16..16.
// Four-bit sections register carries; low sections are realigned at output.
module gf_sdr_integrator32 #(parameter INPUT_SKEW=1,OUTPUT_ALIGN=1)(input wire clk,input wire [31:0] x,output wire [31:0] y);
 reg [31:0] a=0;reg [6:0] c=0;wire [31:0] next_a;wire [7:0] next_c;
 genvar j;
 generate for(j=0;j<8;j=j+1)begin:nibble
  wire [3:0] in_n;wire ci;
  if(j==0)assign ci=1'b0;else assign ci=c[j-1];
  if(INPUT_SKEW&&j!=0)begin:input_delay
   reg [j*4-1:0] delay=0;
   always @(posedge clk)delay<=(delay<<4)|x[j*4+:4];
   assign in_n=delay[(j-1)*4+:4];
  end else assign in_n=x[j*4+:4];
  gf_resolve4 step(a[j*4+:4],in_n,ci,next_a[j*4+:4],next_c[j]);
  if(OUTPUT_ALIGN&&j!=7)begin:output_delay
   reg [(7-j)*4-1:0] delay=0;
   always @(posedge clk)delay<=(delay<<4)|a[j*4+:4];
   assign y[j*4+:4]=delay[(6-j)*4+:4];
  end else assign y[j*4+:4]=a[j*4+:4];
 end endgenerate
 always @(posedge clk)begin a<=next_a;c<=next_c[6:0];end
endmodule

// Three cascaded modulo differences, one bit/clock in each registered stage.
// Each stage delays its previous whole word in a rotating32-bit register.
module gf_sdr_comb3(input wire clk,start,input wire [31:0] x,output reg [31:0] y=0);
 reg [31:0] shift=0,previous1=0,previous2=0,previous3=0,assembled=0;
 reg [5:0] remaining=0;wire [5:0] remaining_dec;
 gf_resolve #(.W(6)) count_down(remaining,6'b111111,1'b0,remaining_dec,);
 reg v1=0,v2=0,first1=0,first2=0;
 reg diff1=0,diff2=0,borrow1=0,borrow2=0,borrow3=0;
 wire active=remaining!=0;
 wire first0=remaining==32;
 wire b1=first0?1'b0:borrow1,b2=first1?1'b0:borrow2,b3=first2?1'b0:borrow3;
 wire outbit=diff2^previous3[0]^b3;
 always @(posedge clk)begin
  if(start)begin shift<=x;remaining<=32;end
  else if(active)begin shift<=shift>>1;remaining<=remaining_dec;end
  v1<=active;first1<=active&&first0;v2<=v1;first2<=v1&&first1;
  if(active)begin
   diff1<=shift[0]^previous1[0]^b1;
   borrow1<=(~shift[0]&previous1[0])|(~(shift[0]^previous1[0])&b1);
   previous1<={shift[0],previous1[31:1]};
  end
  if(v1)begin
   diff2<=diff1^previous2[0]^b2;
   borrow2<=(~diff1&previous2[0])|(~(diff1^previous2[0])&b2);
   previous2<={diff1,previous2[31:1]};
  end
  if(v2)begin
   borrow3<=(~diff2&previous3[0])|(~(diff2^previous3[0])&b3);
   previous3<={diff2,previous3[31:1]};assembled<={outbit,assembled[31:1]};
  end
  if(!v2&&v1==0&&remaining==0)y<=assembled;
 end
endmodule

module gf_sdr_cic3(input wire clk,boundary,input wire signed [5:0] x,output wire [31:0] y);
 wire [31:0] s1,s2,s3;
 // All stages use the same nibble-time skew. Align only at the final output.
 gf_sdr_integrator32 #(.INPUT_SKEW(1),.OUTPUT_ALIGN(0)) int1(clk,{{26{x[5]}},x},s1);
 gf_sdr_integrator32 #(.INPUT_SKEW(0),.OUTPUT_ALIGN(0)) int2(clk,s1,s2);
 gf_sdr_integrator32 #(.INPUT_SKEW(0),.OUTPUT_ALIGN(1)) int3(clk,s2,s3);
 gf_sdr_comb3 comb(clk,boundary,s3,y);
endmodule

module gf_sdr_dds_cic3 #(parameter [48:0] TUNE=0,
 parameter [51:0] INIT_NIBBLES=0,parameter [11:0] INIT_CARRIES=0,
 parameter INIT_BIT47=0)(
 input wire clk,boundary,input wire [15:0] rf_i,rf_q,
 output wire [31:0] iq_i,iq_q);
 wire sign_i,sign_q;wire [15:0] signs_i,signs_q;
 gf_dds49 #(.TUNE(TUNE),.INIT_NIBBLES(INIT_NIBBLES),.INIT_CARRIES(INIT_CARRIES),.INIT_BIT47(INIT_BIT47)) dds(clk,sign_i,sign_q);
 gf_sign_fanout16 fi(clk,sign_i,signs_i),fq(clk,sign_q,signs_q);
 reg [15:0] mi=0,mq=0,mqi=0,mqq=0;
 wire [4:0] si,sq,sqi,sqq;
 reg signed [5:0] centered_i=0,centered_q=0;
 gf_pop16_wallace p0(clk,mi,si);gf_pop16_wallace p1(clk,mq,sq);
 gf_pop16_wallace p2(clk,mqi,sqi);gf_pop16_wallace p3(clk,mqq,sqq);
 wire [5:0] next_i,next_q,qs,qk;
 gf_resolve #(.W(6)) subtract_i({1'b0,sqi},~{1'b0,si},1'b1,next_i,);
 gf_csa #(.W(6)) compress_q({1'b0,sq},{1'b0,sqq},6'b110000,qs,qk);
 gf_resolve #(.W(6)) finish_q(qs,qk,1'b0,next_q,);
 always @(posedge clk)begin
  mi<=rf_i^signs_i;mq<=rf_i^signs_q;
  mqi<=rf_q^signs_q;mqq<=rf_q^signs_i;
  centered_i<=next_i;centered_q<=next_q;
 end
 gf_sdr_cic3 ci(clk,boundary,centered_i,iq_i);
 gf_sdr_cic3 cq(clk,boundary,centered_q,iq_q);
endmodule

// Three registered fanout levels. No merged single high-fanout enable net.
module gf_capture_enable8 #(parameter NEG=0)(input clk,input [3:0] phase,output [7:0] copies);
 (* keep *) wire [1:0] a; (* keep *) wire [3:0] b;
 wire [1:0] pulse;
 genvar j;
 generate for(j=0;j<2;j=j+1)begin:decode
  (* keep *) SB_LUT4 #(.LUT_INIT(16'h4000)) lut(.I0(phase[0]),.I1(phase[1]),.I2(phase[2]),.I3(phase[3]),.O(pulse[j]));
 end endgenerate
 generate if(NEG)begin:n
  (* keep, BEL="X10/Y5/lc0" *) SB_DFFN ff_0_0(.C(clk),.D(pulse[0]),.Q(a[0]));
  (* keep, BEL="X10/Y5/lc1" *) SB_DFFN ff_0_1(.C(clk),.D(pulse[1]),.Q(a[1]));
  (* keep, BEL="X10/Y4/lc0" *) SB_DFFN ff_1_0(.C(clk),.D(a[0]),.Q(b[0]));
  (* keep, BEL="X10/Y4/lc1" *) SB_DFFN ff_1_1(.C(clk),.D(a[0]),.Q(b[1]));
  (* keep, BEL="X10/Y4/lc2" *) SB_DFFN ff_1_2(.C(clk),.D(a[1]),.Q(b[2]));
  (* keep, BEL="X10/Y4/lc3" *) SB_DFFN ff_1_3(.C(clk),.D(a[1]),.Q(b[3]));
  (* keep, BEL="X10/Y3/lc0" *) SB_DFFN ff_2_0(.C(clk),.D(b[0]),.Q(copies[0]));
  (* keep, BEL="X10/Y3/lc1" *) SB_DFFN ff_2_1(.C(clk),.D(b[0]),.Q(copies[1]));
  (* keep, BEL="X10/Y3/lc2" *) SB_DFFN ff_2_2(.C(clk),.D(b[1]),.Q(copies[2]));
  (* keep, BEL="X10/Y3/lc3" *) SB_DFFN ff_2_3(.C(clk),.D(b[1]),.Q(copies[3]));
  (* keep, BEL="X10/Y3/lc4" *) SB_DFFN ff_2_4(.C(clk),.D(b[2]),.Q(copies[4]));
  (* keep, BEL="X10/Y3/lc5" *) SB_DFFN ff_2_5(.C(clk),.D(b[2]),.Q(copies[5]));
  (* keep, BEL="X10/Y3/lc6" *) SB_DFFN ff_2_6(.C(clk),.D(b[3]),.Q(copies[6]));
  (* keep, BEL="X10/Y3/lc7" *) SB_DFFN ff_2_7(.C(clk),.D(b[3]),.Q(copies[7]));
 end else begin:p
  (* keep, BEL="X9/Y5/lc0" *) SB_DFF ff_0_0(.C(clk),.D(pulse[0]),.Q(a[0]));
  (* keep, BEL="X9/Y5/lc1" *) SB_DFF ff_0_1(.C(clk),.D(pulse[1]),.Q(a[1]));
  (* keep, BEL="X9/Y4/lc0" *) SB_DFF ff_1_0(.C(clk),.D(a[0]),.Q(b[0]));
  (* keep, BEL="X9/Y4/lc1" *) SB_DFF ff_1_1(.C(clk),.D(a[0]),.Q(b[1]));
  (* keep, BEL="X9/Y4/lc2" *) SB_DFF ff_1_2(.C(clk),.D(a[1]),.Q(b[2]));
  (* keep, BEL="X9/Y4/lc3" *) SB_DFF ff_1_3(.C(clk),.D(a[1]),.Q(b[3]));
  (* keep, BEL="X9/Y3/lc0" *) SB_DFF ff_2_0(.C(clk),.D(b[0]),.Q(copies[0]));
  (* keep, BEL="X9/Y3/lc1" *) SB_DFF ff_2_1(.C(clk),.D(b[0]),.Q(copies[1]));
  (* keep, BEL="X9/Y3/lc2" *) SB_DFF ff_2_2(.C(clk),.D(b[1]),.Q(copies[2]));
  (* keep, BEL="X9/Y3/lc3" *) SB_DFF ff_2_3(.C(clk),.D(b[1]),.Q(copies[3]));
  (* keep, BEL="X9/Y3/lc4" *) SB_DFF ff_2_4(.C(clk),.D(b[2]),.Q(copies[4]));
  (* keep, BEL="X9/Y3/lc5" *) SB_DFF ff_2_5(.C(clk),.D(b[2]),.Q(copies[5]));
  (* keep, BEL="X9/Y3/lc6" *) SB_DFF ff_2_6(.C(clk),.D(b[3]),.Q(copies[6]));
  (* keep, BEL="X9/Y3/lc7" *) SB_DFF ff_2_7(.C(clk),.D(b[3]),.Q(copies[7]));
 end endgenerate
endmodule

// Four RF samples, advancing by two samples: matched sliding I/Q integrals.
// Eight parallel outputs per16-bit RF word. No periodic integration reset.
module gf_pop4_pipe(input clk,input [3:0] x,output reg [2:0] total=0);
 reg s=0,c=0,d=0,lo=0,cy=0,cm=0;
 always @(posedge clk)begin
  s<=x[0]^x[1]^x[2];c<=(x[0]&x[1])|(x[0]&x[2])|(x[1]&x[2]);d<=x[3];
  lo<=s^d;cy<=s&d;cm<=c;
  total<={cm&cy,cm^cy,lo};
 end
endmodule

module gf_interstage4 #(parameter [51:0] INIT_NIBBLES=0,
 parameter [11:0] INIT_CARRIES=0,parameter INIT_BIT47=0,
 parameter SAMPLE_QUADRATURE=0)(
 input clk,input [15:0] rf_i,rf_q,output [63:0] record,
 output reg [1:0] phase_tag=0);
 reg [15:0] previous_i=0,previous_q=0;
 wire [31:0] history_i={previous_i,rf_i},history_q={previous_q,rf_q};
 reg [15:0] raw0=0,raw1=0,raw2=0,raw3=0,raw4=0,raw5=0;
 always @(posedge clk)begin
  previous_i<=rf_i;previous_q<=rf_q;
  raw0<=rf_i^16'h3333;raw1<=raw0;raw2<=raw1;raw3<=raw2;raw4<=raw3;raw5<=raw4;
 end
 // Quarter turn per25.5MHz word =6.375MHz second LO. Each sign quadrant
 // lasts exactly one word / eight204MS/s complex samples. Full49-bit DDS.
 wire sign_i,sign_q;wire [15:0] si,sq;
 // With SAMPLE_QUADRATURE, eight quarter-turns occur inside each word.
 // The word-to-word phase increment is exactly zero modulo 2^49.
 gf_dds49 #(.TUNE(SAMPLE_QUADRATURE?49'd0:49'd140737488355328),.INIT_NIBBLES(INIT_NIBBLES),
  .INIT_CARRIES(INIT_CARRIES),.INIT_BIT47(INIT_BIT47)) dds(clk,sign_i,sign_q);
 gf_sign_fanout16 fi(clk,sign_i,si),fq(clk,sign_q,sq);
 reg [1:0] product_phase=0;
 always @(posedge clk)begin product_phase<={si[0],sq[0]};phase_tag<=product_phase;end
 assign record[63:48]=raw5;
 genvar j;
 generate for(j=0;j<8;j=j+1)begin:lane
  wire [2:0] pop_i,pop_q;
  // Word bit15 is oldest. Windows end at chronological1,3,...15.
  gf_pop4_pipe ip(clk,history_i[17-j*2-:4],pop_i);
  gf_pop4_pipe qp(clk,history_q[17-j*2-:4],pop_q);
  wire [3:0] center_i,center_q;
  gf_resolve4 ic({pop_i,1'b0},4'hc,1'b0,center_i,);
  gf_resolve4 qc({pop_q,1'b0},4'hc,1'b0,center_q,);
  reg [3:0] integ_i=0,integ_q=0;
  always @(posedge clk)begin integ_i<=center_i;integ_q<=center_q;end
  wire [3:0] ii_next,qq_next,iq_next,qi_next;
  // Exact complex rotations, not a held square-wave approximation.
  // Each replicated base sign drives at most two product inputs.
  wire i0=(!SAMPLE_QUADRATURE||j%4==0)?si[2*j]:j%4==1?~sq[2*j]:j%4==2?~si[2*j]:sq[2*j];
  wire q0=(!SAMPLE_QUADRATURE||j%4==0)?sq[2*j]:j%4==1?si[2*j]:j%4==2?~sq[2*j]:~si[2*j];
  wire i1=(!SAMPLE_QUADRATURE||j%4==0)?si[2*j+1]:j%4==1?~sq[2*j+1]:j%4==2?~si[2*j+1]:sq[2*j+1];
  wire q1=(!SAMPLE_QUADRATURE||j%4==0)?sq[2*j+1]:j%4==1?si[2*j+1]:j%4==2?~sq[2*j+1]:~si[2*j+1];
  gf_resolve4 ii_neg(integ_i^{4{i0}},4'd0,i0,ii_next,);
  gf_resolve4 qq_neg(integ_q^{4{q0}},4'd0,q0,qq_next,);
  gf_resolve4 iq_neg(integ_i^{4{q1}},4'd0,q1,iq_next,);
  gf_resolve4 qi_neg(integ_q^{4{i1}},4'd0,i1,qi_next,);
  reg [3:0] ii=0,qq=0,iq=0,qi=0;
  always @(posedge clk)begin ii<=ii_next;qq<=qq_next;iq<=iq_next;qi<=qi_next;end
  wire [4:0] next_i,next_q;
  // F2 consumes only bits3:1 below: bit0 is exactly zero and bit4 is redundant
  // sign extension. Synthesis removes bit4 carry logic; an extra stage here
  // only delays the live four-bit result (physical trial 2026-09-15).
  gf_resolve #(.W(5)) ir({qq[3],qq},~{ii[3],ii},1'b1,next_i,);
  gf_resolve #(.W(5)) qr({iq[3],iq},{qi[3],qi},1'b0,next_q,);
  reg signed [4:0] out_i=0,out_q=0;
  always @(posedge clk)begin out_i<=next_i;out_q<=next_q;end
  // Exact lossless encoding: outputs are even and within[-4,+4].
  // Store value/2 in signed3 bits; no rounding/truncation of information.
  assign record[j*6+:6]={out_q[3:1],out_i[3:1]};
 end endgenerate
endmodule

// APS6404L SPI/quad-word transfers. No QPI mode or flash commands.
// SCK rises on the word-clock falling edge; data changes/samples on its rising
// edge. At25.5MHz each transaction is below the stricter4us CE limit.
// Quad-only APS6404L burst engine: 66/99,38,EB. Exactly32 data bytes.
// Control tokens replace nested serializer state decisions. All shifts are
// literal wiring; the only arithmetic is three-bit word-index increment.
module gf_psram_word #(parameter BURST=1)(input clk,ready,start,input [7:0] command,
 input [23:0] address,input [31:0] write_data,
 output reg busy=0,output reg done=0,output reg [31:0] read_data=0,
 output reg read_valid=0,output reg [3:0] read_index=0,output reg [3:0] word_index=15,
 inout [3:0] ram_data,inout ram_clk,ram_select);
 reg kick=0;
 always @(posedge clk)kick<=start&&ready&&!busy;
 wire [31:0] prepare;
 gf_psram_dup32 prepare_tree(clk,kick,prepare);
 reg [55:0] prefix=0;
 wire [55:0] prefix_in={3'd0,command[7],3'd0,command[6],3'd0,command[5],
  3'd0,command[4],3'd0,command[3],3'd0,command[2],3'd0,command[1],3'd0,command[0],address};
 wire [55:0] prefix_shift={prefix[51:0],4'd0};
 genvar p;
 generate for(p=0;p<56;p=p+1)begin:prefix_bits
  always @(posedge clk)prefix[p]<=prepare[p/2]?prefix_in[p]:prefix_shift[p];
 end endgenerate
 reg reading=0,reset_only=0;
 always @(posedge clk)if(prepare[30])begin
  reading<=command==8'heb;reset_only<=command==8'h66||command==8'h99;
 end
 wire [15:0] read_copies,reset_copies;
 gf_sign_fanout16 read_mode_tree(clk,reading,read_copies);
 gf_sign_fanout16 reset_mode_tree(clk,reset_only,reset_copies);
 reg [7:0] command_token=0;reg [5:0] address_token=0;
 reg [133:0] data_token=0;
 always @(posedge clk)begin
  command_token<={command_token[6:0],prepare[28]};
  address_token<={address_token[4:0],command_token[7]&&!reset_copies[0]};
  data_token<={data_token[132:0],address_token[5]};
 end
 reg finish=0,prefix_end=0,quad_end=0,quad_begin=0;
 always @(posedge clk)begin
  finish<=(command_token[6]&&reset_copies[1])||(data_token[126]&&!read_copies[0])||(data_token[132]&&read_copies[0]);
  prefix_end<=address_token[4]||(command_token[6]&&reset_copies[2]);
  quad_end<=read_copies[1]?address_token[4]:data_token[126];
  quad_begin<=command_token[6]&&!reset_copies[3];
 end
 reg [15:0] cooldown=0;
 always @(posedge clk)begin
  busy<=prepare[29]||(busy&&!finish);
  cooldown<={cooldown[14:0],finish};done<=cooldown[15];
 end
 reg prefix_active=0,command_enable=0,quad_enable=0;
 always @(posedge clk)begin
  prefix_active<=prepare[31]||(prefix_active&&!prefix_end);
  command_enable<=prepare[29]||(command_enable&&!command_token[7]);
  quad_enable<=quad_begin||(quad_enable&&!quad_end);
 end
 // Reload at wire cycles14,22,...70. Two registered reduction levels,
 // five registered fan-out levels, then each data register consumes its leaf.
 reg [3:0] reload_groups=0;reg reload_early=0;
 always @(posedge clk)begin
  reload_groups[0]<=(command_token[6]&&!reset_copies[4])|data_token[0]|data_token[8]|data_token[16];
  reload_groups[1]<=data_token[24]|data_token[32]|data_token[40]|data_token[48];
  reload_groups[2]<=data_token[56]|data_token[64]|data_token[72]|data_token[80];
  reload_groups[3]<=data_token[88]|data_token[96]|data_token[104]|data_token[112];
  reload_early<=|reload_groups;
 end
 wire [31:0] reload;
 gf_psram_dup32 data_load_tree(clk,reload_early,reload);
 reg [31:0] data=0;wire [31:0] data_shift={data[27:0],4'd0};
 generate for(p=0;p<32;p=p+1)begin:data_bits
  always @(posedge clk)data[p]<=reload[p/2]?write_data[p]:data_shift[p];
 end endgenerate
 always @(posedge clk)if(reload[16])word_index<={word_index[3]^(&word_index[2:0]),word_index[2]^(&word_index[1:0]),word_index[1]^word_index[0],~word_index[0]};
  wire [3:0] dout;
 (* keep, BEL="X22/Y1/lc0" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) ram_out_0(.I0(data[28]),.I1(prefix[52]),.I2(prefix_active),.I3(1'b0),.O(dout[0]));
 (* keep, BEL="X22/Y1/lc1" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) ram_out_1(.I0(data[29]),.I1(prefix[53]),.I2(prefix_active),.I3(1'b0),.O(dout[1]));
 (* keep, BEL="X22/Y1/lc2" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) ram_out_2(.I0(data[30]),.I1(prefix[54]),.I2(prefix_active),.I3(1'b0),.O(dout[2]));
 (* keep, BEL="X22/Y1/lc3" *) SB_LUT4 #(.LUT_INIT(16'hcaca)) ram_out_3(.I0(data[31]),.I1(prefix[55]),.I2(prefix_active),.I3(1'b0),.O(dout[3]));

 wire [3:0] oe={quad_enable,quad_enable,quad_enable,command_enable|quad_enable};
 wire [3:0] din;
 reg pin_busy=0;
 always @(posedge clk)pin_busy<=busy;
 SB_IO #(.PIN_TYPE(6'b100000)) sck(.PACKAGE_PIN(ram_clk),
  .OUTPUT_CLK(clk),.CLOCK_ENABLE(1'b1),.OUTPUT_ENABLE(ready),.D_OUT_0(1'b0),.D_OUT_1(pin_busy));
 SB_IO #(.PIN_TYPE(6'b110101)) cs(.PACKAGE_PIN(ram_select),.OUTPUT_CLK(clk),.CLOCK_ENABLE(1'b1),.OUTPUT_ENABLE(ready),.D_OUT_0(busy));
 generate for(p=0;p<4;p=p+1)begin:io
  SB_IO #(.PIN_TYPE(6'b110100)) pad(.PACKAGE_PIN(ram_data[p]),
   .OUTPUT_CLK(clk),.INPUT_CLK(clk),.CLOCK_ENABLE(1'b1),
   .OUTPUT_ENABLE(oe[p]),.D_OUT_0(dout[p]),.D_IN_0(din[p]));
 end endgenerate
 // Free-running input shift avoids a wide capture-enable fanout.
 always @(posedge clk)read_data<={read_data[27:0],din};
 reg [3:0] read_groups=0;reg read_early=0,read_index_enable=0;reg [3:0] next_read_index=0;
 always @(posedge clk)begin
  read_groups[0]<=data_token[13]|data_token[21]|data_token[29]|data_token[37];
  read_groups[1]<=data_token[45]|data_token[53]|data_token[61]|data_token[69];
  read_groups[2]<=data_token[77]|data_token[85]|data_token[93]|data_token[101];
  read_groups[3]<=data_token[109]|data_token[117]|data_token[125]|data_token[133];
  read_early<=|read_groups;
  read_index_enable<=(|read_groups)&&read_copies[3];
  read_valid<=read_early&&read_copies[2];
  // Index is meaningful only with read_valid. Register it freely, removing
  // four loads from the late enable; qualify the counter one cycle earlier.
  read_index<=next_read_index;
  if(read_index_enable)next_read_index<={next_read_index[3]^(&next_read_index[2:0]),next_read_index[2]^(&next_read_index[1:0]),next_read_index[1]^next_read_index[0],~next_read_index[0]};
 end
endmodule

module gf_psram_dup32(input clk,x,output [31:0] y);
 wire [1:0] a;wire [3:0] b;wire [7:0] c;wire [15:0] d;
 genvar i;
 generate for(i=0;i<2;i=i+1)begin:l0
  (* keep *) SB_DFF ff(.C(clk),.D(x),.Q(a[i]));
 end
 for(i=0;i<4;i=i+1)begin:l1
  (* keep *) SB_DFF ff(.C(clk),.D(a[i/2]),.Q(b[i]));
 end
 for(i=0;i<8;i=i+1)begin:l2
  (* keep *) SB_DFF ff(.C(clk),.D(b[i/2]),.Q(c[i]));
 end
 for(i=0;i<16;i=i+1)begin:l3
  (* keep *) SB_DFF ff(.C(clk),.D(c[i/2]),.Q(d[i]));
 end
 for(i=0;i<32;i=i+1)begin:l4
  (* keep *) SB_DFF ff(.C(clk),.D(d[i/2]),.Q(y[i]));
 end endgenerate
endmodule


// A bounded external-RAM test. Write all24 independent addresses BEFORE reading
// them. Four rounds cover serial, quad, crossed modes and complementary data.
// Every actual read word is returned; no pass/fail substitution for the data.
module gf_psram_probe #(parameter BURST=0)(input clk,start,output reg valid=0,output reg done=0,
 output reg [63:0] record=0,inout [3:0] ram_data,inout ram_clk,ram_select);
 reg [18:0] startup=0;wire [18:0] startup_next;
 gf_resolve #(.W(19)) delay_inc(startup,19'd1,1'b0,startup_next,);
 wire ready=startup[18];
 always @(posedge clk)if(!ready)startup<=startup_next;
 reg [3:0] phase=0;
 reg [4:0] index=0;wire [4:0] index_next;
 gf_resolve #(.W(5)) index_inc(index,5'd1,1'b0,index_next,);
 reg [1:0] round=0;
 reg [5:0] wait_count=0;wire [5:0] wait_next;
 gf_resolve #(.W(6)) wait_inc(wait_count,6'd1,1'b0,wait_next,);
 wire [23:0] address=BURST?(index==0?24'd0:index==19?24'h7fffe0:index==20?24'h0003e0:index==21?24'h000420:index==22?24'h7ffc00:index==23?24'h7ffe00:(24'd16<<index)):
  (index==0?24'd0:index==22?24'h7ffffc:index==23?24'h0003fc:(24'd2<<index));
 reg issue=0;reg [7:0] command=0;wire transfer_busy,transfer_done;
 wire [31:0] actual;wire read_valid;wire [2:0] read_index,word_index;
 wire [2:0] write_index=transfer_busy?(word_index+1'b1):3'd0;
 wire [23:0] write_address=BURST?{address[23:5],write_index,2'd0}:address;
 wire [31:0] expected=32'h96e15ca3^{write_address[15:0],write_address[23:8]}^{32{round[1]}};
 wire [23:0] read_address=BURST?{address[23:5],read_index,2'd0}:address;
 gf_psram_word #(.BURST(BURST)) bus(.clk(clk),.ready(ready),.start(issue),.command(command),.address(address),.write_data(expected),
  .busy(transfer_busy),.done(transfer_done),.read_data(actual),.read_valid(read_valid),.read_index(read_index),.word_index(word_index),
  .ram_data(ram_data),.ram_clk(ram_clk),.ram_select(ram_select));
 always @(posedge clk)begin
  valid<=0;done<=0;issue<=0;
  case(phase)
   0:if(start&&ready)begin index<=0;round<=0;phase<=1;end
   1:begin command<=8'h66;issue<=1;phase<=2;end
   2:if(transfer_done)phase<=3;
   3:begin command<=8'h99;issue<=1;phase<=4;end
   4:if(transfer_done)begin phase<=5;wait_count<=0;end
   5:begin wait_count<=wait_next;if(wait_count==63)phase<=6;end
   // Burst traffic stays quad: 32 serial bytes would exceed CE refresh time.
   6:begin command<=(BURST||round[0])?8'h38:8'h02;issue<=1;phase<=7;end
   7:if(transfer_done)begin
    if(index==23)begin index<=0;phase<=8;end
    else begin index<=index_next;phase<=6;end
   end
   8:begin command<=(BURST||(round[0]^round[1]))?8'heb:8'h03;issue<=1;phase<=9;end
   9:begin
    if(read_valid)begin record<={3'd0,(BURST?read_index:3'd0),round,read_address,actual};valid<=1;end
    if(transfer_done)begin
     if(index==23)begin
      index<=0;
      if(round==3)begin phase<=0;done<=1;end
      else begin round<=round+1'b1;phase<=6;end
     end else begin index<=index_next;phase<=8;end
    end
   end
  endcase
 end
endmodule

// Full-band RF retention: exact zero-run events -> SPRAM queue -> quad PSRAM.
// The SPI engine is the same physically checked 32-byte transfer engine.
module gf_psram_rf #(parameter EVENT_BITS=21)(
 input clk,fast_clk,start,next_chunk,input [15:0] raw_rf,input [31:0] clocks,listen_i,listen_q,input listen_valid,
 input [63:0] mem_out,output [13:0] mem_address,
 output [31:0] mem_data,output [3:0] mem_wen,
 output reg chunk_ready=0,output reg [31:0] first_clock=0,
 output [31:0] rf_words,output reg [15:0] rf_crc=16'hffff,
 output [31:0] events,output reg pressure_stop=0,
 output reg [15:0] chunk_index=0,output reg [15:0] chunk_count=0,
 output reg [15:0] high_water=0,
 inout [3:0] ram_data,inout ram_clk,ram_select);
 reg [18:0] startup=0;wire [18:0] startup_next;
 gf_resolve #(.W(19)) start_inc(startup,19'd1,1'b0,startup_next,);
 wire ready=startup[18];always @(posedge clk)if(!ready)startup<=startup_next;
 reg [3:0] state=0;reg acquiring=0,restart=0;
 reg [15:0] zero_run=0;wire [15:0] queue_count;
 reg [25:0] word_count=0;reg [21:0] event_count=0;
 assign rf_words={9'd0,event_count,1'b0};assign events={10'd0,event_count};
 reg [14:0] write_pointer=0,read_pointer=0;
 wire [15:0] zero_next,queue_up,queue_down;
 wire [14:0] write_next,read_next;
 wire [25:0] words_next;wire [21:0] events_next;
 gf_resolve #(.W(16)) z_inc(zero_run,16'd1,1'b0,zero_next,);
 gf_resolve #(.W(16)) q_inc(queue_count,16'd1,1'b0,queue_up,);
 gf_resolve #(.W(16)) q_dec(queue_count,16'hffff,1'b0,queue_down,);
 gf_resolve #(.W(15)) w_inc(write_pointer,15'd1,1'b0,write_next,);
 gf_resolve #(.W(15)) r_inc(read_pointer,15'd1,1'b0,read_next,);
 gf_resolve #(.W(26)) n_inc(word_count,26'd1,1'b0,words_next,);
 gf_resolve #(.W(22)) e_inc(event_count,22'd1,1'b0,events_next,);
 // Bounded to 0.329s or the event limit. Stop on a represented word, never
 // discard a word and continue. Pressure flag identifies shortened records.
 // J1: no compression; each I/Q word is retained exactly.
 reg [2:0] iq_phase=0;
 // Comb outputs are stable from phase36 through the next boundary.
 // Read phases41..44 directly, without a duplicate64-bit holding register.
 wire [15:0] iq_half=iq_phase==1?listen_i[15:0]:iq_phase==2?listen_i[31:16]:iq_phase==3?listen_q[15:0]:listen_q[31:16];
 wire emit=acquiring&&(iq_phase==1||iq_phase==3);
 wire [31:0] encoded=iq_phase==1?listen_i:listen_q;
 wire encoder_idle=iq_phase==0;
 always @(posedge clk)begin
  if(iq_phase!=0)iq_phase<=iq_phase==4?3'd0:iq_phase+3'd1;
  if(acquiring&&listen_valid)iq_phase<=1;
  if(queue_clear)iq_phase<=0;
 end
 function [15:0] crc_word;
  input [15:0] old_crc,data;reg [15:0] c;integer j;
  begin c=old_crc;for(j=15;j>=0;j=j-1)
   c={c[14:0],1'b0}^((c[15]^data[j])?16'h1021:16'd0);
   crc_word=c;end
 endfunction
 reg [4:0] fill=0;reg pending=0,pending_bank=0;reg fill_bank=0,send_bank=0;
 wire filling=(state==6)||(state==7);
 wire padding=filling&&!pending&&!acquiring&&encoder_idle&&queue_count==0&&fill!=0&&fill<16;
 wire buffer_write=filling&&(pending||padding);
 wire [31:0] buffer_data=pending?(pending_bank?mem_out[63:32]:mem_out[31:0]):32'd0;
 wire pop=filling&&(fill<15||(fill==15&&!pending))&&queue_count!=0&&!emit;
 wire queue_clear=(state==0)&&(start||restart)&&ready;
 wire queue_enable=emit||pop||queue_clear;
 genvar qi;
 generate for(qi=0;qi<16;qi=qi+1)begin:queue_bits
  wire selected;
  (* keep *) SB_LUT4 #(.LUT_INIT(16'hcaca)) mux(.I0(queue_down[qi]),.I1(queue_up[qi]),.I2(emit),.I3(1'b0),.O(selected));
  (* keep *) SB_DFFESR ff(.C(clk),.E(queue_enable),.R(queue_clear),.D(selected),.Q(queue_count[qi]));
 end endgenerate
 reg issue=0;reg [7:0] command=0;reg [23:0] bus_address=0;
 wire bus_done,read_valid;wire [31:0] actual;
 gf_psram_mailbox bus(.clk(clk),.fast_clk(fast_clk),.ready(ready),.start(issue),
  .command(command),.address(bus_address),.buffer_write(buffer_write),.buffer_index({fill_bank,fill[3:0]}),.buffer_bank(send_bank),.buffer_data(buffer_data),
  .done(bus_done),.read_data(actual),.read_valid(read_valid),
  .ram_data(ram_data),.ram_clk(ram_clk),.ram_select(ram_select));
 reg [21:0] written=0,read_total=0;
 wire [21:0] written_next,read_total_next;
 gf_resolve #(.W(22)) written_add(written,22'd16,1'b0,written_next,);
 gf_resolve #(.W(22)) total_add(read_total,22'd16,1'b0,read_total_next,);
 reg [15:0] loaded=0;wire [15:0] loaded_next,chunk_next;
 gf_resolve #(.W(16)) loaded_add(loaded,16'd1,1'b0,loaded_next,);
 gf_resolve #(.W(16)) chunk_add(chunk_index,16'd1,1'b0,chunk_next,);
 wire [31:0] rounded_events;
 gf_resolve #(.W(32)) round_chunks(events,32'd32767,1'b0,rounded_events,);
 always @(posedge clk)chunk_count<=rounded_events[30:15];
 reg more_chunks=0;
 always @(posedge clk)more_chunks<=chunk_next<chunk_count;
 wire loading=(state==9&&read_valid)||(state==10&&loaded<32768);
 wire [14:0] access_pointer=loading?loaded[14:0]:emit?write_pointer:read_pointer;
 assign mem_address=access_pointer[13:0];
 assign mem_data=loading?(state==9?actual:32'd0):encoded;
 wire store=loading||emit;
 assign mem_wen=store?(access_pointer[14]?4'b1100:4'b0011):4'b0000;
 always @(posedge clk)begin
  issue<=0;chunk_ready<=0;restart<=state==11&&start;
  if(emit)write_pointer<=write_next;
  else if(pop)read_pointer<=read_next;
  if(queue_count>high_water)high_water<=queue_count;
  if(filling)begin
    pending<=pop;
    if(pop)begin pending<=1;pending_bank<=read_pointer[14];end
    if(pending)begin
     fill<={fill[4]^(&fill[3:0]),fill[3:0]+4'd1};
    end else if(!acquiring&&encoder_idle&&queue_count==0&&fill!=0&&fill<16)begin
     fill<={fill[4]^(&fill[3:0]),fill[3:0]+4'd1};
    end
  end
  if(emit)event_count<=events_next;
  if(acquiring&&iq_phase!=0)begin
   if(rf_words==0)first_clock<=clocks;
   rf_crc<=crc_word(rf_crc,iq_half);
   if(iq_phase==4&&(events>=32'd2097100||queue_count>=32700))begin
    acquiring<=0;if(queue_count>=32700)pressure_stop<=1;
   end
  end
  case(state)
   0:if((start||restart)&&ready)begin
    state<=1;acquiring<=0;zero_run<=0;write_pointer<=0;read_pointer<=0;
    word_count<=0;rf_crc<=16'hffff;event_count<=0;pressure_stop<=0;high_water<=0;
    written<=0;read_total<=0;fill<=0;pending<=0;fill_bank<=0;send_bank<=0;chunk_index<=0;loaded<=0;
   end
   1:begin command<=8'h66;issue<=1;state<=2;end
   2:if(bus_done)state<=3;
   3:begin command<=8'h99;issue<=1;state<=4;end
   4:if(bus_done)state<=5;
   5:begin acquiring<=1;state<=6;end
   6:begin

    if(fill==16)begin
     command<=8'h38;bus_address<={written,2'b00};issue<=1;state<=7;
     send_bank<=fill_bank;fill_bank<=~fill_bank;fill<=0;
    end else if(!acquiring&&encoder_idle&&queue_count==0&&fill==0&&!pending)begin
     read_total<=0;loaded<=0;state<=8;
    end
   end
   7:if(bus_done)begin written<=written_next;state<=6;end
   8:begin
    if(read_total<written)begin command<=8'heb;bus_address<={read_total,2'b00};issue<=1;state<=9;end
    else state<=10;
   end
   9:begin
    if(read_valid)loaded<=loaded_next;
    if(bus_done)begin
     read_total<=read_total_next;
     if(loaded==32768)begin chunk_ready<=1;state<=11;end
     else state<=8;
    end
   end
   10:begin
    if(loaded<32768)loaded<=loaded_next;
    else begin chunk_ready<=1;state<=11;end
   end
   11:begin
    if(next_chunk&&more_chunks)begin chunk_index<=chunk_next;loaded<=0;state<=8;end
    else if(start)begin state<=0;end
   end
  endcase
 end
endmodule

// Stable bundled write data, request/done toggles, and complete read-block
// buffering cross between the25.5MHz RF word clock and102MHz RAM clock.
module gf_psram_mailbox(input clk,fast_clk,ready,start,input [7:0] command,
 input [23:0] address,input buffer_write,input [4:0] buffer_index,input buffer_bank,input [31:0] buffer_data,
 output reg done=0,output reg read_valid=0,output reg [31:0] read_data=0,
 inout [3:0] ram_data,inout ram_clk,ram_select);
 reg request_toggle=0,complete_toggle=0;reg active_bank=0;
 always @(posedge fast_clk)if(fast_start)active_bank<=buffer_bank;
 reg req_meta=0,req_sync=0,req_seen=0,ready_meta=0,ready_sync=0;
 reg done_meta=0,done_sync=0,done_seen=0;
 reg fast_start=0;wire fast_busy,fast_done,fast_valid;
 wire [31:0] fast_data;wire [3:0] fast_read_index,fast_word_index;
 wire [3:0] write_index_next;
 reg [3:0] write_index=0;
 (* keep *) wire ready_request,ready_bus;
 (* keep *) SB_DFF ready_request_copy(.C(fast_clk),.D(ready_sync),.Q(ready_request));
 (* keep *) SB_DFF ready_bus_copy(.C(fast_clk),.D(ready_sync),.Q(ready_bus));
 wire [3:0] prefetch_next={fast_word_index[3]^(&fast_word_index[2:0]),fast_word_index[2]^(&fast_word_index[1:0]),fast_word_index[1]^fast_word_index[0],~fast_word_index[0]};
 always @(posedge fast_clk)write_index<=fast_busy?prefetch_next:4'd0;
 wire [31:0] write_data,replay_data;
 reg replay=0,done_pending=0,replay_wait=0;reg [3:0] replay_index=0;
 genvar half;
 generate for(half=0;half<2;half=half+1)begin:buffers
  SB_RAM40_4K #(.READ_MODE(0),.WRITE_MODE(0)) outbound(
   .RCLK(fast_clk),.RCLKE(1'b1),.RE(1'b1),.RADDR({6'd0,active_bank,write_index}),.RDATA(write_data[half*16+:16]),
   .WCLK(clk),.WCLKE(1'b1),.WE(buffer_write),.WADDR({6'd0,buffer_index}),.MASK(16'd0),.WDATA(buffer_data[half*16+:16]));
  SB_RAM40_4K #(.READ_MODE(0),.WRITE_MODE(0)) inbound(
   .RCLK(clk),.RCLKE(1'b1),.RE(1'b1),.RADDR({7'd0,replay_index}),.RDATA(replay_data[half*16+:16]),
   .WCLK(fast_clk),.WCLKE(1'b1),.WE(fast_valid),.WADDR({7'd0,fast_read_index}),.MASK(16'd0),.WDATA(fast_data[half*16+:16]));
 end endgenerate
 gf_psram_word #(.BURST(1)) bus(.clk(fast_clk),.ready(ready_bus),.start(fast_start),
  .command(command),.address(address),.write_data(write_data),
  .busy(fast_busy),.done(fast_done),.read_data(fast_data),.read_valid(fast_valid),
  .read_index(fast_read_index),.word_index(fast_word_index),
  .ram_data(ram_data),.ram_clk(ram_clk),.ram_select(ram_select));
 always @(posedge fast_clk)begin
  ready_meta<=ready;ready_sync<=ready_meta;
  req_meta<=request_toggle;req_sync<=req_meta;fast_start<=0;
  if(req_sync!=req_seen&&ready_request)begin req_seen<=req_sync;fast_start<=1;end
  if(fast_done)complete_toggle<=~complete_toggle;
 end
 always @(posedge clk)begin
  done<=0;read_valid<=0;
  if(start)request_toggle<=~request_toggle;
  done_meta<=complete_toggle;done_sync<=done_meta;
  if(done_sync!=done_seen)begin
   done_seen<=done_sync;
   if(command==8'heb)begin replay<=1;replay_wait<=1;replay_index<=0;end
   else done<=1;
  end
  if(replay)begin
   if(replay_wait)replay_wait<=0;
   else begin
    read_data<=replay_data;read_valid<=1;replay_index<=replay_index+1'b1;replay_wait<=1;
    if(replay_index==15)begin replay<=0;done_pending<=1;end
   end
  end
  if(done_pending)begin done_pending<=0;done<=1;end
 end
endmodule

// Free-running exact counter. Nibble increments use registered lookahead.
// No wide addition or unregistered wide carry chain.
module gf_clock_count32(input clk,output [31:0] count);
 genvar k,j,level;
 generate for(k=0;k<8;k=k+1)begin:nibble
  localparam LEAVES=k<=1?1:k<=2?2:k<=4?4:8;
  localparam DEPTH=k<=1?1:k<=2?2:k<=4?3:4;
  wire carry_in;
  if(k==0)begin assign carry_in=1'b1;end
  else begin:lookahead
   wire [LEAVES*2-1:1] tree;
   for(j=0;j<LEAVES;j=j+1)begin:leaf
    reg match=0;
    if(j<k)begin
     // At the edge consuming this carry, low bits must have been all ones
     // DEPTH clocks later. Predict against the advancing counter state.
     always @(posedge clk)match<=count[j*4+:4]==(j==0?(15-DEPTH):15);
    end else always @(posedge clk)match<=1'b1;
    assign tree[LEAVES+j]=match;
   end
   for(j=1;j<LEAVES;j=j+1)begin:branch
    reg match=0;
    always @(posedge clk)match<=tree[2*j]&tree[2*j+1];
    assign tree[j]=match;
   end
   assign carry_in=tree[1];
  end
  reg [3:0] value=0;
  wire [3:0] next_value;
  gf_resolve4 step(value,4'd0,carry_in,next_value,);
  always @(posedge clk)value<=next_value;
  assign count[k*4+:4]=value;
 end endgenerate
endmodule

// Bias decisions run solely in FPGA. ADC is not an input to this module.
// Exact rolling sum of 4096 physical comparator bits; no RF data is discarded.
// One 25.5MHz-clock sink pulse at most once per128 clocks. Output defaults OFF.
module gf_bias_servo(input clk,arm,input [2:0] target,input [15:0] raw_rf,
 output reg sink=0,output [23:0] telemetry,output reg [12:0] density=0);
 wire [4:0] pop;
 gf_pop16_wallace population(clk,raw_rf,pop);
 // Nonresetting modulo integral with four delayed snapshots. Window4096 bits,
 // stride1024 bits: all comparator observations contribute.52 history flops.
 reg [12:0] integral=0,previous0=0,previous1=0,previous2=0,previous3=0;
 wire [12:0] next_integral,next_density;
 gf_resolve #(.W(13)) integrate(integral,{8'd0,pop},1'b0,next_integral,);
 gf_resolve #(.W(13)) slide(next_integral,~previous3,1'b1,next_density,);
 reg [8:0] warmup=0;wire [8:0] warmup_next;
 gf_resolve #(.W(9)) warm(warmup,9'd1,1'b0,warmup_next,);
 wire above,below;wire [12:0] unused_high,unused_low;
 reg [12:0] lower=1920,upper=2176;
 always @(posedge clk)case(target)
  3'd0:begin lower<=13'd2125;upper<=13'd2381;end
  3'd1:begin lower<=13'd2330;upper<=13'd2586;end
  3'd2:begin lower<=13'd2534;upper<=13'd2790;end
  3'd3:begin lower<=13'd2739;upper<=13'd2995;end
  3'd4:begin lower<=13'd1920;upper<=13'd2176;end
  3'd5:begin lower<=13'd2944;upper<=13'd3200;end
  3'd6:begin lower<=13'd3520;upper<=13'd3648;end
  3'd7:begin lower<=13'd3149;upper<=13'd3405;end
 endcase
 // Default50% occupancy +/-3.125%; this is bias balance, not proof of good audio.
 gf_resolve #(.W(13)) high_compare(density,~upper,1'b1,unused_high,above);
 gf_resolve #(.W(13)) low_compare(lower,~density,1'b1,unused_low,below);
 reg discharge_requested=0;
 reg [6:0] pulse_phase=0;wire [6:0] pulse_next;
 gf_resolve #(.W(7)) pulse_advance(pulse_phase,7'd1,1'b0,pulse_next,);
 reg [3:0] emitted_mod16=0;
 assign telemetry={4'hb,arm,discharge_requested,sink,(warmup==9'h1ff),target,density};
 always @(posedge clk)begin
  integral<=next_integral;pulse_phase<=pulse_next;
  if(&pulse_phase[5:0])begin
   density<=next_density;previous0<=next_integral;previous1<=previous0;
   previous2<=previous1;previous3<=previous2;
  end
  if(warmup!=9'h1ff)warmup<=warmup_next;
  if(!arm)discharge_requested<=0;
  else if(above)discharge_requested<=1;
  else if(below)discharge_requested<=0;
  // Measured polarity: increasing capacitor voltage increased comparator ones.
  sink<=arm && warmup==9'h1ff && discharge_requested && pulse_phase==0;
  if(sink)emitted_mod16<=emitted_mod16+1'b1;
 end
endmodule

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
   4'd0:huff=10'b0010000000;
   4'd1:huff=10'b0110000001;
   4'd2:huff=10'b1000000101;
   4'd3:huff=10'b1010001011;
   4'd4:huff=10'b1000001101;
   4'd5:huff=10'b1100010111;
   4'd6:huff=10'b1010011011;
   4'd7:huff=10'b1100110111;
   4'd8:huff=10'b1000000011;
   4'd9:huff=10'b1100001111;
   4'd10:huff=10'b1100101111;
   4'd11:huff=10'b1110011111;
   4'd12:huff=10'b1010000111;
   4'd13:huff=10'b1111011111;
   4'd14:huff=10'b1110111111;
   4'd15:huff=10'b1111111111;
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

// Optional listening diagnostic. Matched16-RF-sample integration precedes
// the second DDS. The CIC runs continuously; its integrators never reset.
// Full32-bit I/Q retained; no FPGA audio discriminator or SDM.
module gf_listen_channel #(parameter [48:0] TUNE=0,
 parameter [51:0] INIT_NIBBLES=0,parameter [11:0] INIT_CARRIES=0,
 parameter INIT_BIT47=0)(input clk,input [15:0] rf_i,rf_q,
 output [31:0] iq_i,iq_q,output valid);
 wire [4:0] pi,pq,ci,cq;
 gf_pop16_wallace first_i(clk,rf_i,pi),first_q(clk,rf_q,pq);
 gf_resolve #(.W(5)) center_i(pi,5'b11000,1'b0,ci,);
 gf_resolve #(.W(5)) center_q(pq,5'b11000,1'b0,cq,);
 reg [4:0] integrated_i=0,integrated_q=0;
 always @(posedge clk)begin integrated_i<=ci;integrated_q<=cq;end
 wire sign_i,sign_q;wire [15:0] si,sq;
 gf_dds49 #(.TUNE(TUNE),.INIT_NIBBLES(INIT_NIBBLES),.INIT_CARRIES(INIT_CARRIES),.INIT_BIT47(INIT_BIT47)) dds(clk,sign_i,sign_q);
 gf_sign_fanout16 itree(clk,sign_i,si),qtree(clk,sign_q,sq);
 wire [4:0] ii,qq,iq,qi;
 gf_resolve #(.W(5)) ii_rot(integrated_i^si[4:0],5'd0,si[10],ii,);
 gf_resolve #(.W(5)) qq_rot(integrated_q^sq[4:0],5'd0,sq[10],qq,);
 gf_resolve #(.W(5)) iq_rot(integrated_i^sq[9:5],5'd0,sq[11],iq,);
 gf_resolve #(.W(5)) qi_rot(integrated_q^si[9:5],5'd0,si[11],qi,);
 reg [4:0] ii_hold=0,qq_hold=0,iq_hold=0,qi_hold=0;
 always @(posedge clk)begin ii_hold<=ii;qq_hold<=qq;iq_hold<=iq;qi_hold<=qi;end
 wire [5:0] next_i,next_q;
 gf_resolve #(.W(6)) combine_i({qq_hold[4],qq_hold},~{ii_hold[4],ii_hold},1'b1,next_i,);
 gf_resolve #(.W(6)) combine_q({iq_hold[4],iq_hold},{qi_hold[4],qi_hold},1'b0,next_q,);
 reg signed [5:0] mixed_i=0,mixed_q=0;
 always @(posedge clk)begin mixed_i<=next_i;mixed_q<=next_q;end
 reg [5:0] phase=0;
 always @(posedge clk)phase<={phase[5]^(&phase[4:0]),phase[4]^(&phase[3:0]),phase[3]^(&phase[2:0]),phase[2]^(&phase[1:0]),phase[1]^phase[0],~phase[0]};
 wire boundary=phase==0;
 gf_sdr_cic3 i_filter(clk,boundary,mixed_i,iq_i),q_filter(clk,boundary,mixed_q,iq_q);
 // The32-bit serial comb has finished after36 clocks;40 leaves margin.
 assign valid=phase==40;
endmodule
