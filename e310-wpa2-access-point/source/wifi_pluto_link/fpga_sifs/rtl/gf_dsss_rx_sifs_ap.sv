// Complete hard-real-time 1 Mb/s receive-to-response path for a Pluto AP.
//
// RX1 IQ -> DSSS PHY -> decoded PSDU bytes -> FCS/RA/TA low-MAC ->
// air-relative SIFS scheduler -> locally generated ACK/CTS IQ for TX1.
// The decoded byte stream is also exposed unchanged for the host C++ stack.

`timescale 1ns/1ps

module gf_dsss_rx_sifs_ap #(
    parameter integer CLOCK_HZ = 20_000_000,
    parameter integer SIFS_US = 10,
    parameter integer DECISION_AGE_WIDTH = 16,
    parameter integer IQ_WIDTH = 32,
    parameter integer SINGLE_PHASE_RX = 0,
    parameter integer SERIAL_DIFFERENTIAL = 0,
    parameter integer TIMING_SCORE_RAM = 0,
    parameter integer SERIAL_CONTROL_CRC = 0,
    parameter integer SERIAL_RX_CRC = 0,
    parameter integer RECURSIVE_CORRELATOR = 0,
    parameter integer SERIAL_BARKER = 0
) (
    input  wire                            clk,
    input  wire                            resetn,
    input  wire                            arm,
    input  wire                            kill,
    input  wire [47:0]                     ap_mac,

    input  wire                            rx_sample_valid,
    input  wire signed [15:0]              rx_i,
    input  wire signed [15:0]              rx_q,

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

    output wire                            host_psdu_start,
    output wire                            host_psdu_byte_valid,
    output wire [7:0]                      host_psdu_byte,
    output wire                            host_psdu_byte_last,
    output wire [DECISION_AGE_WIDTH-1:0]   host_psdu_end_age_cycles,

    output wire [31:0]                     rx_sfd_count,
    output wire [31:0]                     rx_plcp_ok_count,
    output wire [31:0]                     rx_plcp_error_count,
    output wire [31:0]                     rx_psdu_count,
    output wire [31:0]                     classified_frame_count,
    output wire [31:0]                     classified_fcs_ok_count,
    output wire [31:0]                     response_candidate_count,
    output wire [31:0]                     malformed_count,
    output wire [31:0]                     response_count,
    output wire [31:0]                     deadline_miss_count,
    output wire [31:0]                     rejected_count,
    output wire [31:0]                     stream_abort_count,
    input wire                             fast_clk,
    input wire                             serial_clock_locked,
    output wire                            serial_barker_fault
);

    initial if (SERIAL_DIFFERENTIAL && CLOCK_HZ != 40_000_000)
        $error("Serial RX requires the qualified 40 MHz / 20 MS/s schedule");
    initial if(SERIAL_BARKER && (!SERIAL_DIFFERENTIAL || RECURSIVE_CORRELATOR))
        $error("Serial Barker requires serial differential and replaces the direct/recursive correlator");
    wire phy_resetn,external_valid;
    wire signed [23:0] external_i,external_q;
    wire phy_kill=kill || (SERIAL_BARKER && (!serial_clock_locked || serial_barker_fault));
    generate if(SERIAL_BARKER)begin:g_serial_barker
        gf_barker_radio_bridge bridge(
            .radio_clk(clk),.fast_clk(fast_clk),.resetn(resetn),.enable(arm && !kill),
            .clock_locked(serial_clock_locked),.sample_valid(rx_sample_valid),.sample_i(rx_i),.sample_q(rx_q),
            .receiver_resetn(phy_resetn),.result_valid(external_valid),.fault(serial_barker_fault),
            .correlation_i(external_i),.correlation_q(external_q));
    end else begin:g_legacy_barker
        assign phy_resetn=resetn;assign external_valid=0;assign external_i=0;assign external_q=0;
        assign serial_barker_fault=0;
    end endgenerate
    wire receiver_active_unused;
    wire decision_valid_unused;
    wire decision_fcs_ok_unused;
    wire decision_ra_matches_ap_unused;
    wire decision_response_required_unused;
    wire decision_is_rts_unused;
    wire [47:0] decision_response_mac_unused;
    wire [15:0] decision_duration_us_unused;
    wire decision_malformed_unused;
    wire rx_bit_valid, rx_bit_value, rx_crc_restart;
    wire mac_start, mac_valid, mac_last, checked_fcs_ok;
    wire [7:0] mac_byte;
    wire [DECISION_AGE_WIDTH-1:0] mac_age;

    generate if (SERIAL_RX_CRC) begin : g_rx_crc
        // Final decoded bit -> CRC update: 5 clocks. Residue reduction: 3
        // registered levels. Delay only the classifier's final-byte event by
        // ten clocks; the host's byte stream and its timestamp stay unchanged.
        localparam integer FINAL_DELAY = 10;
        wire clear = !resetn || !arm || phy_kill;
        wire [31:0] fcs;
        gf_control_crc_bitserial crc (
            .clk(clk),.clear(clear || rx_crc_restart),
            .bit_valid(rx_bit_valid),.data_bit(rx_bit_value),.fcs(fcs)
        );
        gf_rx_crc_residue residue (
            .clk(clk),.clear(clear || rx_crc_restart),.fcs(fcs),.good(checked_fcs_ok)
        );
        reg [FINAL_DELAY-1:0] last_pipe;
        reg last_start;
        always @(posedge clk) begin
            if (clear) begin
                last_pipe <= 0;
                last_start <= 0;
            end else begin
                last_pipe <= {last_pipe[FINAL_DELAY-2:0],
                              host_psdu_byte_valid && host_psdu_byte_last};
                if (host_psdu_byte_valid && host_psdu_byte_last) begin
                    last_start <= host_psdu_start;
                end
            end
        end
        assign mac_last = last_pipe[FINAL_DELAY-1];
        assign mac_valid = (host_psdu_byte_valid && !host_psdu_byte_last) || mac_last;
        assign mac_start = (host_psdu_start && !host_psdu_byte_last) || (mac_last && last_start);
        // The PHY keeps byte/age registered until the next decoded byte, at
        // least 320 clocks later. Reuse those registers. Absorb the ten-clock
        // decision offset in the scheduler constant, not another wide adder.
        assign mac_byte = host_psdu_byte;
        assign mac_age = host_psdu_end_age_cycles;
    end else begin : g_byte_crc
        assign mac_start = host_psdu_start;
        assign mac_valid = host_psdu_byte_valid;
        assign mac_byte = host_psdu_byte;
        assign mac_last = host_psdu_byte_last;
        assign mac_age = host_psdu_end_age_cycles;
        assign checked_fcs_ok = 1'b0;
    end endgenerate

    gf_dsss_1mbps_rx #(
        .DECISION_AGE_WIDTH(DECISION_AGE_WIDTH),
        .PIPELINED_DIFFERENTIAL(CLOCK_HZ >= 40_000_000),
        .SINGLE_PHASE_RX(SINGLE_PHASE_RX),
        .SERIAL_DIFFERENTIAL(SERIAL_DIFFERENTIAL),
        .TIMING_SCORE_RAM(TIMING_SCORE_RAM),
        .RECURSIVE_CORRELATOR(RECURSIVE_CORRELATOR),
        .EXTERNAL_CORRELATOR(SERIAL_BARKER),.EXTERNAL_CORRELATOR_LATENCY(7)
    ) receiver (
        .clk(clk),
        .resetn(phy_resetn),
        .enable(arm && !phy_kill),
        .rx_sample_valid(rx_sample_valid),
        .rx_i(rx_i),
        .rx_q(rx_q),
        .psdu_start(host_psdu_start),
        .psdu_byte_valid(host_psdu_byte_valid),
        .psdu_byte(host_psdu_byte),
        .psdu_byte_last(host_psdu_byte_last),
        .psdu_end_age_cycles(host_psdu_end_age_cycles),
        .receiver_active(receiver_active_unused),
        .psdu_bit_valid(rx_bit_valid),
        .psdu_bit_value(rx_bit_value),
        .psdu_crc_restart(rx_crc_restart),
        .sfd_count(rx_sfd_count),
        .plcp_ok_count(rx_plcp_ok_count),
        .plcp_error_count(rx_plcp_error_count),
        .psdu_count(rx_psdu_count),
        .external_correlation_valid(external_valid),.external_correlation_i(external_i),.external_correlation_q(external_q)
    );

    gf_dsss_sifs_low_mac #(
        .CLOCK_HZ(CLOCK_HZ),
        .SIFS_US(SIFS_US),
        .DECISION_AGE_WIDTH(DECISION_AGE_WIDTH),
        .IQ_WIDTH(IQ_WIDTH),
        .SERIAL_CONTROL_CRC(SERIAL_CONTROL_CRC),
        .EXTERNAL_FCS(SERIAL_RX_CRC),
        .DECISION_AGE_OFFSET(SERIAL_RX_CRC ? 10 : 0)
    ) low_mac_response (
        .clk(clk),
        .resetn(resetn),
        .arm(arm),
        .kill(phy_kill),
        .ap_mac(ap_mac),
        .psdu_start(mac_start),
        .psdu_byte_valid(mac_valid),
        .psdu_byte(mac_byte),
        .psdu_byte_last(mac_last),
        .psdu_end_age_cycles(mac_age),
        .checked_fcs_ok(checked_fcs_ok),
        .tx_sample_tick(tx_sample_tick),
        .tx_sink_ready(tx_sink_ready),
        .tx_override_valid(tx_override_valid),
        .tx_override_iq(tx_override_iq),
        .response_pending(response_pending),
        .response_active(response_active),
        .response_start(response_start),
        .response_is_cts(response_is_cts),
        .response_mac(response_mac),
        .response_duration_us(response_duration_us),
        .response_count(response_count),
        .deadline_miss_count(deadline_miss_count),
        .rejected_count(rejected_count),
        .stream_abort_count(stream_abort_count),
        .decision_valid(decision_valid_unused),
        .decision_fcs_ok(decision_fcs_ok_unused),
        .decision_ra_matches_ap(decision_ra_matches_ap_unused),
        .decision_response_required(decision_response_required_unused),
        .decision_is_rts(decision_is_rts_unused),
        .decision_response_mac(decision_response_mac_unused),
        .decision_duration_us(decision_duration_us_unused),
        .decision_malformed(decision_malformed_unused),
        .classified_frame_count(classified_frame_count),
        .classified_fcs_ok_count(classified_fcs_ok_count),
        .response_candidate_count(response_candidate_count),
        .malformed_count(malformed_count)
    );

endmodule

// Complemented IEEE CRC-32 residue = ~32'hdebb20e3. Explicit registered
// LUT4 reduction, with a register at every level. Each CRC bit drives only
// its recurrence and one comparator input; no wide inferred comparator.
module gf_rx_crc_residue (
    input wire clk, clear,
    input wire [31:0] fcs,
    output wire good
);
    localparam [31:0] EXPECTED = 32'h2144df1c;
    wire [7:0] groups;
    wire [1:0] halves;
    generate for (genvar node=0;node<8;node=node+1) begin : g_groups
        wire matched;
        gf_serial_lut #(.INIT(16'h0001 << EXPECTED[node*4 +: 4])) compare (
            .a(fcs[node*4]),.b(fcs[node*4+1]),
            .c(fcs[node*4+2]),.d(fcs[node*4+3]),.q(matched)
        );
        gf_serial_reg r(.clk(clk),.reset(clear),.d(matched),.q(groups[node]));
    end
    for (genvar node=0;node<2;node=node+1) begin : g_halves
        wire matched;
        gf_serial_lut #(.INIT(16'h8000)) combine (
            .a(groups[node*4]),.b(groups[node*4+1]),
            .c(groups[node*4+2]),.d(groups[node*4+3]),.q(matched)
        );
        gf_serial_reg r(.clk(clk),.reset(clear),.d(matched),.q(halves[node]));
    end endgenerate
    wire both;
    gf_serial_lut #(.INIT(16'h8888)) combine (
        .a(halves[0]),.b(halves[1]),.c(1'b0),.d(1'b0),.q(both)
    );
    gf_serial_reg result(.clk(clk),.reset(clear),.d(both),.q(good));
endmodule
