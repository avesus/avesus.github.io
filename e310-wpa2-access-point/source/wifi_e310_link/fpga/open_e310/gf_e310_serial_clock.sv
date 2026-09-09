// Dedicated clock primitive only: 40 * 24 / 3 = 320 MHz, VCO 960 MHz.
// No IP integrator, PS clock change, Linux power-mode change or clock gating.
// Primitive reference: AMD UG953 MMCME2_BASE (2024.2).
`timescale 1ns/1ps
module gf_e310_serial_clock(
    input wire radio_clk,control_clk,reset_request,
    output wire fast_clk,locked
);
    wire feedback,feedback_buffered,fast_unbuffered,raw_locked;
    (* ASYNC_REG="TRUE" *) reg [1:0] locked_sync=0;
    reg seen_lock=0;
    reg [3:0] reset_hold=4'hf;
    always @(posedge control_clk or posedge reset_request)begin
        if(reset_request)begin locked_sync<=0;seen_lock<=0;reset_hold<=4'hf;end
        else begin
            locked_sync<={locked_sync[0],raw_locked};
            reset_hold<={reset_hold[2:0],1'b0};
            if(locked_sync[1])seen_lock<=1;
            else if(seen_lock)begin reset_hold<=4'hf;seen_lock<=0;end
        end
    end
    // UG953 requires reset after loss of LOCKED. This supervisor runs from the
    // independent, existing 100-MHz bus clock, not the possibly stopped RF clock.
    wire mmcm_reset=reset_request || reset_hold[3];
    MMCME2_BASE #(.BANDWIDTH("OPTIMIZED"),.CLKFBOUT_MULT_F(24.0),.DIVCLK_DIVIDE(1),
        .CLKIN1_PERIOD(25.0),.CLKOUT0_DIVIDE_F(3.0),.CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),.REF_JITTER1(0.100),.STARTUP_WAIT("FALSE")) mmcm(
        .CLKIN1(radio_clk),.CLKFBIN(feedback_buffered),.CLKFBOUT(feedback),
        .CLKOUT0(fast_unbuffered),.LOCKED(raw_locked),.RST(mmcm_reset),.PWRDWN(1'b0));
    BUFG feedback_buffer(.I(feedback),.O(feedback_buffered));
    BUFG fast_buffer(.I(fast_unbuffered),.O(fast_clk));
    assign locked=raw_locked && !mmcm_reset;
endmodule
