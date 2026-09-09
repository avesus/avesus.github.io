`timescale 1ns/1ps

module tb_gf_dsss_1mbps_psdu_tx;
    reg clk = 1'b0;
    always #12.5 clk = ~clk;

    reg resetn = 1'b0;
    reg arm = 1'b0;
    reg kill = 1'b1;
    reg frame_commit = 1'b0;
    reg [11:0] frame_length = 12'd20;
    wire [11:0] frame_address;
    reg [7:0] memory [0:4095];
    wire [7:0] frame_data = memory[frame_address];
    reg tx_tick = 1'b0;
    wire ready;
    wire busy;
    wire tx_rf_claim;
    wire tx_valid;
    wire [31:0] tx_iq;
    wire frame_done;
    wire frame_error;

    reg [31:0] expected [0:7039];
    string expected_path;
    integer sample_count = 0;
    integer timeout_count = 0;
    integer index;
    reg [31:0] frame_fcs;
    reg allow_frame_error = 1'b0;
    reg saw_frame_error = 1'b0;

    function automatic [31:0] crc32_prefix;
        input integer byte_count;
        integer byte_number;
        integer bit_number;
        reg [31:0] crc;
        begin
            crc = 32'hffff_ffff;
            for (byte_number = 0; byte_number < byte_count;
                 byte_number = byte_number + 1) begin
                crc = crc ^ memory[byte_number];
                for (bit_number = 0; bit_number < 8;
                     bit_number = bit_number + 1) begin
                    if (crc[0])
                        crc = (crc >> 1) ^ 32'hedb8_8320;
                    else
                        crc = crc >> 1;
                end
            end
            crc32_prefix = ~crc;
        end
    endfunction

    gf_dsss_1mbps_psdu_tx #(
        .RF_LEAD_CYCLES(4)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .arm(arm),
        .kill(kill),
        .frame_commit(frame_commit),
        .frame_length_bytes(frame_length),
        .frame_read_address(frame_address),
        .frame_read_data(frame_data),
        .tx_channel_available(1'b1),
        .tx_sample_tick(tx_tick),
        .tx_sink_ready(1'b1),
        .ready(ready),
        .busy(busy),
        .tx_rf_claim(tx_rf_claim),
        .tx_valid(tx_valid),
        .tx_iq(tx_iq),
        .frame_done(frame_done),
        .frame_error(frame_error)
    );

    always @(posedge clk) begin
        tx_tick <= ~tx_tick;
        if (tx_valid && tx_tick) begin
            if (sample_count >= 7040) begin
                $display("unexpected extra sample %0d", sample_count);
                $fatal(1);
            end
            if (tx_iq !== expected[sample_count]) begin
                $display("sample mismatch index=%0d actual=%08x expected=%08x",
                         sample_count, tx_iq, expected[sample_count]);
                $fatal(1);
            end
            sample_count <= sample_count + 1;
        end
        if (frame_error && !allow_frame_error) begin
            $display("unexpected frame error");
            $fatal(1);
        end
        if (frame_error)
            saw_frame_error <= 1'b1;
    end

    initial begin
        if (!$value$plusargs("EXPECTED=%s", expected_path)) begin
            $display("missing +EXPECTED=path");
            $fatal(1);
        end
        $readmemh(expected_path, expected);

        for (index = 0; index < 4096; index = index + 1)
            memory[index] = 8'd0;
        // RTS: AP receiver, fixed station transmitter, duration 3934 us.
        memory[0] = 8'hb4;
        memory[1] = 8'h00;
        memory[2] = 8'h5e;
        memory[3] = 8'h0f;
        memory[4] = 8'h02;
        memory[5] = 8'h47;
        memory[6] = 8'h46;
        memory[7] = 8'h41;
        memory[8] = 8'h50;
        memory[9] = 8'h31;
        memory[10] = 8'hdc;
        memory[11] = 8'h4f;
        memory[12] = 8'h22;
        memory[13] = 8'h5e;
        memory[14] = 8'hd0;
        memory[15] = 8'h2a;
        frame_fcs = crc32_prefix(16);
        memory[16] = frame_fcs[7:0];
        memory[17] = frame_fcs[15:8];
        memory[18] = frame_fcs[23:16];
        memory[19] = frame_fcs[31:24];

        repeat (6) @(posedge clk);
        resetn <= 1'b1;
        arm <= 1'b1;
        kill <= 1'b0;
        repeat (2) @(posedge clk);
        if (!ready) $fatal(1, "transmitter did not become ready");
        frame_commit <= 1'b1;
        @(posedge clk);
        frame_commit <= 1'b0;

        while (!frame_done && timeout_count < 30000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end
        if (!frame_done) $fatal(1, "transmitter timed out");
        if (sample_count != 7040)
            $fatal(1, "sample count %0d != 7040", sample_count);
        if (busy || tx_valid || tx_rf_claim)
            $fatal(1, "transmitter did not return idle");

        // A kill during the next packet must remove TX ownership immediately.
        frame_commit <= 1'b1;
        @(posedge clk);
        frame_commit <= 1'b0;
        wait (tx_valid);
        allow_frame_error <= 1'b1;
        kill <= 1'b1;
        @(posedge clk);
        @(posedge clk);
        #1;
        if (busy || tx_valid || tx_rf_claim)
            $fatal(1, "kill did not close the packet path");
        if (!saw_frame_error)
            $fatal(1, "kill did not report the aborted packet");

        $display("E310_GENERAL_DSSS_TX_SELFTEST_PASS samples=%0d", sample_count);
        $finish;
    end
endmodule
