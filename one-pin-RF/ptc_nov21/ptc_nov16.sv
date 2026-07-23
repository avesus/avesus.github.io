/* FM Radio SDR receiver
(C) Brian Greenforest 2024
MIT License.
*/


module HanCarlsonInputLayer #(
    parameter WORD_SIZE = 7
) (input wire [WORD_SIZE-1:0] a, input wire [WORD_SIZE-1:0] b,
	input wire clk,
	output reg [WORD_SIZE-1:0] g = 0, output reg [WORD_SIZE-1:0] p = 0);
/*
	always @(posedge clk) begin
		g <= a & b;
		p <= a ^ b;
	end
*/	
	always @(posedge clk) g <=    a & b;
	always @(posedge clk) p <=    a ^ b;

endmodule

module HanCarlsonInnerLayer #(
    parameter WORD_SIZE = 7,
    parameter LAYER = 0
) (input wire [WORD_SIZE-1:0] g_in, input wire [WORD_SIZE-1:0] p_in, input wire [WORD_SIZE-1:0] p_in_passthrough,
	input wire clk,
	output reg [WORD_SIZE-1:0] g_out = 0, output reg [WORD_SIZE-1:0] p_out = 0, output reg [WORD_SIZE-1:0] p_out_passthrough = 0);

	genvar pos;
	generate
		for(pos = 0; pos < WORD_SIZE; pos = pos + 1) begin
			always @(posedge clk) begin
				if (pos[0] && pos > (1 << LAYER)) begin // pos > LAYER * 2) begin // 1,3,... layer 0 : > 0; layer 1: > 2; layer 2: > 4 DEBUG: layer=3, pos = 7
					g_out[pos] <= g_in[pos] | (p_in[pos] & g_in[pos-(1 << LAYER)]);
					p_out[pos] <= p_in[pos] & p_in[pos-(1 << LAYER)];
				end else begin // 0, 2,...
					g_out[pos] <= g_in[pos];
					p_out[pos] <= p_in[pos];
				end
				p_out_passthrough[pos] <= p_in_passthrough[pos];
			end
		end
	endgenerate

endmodule

module HanCarlsonOutputLayer #(
    parameter WORD_SIZE = 7
) (input wire [WORD_SIZE-1:0] g_in, input wire [WORD_SIZE-1:0] p_in, input wire [WORD_SIZE-1:0] p_in_passthrough,
	input wire clk,
	output reg [WORD_SIZE:0] result = 0);
	
	always @(posedge clk) result[0] <= p_in_passthrough[0];
	
	genvar pos;
	generate
		for(pos = 1; pos < WORD_SIZE; pos = pos + 1) begin
			always @(posedge clk) begin
				if (pos[0] && pos > 2) begin // 3, 5, ...
					result[pos] <= (g_in[pos - 1] | (p_in[pos - 1] & g_in[pos - 2])) ^ p_in_passthrough[pos];
				end else begin // 1, 2, 4, 6,... 
					result[pos] <= g_in[pos - 1] ^ p_in_passthrough[pos];
				end
			end
		end
	endgenerate
	
	always @(posedge clk) result[WORD_SIZE] <= g_in[WORD_SIZE - 1] | (p_in[WORD_SIZE - 1] & g_in[WORD_SIZE - 2]);

endmodule

