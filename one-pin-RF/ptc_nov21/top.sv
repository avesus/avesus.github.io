
module top (
  // 12MHz
  input CLK_PIN,
  output LED_R,
  output LED_G,
  output LED_B,
  input PIN4,
  output PIN2
);

    //SB_GB htree1 (
    //  .USER_SIGNAL_TO_GLOBAL_BUFFER (CLK_PIN),
    //  .GLOBAL_BUFFER_OUTPUT (CLK)
    //);


    localparam N = 27;

    reg [N-1:0] counter;

    always @(posedge CLK) begin
        counter <= counter + 1;
    end

    assign LED_G = counter[N - 1];
    assign LED_B = counter[N - 2];
    assign LED_R = counter[N - 3];

    wire rf2x;

    // 186MHz => /2 => 93MHz
    /*
    SB_PLL40_2F_PAD #(
      .DIVR(4'b0000),
      .DIVF(7'b0111101),
      .DIVQ(3'b010),
      .FILTER_RANGE(3'b001),
      .FEEDBACK_PATH("SIMPLE"),
      .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
      .FDA_FEEDBACK(4'b0000),
      .SHIFTREG_DIV_MODE(2'b00),
      .PLLOUT_SELECT_PORTA("GENCLK"),
      .PLLOUT_SELECT_PORTB("GENCLK_HALF"),
      .ENABLE_ICEGATE_PORTA(1'b0),
      .ENABLE_ICEGATE_PORTB(1'b0)
    ) the_pll (
      // .REFERENCECLK(CLK_PIN),
      .PACKAGEPIN(CLK_PIN),
      .PLLOUTCOREA(rf2x),
      .PLLOUTGLOBALA(),
      .PLLOUTCOREB(),
      .PLLOUTGLOBALB(CLK),
      .EXTFEEDBACK(1'b0),
      .DYNAMICDELAY(8'h00),
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .LATCHINPUTVALUE(1'b0),
      .LOCK(),
      .SDI(1'b0),
      .SDO(),
      .SCLK(1'b0)
    );
  */
    // 100.5MHz => 50.25MHz
    /*
    SB_PLL40_2F_PAD #(
      .DIVR(4'b0000),
      .DIVF(7'b1000010),
      .DIVQ(3'b011),
      .FILTER_RANGE(3'b001),
      .FEEDBACK_PATH("SIMPLE"),
      .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
      .FDA_FEEDBACK(4'b0000),
      .SHIFTREG_DIV_MODE(2'b00),
      .PLLOUT_SELECT_PORTA("GENCLK"),
      .PLLOUT_SELECT_PORTB("GENCLK_HALF"),
      .ENABLE_ICEGATE_PORTA(1'b0),
      .ENABLE_ICEGATE_PORTB(1'b0)
    ) the_pll (
      // .REFERENCECLK(CLK_PIN),
      .PACKAGEPIN(CLK_PIN),
      .PLLOUTCOREA(rf2x),
      .PLLOUTGLOBALA(),
      .PLLOUTCOREB(),
      .PLLOUTGLOBALB(CLK),
      .EXTFEEDBACK(1'b0),
      .DYNAMICDELAY(8'h00),
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .LATCHINPUTVALUE(1'b0),
      .LOCK(),
      .SDI(1'b0),
      .SDO(),
      .SCLK(1'b0)
    );
    */

    // 201MHz => /2 => 100.5MHz FM mono station!
    SB_PLL40_2F_PAD #(
      .DIVR(4'b0000),
      .DIVF(7'b1000010),
      .DIVQ(3'b010),
      .FILTER_RANGE(3'b001),
      .FEEDBACK_PATH("SIMPLE"),
      .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
      .FDA_FEEDBACK(4'b0000),
      .SHIFTREG_DIV_MODE(2'b00),
      .PLLOUT_SELECT_PORTA("GENCLK"),
      .PLLOUT_SELECT_PORTB("GENCLK_HALF"),
      .ENABLE_ICEGATE_PORTA(1'b0),
      .ENABLE_ICEGATE_PORTB(1'b0)
    ) the_pll (
      // .REFERENCECLK(CLK_PIN),
      .PACKAGEPIN(CLK_PIN),
      .PLLOUTCOREA(rf2x),
      .PLLOUTGLOBALA(),
      .PLLOUTCOREB(),
      .PLLOUTGLOBALB(CLK),
      .EXTFEEDBACK(1'b0),
      .DYNAMICDELAY(8'h00),
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .LATCHINPUTVALUE(1'b0),
      .LOCK(),
      .SDI(1'b0),
      .SDO(),
      .SCLK(1'b0)
    );

  wire rf;
  wire rf90;

  SB_IO #(
      .PIN_TYPE(6'b000000),
      .IO_STANDARD("SB_LVDS_INPUT")
  ) io_blk_1 (
      .PACKAGE_PIN(PIN4),
      .INPUT_CLK(rf2x),
      .D_IN_0(rf),
      .D_IN_1(rf90)
  );

  //assign LED_R = rf;
  //assign LED_G = rf90;

    reg [26:0] accum1;
    reg [26:0] accum2;
    reg [26:0] total;

    // reg flip = 1'b0;

    always @(posedge CLK) begin
        accum1 <= accum1 + {25'b0, rf};
        // flip <= ~flip;
    end

    always @(negedge CLK) begin
        accum2 <= accum2 + {25'b0, ~rf};
        // flip <= ~flip;
    end

    always @(posedge counter[1]) begin
        total <= accum1 + accum2;
    end

  // assign PIN2 = 1'b0; //rf; // CLK; //rf;
  //assign PIN2 = total[8]; //rf; // CLK; //rf;
  //assign PIN2 = total[9]; //rf; // CLK; //rf;
  assign PIN2 = total[12]; //rf; // CLK; //rf;

endmodule
