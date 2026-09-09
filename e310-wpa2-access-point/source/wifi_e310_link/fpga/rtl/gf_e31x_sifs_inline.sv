// Greenforest hard-real-time Wi-Fi receive/response insertion for Ettus E31x.
//
// The stock E31x radio sample format is signed IQ16 with the AD9361's twelve
// data bits left aligned. Channel zero occupies rx_flat/tx_flat[31:0] as
// {I[15:0], Q[15:0]}. Channel one is passed through unchanged.

`timescale 1ns/1ps

module gf_e31x_sifs_inline #(
    // At 20 MS/s in the stock two-channel (MIMO) interface, radio_clk is 40 MHz
    // and rx_sample_valid/tx_sample_tick assert once per channel-zero sample.
    parameter integer CLOCK_HZ = 40_000_000,
    parameter integer SIFS_US = 10,
    parameter integer SINGLE_PHASE_RX = 0,
    parameter integer SERIAL_DIFFERENTIAL = 0,
    parameter integer TIMING_SCORE_RAM = 0,
    parameter integer SERIAL_CONTROL_CRC = 0,
    parameter integer SERIAL_RX_CRC = 0,
    parameter integer RECURSIVE_CORRELATOR = 0,
    parameter integer SERIAL_BARKER = 0
) (
    input  wire                 clk,
    input  wire                 resetn,
    input  wire                 mode_mimo,
    input  wire                 arm,
    input  wire                 kill,
    input  wire [47:0]          ap_mac,

    input  wire                 rx_sample_valid,
    input  wire [63:0]          rx_flat,
    input  wire                 tx_sample_tick,
    input  wire [63:0]          host_tx_flat,
    output wire [63:0]          air_tx_flat,

    output wire                 host_psdu_start,
    output wire                 host_psdu_byte_valid,
    output wire [7:0]           host_psdu_byte,
    output wire                 host_psdu_byte_last,
    output wire [15:0]          host_psdu_end_age_cycles,

    output wire                 response_pending,
    output wire                 response_active,
    output wire                 response_start,
    output wire                 response_is_cts,
    output wire [47:0]          response_mac,
    output wire [15:0]          response_duration_us,
    output wire                 tx_override_valid,
    output wire                 mode_fault,

    output wire [31:0]          rx_sfd_count,
    output wire [31:0]          rx_plcp_ok_count,
    output wire [31:0]          rx_plcp_error_count,
    output wire [31:0]          rx_psdu_count,
    output wire [31:0]          classified_frame_count,
    output wire [31:0]          classified_fcs_ok_count,
    output wire [31:0]          response_candidate_count,
    output wire [31:0]          malformed_count,
    output wire [31:0]          response_count,
    output wire [31:0]          deadline_miss_count,
    output wire [31:0]          rejected_count,
    output wire [31:0]          stream_abort_count,
    input wire                  fast_clk,serial_clock_locked
);

    wire [31:0] tx_override_iq;
    (* ASYNC_REG = "TRUE" *) reg [1:0] mode_mimo_sync = 2'b00;
    always @(posedge clk) begin
        if (!resetn)
            mode_mimo_sync <= 2'b00;
        else
            mode_mimo_sync <= {mode_mimo_sync[0], mode_mimo};
    end

    wire mode_mimo_radio = mode_mimo_sync[1];
    wire local_kill = kill || !mode_mimo_radio;
    wire channel_zero_claim = response_pending || response_active ||
                              tx_override_valid;

    wire serial_barker_fault;
    assign mode_fault = arm && (!mode_mimo_radio || serial_barker_fault);

    // gf_dsss_* uses {Q, I}; E31x channel zero uses {I, Q}.
    wire [31:0] override_channel_zero = {
        tx_override_iq[15:0], tx_override_iq[31:16]
    };

    assign air_tx_flat[63:32] = host_tx_flat[63:32];
    assign air_tx_flat[31:0] = tx_override_valid ? override_channel_zero :
                               (channel_zero_claim ? 32'd0 :
                                host_tx_flat[31:0]);

    gf_dsss_rx_sifs_ap #(
        .CLOCK_HZ(CLOCK_HZ),
        .SIFS_US(SIFS_US),
        .SINGLE_PHASE_RX(SINGLE_PHASE_RX),
        .SERIAL_DIFFERENTIAL(SERIAL_DIFFERENTIAL),
        .TIMING_SCORE_RAM(TIMING_SCORE_RAM),
        .SERIAL_CONTROL_CRC(SERIAL_CONTROL_CRC),
        .SERIAL_RX_CRC(SERIAL_RX_CRC),
        .RECURSIVE_CORRELATOR(RECURSIVE_CORRELATOR),.SERIAL_BARKER(SERIAL_BARKER)
    ) low_mac (
        .clk(clk),
        .resetn(resetn),
        .arm(arm),
        .kill(local_kill),
        .ap_mac(ap_mac),
        .rx_sample_valid(rx_sample_valid),
        .rx_i($signed(rx_flat[31:16])),
        .rx_q($signed(rx_flat[15:0])),
        .tx_sample_tick(tx_sample_tick),
        .tx_sink_ready(1'b1),
        .tx_override_valid(tx_override_valid),
        .tx_override_iq(tx_override_iq),
        .response_pending(response_pending),
        .response_active(response_active),
        .response_start(response_start),
        .response_is_cts(response_is_cts),
        .response_mac(response_mac),
        .response_duration_us(response_duration_us),
        .host_psdu_start(host_psdu_start),
        .host_psdu_byte_valid(host_psdu_byte_valid),
        .host_psdu_byte(host_psdu_byte),
        .host_psdu_byte_last(host_psdu_byte_last),
        .host_psdu_end_age_cycles(host_psdu_end_age_cycles),
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
        .stream_abort_count(stream_abort_count),.fast_clk(fast_clk),.serial_clock_locked(serial_clock_locked),
        .serial_barker_fault(serial_barker_fault)
    );

endmodule