module Adder #(
    parameter WORD_SIZE = 7
) (input wire [WORD_SIZE-1:0] a, input wire [WORD_SIZE-1:0] b,
	input wire clk,
	output wire [WORD_SIZE:0] result);

	localparam INNER_LAYERS = $clog2(WORD_SIZE);
	
	HanCarlsonInputLayer #(.WORD_SIZE(WORD_SIZE)) hc_input_layer(.a(a), .b(b), .clk(clk));
	
	wire [WORD_SIZE-1:0] g [0:INNER_LAYERS];
	wire [WORD_SIZE-1:0] p [0:INNER_LAYERS];
	wire [WORD_SIZE-1:0] p_passthrough [0:INNER_LAYERS];
	
	assign g[0] = hc_input_layer.g;
	assign p[0] = hc_input_layer.p;
	assign p_passthrough[0] = hc_input_layer.p;

	genvar layer;
	generate
		for(layer = 0; layer < INNER_LAYERS; layer = layer + 1) begin
			HanCarlsonInnerLayer #(.LAYER(layer), .WORD_SIZE(WORD_SIZE)) hc_inner_layer_x(
				.g_in(g[layer]), .p_in(p[layer]), .p_in_passthrough(p_passthrough[layer]), .clk(clk),
				.g_out(g[layer + 1]), .p_out(p[layer + 1]), .p_out_passthrough(p_passthrough[layer + 1]));
		end
	endgenerate
	
	HanCarlsonOutputLayer #(.WORD_SIZE(WORD_SIZE)) hc_output_layer(
		.g_in(g[INNER_LAYERS]), .p_in(p[INNER_LAYERS]), .p_in_passthrough(p_passthrough[INNER_LAYERS]), .clk(clk),
		.result(result));

