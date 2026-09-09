`timescale 1ns/1ps

module tb_gf_e310_gp0_regs #(parameter integer HOST_WAVEFORM=0, TX_BLOCK_RAM=0, COUNTERS_TO_SOFTWARE=0, RX_FIFO_BLOCK_RAM=0, PEAKS_TO_SOFTWARE=0);
    reg bus_clk = 1'b0;
    reg radio_clk = 1'b0;
    always #5 bus_clk = ~bus_clk;
    always #12.5 radio_clk = ~radio_clk;

    reg bus_reset = 1'b1;
    reg radio_reset = 1'b1;
    reg bus_write = 1'b0;
    reg [11:0] bus_write_address = 12'd0;
    reg [31:0] bus_write_data = 32'd0;
    reg [3:0] bus_write_strobe = 4'hf;
    reg bus_read = 1'b0;
    reg [11:0] bus_read_address = 12'd0;
    wire [31:0] bus_read_data;

    reg radio_path_ready = 1'b1;
    wire radio_arm, radio_kill;
    wire [47:0] radio_ap_mac;
    wire radio_channel;
    wire [1:0] radio_rx_use_txrx;
    wire radio_tx_commit;
    wire [11:0] radio_tx_length;
    reg [11:0] radio_tx_read_address = 12'd0;
    wire [7:0] radio_tx_read_data;
    reg radio_tx_busy = 1'b0;
    reg radio_tx_done = 1'b0;
    reg radio_tx_error = 1'b0;

    reg psdu_start = 1'b0;
    reg psdu_byte_valid = 1'b0;
    reg [7:0] psdu_byte = 8'd0;
    reg psdu_byte_last = 1'b0;

    gf_e310_gp0_regs #(.USE_HOST_WAVEFORM(HOST_WAVEFORM),.USE_TX_BLOCK_RAM(TX_BLOCK_RAM),
                      .COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE),.RX_FIFO_BLOCK_RAM(RX_FIFO_BLOCK_RAM),
                      .PEAKS_TO_SOFTWARE(PEAKS_TO_SOFTWARE)) dut (
        .bus_clk(bus_clk), .bus_reset(bus_reset),
        .bus_write(bus_write), .bus_write_address(bus_write_address),
        .bus_write_data(bus_write_data),
        .bus_write_strobe(bus_write_strobe),
        .bus_read(bus_read), .bus_read_address(bus_read_address),
        .bus_read_data(bus_read_data),
        .radio_clk(radio_clk), .radio_reset(radio_reset),
        .radio_path_ready(radio_path_ready),
        .radio_arm(radio_arm), .radio_kill(radio_kill),
        .radio_ap_mac(radio_ap_mac),
        .radio_logical_tx_channel(radio_channel),
        .radio_rx_use_txrx(radio_rx_use_txrx),
        .radio_tx_commit(radio_tx_commit),
        .radio_tx_length(radio_tx_length),
        .radio_tx_read_address(radio_tx_read_address),
        .radio_tx_read_data(radio_tx_read_data),
        .radio_tx_busy(radio_tx_busy),
        .radio_tx_done(radio_tx_done),
        .radio_tx_error(radio_tx_error),
        .psdu_start(psdu_start),
        .psdu_byte_valid(psdu_byte_valid),
        .psdu_byte(psdu_byte), .psdu_byte_last(psdu_byte_last),
        .response_pending(1'b0), .response_active(1'b0),
        .tx_override_valid(1'b0), .mode_fault(1'b0),
        .rx_psdu_count(32'd7), .response_count(32'd3),
        .deadline_miss_count(32'd0), .rejected_count(32'd1),
        .rx_sample_valid(1'b0), .rx_sample_iq(32'd0), .rx_capture_veto(1'b0),
        .rx_sfd_count(32'd0), .rx_plcp_ok_count(32'd0), .rx_plcp_error_count(32'd0)
    );

    task automatic write_register;
        input [11:0] address;
        input [31:0] value;
        begin
            @(negedge bus_clk);
            bus_write_address = address;
            bus_write_data = value;
            bus_write = 1'b1;
            @(negedge bus_clk);
            bus_write = 1'b0;
        end
    endtask

    task automatic read_register;
        input [11:0] address;
        output [31:0] value;
        begin
            @(negedge bus_clk);
            bus_read_address = address;
            bus_read = 1'b1;
            #1 value = bus_read_data;
            @(negedge bus_clk);
            bus_read = 1'b0;
        end
    endtask

    task automatic push_psdu_byte;
        input [7:0] value;
        input first;
        input last;
        begin
            @(negedge radio_clk);
            psdu_byte = value;
            psdu_start = first;
            psdu_byte_last = last;
            psdu_byte_valid = 1'b1;
            @(negedge radio_clk);
            psdu_byte_valid = 1'b0;
            psdu_start = 1'b0;
            psdu_byte_last = 1'b0;
        end
    endtask

    reg [31:0] value;
    integer wait_count;
    initial begin
        repeat (5) @(posedge bus_clk);
        bus_reset = 1'b0;
        repeat (3) @(posedge radio_clk);
        radio_reset = 1'b0;

        read_register(12'h200, value);
        if (value != 32'h47464531) $fatal(1, "magic mismatch");
        read_register(12'h22c, value);
        if (value != 32'h00010003) $fatal(1, "version mismatch");
        read_register(12'h284, value);
        if(value !== (PEAKS_TO_SOFTWARE ? 32'h504b5357 : 32'd0)) $fatal(1,"Peak offload capability mismatch");
        read_register(12'h27c, value);
        if (value !== (HOST_WAVEFORM ? 32'h57463230 : 32'd0))
            $fatal(1, "waveform capability mismatch");
        read_register(12'h280, value);
        if(value !== (COUNTERS_TO_SOFTWARE ? 32'h47523332 : 32'd0))
            $fatal(1,"counter contract mismatch");
        read_register(12'h21c, value);
        if(value !== (COUNTERS_TO_SOFTWARE ? 32'd4 : 32'd7))
            $fatal(1,"RX counter encoding mismatch");
        read_register(12'h220, value);
        if(value !== (COUNTERS_TO_SOFTWARE ? 32'd2 : 32'd3))
            $fatal(1,"response counter encoding mismatch");

        // Arm without the key must fail closed.
        write_register(12'h204, 32'h1);
        repeat (5) @(posedge radio_clk);
        if (radio_arm || !radio_kill)
            $fatal(1, "unkeyed arm escaped fail-close");

        write_register(12'h204, 32'h2);
        write_register(12'h208, 32'h46415031);
        write_register(12'h20c, 32'h00000247);
        write_register(12'h244, 32'h00000007);
        write_register(12'h240, 32'h47324641);
        write_register(12'h204, 32'h1);
        repeat (6) @(posedge radio_clk);
        if (!radio_arm || radio_kill)
            $fatal(1, "keyed arm did not reach radio domain");
        if (radio_ap_mac != 48'h024746415031)
            $fatal(1, "AP MAC crossing mismatch");
        if (!radio_channel || radio_rx_use_txrx != 2'b11)
            $fatal(1, "RF configuration crossing mismatch");

        write_register(12'h230, 32'h000000b4);
        write_register(12'h230, 32'h00000100);
        write_register(12'h230, 32'h00000200);
        write_register(12'h230, 32'h00000300);
        write_register(12'h234, 32'h00000004);

        wait_count = 0;
        while (!radio_tx_commit && wait_count < 20) begin
            @(posedge radio_clk);
            wait_count = wait_count + 1;
        end
        if (!radio_tx_commit) $fatal(1, "TX commit did not cross domains");
        if (radio_tx_length != 4) $fatal(1, "TX length mismatch");
        radio_tx_read_address = 0;
        #1 if (radio_tx_read_data != 8'hb4) $fatal(1, "TX byte zero");
        radio_tx_read_address = 3;
        if(TX_BLOCK_RAM) @(posedge radio_clk);
        #1 if (radio_tx_read_data != 8'h00) $fatal(1, "TX byte three");

        radio_tx_busy = 1'b1;
        repeat (3) @(posedge radio_clk);
        @(negedge radio_clk);
        radio_tx_busy = 1'b0;
        radio_tx_done = 1'b1;
        @(negedge radio_clk);
        radio_tx_done = 1'b0;
        repeat (20) @(posedge bus_clk);
        read_register(12'h23c, value);
        if (value != 1) $fatal(1, "TX done counter mismatch");

        // A telemetry carry must never release packet RAM ownership. Seed a
        // long-running count while idle, then cross 0xffff -> 0x10000 with an
        // actual completion. Simulation is a logic check, not CDC metrology.
        @(negedge radio_clk);
        dut.tx_done_count_radio = 32'h0000ffff;
        repeat (24) @(posedge bus_clk);
        write_register(12'h230, 32'h000000ab);
        write_register(12'h234, 32'h00000001);
        repeat (12) @(posedge radio_clk);
        read_register(12'h238, value);
        if (!value[0]) $fatal(1, "counter change released in-flight frame");
        write_register(12'h230, 32'h000000cd);
        radio_tx_read_address = 0;
        if(TX_BLOCK_RAM) @(posedge radio_clk);
        #1 if (radio_tx_read_data != 8'hab) $fatal(1, "in-flight packet RAM was overwritten");
        @(negedge radio_clk);
        radio_tx_done = 1'b1;
        @(negedge radio_clk);
        radio_tx_done = 1'b0;
        repeat (24) @(posedge bus_clk);
        read_register(12'h23c, value);
        if (value != (COUNTERS_TO_SOFTWARE ? 32'h18000 : 32'h10000)) $fatal(1, "Gray counter carry mismatch");
        read_register(12'h238, value);
        if (value[0]) $fatal(1, "completion did not release packet RAM");

        write_register(12'h230, 32'h000000ef);
        write_register(12'h234, 32'h00000001);
        repeat (12) @(posedge radio_clk);
        @(negedge radio_clk);
        radio_tx_error = 1'b1;
        @(negedge radio_clk);
        radio_tx_error = 1'b0;
        repeat (24) @(posedge bus_clk);
        read_register(12'h238, value);
        if (value[0]) $fatal(1, "TX error left packet RAM stuck in flight");
        read_register(12'h24c, value);
        if (value != 1) $fatal(1, "TX error counter mismatch");

        push_psdu_byte(8'h12, 1'b1, 1'b0);
        push_psdu_byte(8'h34, 1'b0, 1'b1);
        repeat (8) @(posedge bus_clk);
        read_register(12'h214, value);
        if (value != 32'h80000112)
            $fatal(1, "first RX FIFO word %08x", value);
        read_register(12'h214, value);
        if (value != 32'h80000234)
            $fatal(1, "last RX FIFO word %08x", value);

        radio_path_ready = 1'b0;
        #1;
        if (radio_arm || !radio_kill)
            $fatal(1, "PLL loss did not kill radio arm");

        $display("E310_GP0_REGS_SELFTEST_PASS");
        $finish;
    end
endmodule
