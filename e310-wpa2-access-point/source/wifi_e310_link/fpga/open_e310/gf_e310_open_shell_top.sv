// SPDX-License-Identifier: MIT
// Minimal open-tool E310 Wi-Fi baseband shell.
//
// The already-booted Zynq PS keeps Linux, DDR, MIO, FCLK0, GP0, and SPI0.
// This PL image preserves the AD9361 SPI path, owns the exact E310 CMOS sample
// and RF-switch pins, receives 1 Mb/s DSSS, generates SIFS ACK/CTS locally,
// and transmits arbitrary C++-formatted PSDUs from a byte-addressed GP0 RAM.

`timescale 1ns/1ps

module gf_e310_open_shell_top #(
    parameter integer USE_RX_BUFR = 0,
    parameter integer SPI_CS_INDEX = 0,
    parameter integer USE_HOST_WAVEFORM = 0,
    parameter integer USE_TX_BLOCK_RAM = 0,
    parameter integer COUNTERS_TO_SOFTWARE = 0,
    parameter integer RX_FIFO_BLOCK_RAM = 0,
    parameter integer SINGLE_PHASE_RX = 0,
    parameter integer SERIAL_DIFFERENTIAL = 0,
    parameter integer TIMING_SCORE_RAM = 0,
    parameter integer SERIAL_CONTROL_CRC = 0,
    parameter integer SERIAL_RX_CRC = 0,
    parameter integer RECURSIVE_CORRELATOR = 0,
    parameter integer PEAKS_TO_SOFTWARE = 0,
    parameter integer SERIAL_BARKER = 0
) (
    input  wire [7:0]  CAT_CTRL_OUT,
    output wire [3:0]  CAT_CTRL_IN,
    output wire        CAT_RESET,
    output wire        CAT_CS,
    output wire        CAT_SCLK,
    output wire        CAT_MOSI,
    input  wire        CAT_MISO,
    output wire        CAT_SYNC,
    output wire        CAT_TXNRX,
    output wire        CAT_ENABLE,
    output wire        CAT_ENAGC,
    input  wire        CAT_RX_FRAME,
    input  wire        CAT_DATA_CLK,
    output wire        CAT_TX_FRAME,
    output wire        CAT_FB_CLK,
    input  wire [11:0] CAT_P0_D,
    output wire [11:0] CAT_P1_D,

    output wire [2:0]  TX_BANDSEL,
    output wire [2:0]  RX1_BANDSEL,
    output wire [2:0]  RX2_BANDSEL,
    output wire [1:0]  RX1B_BANDSEL,
    output wire [1:0]  RX1C_BANDSEL,
    output wire [1:0]  RX2B_BANDSEL,
    output wire [1:0]  RX2C_BANDSEL,
    output wire        TX_ENABLE1A,
    output wire        TX_ENABLE1B,
    output wire        TX_ENABLE2A,
    output wire        TX_ENABLE2B,
    output wire        VCTXRX1_V1,
    output wire        VCTXRX1_V2,
    output wire        VCTXRX2_V1,
    output wire        VCTXRX2_V2,
    output wire        VCRX1_V1,
    output wire        VCRX1_V2,
    output wire        VCRX2_V1,
    output wire        VCRX2_V2,
    output wire        LED_TXRX1_TX,
    output wire        LED_TXRX1_RX,
    output wire        LED_RX1_RX,
    output wire        LED_TXRX2_TX,
    output wire        LED_TXRX2_RX,
    output wire        LED_RX2_RX,
    input wire         AVR_CS_R, AVR_MOSI_R, AVR_SCK_R,
    output wire        AVR_MISO_R, AVR_IRQ
);
    wire [3:0] fclk_clk;
    wire [3:0] fclk_resetn;
    wire gp0_aresetn;

    wire [31:0] gp0_awaddr;
    wire [11:0] gp0_awid;
    wire [3:0] gp0_awlen;
    wire gp0_awvalid;
    reg gp0_awready = 1'b0;
    wire [31:0] gp0_wdata;
    wire [11:0] gp0_wid;
    wire gp0_wlast;
    wire [3:0] gp0_wstrb;
    wire gp0_wvalid;
    reg gp0_wready = 1'b0;
    wire gp0_bready;
    reg [11:0] gp0_bid = 12'd0;
    reg [1:0] gp0_bresp = 2'b00;
    reg gp0_bvalid = 1'b0;
    wire [31:0] gp0_araddr;
    wire [11:0] gp0_arid;
    wire [3:0] gp0_arlen;
    wire gp0_arvalid;
    reg gp0_arready = 1'b0;
    wire gp0_rready;
    reg [11:0] gp0_rid = 12'd0;
    reg [31:0] gp0_rdata = 32'd0;
    reg [1:0] gp0_rresp = 2'b00;
    reg gp0_rlast = 1'b1;
    reg gp0_rvalid = 1'b0;

    wire spi0_mosi;
    wire spi0_sclk;
    wire [2:0] spi0_ss;
    wire pmu_irq;
    // Stock e31x.v places PMU on fabric bit 3: GIC ID 64 (DT SPI 32).
    // Bit 2 is the stock power-button release interrupt, not the PMU.
    wire [19:0] ps_irq_f2p = {16'd0, pmu_irq, 3'd0};

    (* keep *) PS7 ps7_i (
        .FCLKCLK(fclk_clk),
        .FCLKRESETN(fclk_resetn),
        // Match the installed processing_system7 IP's disabled-port default
        // (component.xml FPGA_IDLE_N defaultValue=0). The old constant 1 was
        // an unsupported change to PS central-interconnect power management.
        // The idle0-only physical test did not resolve the observed stalls.
        .FPGAIDLEN(1'b0),
        .IRQF2P(ps_irq_f2p),

        .EMIOSPI0MI(CAT_MISO),
        .EMIOSPI0MO(spi0_mosi),
        .EMIOSPI0SCLKO(spi0_sclk),
        .EMIOSPI0SSON(spi0_ss),
        .EMIOSPI0SI(1'b0),
        .EMIOSPI0SCLKI(1'b0),
        .EMIOSPI0SSIN(1'b1),

        .MAXIGP0ACLK(fclk_clk[0]),
        // UG585 "AXI Clocks and Resets": GPV accesses require ALL PS-PL
        // AXI clocks, even for unused interfaces. Keep request inputs on
        // unused slave ports inactive; providing a clock does not start DMA.
        // This corrects a clock-contract omission, not a proven stall cause.
        .MAXIGP1ACLK(fclk_clk[0]),
        .SAXIGP0ACLK(fclk_clk[0]),
        .SAXIGP1ACLK(fclk_clk[0]),
        .SAXIHP0ACLK(fclk_clk[0]),
        .SAXIHP1ACLK(fclk_clk[0]),
        .SAXIHP2ACLK(fclk_clk[0]),
        .SAXIHP3ACLK(fclk_clk[0]),
        .SAXIACPACLK(fclk_clk[0]),
        .MAXIGP0ARESETN(gp0_aresetn),
        .MAXIGP0AWADDR(gp0_awaddr),
        .MAXIGP0AWID(gp0_awid),
        .MAXIGP0AWLEN(gp0_awlen),
        .MAXIGP0AWVALID(gp0_awvalid),
        .MAXIGP0AWREADY(gp0_awready),
        .MAXIGP0WDATA(gp0_wdata),
        .MAXIGP0WID(gp0_wid),
        .MAXIGP0WLAST(gp0_wlast),
        .MAXIGP0WSTRB(gp0_wstrb),
        .MAXIGP0WVALID(gp0_wvalid),
        .MAXIGP0WREADY(gp0_wready),
        .MAXIGP0BID(gp0_bid),
        .MAXIGP0BRESP(gp0_bresp),
        .MAXIGP0BVALID(gp0_bvalid),
        .MAXIGP0BREADY(gp0_bready),
        .MAXIGP0ARADDR(gp0_araddr),
        .MAXIGP0ARID(gp0_arid),
        .MAXIGP0ARLEN(gp0_arlen),
        .MAXIGP0ARVALID(gp0_arvalid),
        .MAXIGP0ARREADY(gp0_arready),
        .MAXIGP0RID(gp0_rid),
        .MAXIGP0RDATA(gp0_rdata),
        .MAXIGP0RRESP(gp0_rresp),
        .MAXIGP0RLAST(gp0_rlast),
        .MAXIGP0RVALID(gp0_rvalid),
        .MAXIGP0RREADY(gp0_rready)
    );

    assign CAT_MOSI = spi0_mosi;
    assign CAT_SCLK = spi0_sclk;
    // UHD 3.10 E310 Linux uses spidev0.1 and stock SPI0_SS1; newer MPM
    // images use SS0. Select the installed PS/Linux contract at build time.
    assign CAT_CS = spi0_ss[SPI_CS_INDEX];
    // Match the stock E310 control contract. Only CTRL_IN[0] is asserted.
    assign CAT_CTRL_IN = 4'b0001;
    assign CAT_RESET = 1'b1;
    assign CAT_SYNC = 1'b0;
    assign CAT_TXNRX = 1'b1;
    assign CAT_ENABLE = 1'b1;
    assign CAT_ENAGC = 1'b1;

    wire fabric_resetn = gp0_aresetn & fclk_resetn[0];
    wire bus_reset = !fabric_resetn;
    reg [31:0] saved_write_address = 32'd0;
    reg [11:0] saved_write_id = 12'd0;
    reg [3:0] saved_write_length = 4'd0;
    reg [3:0] write_beats_remaining = 4'd0;
    reg write_error = 1'b0;
    reg saved_write_address_valid = 1'b0;
    reg [31:0] saved_write_data = 32'd0;
    reg [3:0] saved_write_strobe = 4'd0;
    reg [11:0] saved_write_data_id = 12'd0;
    reg saved_write_last = 1'b0;
    reg saved_write_data_valid = 1'b0;
    reg [3:0] read_beats_remaining = 4'd0;

    wire write_beat_consume = saved_write_address_valid &&
        saved_write_data_valid && !gp0_bvalid;
    wire write_final_beat = (write_beats_remaining == 4'd0);
    wire write_beat_error = (saved_write_data_id != saved_write_id) ||
        (saved_write_last != write_final_beat);
    // One outstanding write address; write interleaving depth is one.
    // Buffer W independently of AW, then drain exactly AWLEN+1 beats. Bursts
    // are unsupported register operations, not permission to complete early
    // or to execute the first beat against a radio-control register.
    // Legacy 2017 Linux locates its real PMU syscon at 0x40300000; newer MPM
    // uses 0x40000000. Neither may alias the custom Wi-Fi bank at 0x40010000.
    localparam [31:0] PMU_BASE = SPI_CS_INDEX == 1 ? 32'h40300000 : 32'h40000000;
    wire write_wifi = saved_write_address[31:12] == 20'h40010;
    wire read_wifi = gp0_araddr[31:12] == 20'h40010;
    wire write_pmu = saved_write_address[31:8] == PMU_BASE[31:8];
    wire read_pmu = gp0_araddr[31:8] == PMU_BASE[31:8];
    wire write_single = write_beat_consume && saved_write_length == 0 &&
        !write_error && !write_beat_error;
    wire register_write = write_single && write_wifi;
    wire pmu_write_error;
    wire [31:0] pmu_read_data;
    gf_e310_pmu_regs pmu (
        .clk(fclk_clk[0]), .reset(bus_reset),
        .spi_ss(AVR_CS_R), .spi_mosi(AVR_MOSI_R), .spi_sck(AVR_SCK_R),
        .spi_miso(AVR_MISO_R), .irq(pmu_irq),
        .write_enable(write_single && write_pmu),
        .write_address(saved_write_address[7:0]),
        .write_data(saved_write_data), .write_strobe(saved_write_strobe),
        .write_error(pmu_write_error), .read_address(gp0_araddr[7:0]),
        .read_data(pmu_read_data)
    );
    assign AVR_IRQ = 1'b0; // Same inactive AVR interrupt output as stock E310.
    wire read_address_accept = gp0_arvalid && gp0_arready;
    // GP0 is AXI3, not AXI-Lite. An unsupported burst must still receive
    // ARLEN+1 beats and exactly one final RLAST, even when returning DECERR.
    // No burst is allowed to pop a receive FIFO or touch any register state.
    wire register_read = read_address_accept && (gp0_arlen == 4'd0) && read_wifi;
    wire [31:0] register_read_data;

    always @(posedge fclk_clk[0]) begin
        if (bus_reset) begin
            gp0_awready <= 1'b0;
            gp0_wready <= 1'b0;
            gp0_bvalid <= 1'b0;
            gp0_arready <= 1'b0;
            gp0_rvalid <= 1'b0;
            gp0_rlast <= 1'b1;
            gp0_bresp <= 2'b00;
            gp0_rresp <= 2'b00;
            read_beats_remaining <= 4'd0;
            saved_write_address_valid <= 1'b0;
            saved_write_data_valid <= 1'b0;
            write_beats_remaining <= 4'd0;
            write_error <= 1'b0;
        end else begin
            // Registered READY must close its slot on the accepting edge.
            // Looking only at the old pending flag leaves READY high for one
            // extra cycle and can overwrite an unanswered transaction.
            gp0_awready <= !saved_write_address_valid && !gp0_bvalid &&
                !(gp0_awvalid && gp0_awready);
            gp0_wready <= !saved_write_data_valid && !gp0_bvalid &&
                !(gp0_wvalid && gp0_wready);
            gp0_arready <= !gp0_rvalid && !read_address_accept;

            if (gp0_awvalid && gp0_awready) begin
                saved_write_address <= gp0_awaddr;
                saved_write_id <= gp0_awid;
                saved_write_length <= gp0_awlen;
                write_beats_remaining <= gp0_awlen;
                write_error <= 1'b0;
                saved_write_address_valid <= 1'b1;
            end
            if (gp0_wvalid && gp0_wready) begin
                saved_write_data <= gp0_wdata;
                saved_write_strobe <= gp0_wstrb;
                saved_write_data_id <= gp0_wid;
                saved_write_last <= gp0_wlast;
                saved_write_data_valid <= 1'b1;
            end

            if (write_beat_consume) begin
                saved_write_data_valid <= 1'b0;
                write_error <= write_error || write_beat_error;
                if (write_final_beat) begin
                    gp0_bid <= saved_write_id;
                    gp0_bresp <= (write_error || write_beat_error ||
                        (write_pmu && pmu_write_error)) ? 2'b10 :
                        ((saved_write_length == 0 && (write_wifi || write_pmu)) ? 2'b00 : 2'b11);
                    gp0_bvalid <= 1'b1;
                    saved_write_address_valid <= 1'b0;
                end else begin
                    write_beats_remaining <= write_beats_remaining - 4'd1;
                end
            end else if (gp0_bvalid && gp0_bready) begin
                gp0_bvalid <= 1'b0;
            end

            if (read_address_accept) begin
                gp0_rid <= gp0_arid;
                gp0_rdata <= gp0_arlen != 0 ? 32'd0 :
                    (read_wifi ? register_read_data : (read_pmu ? pmu_read_data : 32'd0));
                gp0_rresp <= (gp0_arlen == 0 && (read_wifi || read_pmu)) ? 2'b00 : 2'b11;
                gp0_rlast <= (gp0_arlen == 4'd0);
                read_beats_remaining <= gp0_arlen;
                gp0_rvalid <= 1'b1;
            end else if (gp0_rvalid && gp0_rready) begin
                if (read_beats_remaining != 4'd0) begin
                    read_beats_remaining <= read_beats_remaining - 4'd1;
                    gp0_rlast <= (read_beats_remaining == 4'd1);
                end else begin
                    gp0_rvalid <= 1'b0;
                end
            end
        end
    end

    wire radio_clk;
    wire radio_rst;
    wire [11:0] rx_i0;
    wire [11:0] rx_q0;
    wire [11:0] rx_i1;
    wire [11:0] rx_q1;
    wire rx_stb;
    wire [11:0] tx_i0;
    wire [11:0] tx_q0;
    wire [11:0] tx_i1;
    wire [11:0] tx_q1;
    wire tx_stb;

    // Mirror the channel swap in the stock E310 top level.
    gf_e310_io_open #(.USE_RX_BUFR(USE_RX_BUFR)) ad9361_io (
        .areset(bus_reset),
        .mimo(1'b1),
        .radio_clk(radio_clk),
        .radio_rst(radio_rst),
        .rx_i0(rx_i1),
        .rx_q0(rx_q1),
        .rx_i1(rx_i0),
        .rx_q1(rx_q0),
        .rx_stb(rx_stb),
        .tx_i0(tx_i1),
        .tx_q0(tx_q1),
        .tx_i1(tx_i0),
        .tx_q1(tx_q0),
        .tx_stb(tx_stb),
        .rx_clk(CAT_DATA_CLK),
        .rx_frame(CAT_RX_FRAME),
        .rx_data(CAT_P0_D),
        .tx_clk(CAT_FB_CLK),
        .tx_frame(CAT_TX_FRAME),
        .tx_data(CAT_P1_D)
    );

    (* ASYNC_REG = "TRUE" *) reg [1:0] tx_lock_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [1:0] rx_lock_sync = 2'b00;
    always @(posedge radio_clk) begin
        if (radio_rst) begin
            tx_lock_sync <= 2'b00;
            rx_lock_sync <= 2'b00;
        end else begin
            tx_lock_sync <= {tx_lock_sync[0], CAT_CTRL_OUT[7]};
            rx_lock_sync <= {rx_lock_sync[0], CAT_CTRL_OUT[6]};
        end
    end
    wire serial_clk,serial_clock_locked;
    generate if(SERIAL_BARKER)begin:g_serial_clock
        gf_e310_serial_clock clock_generator(.radio_clk(radio_clk),.control_clk(fclk_clk[0]),
            .reset_request(bus_reset || radio_rst),.fast_clk(serial_clk),.locked(serial_clock_locked));
    end else begin:g_no_serial_clock
        assign serial_clk=1'b0;assign serial_clock_locked=1'b1;
    end endgenerate
    wire radio_path_ready = tx_lock_sync[1] && rx_lock_sync[1] && serial_clock_locked;

    wire radio_arm;
    wire radio_kill;
    wire [47:0] radio_ap_mac;
    wire logical_tx_channel;
    wire [1:0] rx_use_txrx;
    wire radio_tx_commit;
    wire [11:0] radio_tx_length;
    wire [11:0] radio_tx_read_address;
    wire [7:0] radio_tx_read_data;
    wire ordinary_tx_busy;
    wire ordinary_tx_done;
    wire ordinary_tx_error;

    wire host_psdu_start;
    wire host_psdu_byte_valid;
    wire [7:0] host_psdu_byte;
    wire host_psdu_byte_last;
    wire [15:0] host_psdu_end_age_cycles;
    wire response_pending;
    wire response_active;
    wire response_start;
    wire response_is_cts;
    wire [47:0] response_mac;
    wire [15:0] response_duration_us;
    wire tx_override_valid;
    wire mode_fault;
    wire rf_kill=radio_kill || (SERIAL_BARKER && (!serial_clock_locked || mode_fault));
    wire [31:0] rx_sfd_count;
    wire [31:0] rx_plcp_ok_count;
    wire [31:0] rx_plcp_error_count;
    wire [31:0] rx_psdu_count;
    wire [31:0] classified_frame_count;
    wire [31:0] classified_fcs_ok_count;
    wire [31:0] response_candidate_count;
    wire [31:0] malformed_count;
    wire [31:0] response_count;
    wire [31:0] deadline_miss_count;
    wire [31:0] rejected_count;
    wire [31:0] stream_abort_count;

    initial if(USE_TX_BLOCK_RAM && !USE_HOST_WAVEFORM)
        $error("Block RAM TX requires the host waveform player");
    gf_e310_gp0_regs #(.USE_HOST_WAVEFORM(USE_HOST_WAVEFORM),
                       .USE_TX_BLOCK_RAM(USE_TX_BLOCK_RAM),
                       .COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE),
                       .RX_FIFO_BLOCK_RAM(RX_FIFO_BLOCK_RAM),
                       .PEAKS_TO_SOFTWARE(PEAKS_TO_SOFTWARE)) control_plane (
        .bus_clk(fclk_clk[0]),
        .bus_reset(bus_reset),
        .bus_write(register_write),
        .bus_write_address(saved_write_address[11:0]),
        .bus_write_data(saved_write_data),
        .bus_write_strobe(saved_write_strobe),
        .bus_read(register_read),
        .bus_read_address(gp0_araddr[11:0]),
        .bus_read_data(register_read_data),
        .radio_clk(radio_clk),
        .radio_reset(radio_rst),
        .radio_path_ready(radio_path_ready),
        .radio_arm(radio_arm),
        .radio_kill(radio_kill),
        .radio_ap_mac(radio_ap_mac),
        .radio_logical_tx_channel(logical_tx_channel),
        .radio_rx_use_txrx(rx_use_txrx),
        .radio_tx_commit(radio_tx_commit),
        .radio_tx_length(radio_tx_length),
        .radio_tx_read_address(radio_tx_read_address),
        .radio_tx_read_data(radio_tx_read_data),
        .radio_tx_busy(ordinary_tx_busy),
        .radio_tx_done(ordinary_tx_done),
        .radio_tx_error(ordinary_tx_error),
        .psdu_start(host_psdu_start),
        .psdu_byte_valid(host_psdu_byte_valid),
        .psdu_byte(host_psdu_byte),
        .psdu_byte_last(host_psdu_byte_last),
        .response_pending(response_pending),
        .response_active(response_active),
        .tx_override_valid(tx_override_valid),
        .mode_fault(mode_fault),
        .rx_psdu_count(rx_psdu_count),
        .response_count(response_count),
        .deadline_miss_count(deadline_miss_count),
        .rejected_count(rejected_count),
        .rx_sample_valid(rx_stb),
        .rx_sample_iq({rx_q0, 4'd0, rx_i0, 4'd0}),
        .rx_capture_veto(radio_kill || ordinary_tx_rf_claim || sifs_channel_claim),
        .rx_sfd_count(rx_sfd_count),
        .rx_plcp_ok_count(rx_plcp_ok_count),
        .rx_plcp_error_count(rx_plcp_error_count)
    );

    wire ordinary_tx_ready;
    wire ordinary_tx_rf_claim;
    wire ordinary_tx_valid;
    wire [31:0] ordinary_tx_iq;
    wire sifs_channel_claim =
        response_pending || response_active || tx_override_valid;

    generate if(USE_HOST_WAVEFORM) begin: host_waveform_path
    gf_host_waveform_tx #(.MEMORY_READ_LATENCY(USE_TX_BLOCK_RAM)) ordinary_tx (
        .clk(radio_clk), .resetn(!radio_rst), .arm(radio_arm), .kill(rf_kill),
        .frame_commit(radio_tx_commit), .frame_length_bytes(radio_tx_length),
        .frame_read_address(radio_tx_read_address), .frame_read_data(radio_tx_read_data),
        .tx_channel_available(!sifs_channel_claim), .tx_sample_tick(tx_stb),
        .tx_sink_ready(1'b1), .ready(ordinary_tx_ready), .busy(ordinary_tx_busy),
        .tx_rf_claim(ordinary_tx_rf_claim), .tx_valid(ordinary_tx_valid),
        .tx_iq(ordinary_tx_iq), .frame_done(ordinary_tx_done), .frame_error(ordinary_tx_error)
    );
    end else begin: psdu_path
    gf_dsss_1mbps_psdu_tx ordinary_tx (
        .clk(radio_clk),
        .resetn(!radio_rst),
        .arm(radio_arm),
        .kill(radio_kill),
        .frame_commit(radio_tx_commit),
        .frame_length_bytes(radio_tx_length),
        .frame_read_address(radio_tx_read_address),
        .frame_read_data(radio_tx_read_data),
        .tx_channel_available(!sifs_channel_claim),
        .tx_sample_tick(tx_stb),
        .tx_sink_ready(1'b1),
        .ready(ordinary_tx_ready),
        .busy(ordinary_tx_busy),
        .tx_rf_claim(ordinary_tx_rf_claim),
        .tx_valid(ordinary_tx_valid),
        .tx_iq(ordinary_tx_iq),
        .frame_done(ordinary_tx_done),
        .frame_error(ordinary_tx_error)
    );
    end endgenerate

    wire [63:0] host_tx_flat = ordinary_tx_valid
        ? {32'd0, ordinary_tx_iq[15:0], ordinary_tx_iq[31:16]}
        : 64'd0;
    wire [63:0] rx_flat = {
        rx_i1, 4'd0, rx_q1, 4'd0,
        rx_i0, 4'd0, rx_q0, 4'd0
    };
    wire [63:0] air_tx_flat;

    gf_e31x_sifs_inline #(
        .CLOCK_HZ(40_000_000),
        .SIFS_US(10),
        .SINGLE_PHASE_RX(SINGLE_PHASE_RX),
        .SERIAL_DIFFERENTIAL(SERIAL_DIFFERENTIAL),
        .TIMING_SCORE_RAM(TIMING_SCORE_RAM),
        .SERIAL_CONTROL_CRC(SERIAL_CONTROL_CRC),
        .SERIAL_RX_CRC(SERIAL_RX_CRC),
        .RECURSIVE_CORRELATOR(RECURSIVE_CORRELATOR),.SERIAL_BARKER(SERIAL_BARKER)
    ) sifs_path (
        .clk(radio_clk),
        .resetn(!radio_rst),
        .mode_mimo(1'b1),
        .arm(radio_arm),
        .kill(radio_kill),
        .ap_mac(radio_ap_mac),
        .rx_sample_valid(rx_stb),
        .rx_flat(rx_flat),
        .tx_sample_tick(tx_stb),
        .host_tx_flat(host_tx_flat),
        .air_tx_flat(air_tx_flat),
        .host_psdu_start(host_psdu_start),
        .host_psdu_byte_valid(host_psdu_byte_valid),
        .host_psdu_byte(host_psdu_byte),
        .host_psdu_byte_last(host_psdu_byte_last),
        .host_psdu_end_age_cycles(host_psdu_end_age_cycles),
        .response_pending(response_pending),
        .response_active(response_active),
        .response_start(response_start),
        .response_is_cts(response_is_cts),
        .response_mac(response_mac),
        .response_duration_us(response_duration_us),
        .tx_override_valid(tx_override_valid),
        .mode_fault(mode_fault),
        .rx_sfd_count(rx_sfd_count),
        .rx_plcp_ok_count(rx_plcp_ok_count),
        .rx_plcp_error_count(rx_plcp_error_count),
        .rx_psdu_count(rx_psdu_count),
        .classified_frame_count(classified_frame_count),
        .classified_fcs_ok_count(classified_fcs_ok_count),
        .response_candidate_count(response_candidate_count),
        .malformed_count(malformed_count),
        .response_count(response_count),
        .deadline_miss_count(deadline_miss_count),
        .rejected_count(rejected_count),
        .stream_abort_count(stream_abort_count),.fast_clk(serial_clk),.serial_clock_locked(serial_clock_locked)
    );

    assign tx_i0 = air_tx_flat[31:20];
    assign tx_q0 = air_tx_flat[15:4];
    assign tx_i1 = air_tx_flat[63:52];
    assign tx_q1 = air_tx_flat[47:36];

    wire tx_rf_active;
    gf_e310_frontend_2g4 frontend (
        .arm(radio_arm),
        .kill(rf_kill),
        .tx_pll_locked(tx_lock_sync[1]),
        .rx_pll_locked(rx_lock_sync[1]),
        .tx_claim(ordinary_tx_rf_claim || sifs_channel_claim),
        .logical_tx_channel(logical_tx_channel),
        .rx_use_txrx(rx_use_txrx),
        .TX_BANDSEL(TX_BANDSEL),
        .RX1_BANDSEL(RX1_BANDSEL),
        .RX2_BANDSEL(RX2_BANDSEL),
        .RX1B_BANDSEL(RX1B_BANDSEL),
        .RX1C_BANDSEL(RX1C_BANDSEL),
        .RX2B_BANDSEL(RX2B_BANDSEL),
        .RX2C_BANDSEL(RX2C_BANDSEL),
        .TX_ENABLE1A(TX_ENABLE1A),
        .TX_ENABLE1B(TX_ENABLE1B),
        .TX_ENABLE2A(TX_ENABLE2A),
        .TX_ENABLE2B(TX_ENABLE2B),
        .VCTXRX1_V1(VCTXRX1_V1),
        .VCTXRX1_V2(VCTXRX1_V2),
        .VCTXRX2_V1(VCTXRX2_V1),
        .VCTXRX2_V2(VCTXRX2_V2),
        .VCRX1_V1(VCRX1_V1),
        .VCRX1_V2(VCRX1_V2),
        .VCRX2_V1(VCRX2_V1),
        .VCRX2_V2(VCRX2_V2),
        .LED_TXRX1_TX(LED_TXRX1_TX),
        .LED_TXRX1_RX(LED_TXRX1_RX),
        .LED_RX1_RX(LED_RX1_RX),
        .LED_TXRX2_TX(LED_TXRX2_TX),
        .LED_TXRX2_RX(LED_TXRX2_RX),
        .LED_RX2_RX(LED_RX2_RX),
        .tx_rf_active(tx_rf_active)
    );

    wire unused = &{
        1'b0,
        ordinary_tx_ready,
        tx_rf_active,
        host_psdu_end_age_cycles,
        response_start,
        response_is_cts,
        response_mac,
        response_duration_us,
        rx_sfd_count,
        rx_plcp_ok_count,
        rx_plcp_error_count,
        classified_frame_count,
        classified_fcs_ok_count,
        response_candidate_count,
        malformed_count,
        stream_abort_count,
        CAT_CTRL_OUT[5:0]
    };
endmodule
