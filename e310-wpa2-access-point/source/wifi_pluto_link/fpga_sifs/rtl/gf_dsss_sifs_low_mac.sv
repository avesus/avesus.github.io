// End-to-end hard-real-time boundary from decoded PSDU bytes to TX1 I/Q.
// A separate RX PHY owns synchronization/demodulation and supplies this byte
// stream. This wrapper performs the minimum low-MAC classification and then
// generates an ACK or CTS locally at the original air-relative SIFS deadline.

`timescale 1ns/1ps

module gf_dsss_sifs_low_mac #(
    parameter integer CLOCK_HZ = 20_000_000,
    parameter integer SIFS_US = 10,
    parameter integer DECISION_AGE_WIDTH = 16,
    parameter integer IQ_WIDTH = 32,
    parameter integer SERIAL_CONTROL_CRC = 0,
    parameter integer EXTERNAL_FCS = 0,
    parameter integer DECISION_AGE_OFFSET = 0
) (
    input  wire                            clk,
    input  wire                            resetn,
    input  wire                            arm,
    input  wire                            kill,
    input  wire [47:0]                     ap_mac,

    input  wire                            psdu_start,
    input  wire                            psdu_byte_valid,
    input  wire [7:0]                      psdu_byte,
    input  wire                            psdu_byte_last,
    input  wire [DECISION_AGE_WIDTH-1:0]   psdu_end_age_cycles,
    input  wire                            checked_fcs_ok,

    input  wire                            tx_sample_tick,
    input  wire                            tx_sink_ready,
    output wire                            tx_override_valid,
    output wire [IQ_WIDTH-1:0]             tx_override_iq,
    output wire                            response_pending,
    output wire                            response_active,
    output wire                            response_start,
    output wire                            response_is_cts,
    output wire [47:0]                     response_mac,
    output wire [15:0]                     response_duration_us,
    output wire [31:0]                     response_count,
    output wire [31:0]                     deadline_miss_count,
    output wire [31:0]                     rejected_count,
    output wire [31:0]                     stream_abort_count,

    output wire                            decision_valid,
    output wire                            decision_fcs_ok,
    output wire                            decision_ra_matches_ap,
    output wire                            decision_response_required,
    output wire                            decision_is_rts,
    output wire [47:0]                     decision_response_mac,
    output wire [15:0]                     decision_duration_us,
    output wire                            decision_malformed,
    output wire [31:0]                     classified_frame_count,
    output wire [31:0]                     classified_fcs_ok_count,
    output wire [31:0]                     response_candidate_count,
    output wire [31:0]                     malformed_count
);

    wire [DECISION_AGE_WIDTH-1:0] decision_age_cycles;
    wire response_station_unused;

    gf_low_mac_classifier #(
        .DECISION_AGE_WIDTH(DECISION_AGE_WIDTH),
        .EXTERNAL_FCS(EXTERNAL_FCS)
    ) classifier (
        .clk(clk),
        .resetn(resetn),
        .ap_mac(ap_mac),
        .psdu_start(psdu_start),
        .psdu_byte_valid(psdu_byte_valid),
        .psdu_byte(psdu_byte),
        .psdu_byte_last(psdu_byte_last),
        .psdu_end_age_cycles(psdu_end_age_cycles),
        .checked_fcs_ok(checked_fcs_ok),
        .decision_valid(decision_valid),
        .decision_age_cycles(decision_age_cycles),
        .decision_fcs_ok(decision_fcs_ok),
        .decision_ra_matches_ap(decision_ra_matches_ap),
        .decision_response_required(decision_response_required),
        .decision_is_rts(decision_is_rts),
        .decision_response_mac(decision_response_mac),
        .decision_duration_us(decision_duration_us),
        .decision_malformed(decision_malformed),
        .frame_count(classified_frame_count),
        .fcs_ok_count(classified_fcs_ok_count),
        .response_candidate_count(response_candidate_count),
        .malformed_count(malformed_count)
    );

    gf_dsss_sifs_island #(
        .CLOCK_HZ(CLOCK_HZ),
        .SIFS_US(SIFS_US),
        .STATION_SLOTS(1),
        .DECISION_AGE_OFFSET(DECISION_AGE_OFFSET),
        .DECISION_AGE_WIDTH(DECISION_AGE_WIDTH),
        .IQ_WIDTH(IQ_WIDTH),
        .SERIAL_CONTROL_CRC(SERIAL_CONTROL_CRC)
    ) response_island (
        .clk(clk),
        .resetn(resetn),
        .arm(arm),
        .kill(kill),
        .rx_frame_end(decision_valid),
        .rx_decision_age_cycles(decision_age_cycles),
        .rx_fcs_ok(decision_fcs_ok),
        .rx_ra_matches_ap(decision_ra_matches_ap),
        .rx_response_required(decision_response_required),
        .rx_is_rts(decision_is_rts),
        .rx_station(1'b0),
        .rx_response_mac(decision_response_mac),
        .rx_duration_us(decision_duration_us),
        .tx_sample_tick(tx_sample_tick),
        .tx_sink_ready(tx_sink_ready),
        .tx_override_valid(tx_override_valid),
        .tx_override_iq(tx_override_iq),
        .response_pending(response_pending),
        .response_active(response_active),
        .response_start(response_start),
        .response_is_cts(response_is_cts),
        .response_station(response_station_unused),
        .response_mac(response_mac),
        .response_duration_us(response_duration_us),
        .response_count(response_count),
        .deadline_miss_count(deadline_miss_count),
        .rejected_count(rejected_count),
        .stream_abort_count(stream_abort_count)
    );

endmodule
