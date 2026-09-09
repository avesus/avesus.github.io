`timescale 1ns/1ps
// Host-bus logic only. Undefined PS7/radio primitives are deliberately omitted
// with iverilog -i; their interface nets are driven below, never treated as RF.
module tb_gf_e310_gp0_backpressure;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0;
    reg arvalid = 0, rready = 0;
    reg [31:0] araddr = 0;
    reg [11:0] arid = 0;
    reg [3:0] arlen = 0;
    reg awvalid = 0, wvalid = 0, bready = 0;
    reg [31:0] awaddr = 0, wdata = 0;
    reg [11:0] awid = 0;
    reg [3:0] awlen = 0;
    reg [11:0] wid = 0;
    reg wlast = 1;
    gf_e310_open_shell_top #(.SPI_CS_INDEX(1)) dut(.AVR_CS_R(1'b1), .AVR_SCK_R(1'b0), .AVR_MOSI_R(1'b0));
    initial begin
        force dut.pmu_irq = 1'b0;
        #1;
        if (dut.ps_irq_f2p !== 20'd0) $fatal(1, "Inactive PMU raised PS interrupt");
        force dut.pmu_irq = 1'b1;
        #1;
        if (dut.ps_irq_f2p !== 20'h00008)
            $fatal(1, "PMU must map to F2P[3]/GIC64/DT SPI32, not button release");
        release dut.pmu_irq;
        $display("E310_PMU_IRQ_ROUTING_PASS fabric_bit=3 gic_id=64 dt_spi=32");
    end
    integer accepted_reads = 0, completed_reads = 0;
    integer accepted_addresses = 0, accepted_data = 0, completed_writes = 0;
    integer register_reads = 0;
    integer register_writes = 0;
    integer burst_length;
    reg [11:0] held_id;
    reg [31:0] held_data;
    wire [3:0] driven_clocks = {3'd0, clk};
    wire [3:0] driven_resets = {3'd0, resetn};
    // Registers support individual transfers, not bursts. Reject each burst
    // without touching the register/FIFO, but return every AXI3 response beat.
    task reject_read_burst(input integer length);
        integer beat, reads_before, responses_before, touches_before;
        reg [11:0] expected_id;
        begin
            reads_before = accepted_reads;
            responses_before = completed_reads;
            touches_before = register_reads;
            expected_id = 12'h600 + length;
            rready = 0;
            arvalid = 1;
            arlen = length - 1;
            araddr = 32'h4001021c;
            arid = expected_id;
            while (!dut.gp0_arready) @(negedge clk);
            @(negedge clk);
            arvalid = 0;
            // Live address/ID changes cannot alter the accepted transaction.
            araddr = 32'h40010200;
            arid = 12'hbad;
            arlen = 0;
            for (beat = 0; beat < length; beat = beat + 1) begin
                repeat (3) begin
                    if (!dut.gp0_rvalid || dut.gp0_rid !== expected_id ||
                        dut.gp0_rdata !== 0 || dut.gp0_rresp !== 2'b11 ||
                        dut.gp0_rlast !== (beat == length - 1))
                        $fatal(1, "GP0 malformed rejected burst length=%0d beat=%0d last=%b resp=%b",
                               length, beat, dut.gp0_rlast, dut.gp0_rresp);
                    if (dut.gp0_arready)
                        $fatal(1, "GP0 opened read slot inside incomplete burst");
                    @(negedge clk);
                end
                rready = 1;
                @(negedge clk);
                rready = 0;
            end
            repeat (4) @(negedge clk);
            if (dut.gp0_rvalid || accepted_reads != reads_before + 1 ||
                completed_reads != responses_before + length ||
                register_reads != touches_before)
                $fatal(1, "GP0 rejected burst count or register side effect mismatch");
        end
    endtask
    // One outstanding address, non-interleaved AXI3 WID stream. Exercise
    // data-before-address as well as address-before-data, B backpressure,
    // unsupported burst draining, and malformed ID/LAST rejection.
    task check_write(input integer length, input integer data_first,
                     input integer bad_id, input integer bad_last);
        integer beat, addresses_before, data_before, responses_before, touches_before;
        reg [11:0] expected_id;
        reg [1:0] expected_resp;
        begin
            addresses_before = accepted_addresses;
            data_before = accepted_data;
            responses_before = completed_writes;
            touches_before = register_writes;
            expected_id = 12'h700 + length;
            expected_resp = (bad_id || bad_last) ? 2'b10 : ((length == 1) ? 2'b00 : 2'b11);
            bready = 0;
            awaddr = 32'h40010230;
            awid = expected_id;
            awlen = length - 1;
            awvalid = !data_first;
            if (!data_first) begin
                while (!dut.gp0_awready) @(negedge clk);
                @(negedge clk);
                awvalid = 0;
                awid = 12'hbad;
                awlen = 0;
            end
            for (beat = 0; beat < length; beat = beat + 1) begin
                wdata = 32'h80 + beat;
                wid = (bad_id && beat == 0) ? 12'hbad : expected_id;
                wlast = (beat == length - 1);
                if (bad_last) wlast = !wlast;
                wvalid = 1;
                while (!dut.gp0_wready) begin
                    if (dut.gp0_bvalid) $fatal(1, "GP0 responded before final write beat");
                    @(negedge clk);
                end
                if (dut.gp0_bvalid) $fatal(1, "GP0 responded before accepting write data");
                @(negedge clk);
                wvalid = 0;
                if (data_first && beat == 0) begin
                    repeat (4) @(negedge clk);
                    if (dut.gp0_bvalid || accepted_data != data_before + 1)
                        $fatal(1, "GP0 data-first slot did not wait for its address");
                    awvalid = 1;
                    while (!dut.gp0_awready) @(negedge clk);
                    @(negedge clk);
                    awvalid = 0;
                    awid = 12'hbad;
                    awlen = 0;
                end
                repeat (3) @(negedge clk);
                if (beat != length - 1 && dut.gp0_bvalid)
                    $fatal(1, "GP0 early write response length=%0d beat=%0d", length, beat);
            end
            // Offer a new transaction while the old B response is blocked.
            // Neither slot may accept it until the old response completes.
            awvalid = 1;
            wvalid = 1;
            repeat (4) begin
                if (!dut.gp0_bvalid || dut.gp0_bid !== expected_id ||
                    dut.gp0_bresp !== expected_resp || dut.gp0_awready || dut.gp0_wready)
                    $fatal(1, "GP0 write response mismatch length=%0d id=%h resp=%b expected=%b",
                           length, dut.gp0_bid, dut.gp0_bresp, expected_resp);
                @(negedge clk);
            end
            awvalid = 0;
            wvalid = 0;
            bready = 1;
            repeat (4) @(negedge clk);
            if (accepted_addresses != addresses_before + 1 || accepted_data != data_before + length ||
                completed_writes != responses_before + 1 ||
                register_writes != touches_before + ((expected_resp == 0) ? 1 : 0))
                $fatal(1, "GP0 write transaction count or side effect mismatch");
            wlast = 1;
        end
    endtask
    task reset_bus;
        begin
            arvalid = 0; awvalid = 0; wvalid = 0;
            rready = 0; bready = 0; resetn = 0;
            repeat (3) @(negedge clk);
            if (dut.gp0_rvalid || dut.gp0_bvalid || dut.register_write || dut.register_read)
                $fatal(1, "GP0 reset retained a response or register effect");
            resetn = 1;
            repeat (3) @(negedge clk);
        end
    endtask
    task check_address(input [31:0] address, input [1:0] response,
                       input [31:0] expected, input integer wifi);
        integer before_read, before_write;
        begin
            before_read = register_reads; before_write = register_writes;
            araddr = address; arlen = 0; arid = 12'h949;
            arvalid = 1; rready = 0;
            while (!dut.gp0_arready) @(negedge clk);
            @(negedge clk); arvalid = 0;
            repeat (3) begin
                if (!dut.gp0_rvalid || dut.gp0_rresp !== response || dut.gp0_rdata !== expected)
                    $fatal(1, "GP0 aperture read address=%h response=%b data=%h", address, dut.gp0_rresp, dut.gp0_rdata);
                @(negedge clk);
            end
            rready = 1; repeat (4) @(negedge clk);
            awaddr = address; awlen = 0; awid = 12'h949; awvalid = 1;
            while (!dut.gp0_awready) @(negedge clk);
            @(negedge clk); awvalid = 0;
            wdata = 0; wid = 12'h949; wlast = 1; wvalid = 1; bready = 0;
            while (!dut.gp0_wready) @(negedge clk);
            @(negedge clk); wvalid = 0;
            while (!dut.gp0_bvalid) @(negedge clk);
            if (dut.gp0_bresp !== response) $fatal(1, "GP0 aperture write response");
            bready = 1; repeat (4) @(negedge clk);
            if (register_reads != before_read + wifi || register_writes != before_write + wifi)
                $fatal(1, "GP0 aperture isolation failure");
        end
    endtask
    initial begin
        force dut.fclk_clk = driven_clocks;
        force dut.fclk_resetn = driven_resets;
        force dut.gp0_aresetn = resetn;
        force dut.gp0_arvalid = arvalid;
        force dut.gp0_araddr = araddr;
        force dut.gp0_arid = arid;
        force dut.gp0_arlen = arlen;
        force dut.gp0_rready = rready;
        force dut.gp0_awvalid = awvalid;
        force dut.gp0_awaddr = awaddr;
        force dut.gp0_awid = awid;
        force dut.gp0_awlen = awlen;
        force dut.gp0_wvalid = wvalid;
        force dut.gp0_wdata = wdata;
        force dut.gp0_wid = wid;
        force dut.gp0_wlast = wlast;
        force dut.gp0_wstrb = 4'hf;
        force dut.gp0_bready = bready;
        force dut.register_read_data = araddr;
        repeat (4) @(negedge clk);
        resetn = 1;
        repeat (3) @(negedge clk);
        araddr = 32'h40010200;
        arid = 12'h123;
        arvalid = 1;
        @(negedge clk);
        if (!dut.gp0_rvalid) $fatal(1, "first read response missing");
        held_id = dut.gp0_rid;
        held_data = dut.gp0_rdata;
        // A second read arrives while the first response is backpressured.
        araddr = 32'h40010210;
        arid = 12'h456;
        repeat (4) begin
            @(negedge clk);
            if (!dut.gp0_rvalid || dut.gp0_rid != held_id || dut.gp0_rdata != held_data)
                $fatal(1, "GP0 overwrote a backpressured read response");
        end
        arvalid = 0;
        rready = 1;
        repeat (4) @(negedge clk);
        if (accepted_reads != 1 || completed_reads != 1)
            $fatal(1, "GP0 lost or duplicated an accepted read");

        // Independent AXI address/data arrivals must each have one slot.
        awvalid = 1;
        awid = 12'habc;
        awaddr = 32'h40010230;
        @(negedge clk);
        awid = 12'hdef;
        awaddr = 32'h40010234;
        repeat (4) @(negedge clk);
        if (accepted_addresses != 1)
            $fatal(1, "GP0 accepted a write address with no free slot");
        awvalid = 0;
        wvalid = 1;
        wid = 12'habc;
        wdata = 32'h00000080;
        @(negedge clk);
        wdata = 32'h00000099;
        repeat (4) @(negedge clk);
        if (accepted_data != 1 || !dut.gp0_bvalid || dut.gp0_bid != 12'habc)
            $fatal(1, "GP0 write slot or response ID was overwritten");
        wvalid = 0;
        bready = 1;
        repeat (4) @(negedge clk);
        if (completed_writes != 1) $fatal(1, "GP0 write response count mismatch");
        for (burst_length = 2; burst_length <= 16; burst_length = burst_length + 1)
            reject_read_burst(burst_length);
        // The next individual read must still operate normally.
        rready = 1;
        araddr = 32'h40010200;
        arid = 12'h135;
        arvalid = 1;
        while (!dut.gp0_arready) @(negedge clk);
        @(negedge clk);
        arvalid = 0;
        if (!dut.gp0_rvalid || dut.gp0_rid !== 12'h135 ||
            dut.gp0_rdata !== 32'h40010200 || dut.gp0_rresp !== 0 || !dut.gp0_rlast)
            $fatal(1, "GP0 individual read failed after rejected bursts");
        repeat (4) @(negedge clk);
        if (register_reads != 2) $fatal(1, "GP0 register read count mismatch");
        for (burst_length = 1; burst_length <= 16; burst_length = burst_length + 1) begin
            check_write(burst_length, 0, 0, 0);
            check_write(burst_length, 1, 0, 0);
        end
        check_write(1, 0, 1, 0);
        check_write(1, 1, 0, 1);
        check_write(2, 1, 0, 1);
        check_write(16, 0, 1, 0);
        check_write(1, 1, 0, 0);
        // Reset with a backpressured multi-beat read still outstanding.
        arlen = 15; arid = 12'h811; arvalid = 1; rready = 0;
        while (!dut.gp0_arready) @(negedge clk);
        @(negedge clk);
        arvalid = 0;
        if (!dut.gp0_rvalid || dut.gp0_rlast) $fatal(1, "GP0 reset-read setup failed");
        reset_bus();
        reject_read_burst(2);
        // Reset after the first beat of a rejected write. No B response yet.
        awlen = 15; awid = 12'h812; awvalid = 1;
        while (!dut.gp0_awready) @(negedge clk);
        @(negedge clk);
        awvalid = 0;
        wvalid = 1; wid = 12'h812; wlast = 0;
        while (!dut.gp0_wready) @(negedge clk);
        @(negedge clk);
        wvalid = 0;
        repeat (3) @(negedge clk);
        if (dut.gp0_bvalid) $fatal(1, "GP0 reset-write setup completed early");
        reset_bus();
        check_write(1, 1, 0, 0);
        check_address(32'h40300004, 0, 0, 0);
        check_address(32'h40000240, 3, 0, 0);
        check_address(32'h40300240, 3, 0, 0);
        check_address(32'h50010240, 3, 0, 0);
        check_address(32'h40011240, 3, 0, 0);
        check_address(32'h40010240, 0, 32'h40010240, 1);
        $display("E310_GP0_ADDRESS_ISOLATION_SELFTEST_PASS legacy_pmu=40300000 wifi=40010000 physical_test=false");
        $display("E310_GP0_BACKPRESSURE_SELFTEST_PASS");
        $display("E310_GP0_READ_BURST_REJECTION_SELFTEST_PASS lengths=2..16 physical_test=false");
        $display("E310_GP0_WRITE_BURST_SELFTEST_PASS lengths=1..16 arrival_orders=2 malformed_id_last_rejected=true physical_test=false");
        $display("E310_GP0_MID_BURST_RESET_SELFTEST_PASS physical_test=false");
        $finish;
    end
    always @(posedge clk) if (resetn) begin
        if (arvalid && dut.gp0_arready) accepted_reads <= accepted_reads + 1;
        if (rready && dut.gp0_rvalid) completed_reads <= completed_reads + 1;
        if (dut.register_read) register_reads <= register_reads + 1;
        if (dut.register_write) register_writes <= register_writes + 1;
        if (awvalid && dut.gp0_awready) accepted_addresses <= accepted_addresses + 1;
        if (wvalid && dut.gp0_wready) accepted_data <= accepted_data + 1;
        if (bready && dut.gp0_bvalid) completed_writes <= completed_writes + 1;
    end
    initial begin
        #100000;
        $fatal(1, "GP0 test timeout");
    end
endmodule
