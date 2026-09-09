// SPDX-License-Identifier: MIT
// E310 GP0 register plane, decoded-PSDU FIFO, and host-loaded TX frame RAM.
//
// The ARM writes protocol frames as bytes.  Only a committed, complete frame
// can cross into radio_clk.  Arming requires a separate key write, and reset,
// kill, PLL loss, or malformed TX commands leave the RF path disarmed.

`timescale 1ns/1ps

module gf_e310_gp0_regs #(
    parameter [47:0] DEFAULT_AP_MAC = 48'h024746415031,
    parameter integer USE_HOST_WAVEFORM = 0,
    parameter integer USE_TX_BLOCK_RAM = 0,
    parameter integer COUNTERS_TO_SOFTWARE = 0,
    parameter integer RX_FIFO_BLOCK_RAM = 0,
    parameter integer PEAKS_TO_SOFTWARE = 0
) (
    input  wire         bus_clk,
    input  wire         bus_reset,
    input  wire         bus_write,
    input  wire [11:0]  bus_write_address,
    input  wire [31:0]  bus_write_data,
    input  wire [3:0]   bus_write_strobe,
    input  wire         bus_read,
    input  wire [11:0]  bus_read_address,
    output reg  [31:0]  bus_read_data,

    input  wire         radio_clk,
    input  wire         radio_reset,
    input  wire         radio_path_ready,
    output wire         radio_arm,
    output wire         radio_kill,
    output wire [47:0]  radio_ap_mac,
    output wire         radio_logical_tx_channel,
    output wire [1:0]   radio_rx_use_txrx,

    output reg          radio_tx_commit,
    output wire [11:0]  radio_tx_length,
    input  wire [11:0]  radio_tx_read_address,
    output wire [7:0]   radio_tx_read_data,
    input  wire         radio_tx_busy,
    input  wire         radio_tx_done,
    input  wire         radio_tx_error,

    input  wire         psdu_start,
    input  wire         psdu_byte_valid,
    input  wire [7:0]   psdu_byte,
    input  wire         psdu_byte_last,
    input  wire         response_pending,
    input  wire         response_active,
    input  wire         tx_override_valid,
    input  wire         mode_fault,
    input  wire [31:0]  rx_psdu_count,
    input  wire [31:0]  response_count,
    input  wire [31:0]  deadline_miss_count,
    input  wire [31:0]  rejected_count,
    input wire rx_sample_valid,
    input wire [31:0] rx_sample_iq,
    input wire rx_capture_veto,
    input wire [31:0] rx_sfd_count,
    input wire [31:0] rx_plcp_ok_count,
    input wire [31:0] rx_plcp_error_count
);
    localparam [11:0] REG_MAGIC          = 12'h200;
    localparam [11:0] REG_CONTROL        = 12'h204;
    localparam [11:0] REG_AP_MAC_LO      = 12'h208;
    localparam [11:0] REG_AP_MAC_HI      = 12'h20c;
    localparam [11:0] REG_STATUS         = 12'h210;
    localparam [11:0] REG_PSDU_EVENT     = 12'h214;
    localparam [11:0] REG_FIFO_OVERFLOW  = 12'h218;
    localparam [11:0] REG_RX_PSDU_COUNT  = 12'h21c;
    localparam [11:0] REG_RESPONSE_COUNT = 12'h220;
    localparam [11:0] REG_DEADLINE_MISS  = 12'h224;
    localparam [11:0] REG_REJECTED_COUNT = 12'h228;
    localparam [11:0] REG_VERSION        = 12'h22c;
    localparam [11:0] REG_TX_WRITE       = 12'h230;
    localparam [11:0] REG_TX_COMMIT      = 12'h234;
    localparam [11:0] REG_TX_STATUS      = 12'h238;
    localparam [11:0] REG_TX_DONE_COUNT  = 12'h23c;
    localparam [11:0] REG_ARM_KEY        = 12'h240;
    localparam [11:0] REG_RF_CONFIG      = 12'h244;
    localparam [11:0] REG_TX_REJECTED    = 12'h248;
    localparam [11:0] REG_TX_ERROR_COUNT = 12'h24c;

    localparam [31:0] MAGIC = 32'h47464531;       // "GFE1"
    localparam [31:0] VERSION = 32'h00010003;     // v1.3, SFD pretrigger capture
    localparam [31:0] ARM_KEY = 32'h47324641;     // "G2FA"

    reg armed_bus = 1'b0;
    reg arm_key_valid = 1'b0;
    reg [47:0] ap_mac_bus = DEFAULT_AP_MAC;
    // bit 0 selects logical TX channel; bits 2:1 select TX/RX rather than
    // dedicated RX for logical channels 0 and 1.
    reg [2:0] rf_config_bus = 3'b000;

    (* ram_style = USE_TX_BLOCK_RAM ? "block" : "distributed" *)
    reg [7:0] tx_memory [0:4095];
    reg [12:0] tx_bytes_written = 13'd0;
    reg [11:0] tx_length_bus = 12'd0;
    reg tx_start_toggle_bus = 1'b0;
    reg tx_inflight_bus = 1'b0;
    reg [31:0] tx_rejected_bus = 32'd0;
    reg config_fault_bus = 1'b0;

    (* ASYNC_REG = "TRUE" *) reg [1:0] arm_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [47:0] ap_mac_sync_1 = DEFAULT_AP_MAC;
    (* ASYNC_REG = "TRUE" *) reg [47:0] ap_mac_sync_2 = DEFAULT_AP_MAC;
    (* ASYNC_REG = "TRUE" *) reg [2:0] rf_config_sync_1 = 3'b000;
    (* ASYNC_REG = "TRUE" *) reg [2:0] rf_config_sync_2 = 3'b000;
    (* ASYNC_REG = "TRUE" *) reg [1:0] tx_toggle_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [11:0] tx_length_sync_1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg [11:0] tx_length_sync_2 = 12'd0;
    reg tx_toggle_seen = 1'b0;
    reg [31:0] tx_done_count_radio = 32'd0;
    reg [31:0] tx_error_count_radio = 32'd0;
    reg tx_complete_toggle_radio = 1'b0;

    assign radio_arm = arm_sync[1] && radio_path_ready;
    assign radio_kill = !radio_arm;
    assign radio_ap_mac = ap_mac_sync_2;
    assign radio_logical_tx_channel = rf_config_sync_2[0];
    assign radio_rx_use_txrx = rf_config_sync_2[2:1];
    assign radio_tx_length = tx_length_sync_2;
    generate if(USE_TX_BLOCK_RAM) begin: tx_block_ram_read
        reg [7:0] read_data_q;
        // One clock read latency; committed ownership excludes read/write races.
        // No array/read-port reset: the complete committed frame is written first.
        always @(posedge radio_clk) read_data_q <= tx_memory[radio_tx_read_address];
        assign radio_tx_read_data = read_data_q;
    end else begin: tx_distributed_read
        assign radio_tx_read_data = tx_memory[radio_tx_read_address];
    end endgenerate

    always @(posedge radio_clk) begin
        if (radio_reset) begin
            arm_sync <= 2'b00;
            ap_mac_sync_1 <= DEFAULT_AP_MAC;
            ap_mac_sync_2 <= DEFAULT_AP_MAC;
            rf_config_sync_1 <= 3'b000;
            rf_config_sync_2 <= 3'b000;
            tx_toggle_sync <= 2'b00;
            tx_length_sync_1 <= 12'd0;
            tx_length_sync_2 <= 12'd0;
            tx_toggle_seen <= 1'b0;
            radio_tx_commit <= 1'b0;
            tx_done_count_radio <= 32'd0;
            tx_error_count_radio <= 32'd0;
            tx_complete_toggle_radio <= 1'b0;
        end else begin
            arm_sync <= {arm_sync[0], armed_bus};
            ap_mac_sync_1 <= ap_mac_bus;
            ap_mac_sync_2 <= ap_mac_sync_1;
            rf_config_sync_1 <= rf_config_bus;
            rf_config_sync_2 <= rf_config_sync_1;
            tx_toggle_sync <= {tx_toggle_sync[0], tx_start_toggle_bus};
            tx_length_sync_1 <= tx_length_bus;
            tx_length_sync_2 <= tx_length_sync_1;
            radio_tx_commit <= 1'b0;
            if (tx_toggle_sync[1] != tx_toggle_seen) begin
                tx_toggle_seen <= tx_toggle_sync[1];
                if (radio_arm)
                    radio_tx_commit <= 1'b1;
            end
            if (radio_tx_done)
                tx_done_count_radio <= tx_done_count_radio + 1'b1;
            if (radio_tx_error)
                tx_error_count_radio <= tx_error_count_radio + 1'b1;
            if (radio_tx_done || radio_tx_error)
                tx_complete_toggle_radio <= ~tx_complete_toggle_radio;
        end
    end

    wire [9:0] fifo_write_data = {
        psdu_byte_last, psdu_start, psdu_byte
    };
    wire fifo_write_ready;
    wire fifo_write_overflow;
    wire [9:0] fifo_read_data;
    wire fifo_read_valid;
    wire fifo_read_pop = bus_read &&
        bus_read_address == REG_PSDU_EVENT && fifo_read_valid;

    gf_e310_async_fifo #(
        .WIDTH(10),
        .ADDRESS_WIDTH(12),
        .USE_BLOCK_RAM(RX_FIFO_BLOCK_RAM)
    ) decoded_psdu_fifo (
        .write_clk(radio_clk),
        .write_reset(radio_reset),
        .write_data(fifo_write_data),
        .write_enable(psdu_byte_valid),
        .write_ready(fifo_write_ready),
        .write_overflow(fifo_write_overflow),
        .read_clk(bus_clk),
        .read_reset(bus_reset),
        .read_data(fifo_read_data),
        .read_valid(fifo_read_valid),
        .read_pop(fifo_read_pop)
    );

    reg [31:0] fifo_overflow_count_radio = 32'd0;
    always @(posedge radio_clk) begin
        if (radio_reset)
            fifo_overflow_count_radio <= 32'd0;
        else if (fifo_write_overflow)
            fifo_overflow_count_radio <= fifo_overflow_count_radio + 1'b1;
    end

    (* ASYNC_REG = "TRUE" *) reg [1:0] radio_arm_bus_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [1:0] radio_kill_bus_sync = 2'b11;
    (* ASYNC_REG = "TRUE" *) reg [1:0] radio_busy_bus_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [1:0] ready_bus_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [1:0] complete_bus_sync = 2'b00;
    (* ASYNC_REG = "TRUE" *) reg [3:0] status_sync_1 = 4'd0, status_sync_2 = 4'd0;
    reg previous_tx_complete = 1'b0;
    // Register derived status in its source domain before synchronization.
    // The immediate radio-side kill path remains combinational and unchanged.
    reg [7:0] status_radio = 8'h20;
    always @(posedge radio_clk) begin
        if (radio_reset)
            status_radio <= 8'h20;
        else
            status_radio <= {radio_path_ready, radio_arm, radio_kill,
                radio_tx_busy, mode_fault, tx_override_valid,
                response_active, response_pending};
    end

    wire [31:0] tx_done_sync_2, tx_error_sync_2, overflow_sync_2;
    wire [31:0] rx_psdu_sync_2, response_sync_2, deadline_sync_2, rejected_sync_2;
    // Diagnostic counters advance by at most one per radio clock. Registered
    // Gray encoding avoids incoherent binary carries crossing clock domains.
    // Packet RAM ownership uses the completion toggle, never a counter value.
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) cdc_done (radio_clk, radio_reset, tx_done_count_radio, bus_clk, bus_reset, tx_done_sync_2);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) cdc_error (radio_clk, radio_reset, tx_error_count_radio, bus_clk, bus_reset, tx_error_sync_2);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) cdc_overflow (radio_clk, radio_reset, fifo_overflow_count_radio, bus_clk, bus_reset, overflow_sync_2);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) cdc_rx (radio_clk, radio_reset, rx_psdu_count, bus_clk, bus_reset, rx_psdu_sync_2);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) cdc_response (radio_clk, radio_reset, response_count, bus_clk, bus_reset, response_sync_2);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) cdc_deadline (radio_clk, radio_reset, deadline_miss_count, bus_clk, bus_reset, deadline_sync_2);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) cdc_rejected (radio_clk, radio_reset, rejected_count, bus_clk, bus_reset, rejected_sync_2);

    integer tx_byte_index;
    always @(posedge bus_clk) begin
        if (bus_reset) begin
            armed_bus <= 1'b0;
            arm_key_valid <= 1'b0;
            ap_mac_bus <= DEFAULT_AP_MAC;
            rf_config_bus <= 3'b000;
            tx_bytes_written <= 13'd0;
            tx_length_bus <= 12'd0;
            tx_start_toggle_bus <= 1'b0;
            tx_inflight_bus <= 1'b0;
            tx_rejected_bus <= 32'd0;
            config_fault_bus <= 1'b0;
            radio_arm_bus_sync <= 2'b00;
            radio_kill_bus_sync <= 2'b11;
            radio_busy_bus_sync <= 2'b00;
            ready_bus_sync <= 2'b00;
            complete_bus_sync <= 2'b00;
            status_sync_1 <= 4'd0;
            status_sync_2 <= 4'd0;
            previous_tx_complete <= 1'b0;
        end else begin
            radio_arm_bus_sync <= {radio_arm_bus_sync[0], status_radio[6]};
            radio_kill_bus_sync <= {radio_kill_bus_sync[0], status_radio[5]};
            radio_busy_bus_sync <= {radio_busy_bus_sync[0], status_radio[4]};
            ready_bus_sync <= {ready_bus_sync[0], status_radio[7]};
            complete_bus_sync <= {complete_bus_sync[0], tx_complete_toggle_radio};
            status_sync_1 <= status_radio[3:0];
            status_sync_2 <= status_sync_1;

            if (complete_bus_sync[1] != previous_tx_complete) begin
                previous_tx_complete <= complete_bus_sync[1];
                tx_inflight_bus <= 1'b0;
            end
            if (radio_kill_bus_sync[1])
                tx_inflight_bus <= 1'b0;

            if (bus_write) begin
                case (bus_write_address)
                    REG_ARM_KEY: begin
                        arm_key_valid <=
                            bus_write_strobe == 4'hf &&
                            bus_write_data == ARM_KEY;
                    end

                    REG_CONTROL: begin
                        if (bus_write_data[1] || !bus_write_data[0]) begin
                            armed_bus <= 1'b0;
                            arm_key_valid <= 1'b0;
                            tx_bytes_written <= 13'd0;
                            tx_inflight_bus <= 1'b0;
                            config_fault_bus <= 1'b0;
                        end else if (bus_write_data[0] && arm_key_valid) begin
                            armed_bus <= 1'b1;
                            arm_key_valid <= 1'b0;
                        end else begin
                            armed_bus <= 1'b0;
                            config_fault_bus <= 1'b1;
                            tx_rejected_bus <= tx_rejected_bus + 1'b1;
                        end
                    end

                    REG_AP_MAC_LO: begin
                        if (!armed_bus) begin
                            for (tx_byte_index = 0; tx_byte_index < 4;
                                 tx_byte_index = tx_byte_index + 1)
                                if (bus_write_strobe[tx_byte_index])
                                    ap_mac_bus[tx_byte_index*8 +: 8] <=
                                        bus_write_data[tx_byte_index*8 +: 8];
                        end else begin
                            config_fault_bus <= 1'b1;
                        end
                    end

                    REG_AP_MAC_HI: begin
                        if (!armed_bus) begin
                            if (bus_write_strobe[0])
                                ap_mac_bus[39:32] <= bus_write_data[7:0];
                            if (bus_write_strobe[1])
                                ap_mac_bus[47:40] <= bus_write_data[15:8];
                        end else begin
                            config_fault_bus <= 1'b1;
                        end
                    end

                    REG_RF_CONFIG: begin
                        if (!armed_bus)
                            rf_config_bus <= bus_write_data[2:0];
                        else
                            config_fault_bus <= 1'b1;
                    end

                    REG_TX_WRITE: begin
                        if (armed_bus && !tx_inflight_bus &&
                            !radio_busy_bus_sync[1] &&
                            bus_write_strobe[0] && bus_write_strobe[1] &&
                            bus_write_strobe[2] &&
                            bus_write_data[19:8] == tx_bytes_written[11:0] &&
                            tx_bytes_written < 4095) begin
                            tx_memory[bus_write_data[19:8]] <=
                                bus_write_data[7:0];
                            tx_bytes_written <= tx_bytes_written + 1'b1;
                        end else begin
                            tx_rejected_bus <= tx_rejected_bus + 1'b1;
                        end
                    end

                    REG_TX_COMMIT: begin
                        if (armed_bus && !tx_inflight_bus &&
                            !radio_busy_bus_sync[1] &&
                            bus_write_data[11:0] != 0 &&
                            {1'b0, bus_write_data[11:0]} ==
                                tx_bytes_written) begin
                            tx_length_bus <= bus_write_data[11:0];
                            tx_start_toggle_bus <= ~tx_start_toggle_bus;
                            tx_inflight_bus <= 1'b1;
                            tx_bytes_written <= 13'd0;
                        end else begin
                            tx_rejected_bus <= tx_rejected_bus + 1'b1;
                            config_fault_bus <= 1'b1;
                        end
                    end

                    default: begin
                        tx_rejected_bus <= tx_rejected_bus + 1'b1;
                    end
                endcase
            end
        end
    end

    wire [31:0] rx_diagnostic_read_data;
    gf_e310_rx_capture #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE),
                         .PEAKS_TO_SOFTWARE(PEAKS_TO_SOFTWARE)) rx_diagnostic (
        .bus_clk(bus_clk), .bus_reset(bus_reset),
        .bus_write(bus_write && bus_write_strobe == 4'hf),
        .bus_address(bus_write_address), .bus_write_data(bus_write_data),
        .bus_read_address(bus_read_address), .bus_read_data(rx_diagnostic_read_data),
        .radio_clk(radio_clk), .radio_reset(radio_reset),
        .sample_valid(rx_sample_valid), .sample_iq(rx_sample_iq),
        .capture_veto(rx_capture_veto),
        .sfd_count(rx_sfd_count), .plcp_ok_count(rx_plcp_ok_count),
        .plcp_error_count(rx_plcp_error_count)
    );

    always @* begin
        case (bus_read_address)
            REG_MAGIC: bus_read_data = MAGIC;
            REG_CONTROL: bus_read_data = {30'd0, !armed_bus, armed_bus};
            REG_AP_MAC_LO: bus_read_data = ap_mac_bus[31:0];
            REG_AP_MAC_HI: bus_read_data = {16'd0, ap_mac_bus[47:32]};
            REG_STATUS: bus_read_data = {
                18'd0,
                ready_bus_sync[1],
                config_fault_bus,
                tx_error_sync_2 != 0,
                tx_done_sync_2 != 0,
                radio_busy_bus_sync[1],
                tx_inflight_bus,
                status_sync_2[3:0],
                overflow_sync_2 != 0,
                fifo_read_valid,
                radio_kill_bus_sync[1],
                radio_arm_bus_sync[1]
            };
            REG_PSDU_EVENT: bus_read_data = fifo_read_valid
                ? {1'b1, 21'd0, fifo_read_data}
                : 32'd0;
            REG_FIFO_OVERFLOW: bus_read_data = overflow_sync_2;
            REG_RX_PSDU_COUNT: bus_read_data = rx_psdu_sync_2;
            REG_RESPONSE_COUNT: bus_read_data = response_sync_2;
            REG_DEADLINE_MISS: bus_read_data = deadline_sync_2;
            REG_REJECTED_COUNT: bus_read_data = rejected_sync_2;
            REG_VERSION: bus_read_data = VERSION;
            12'h27c: bus_read_data = USE_HOST_WAVEFORM ? 32'h57463230 : 32'd0;
            12'h280: bus_read_data = COUNTERS_TO_SOFTWARE ? 32'h47523332 : 32'd0; // GR32
            12'h284: bus_read_data = PEAKS_TO_SOFTWARE ? 32'h504b5357 : 32'd0; // PKSW
            REG_TX_STATUS: bus_read_data = {
                16'd0, tx_bytes_written[12:0], config_fault_bus,
                radio_busy_bus_sync[1], tx_inflight_bus
            };
            REG_TX_DONE_COUNT: bus_read_data = tx_done_sync_2;
            REG_RF_CONFIG: bus_read_data = {29'd0, rf_config_bus};
            REG_TX_REJECTED: bus_read_data = tx_rejected_bus;
            REG_TX_ERROR_COUNT: bus_read_data = tx_error_sync_2;
            12'h250, 12'h254, 12'h258, 12'h25c,
            12'h260, 12'h264, 12'h268, 12'h26c, 12'h270, 12'h278:
                bus_read_data = rx_diagnostic_read_data;
            default: bus_read_data = 32'hdead0000 |
                {20'd0, bus_read_address};
        endcase
    end
endmodule

// Observation only: cannot arm RF, touch TX data, or change decoder state.
// 16384 consecutive {Q16,I16} samples (819.2 us at 20 MS/s). Amplitude mode
// starts at a threshold crossing; SFD mode retains a quarter-buffer pretrigger.
// Neither mode accepts a trigger during/just after our TX. No resampling.
// The CPU reads memory only after DONE; an explicit new ARM releases it.
module gf_e310_rx_capture #(
    parameter integer ADDRESS_BITS = 14,
    parameter integer COUNTERS_TO_SOFTWARE = 0,
    parameter integer PEAKS_TO_SOFTWARE = 0
) (
    input wire bus_clk, bus_reset, bus_write,
    input wire [11:0] bus_address, bus_read_address,
    input wire [31:0] bus_write_data,
    output reg [31:0] bus_read_data,
    input wire radio_clk, radio_reset, sample_valid,
    input wire [31:0] sample_iq,
    input wire capture_veto,
    input wire [31:0] sfd_count, plcp_ok_count, plcp_error_count
);
    reg request_toggle = 0;
    reg sfd_mode_bus = 0;
    reg [15:0] threshold_bus = 16'd256;
    reg [ADDRESS_BITS-1:0] read_index = 0;
    (* ram_style = "block" *) reg [31:0] memory [0:(1<<ADDRESS_BITS)-1];
    reg [31:0] memory_read;
    localparam integer PRETRIGGER_SAMPLES = (1<<ADDRESS_BITS)/4;
    (* ASYNC_REG = "TRUE" *) reg [1:0] request_sync = 0;
    (* ASYNC_REG = "TRUE" *) reg [15:0] threshold_sync1 = 256, threshold_sync2 = 256;
    reg request_seen = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sfd_mode_sync = 0;
    reg active_sfd_mode = 0;
    reg [31:0] previous_sfd = 0;
    reg [ADDRESS_BITS-1:0] start_index = 0;
    reg [ADDRESS_BITS:0] filled_samples = 0;
    reg [ADDRESS_BITS:0] post_remaining = 0;
    reg armed = 0, capturing = 0, done = 0;
    reg [15:0] active_threshold = 256;
    reg [ADDRESS_BITS-1:0] write_index = 0;
    reg [31:0] sample_count = 0;
    reg [15:0] peak_i = 0, peak_q = 0;
    reg [31:0] captured_peak = 0;
    reg [9:0] tx_guard = 0;
    wire [15:0] abs_i = sample_iq[15] ? (~sample_iq[15:0] + 16'd1) : sample_iq[15:0];
    wire [15:0] abs_q = sample_iq[31] ? (~sample_iq[31:16] + 16'd1) : sample_iq[31:16];
    wire trigger_now = sample_valid && armed && !capturing &&
        !capture_veto && tx_guard == 0 &&
        (active_sfd_mode ? (sfd_count != previous_sfd && filled_samples >= PRETRIGGER_SAMPLES)
                         : (abs_i >= active_threshold || abs_q >= active_threshold));
    wire store_sample = sample_valid && armed;
    (* ASYNC_REG = "TRUE" *) reg [2:0] status_sync1 = 0, status_sync2 = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] capture_mode_sync = 0;
    // Multi-bit frozen payload is stable several bus clocks before DONE is used.
    reg [31:0] peak_sync1 = 0, peak_sync2 = 0;
    reg [ADDRESS_BITS-1:0] start_sync1 = 0, start_sync2 = 0;
    wire [ADDRESS_BITS-1:0] memory_read_index = start_sync2 + read_index;
    wire [31:0] sfd_bus, plcp_ok_bus, plcp_error_bus, sample_count_bus;
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) diag_sfd (radio_clk, radio_reset, sfd_count, bus_clk, bus_reset, sfd_bus);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) diag_plcp (radio_clk, radio_reset, plcp_ok_count, bus_clk, bus_reset, plcp_ok_bus);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) diag_error (radio_clk, radio_reset, plcp_error_count, bus_clk, bus_reset, plcp_error_bus);
    gf_e310_counter_cdc #(.COUNTERS_TO_SOFTWARE(COUNTERS_TO_SOFTWARE)) diag_samples (radio_clk, radio_reset, sample_count, bus_clk, bus_reset, sample_count_bus);

    // True dual-clock RAM: no reset/clear loop, and read/write ports separate.
    always @(posedge radio_clk)
        if (!radio_reset && store_sample) memory[write_index] <= sample_iq;
    always @(posedge bus_clk) memory_read <= memory[memory_read_index];

    always @(posedge bus_clk) begin
        if (bus_reset) begin
            request_toggle <= 0;
            sfd_mode_bus <= 0;
            threshold_bus <= 256;
            read_index <= 0;
            status_sync1 <= 0;
            status_sync2 <= 0;
            capture_mode_sync <= 0;
            peak_sync1 <= 0;
            peak_sync2 <= 0;
            start_sync1 <= 0;
            start_sync2 <= 0;
        end else begin
            status_sync1 <= {done, capturing, armed};
            status_sync2 <= status_sync1;
            capture_mode_sync <= {capture_mode_sync[0], active_sfd_mode};
            peak_sync1 <= captured_peak;
            peak_sync2 <= peak_sync1;
            start_sync1 <= start_index;
            start_sync2 <= start_sync1;
            if (bus_write) begin
                case (bus_address)
                    12'h250: if (bus_write_data == 32'h52584341) request_toggle <= !request_toggle;
                    12'h254: threshold_bus <= bus_write_data[15:0];
                    12'h258: read_index <= bus_write_data[ADDRESS_BITS-1:0];
                    12'h278: sfd_mode_bus <= bus_write_data[0];
                endcase
            end
        end
    end
    always @(posedge radio_clk) begin
        if (radio_reset) begin
            request_sync <= 0;
            request_seen <= 0;
            sfd_mode_sync <= 0;
            active_sfd_mode <= 0;
            previous_sfd <= 0;
            start_index <= 0;
            filled_samples <= 0;
            post_remaining <= 0;
            threshold_sync1 <= 256;
            threshold_sync2 <= 256;
            armed <= 0;
            capturing <= 0;
            done <= 0;
            write_index <= 0;
            active_threshold <= 256;
            sample_count <= 0;
            peak_i <= 0;
            peak_q <= 0;
            captured_peak <= 0;
            tx_guard <= 0;
        end else begin
            request_sync <= {request_sync[0], request_toggle};
            sfd_mode_sync <= {sfd_mode_sync[0], sfd_mode_bus};
            threshold_sync1 <= threshold_bus;
            threshold_sync2 <= threshold_sync1;
            if (sample_valid) begin
                sample_count <= sample_count + 1'b1;
                previous_sfd <= sfd_count;
            end
            if (capture_veto) tx_guard <= 10'd800; // 20 us at 40 MHz after own TX.
            else if (tx_guard != 0) tx_guard <= tx_guard - 1'b1;
            if (request_sync[1] != request_seen) begin
                request_seen <= request_sync[1];
                armed <= 1;
                capturing <= 0;
                done <= 0;
                write_index <= 0;
                active_threshold <= threshold_sync2;
                active_sfd_mode <= sfd_mode_sync[1];
                filled_samples <= 0;
                post_remaining <= 0;
                peak_i <= 0;
                peak_q <= 0;
                captured_peak <= 0;
            end else if (store_sample) begin
                write_index <= write_index + 1'b1;
                if (filled_samples < PRETRIGGER_SAMPLES) filled_samples <= filled_samples + 1'b1;
                if (!PEAKS_TO_SOFTWARE && (capturing || trigger_now) && abs_i > peak_i) peak_i <= abs_i;
                if (!PEAKS_TO_SOFTWARE && (capturing || trigger_now) && abs_q > peak_q) peak_q <= abs_q;
                if (trigger_now) begin
                    capturing <= 1;
                    start_index <= active_sfd_mode ? write_index - PRETRIGGER_SAMPLES : write_index;
                    post_remaining <= (1<<ADDRESS_BITS) - 1 - (active_sfd_mode ? PRETRIGGER_SAMPLES : 0);
                end else if (capturing && post_remaining == 1) begin
                    armed <= 0;
                    capturing <= 0;
                    done <= 1;
                    if (!PEAKS_TO_SOFTWARE)
                        captured_peak <= {abs_q > peak_q ? abs_q : peak_q,
                                          abs_i > peak_i ? abs_i : peak_i};
                end else if (capturing) post_remaining <= post_remaining - 1'b1;
            end
        end
    end
    always @* begin
        case (bus_read_address)
            12'h250: bus_read_data = {16'd0, 8'(ADDRESS_BITS), 4'd0,
                (PEAKS_TO_SOFTWARE ? capture_mode_sync[1] : 1'b0), status_sync2};
            12'h254: bus_read_data = {16'd0, threshold_bus};
            12'h258: bus_read_data = {{(32-ADDRESS_BITS){1'b0}}, read_index};
            12'h25c: bus_read_data = status_sync2[2] ? memory_read : 32'd0;
            12'h260: bus_read_data = sfd_bus;
            12'h264: bus_read_data = plcp_ok_bus;
            12'h268: bus_read_data = plcp_error_bus;
            12'h26c: bus_read_data = sample_count_bus;
            12'h270: bus_read_data = status_sync2[2] ? peak_sync2 : 32'd0;
            12'h278: bus_read_data = {31'd0, sfd_mode_bus};
            default: bus_read_data = 32'hdead0000 | {20'd0, bus_read_address};
        endcase
    end
endmodule

// Coherent monotonic diagnostic counter transfer. Reset samples are not events.
module gf_e310_counter_cdc #(parameter integer COUNTERS_TO_SOFTWARE = 0) (
    input wire source_clk,
    input wire source_reset,
    input wire [31:0] source_count,
    input wire destination_clk,
    input wire destination_reset,
    output wire [31:0] destination_count
);
    reg [31:0] gray_radio = 32'd0;
    (* ASYNC_REG = "TRUE" *) reg [31:0] gray_sync_1 = 32'd0;
    (* ASYNC_REG = "TRUE" *) reg [31:0] gray_sync_2 = 32'd0;
    always @(posedge source_clk)
        if (source_reset) gray_radio <= 32'd0;
        else gray_radio <= source_count ^ (source_count >> 1);
    always @(posedge destination_clk) begin
        if (destination_reset) begin
            gray_sync_1 <= 32'd0;
            gray_sync_2 <= 32'd0;
        end else begin
            gray_sync_1 <= gray_radio;
            gray_sync_2 <= gray_sync_1;
        end
    end
    // The optional contract exposes the coherent Gray word unchanged. C++
    // decodes diagnostics; RF control and packet-RAM ownership do not use it.
    generate if(COUNTERS_TO_SOFTWARE) begin: software_decode
        assign destination_count = gray_sync_2;
    end else begin: hardware_decode
        // Preserve the legacy registered prefix-tree register contract.
        reg [31:0] decode_1=0, decode_2=0, decode_4=0, decode_8=0, decoded=0;
        assign destination_count = decoded;
        always @(posedge destination_clk) begin
            if(destination_reset) begin
                decode_1<=0; decode_2<=0; decode_4<=0; decode_8<=0; decoded<=0;
            end else begin
                decode_1 <= gray_sync_2 ^ (gray_sync_2 >> 1);
                decode_2 <= decode_1 ^ (decode_1 >> 2);
                decode_4 <= decode_2 ^ (decode_2 >> 4);
                decode_8 <= decode_4 ^ (decode_4 >> 8);
                decoded <= decode_8 ^ (decode_8 >> 16);
            end
        end
    end endgenerate
endmodule
