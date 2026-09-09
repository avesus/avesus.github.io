// BRAM-free low-MAC SIFS island. The RX PHY supplies the transmitter MAC with
// each decision, so a previously unseen station can receive an immediate
// ACK/CTS without a host-configured lookup. ACK/CTS bytes, FCS, DSSS, and I/Q
// are generated locally after that decision.

`timescale 1ns/1ps

module gf_dsss_sifs_island #(
    parameter integer CLOCK_HZ = 20_000_000,
    parameter integer SIFS_US = 10,
    parameter integer STATION_SLOTS = 2,
    parameter integer STATION_WIDTH =
        (STATION_SLOTS <= 1) ? 1 : $clog2(STATION_SLOTS),
    parameter integer DECISION_AGE_WIDTH = 16,
    parameter integer IQ_WIDTH = 32,
    parameter integer SERIAL_CONTROL_CRC = 0,
    parameter integer DECISION_AGE_OFFSET = 0
) (
    input  wire                            clk,
    input  wire                            resetn,
    input  wire                            arm,
    input  wire                            kill,

    input  wire                            rx_frame_end,
    input  wire [DECISION_AGE_WIDTH-1:0]   rx_decision_age_cycles,
    input  wire                            rx_fcs_ok,
    input  wire                            rx_ra_matches_ap,
    input  wire                            rx_response_required,
    input  wire                            rx_is_rts,
    input  wire [STATION_WIDTH-1:0]        rx_station,
    input  wire [47:0]                     rx_response_mac,
    input  wire [15:0]                     rx_duration_us,

    input  wire                            tx_sample_tick,
    input  wire                            tx_sink_ready,
    output wire                            tx_override_valid,
    output wire [IQ_WIDTH-1:0]             tx_override_iq,
    output wire                            response_pending,
    output wire                            response_active,
    output wire                            response_start,
    output wire                            response_is_cts,
    output wire [STATION_WIDTH-1:0]        response_station,
    output wire [47:0]                     response_mac,
    output wire [15:0]                     response_duration_us,
    output wire [31:0]                     response_count,
    output wire [31:0]                     deadline_miss_count,
    output wire [31:0]                     rejected_count,
    output wire [31:0]                     stream_abort_count
);

    wire response_prepare;
    wire response_path_ready;
    wire response_done;
    wire deadline_miss;
    wire event_rejected;
    wire stream_abort;

    gf_sifs_scheduler #(
        .CLOCK_HZ(CLOCK_HZ),
        .SIFS_US(SIFS_US),
        .DECISION_AGE_OFFSET(DECISION_AGE_OFFSET),
        .STATION_SLOTS(STATION_SLOTS),
        .STATION_WIDTH(STATION_WIDTH),
        .DECISION_AGE_WIDTH(DECISION_AGE_WIDTH)
    ) scheduler (
        .clk(clk),
        .resetn(resetn),
        .arm(arm),
        .kill(kill),
        .rx_frame_end(rx_frame_end),
        .rx_decision_age_cycles(rx_decision_age_cycles),
        .rx_fcs_ok(rx_fcs_ok),
        .rx_ra_matches_ap(rx_ra_matches_ap),
        .rx_response_required(rx_response_required),
        .rx_is_rts(rx_is_rts),
        .rx_station(rx_station),
        .rx_response_mac(rx_response_mac),
        .rx_duration_us(rx_duration_us),
        .response_path_busy(response_active),
        .response_path_ready(response_path_ready),
        .response_pending(response_pending),
        .response_prepare(response_prepare),
        .response_start(response_start),
        .response_is_cts(response_is_cts),
        .response_station(response_station),
        .response_mac(response_mac),
        .response_duration_us(response_duration_us),
        .deadline_miss(deadline_miss),
        .event_rejected(event_rejected),
        .response_count(response_count),
        .deadline_miss_count(deadline_miss_count),
        .rejected_count(rejected_count)
    );

    gf_dsss_1mbps_control_tx #(
        .IQ_WIDTH(IQ_WIDTH),
        .SERIAL_CONTROL_CRC(SERIAL_CONTROL_CRC)
    ) formatter (
        .clk(clk),
        .resetn(resetn),
        .arm(arm),
        .kill(kill),
        .response_prepare(response_prepare),
        .response_start(response_start),
        .response_is_cts(response_is_cts),
        .response_duration_us(response_duration_us),
        .response_station_mac(response_mac),
        .tx_sample_tick(tx_sample_tick),
        .tx_sink_ready(tx_sink_ready),
        .response_path_ready(response_path_ready),
        .response_active(response_active),
        .tx_override_valid(tx_override_valid),
        .tx_override_iq(tx_override_iq),
        .response_done(response_done),
        .stream_abort(stream_abort),
        .stream_abort_count(stream_abort_count)
    );

endmodule
