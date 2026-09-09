`timescale 1ns/1ps

module tb_gf_e310_frontend_2g4;
    reg arm = 1'b0;
    reg kill = 1'b1;
    reg tx_pll_locked = 1'b0;
    reg rx_pll_locked = 1'b0;
    reg tx_claim = 1'b0;
    reg logical_tx_channel = 1'b0;
    reg [1:0] rx_use_txrx = 2'b00;

    wire [2:0] tx_bandsel, rx1_bandsel, rx2_bandsel;
    wire [1:0] rx1b, rx1c, rx2b, rx2c;
    wire tx1a, tx1b, tx2a, tx2b;
    wire vctx1v1, vctx1v2, vctx2v1, vctx2v2;
    wire vcrx1v1, vcrx1v2, vcrx2v1, vcrx2v2;
    wire led1tx, led1trxrx, led1rx, led2tx, led2trxrx, led2rx;
    wire tx_rf_active;

    gf_e310_frontend_2g4 dut (
        .arm(arm), .kill(kill),
        .tx_pll_locked(tx_pll_locked),
        .rx_pll_locked(rx_pll_locked),
        .tx_claim(tx_claim),
        .logical_tx_channel(logical_tx_channel),
        .rx_use_txrx(rx_use_txrx),
        .TX_BANDSEL(tx_bandsel),
        .RX1_BANDSEL(rx1_bandsel),
        .RX2_BANDSEL(rx2_bandsel),
        .RX1B_BANDSEL(rx1b), .RX1C_BANDSEL(rx1c),
        .RX2B_BANDSEL(rx2b), .RX2C_BANDSEL(rx2c),
        .TX_ENABLE1A(tx1a), .TX_ENABLE1B(tx1b),
        .TX_ENABLE2A(tx2a), .TX_ENABLE2B(tx2b),
        .VCTXRX1_V1(vctx1v1), .VCTXRX1_V2(vctx1v2),
        .VCTXRX2_V1(vctx2v1), .VCTXRX2_V2(vctx2v2),
        .VCRX1_V1(vcrx1v1), .VCRX1_V2(vcrx1v2),
        .VCRX2_V1(vcrx2v1), .VCRX2_V2(vcrx2v2),
        .LED_TXRX1_TX(led1tx), .LED_TXRX1_RX(led1trxrx),
        .LED_RX1_RX(led1rx),
        .LED_TXRX2_TX(led2tx), .LED_TXRX2_RX(led2trxrx),
        .LED_RX2_RX(led2rx),
        .tx_rf_active(tx_rf_active)
    );

    task automatic require;
        input condition;
        input [8*80-1:0] message;
        begin
            if (!condition) begin
                $display("FAIL: %0s", message);
                $fatal(1);
            end
        end
    endtask

    initial begin
        #1;
        require(tx_bandsel == 3'b000 &&
                rx1_bandsel == 3'b101 && rx2_bandsel == 3'b100 &&
                rx1b == 2'b01 && rx1c == 2'b00 &&
                rx2b == 2'b10 && rx2c == 2'b00,
                "2.4 GHz filter codes");
        require({tx1b,tx1a,tx2b,tx2a} == 4'b0000 &&
                {vctx1v1,vctx1v2,vctx2v1,vctx2v2} == 4'b0000 &&
                {vcrx1v1,vcrx1v2,vcrx2v1,vcrx2v2} == 4'b0000,
                "killed state is not RF closed");

        arm = 1'b1;
        kill = 1'b0;
        tx_pll_locked = 1'b1;
        rx_pll_locked = 1'b1;
        #1;
        require({vcrx1v1,vcrx1v2} == 2'b01 &&
                {vcrx2v1,vcrx2v2} == 2'b01,
                "dedicated RX routing");
        require(led1rx && led2rx && !tx_rf_active,
                "dedicated RX LEDs");

        rx_use_txrx = 2'b11;
        #1;
        require({vcrx1v1,vcrx1v2} == 2'b10 &&
                {vcrx2v1,vcrx2v2} == 2'b10 &&
                {vctx1v1,vctx1v2} == 2'b10 &&
                {vctx2v1,vctx2v2} == 2'b01,
                "shared TX/RX routing");

        tx_claim = 1'b1;
        logical_tx_channel = 1'b0;
        #1;
        require({tx2b,tx2a} == 2'b10 && {tx1b,tx1a} == 2'b00,
                "logical channel zero did not select front end two");
        require({vctx2v1,vctx2v2} == 2'b10 &&
                {vctx1v1,vctx1v2} == 2'b00 && led2tx && !led1tx,
                "front end two TX routing");

        logical_tx_channel = 1'b1;
        #1;
        require({tx1b,tx1a} == 2'b10 && {tx2b,tx2a} == 2'b00,
                "logical channel one did not select front end one");
        require({vctx1v1,vctx1v2} == 2'b01 && led1tx && !led2tx,
                "front end one TX routing");

        tx_pll_locked = 1'b0;
        #1;
        require(!tx_rf_active &&
                {tx1b,tx1a,tx2b,tx2a} == 4'b0000 &&
                {vctx1v1,vctx1v2,vctx2v1,vctx2v2} == 4'b0000 &&
                {vcrx1v1,vcrx1v2,vcrx2v1,vcrx2v2} == 4'b0000,
                "PLL loss did not close RF paths");

        $display("E310_FRONTEND_2G4_SELFTEST_PASS");
        $finish;
    end
endmodule
