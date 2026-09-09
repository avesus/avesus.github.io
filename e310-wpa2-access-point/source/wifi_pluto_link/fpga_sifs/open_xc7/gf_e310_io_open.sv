// SPDX-License-Identifier: LGPL-3.0-or-later
// Open-tool E310 CMOS interface, functionally derived from Ettus e310_io.v.
// Default open flow uses direct BUFG capture because nextpnr-xilinx does not
// expose BUFR as a placeable BEL. USE_RX_BUFR selects the stock regional
// capture clock and BUFR->BUFG arrangement in the native Vivado build.

`timescale 1ns/1ps

module gf_e310_io_open #(
    parameter integer USE_RX_BUFR = 0
) (
    input  wire        areset,
    input  wire        mimo,
    output wire        radio_clk,
    output wire        radio_rst,
    output reg  [11:0] rx_i0,
    output reg  [11:0] rx_q0,
    output reg  [11:0] rx_i1,
    output reg  [11:0] rx_q1,
    output reg         rx_stb,
    input  wire [11:0] tx_i0,
    input  wire [11:0] tx_q0,
    input  wire [11:0] tx_i1,
    input  wire [11:0] tx_q1,
    output reg         tx_stb,
    input  wire        rx_clk,
    input  wire        rx_frame,
    input  wire [11:0] rx_data,
    output wire        tx_clk,
    output wire        tx_frame,
    output wire [11:0] tx_data
);
    wire radio_clock_input;
    wire capture_clk;
    generate
        if (USE_RX_BUFR != 0) begin : g_rx_bufr
            // The native Vivado path can use the stock E310 regional input
            // capture clock, avoiding the global tree's input hold penalty.
            BUFR #(.BUFR_DIVIDE("BYPASS")) capture_buffer (
                .I(rx_clk), .CE(1'b1), .CLR(1'b0), .O(radio_clock_input));
            assign capture_clk = radio_clock_input;
        end else begin : g_rx_global
            assign radio_clock_input = rx_clk;
            assign capture_clk = radio_clk;
        end
    endgenerate
    BUFG radio_clock_buffer (.I(radio_clock_input), .O(radio_clk));

    synchronizer #(.STAGES(3), .INITIAL_VAL(1'b1)) radio_reset_sync (
        .clk(radio_clk), .rst(areset), .in(1'b0), .out(radio_rst));
    wire mimo_sync;
    synchronizer mimo_mode_sync (
        .clk(radio_clk), .rst(radio_rst), .in(mimo), .out(mimo_sync));

    wire [11:0] rx_i;
    wire [11:0] rx_q;
    genvar bit_index;
    generate
        for (bit_index = 0; bit_index < 12; bit_index = bit_index + 1) begin : rx_ddr
            IDDR #(.DDR_CLK_EDGE("SAME_EDGE")) input_ddr (
                .C(capture_clk), .CE(1'b1), .R(1'b0), .S(1'b0),
                .D(rx_data[bit_index]),
                .Q1(rx_q[bit_index]), .Q2(rx_i[bit_index]));
        end
    endgenerate

    wire rx_frame_rising;
    wire rx_frame_falling;
    IDDR #(.DDR_CLK_EDGE("SAME_EDGE")) frame_input_ddr (
        .C(capture_clk), .CE(1'b1), .R(1'b0), .S(1'b0),
        .D(rx_frame), .Q1(rx_frame_rising), .Q2(rx_frame_falling));

    always @(posedge radio_clk or posedge radio_rst) begin
        if (radio_rst) begin
            rx_stb <= 1'b0;
            rx_i0 <= 12'd0;
            rx_q0 <= 12'd0;
            rx_i1 <= 12'd0;
            rx_q1 <= 12'd0;
        end else if (mimo_sync) begin
            if (rx_frame_rising) begin
                rx_i0 <= rx_i;
                rx_q0 <= rx_q;
            end else begin
                rx_i1 <= rx_i;
                rx_q1 <= rx_q;
            end
            rx_stb <= ~rx_frame_rising;
        end else begin
            rx_i0 <= rx_i;
            rx_q0 <= rx_q;
            rx_i1 <= rx_i;
            rx_q1 <= rx_q;
            rx_stb <= 1'b1;
        end
    end

    reg [11:0] tx_i = 12'd0;
    reg [11:0] tx_q = 12'd0;
    reg tx_frame_internal = 1'b1;

    // Match the stock E310 AD9361 source-synchronous output exactly. Each
    // pin uses its I/O-site ODDR: I on the rising edge, Q on the falling edge,
    // with a same-domain forwarded clock. The open nextpnr database includes
    // the fixed OUTFF -> OMUX -> IOB path required by these primitives.
    generate
        for (bit_index = 0; bit_index < 12; bit_index = bit_index + 1) begin : tx_ddr
            ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) output_ddr (
                .C(radio_clk), .CE(1'b1), .R(1'b0), .S(1'b0),
                .D1(tx_i[bit_index]), .D2(tx_q[bit_index]),
                .Q(tx_data[bit_index]));
        end
    endgenerate

    ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) frame_output_ddr (
        .C(radio_clk), .CE(1'b1), .R(1'b0), .S(1'b0),
        .D1(tx_frame_internal), .D2(tx_frame_internal & mimo_sync),
        .Q(tx_frame));

    ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) clock_output_ddr (
        .C(radio_clk), .CE(1'b1), .R(1'b0), .S(1'b0),
        .D1(1'b1), .D2(1'b0), .Q(tx_clk));

    reg [11:0] tx_i1_hold = 12'd0;
    reg [11:0] tx_q1_hold = 12'd0;
    always @(posedge radio_clk or posedge radio_rst) begin
        if (radio_rst) begin
            tx_stb <= 1'b0;
            tx_frame_internal <= 1'b1;
            tx_i <= 12'd0;
            tx_q <= 12'd0;
            tx_i1_hold <= 12'd0;
            tx_q1_hold <= 12'd0;
        end else if (mimo_sync) begin
            tx_stb <= ~tx_stb;
            tx_frame_internal <= tx_stb;
            if (tx_stb) begin
                tx_i <= tx_i0;
                tx_q <= tx_q0;
                tx_i1_hold <= tx_i1;
                tx_q1_hold <= tx_q1;
            end else begin
                tx_i <= tx_i1_hold;
                tx_q <= tx_q1_hold;
            end
        end else begin
            tx_stb <= 1'b1;
            tx_frame_internal <= 1'b1;
            if ({tx_i0, tx_q0} != 24'd0) begin
                tx_i <= tx_i0;
                tx_q <= tx_q0;
            end else begin
                tx_i <= tx_i1;
                tx_q <= tx_q1;
            end
        end
    end

    wire unused_rx_frame_falling = rx_frame_falling;
endmodule