endmodule


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
  //output LED_G,
  //output LED_B,

  // input DIFF_PINS_4P_3N,
  //output wire PIN4,
  //output wire PIN3,

  input DIFF_PINS_32P_31N,

  // Measurement & Debug pins
  // RC-filtered audio Sigma-Delta Ready
  output PIN2,

  output wire RF_OUT

  // High-frequency probes
  //output PIN42,
  //output PIN43,

  //input PIN10
);

  // Reserve all global buffers so that some intermediate short and small fast clock wires
  // do not drive the whole chip's H-tree with all its power consumption and capacitance
  // at super high clock frequency accidentally. Verilog compilers love to waste global buffers.

  assign LED_R = 1'b1;

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

  SB_PLL40_2F_CORE #(
  //SB_PLL40_2F_PAD #(
    .FEEDBACK_PATH("PHASE_AND_DELAY"),
    // Feedback multiplier 0..63 => REF_CLK * 1..64
    // This value plus 1 is the output clock multiplier, i.e. 13 => 14 * 12MHz = 168MHz
    //.DIVF(7'd13), // 168MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
    //.DIVF(7'd27), // 336MHz  // feedback multiplier 0..63 => REF_CLK * 1..64

    // 32 -> 33*12MHz = 396MHz
    .DIVF(7'd32), // 432MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
    //.DIVF(7'd33), // 432MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
    //.DIVF(7'd35), // 432MHz  // feedback multiplier 0..63 => REF_CLK * 1..64

    //.DIVF(7'd17), // 216MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
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
    .REFERENCECLK(CRYSTAL_12MHZ),
    //.PACKAGEPIN(CRYSTAL_12MHZ),
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
      .D_IN_1(RF4X_SAMPLES[0]),
      .D_IN_0(RF4X_SAMPLES[1])
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
  // 104.1+
  //reg [CH1_MSB:0] ch1_tune = 49'd539572196669882;
  //reg [CH1_MSB:0] ch1_tune = 49'd538823526846113;
  // 84.904MHz
  //reg [CH1_MSB:0] ch1_tune = 49'd24233655137755;
  // 90.233470MHz
  //reg [CH1_MSB:0] ch1_tune = 49'd167101506959674;
  // 92.953952
  //reg [CH1_MSB:0] ch1_tune = 49'd240029850539841;


  //reg [CH1_MSB:0] ch1_tune =   49'd239334151625975;
  //reg [CH1_MSB:0] ch1_tune =   49'd344954285744069;
  //reg [CH1_MSB:0] ch1_tune =   49'd58975709406042;
  //reg [CH1_MSB:0] ch1_tune =   49'd141836581121531;
  //reg [CH1_MSB:0] ch1_tune =   49'd238583551688080;
  //reg [CH1_MSB:0] ch1_tune =   49'd240165172985787;
  // 88.124555MHz
  //reg [CH1_MSB:0] ch1_tune = 49'd110567525958745;
  // 92.959
  //reg [CH1_MSB:0] ch1_tune =   49'd240165172985798;

  // 104.159
  //reg [CH1_MSB:0] ch1_tune =   49'd540405148143821;
  // 106.559 good signal
  //reg [CH1_MSB:0] ch1_tune =   49'd604742285677685;
  //reg [CH1_MSB:0] ch1_tune =   49'd540405148143821;

  // 220.7375
  //reg [CH1_MSB:0] ch1_tune =   49'd3665541393140320;
  // 220.7375
  //reg [CH1_MSB:0] ch1_tune =     49'd49388433413583;
  //reg [CH1_MSB:0] ch1_tune =     49'd52293635379089;
  //reg [CH1_MSB:0] ch1_tune =     49'd258587364968019;
  // 217.6125MHz @ 198MHz LO / 8
  //reg [CH1_MSB:0] ch1_tune =     49'd223048163817639; // This  received  ITCnet packet from connected radio

  //reg [CH1_MSB:0] ch1_tune =     49'd235557594146241; // 20.712500 MHz
  //reg [CH1_MSB:0] ch1_tune =     49'd272803272882701; // 23.987500 MHz

  // reg [CH1_MSB:0] ch1_tune =     49'd258587364968022; // 22.737500 MHz Ch  126 220.7375 this received on Nov25 from SV air Base

  //reg [CH1_MSB:0] ch1_tune =     49'd247456309070828; // 21.758750 MHz
  //reg [CH1_MSB:0] ch1_tune =     49'd247697979505377; //21.78MHz 
  //reg [CH1_MSB:0] ch1_tune =     49'd124542157422610; //21.78MHz 

  reg [CH1_MSB:0] ch1_tune =     49'd18054203051643; // offset to 217.5875 from 216MHz

  wire [CH1_MSB:0] QUARTER_REG = 49'd140737488355328; // 2^(bits-2)

  reg [CH1_MSB:0] dds_ch1_90 = 49'd0;
  reg [CH1_MSB:0] dds_ch1 = QUARTER_REG; 

  wire pll_216mhz;
  wire pll_216mhz_90;

  reg [2047:0] johnson_ctr_0;
  always @(posedge CLK_21_MHZ) johnson_ctr_0 <= { johnson_ctr_0[2046:0], ~johnson_ctr_0[2047] };

  //wire rf_modulated = pll_216mhz ^ dds_ch1[CH1_MSB] ^ johnson_ctr_0[0];
  //wire rf_modulated = pll_216mhz ^ dds_ch1[CH1_MSB] ^ johnson_ctr_0[0];
  wire rf_modulated = pll_216mhz ^ johnson_ctr_0[0];
  //wire rf_modulated = johnson_ctr_0[0];
  //wire rf_modulated;
  //assign rf_modulated = johnson_ctr_0[0];

  wire [CH1_MSB:0] new_ch1;
  //Adder #(.WORD_SIZE(CH1_MSB+1)) adder1(.a(dds_ch1), .b(ch1_tune), .clk(CLK_21_MHZ), .result(new_ch1));

  wire [CH1_MSB:0] new_ch1_90;
  //Adder #(.WORD_SIZE(CH1_MSB+1)) adder2(.a(dds_ch1_90), .b(ch1_tune), .clk(CLK_21_MHZ), .result(new_ch1_90));
  
  reg reload = 1'b0;
  always @(posedge CLK_21_MHZ) dds_ch1 <= reload ? QUARTER_REG : dds_ch1 + ch1_tune;
  always @(posedge CLK_21_MHZ) dds_ch1_90 <= reload ? 49'd0 : dds_ch1_90 + ch1_tune;
  //always @(posedge CLK_21_MHZ) dds_ch1 <= reload ? QUARTER_REG : new_ch1;
  //always @(posedge CLK_21_MHZ) dds_ch1_90 <= reload ? 49'd0 : new_ch1_90;

  reg disable_pll_2 = 1'b0;
  reg [3:0] pll_out_delay_a_2 = 4'd0; // 0..15 in 150ps increments (applied even in BYPASS mode)
  SB_PLL40_2F_CORE #(
    .FEEDBACK_PATH("PHASE_AND_DELAY"),
    //.DIVF(7'd9), //  // feedback multiplier 0..63 => REF_CLK * 1..64
    .DIVF(7'd17), // 216MHz  // feedback multiplier 0..63 => REF_CLK * 1..64
    .FILTER_RANGE(3'd1), // low-pass filter before VCO 0..7
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
  ) pll2 (
    //.REFERENCECLK(dds_ch1[CH1_MSB]),
    .REFERENCECLK(CRYSTAL_12MHZ),
    //.PLLOUTCOREA(RF_OUT),
    .PLLOUTCOREA(pll_216mhz_90),
    .PLLOUTCOREB(pll_216mhz),
    .DYNAMICDELAY({ pll_out_delay_a_2, 4'b0 }),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    //.BYPASS(1'b1), // test path!
    .LATCHINPUTVALUE(disable_pll_2),
    .LOCK(),
    .SDI(1'b0),
    .SDO(),
    .SCLK(1'b0)
  );

  wire MODULATED_RF_OUT;

  // pMOS side only
  SB_IO #(
      .PIN_TYPE(6'b101000),
      .IO_STANDARD("SB_LVCMOS"),
      .PULLUP(1'b0)
  ) ddr_io_1 (
      .PACKAGE_PIN(RF_OUT),
      //.INPUT_CLK(CLK_168_MHZ),
      .D_OUT_0(1'b1),
      .OUTPUT_ENABLE(MODULATED_RF_OUT)
      //.D_IN_1(RF4X_SAMPLES[0]),
      //.D_IN_0(RF4X_SAMPLES[1])
  );

  // assign RF_OUT = MODULATED_RF_OUT;

  // assign RF_OUT = rf_modulated;
  // assign RF_OUT = CRYSTAL_12MHZ;
  //assign RF_OUT = pll_216mhz;

/*
  reg btn;
  reg btn2;
  reg btn3;
  always @(posedge CLK_21_MHZ) begin
    if (decimator[DECIMATOR_MSB]) begin
      ch1_tune <= btn3 & btn2 & btn ? ch1_tune + 49'd1 : ch1_tune;
      btn <= ~PIN10;
      btn2 <= btn;
      btn3 <= btn2;
      reload <= btn3 & ~btn2 & ~btn;
    end
  end

*/
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
    + { 27'd0, sum }
    - { 27'd0, sum_qq }
  );

  wire [31:0] baseband_q = (
    samples_q_bb
    - { 27'd0, sum_iq }
    - { 27'd0, sum_qi }
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

  reg half_clk;
  always @(posedge CLK_21_MHZ) half_clk <= ~half_clk;
  reg [15:0] phase_delta;

  // TODO: 50% duty cycle for arctan2 clock off the BB decimator
  always @(posedge half_clk) begin
  //always @(posedge CLK_21_MHZ) begin
    phase_delta <= decimator[DECIMATOR_MSB] ? (
      samples_bb[25:10] * samples_q_bb[25:10]
      -
      samples_bb_q[25:10] * samples[25:10]
    ) : phase_delta;

  end

  reg dac_out = 1'b0;

  reg [32:0] sawtooth = 32'd0;

  reg quarter_clk = 1'b0;

  reg inc_dec = 1'b0;

  wire quantizer;

  always @(posedge half_clk) begin
    quarter_clk <= ~quarter_clk;
  end

  always @(posedge quarter_clk) begin
       //sawtooth <= sawtooth - 32'd848000;
       //sawtooth <= sawtooth + 32'd848000;
       sawtooth <= sawtooth + 32'd148000;
       //sawtooth <= inc_dec ? (sawtooth + 32'd848000) : (sawtooth - 32'd848000);
       //sawtooth <= inc_dec ? (sawtooth + 32'd448000) : (sawtooth - 32'd448000);
       //inc_dec <= inc_dec & (sawtooth > 32'd200_000) ? 1'b0 :
       //  (~inc_dec & (sawtooth < 32'd300000) ? 1'b1 : inc_dec);
  end

  always @(posedge CLK_21_MHZ) begin
   quantizer = sd_dac > 34'd8589934592 ? 1'b1 : 1'b0;
   sd_dac <= (quantizer ? ({2'd0, sawtooth} + sd_dac - 34'd8589934592) :
                         ({2'd0, sawtooth} + sd_dac + 34'd8589934591));
             //+ 34'd6442450944;
   dac_out <= quantizer;

/*
    sd_dac <= {2'd0, sawtooth} + sd_dac + // + 34'd6442450944 +
      // + 34'd6442450944 +
      (~sd_dac[SD_DAC_MSB] ? 34'd0 : 34'd17179869183);
    dac_out <= sd_dac[SD_DAC_MSB];
*/


  end

  //assign PIN42 = 1'b0;
  //assign PIN43 = 1'b0;

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
  assign PIN2 = 1'b0; //~dac_out;

  // 14:0 => 3.333 MHz ish
  // 8:0 => 5.7 MHz ish
  //reg [14:0] j_0 = 15'b0;
  //always @(posedge CLK_21_MHZ) j_0 <= { j_0[13:0], ~j_0[14] };

  reg [3:0] j_0 = 4'b0;
  always @(posedge CLK_21_MHZ) j_0 <= { j_0[2:0], ~j_0[3] };

  reg modltr = 1'b0;
  always @(posedge ~j_0[1]) modltr <= ~modltr;

//  reg [127:0] j2_0 = 128'b0;
//  always @(posedge CLK_21_MHZ) j2_0 <= { j2_0[126:0], ~j2_0[127] };

  // assign MODULATED_RF_OUT = sd_dac[SD_DAC_MSB] ? (j_0[0] ^ pll_216mhz) ^ j2_0[0] : ((j_0[0] ^ ~pll_216mhz) ^ j2_0[0]);
  //assign MODULATED_RF_OUT = j2_0[0] ? (j_0[0] ? pll_216mhz : ~pll_216mhz) : (j_0[0] ? ~pll_216mhz : pll_216mhz);
  //assign MODULATED_RF_OUT = j_0[0] ? pll_216mhz : pll_216mhz_90;

  // Quadrature carrier at 216 +- 6.186MHz = 209.814 MHz and 222.186 MHz
  //wire s216_Q_6_186 = j_0[0] ? pll_216mhz : pll_216mhz_90;


  wire p1 = pll_216mhz;
  wire p2 = pll_216mhz_90;
  wire p3 = ~pll_216mhz;
  wire p4 = ~pll_216mhz_90;

  // wire rfI = quarter_clk ^ j_0[0];
  //wire rfI = j_0[0];
  wire rfI = dac_out;// ^ j_0[0];

  //wire rfQ = dac_out ^ j_0[1];
  //wire rfQ = modltr ^ j_0[1];
  wire rfQ = 1'b0; // quarter_clk;// ^ j_0[1];
  //wire rfQ = inc_dec ^ j_0[1];

  // I = 1 Q = 1 => phase 0

  assign MODULATED_RF_OUT = rfI ? (
    rfQ ? p1 : p4
  ) : (
    rfQ ? p2 : p3
  );


  // assign MODULATED_RF_OUT = dac_out ^ j_0[0] ^ pll_216mhz;
  //assign MODULATED_RF_OUT = dac_out ^ pll_216mhz;

endmodule
