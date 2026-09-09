// SPDX-License-Identifier: MIT
// Exact E310 external RF-switch settings for the 2.4 GHz Wi-Fi band.
//
// Values are derived from UHD's E31x switch tables.  The E310 swaps logical
// channels: logical channel zero uses physical front end two.  TX bias and the
// TX/RX switch are asserted only while an armed packet path owns the DAC.

`timescale 1ns/1ps

module gf_e310_frontend_2g4 (
    input  wire       arm,
    input  wire       kill,
    input  wire       tx_pll_locked,
    input  wire       rx_pll_locked,
    input  wire       tx_claim,
    input  wire       logical_tx_channel,
    input  wire [1:0] rx_use_txrx,

    output wire [2:0] TX_BANDSEL,
    output wire [2:0] RX1_BANDSEL,
    output wire [2:0] RX2_BANDSEL,
    output wire [1:0] RX1B_BANDSEL,
    output wire [1:0] RX1C_BANDSEL,
    output wire [1:0] RX2B_BANDSEL,
    output wire [1:0] RX2C_BANDSEL,
    output wire       TX_ENABLE1A,
    output wire       TX_ENABLE1B,
    output wire       TX_ENABLE2A,
    output wire       TX_ENABLE2B,
    output wire       VCTXRX1_V1,
    output wire       VCTXRX1_V2,
    output wire       VCTXRX2_V1,
    output wire       VCTXRX2_V2,
    output wire       VCRX1_V1,
    output wire       VCRX1_V2,
    output wire       VCRX2_V1,
    output wire       VCRX2_V2,
    output wire       LED_TXRX1_TX,
    output wire       LED_TXRX1_RX,
    output wire       LED_RX1_RX,
    output wire       LED_TXRX2_TX,
    output wire       LED_TXRX2_RX,
    output wire       LED_RX2_RX,
    output wire       tx_rf_active
);
    // 2.4 GHz is RX LB_B7 and TX LB_2750 in the E31x tables.
    assign TX_BANDSEL = 3'b000;
    assign RX1_BANDSEL = 3'b101;
    assign RX2_BANDSEL = 3'b100;
    assign RX1B_BANDSEL = 2'b01;
    assign RX1C_BANDSEL = 2'b00;
    assign RX2B_BANDSEL = 2'b10;
    assign RX2C_BANDSEL = 2'b00;

    wire rf_ready = arm && !kill && tx_pll_locked && rx_pll_locked;
    assign tx_rf_active = rf_ready && tx_claim;

    // logical channel 0 -> physical front end 2; logical channel 1 -> front
    // end 1.  Low-band TX uses bias code {B,A}=2'b10.
    wire tx_frontend_1 = tx_rf_active && logical_tx_channel;
    wire tx_frontend_2 = tx_rf_active && !logical_tx_channel;
    assign {TX_ENABLE1B, TX_ENABLE1A} =
        tx_frontend_1 ? 2'b10 : 2'b00;
    assign {TX_ENABLE2B, TX_ENABLE2A} =
        tx_frontend_2 ? 2'b10 : 2'b00;

    // VCTXRX codes are asymmetric on the two front ends.
    // Front end 1: TX=01, RX=10. Front end 2: TX=10, RX=01.
    wire [1:0] vctxrx1 = tx_frontend_1 ? 2'b01 :
        ((rf_ready && !tx_rf_active && rx_use_txrx[1]) ? 2'b10 : 2'b00);
    wire [1:0] vctxrx2 = tx_frontend_2 ? 2'b10 :
        ((rf_ready && !tx_rf_active && rx_use_txrx[0]) ? 2'b01 : 2'b00);
    assign {VCTXRX1_V1, VCTXRX1_V2} = vctxrx1;
    assign {VCTXRX2_V1, VCTXRX2_V2} = vctxrx2;

    // Low-band receive selector: 01 routes the dedicated RX connector and 10
    // routes TX/RX.  Both are disconnected while transmitting or killed.
    wire [1:0] vcrx1 = (rf_ready && !tx_rf_active)
        ? (rx_use_txrx[1] ? 2'b10 : 2'b01) : 2'b00;
    wire [1:0] vcrx2 = (rf_ready && !tx_rf_active)
        ? (rx_use_txrx[0] ? 2'b10 : 2'b01) : 2'b00;
    assign {VCRX1_V1, VCRX1_V2} = vcrx1;
    assign {VCRX2_V1, VCRX2_V2} = vcrx2;

    assign LED_TXRX1_TX = tx_frontend_1;
    assign LED_TXRX1_RX = rf_ready && !tx_rf_active && rx_use_txrx[1];
    assign LED_RX1_RX = rf_ready && !tx_rf_active && !rx_use_txrx[1];
    assign LED_TXRX2_TX = tx_frontend_2;
    assign LED_TXRX2_RX = rf_ready && !tx_rf_active && rx_use_txrx[0];
    assign LED_RX2_RX = rf_ready && !tx_rf_active && !rx_use_txrx[0];
endmodule
