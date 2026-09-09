// Deterministic IEEE 802.11 immediate-response scheduler.
//
// This block deliberately owns only the hard real-time low-MAC boundary.  A
// receive PHY presents a decision after checking FCS and the receiver address,
// together with the number of clocks already elapsed since the PPDU ended.
// The scheduler subtracts that decode age, then either starts ACK/CTS exactly
// SIFS after the air-frame boundary or drops the response. It never emits late.
//
// The response formatter/player is downstream.  Windows remains responsible
// for management, WPA2, DHCP, ARP, TCP, and HTTP.

`timescale 1ns/1ps

module gf_sifs_scheduler #(
    parameter integer CLOCK_HZ = 100_000_000,
    parameter integer SIFS_US = 10,
    parameter integer CTS_AIRTIME_US = 304,
    parameter integer STATION_SLOTS = 2,
    parameter integer STATION_WIDTH =
        (STATION_SLOTS <= 1) ? 1 : $clog2(STATION_SLOTS),
    parameter integer DECISION_AGE_WIDTH = 16,
    parameter integer COUNT_WIDTH = 32,
    // Fixed pipeline delay after the PHY timestamp, folded into constants.
    parameter integer DECISION_AGE_OFFSET = 0
) (
    input  wire                         clk,
    input  wire                         resetn,

    // The host arms a bounded experiment. kill has immediate priority.
    input  wire                         arm,
    input  wire                         kill,

    // Pulse when the receive decision is valid. rx_decision_age_cycles plus
    // DECISION_AGE_OFFSET is the elapsed time from PPDU end to this clock edge.
    input  wire                         rx_frame_end,
    input  wire [DECISION_AGE_WIDTH-1:0] rx_decision_age_cycles,
    input  wire                         rx_fcs_ok,
    input  wire                         rx_ra_matches_ap,
    input  wire                         rx_response_required,
    input  wire                         rx_is_rts,
    input  wire [STATION_WIDTH-1:0]     rx_station,
    input  wire [47:0]                  rx_response_mac,
    input  wire [15:0]                  rx_duration_us,

    // Must already be true at the deadline. There is intentionally no retry.
    input  wire                         response_path_busy,
    input  wire                         response_path_ready,

    output reg                          response_pending,
    output reg                          response_prepare,
    output reg                          response_start,
    output reg                          response_is_cts,
    output reg  [STATION_WIDTH-1:0]     response_station,
    output reg  [47:0]                  response_mac,
    output reg  [15:0]                  response_duration_us,

    output reg                          deadline_miss,
    output reg                          event_rejected,
    output reg  [COUNT_WIDTH-1:0]       response_count,
    output reg  [COUNT_WIDTH-1:0]       deadline_miss_count,
    output reg  [COUNT_WIDTH-1:0]       rejected_count
);

    localparam integer CLOCKS_PER_US = CLOCK_HZ / 1_000_000;
    localparam integer SIFS_CYCLES = CLOCKS_PER_US * SIFS_US;
    localparam integer DECISION_BUDGET = SIFS_CYCLES - DECISION_AGE_OFFSET;
    localparam integer WAIT_WIDTH =
        (SIFS_CYCLES <= 1) ? 1 : $clog2(SIFS_CYCLES + 1);
    localparam integer CTS_SUBTRACT_US = SIFS_US + CTS_AIRTIME_US;

    reg [WAIT_WIDTH-1:0] wait_cycles;

    initial begin
        if ((CLOCK_HZ % 1_000_000) != 0)
            $error("CLOCK_HZ must be an integer multiple of 1 MHz");
        if (SIFS_CYCLES < 1)
            $error("SIFS must contain at least one clock cycle");
        if (DECISION_AGE_OFFSET < 0 || DECISION_BUDGET < 1)
            $error("Fixed decision pipeline must fit inside SIFS");
        if (STATION_SLOTS < 1 ||
            STATION_SLOTS > (1 << STATION_WIDTH))
            $error("STATION_SLOTS does not fit STATION_WIDTH");
        if (DECISION_AGE_WIDTH < WAIT_WIDTH)
            $error("DECISION_AGE_WIDTH cannot represent the SIFS interval");
    end

    wire station_in_range = rx_station < STATION_SLOTS;
    wire eligible_event = rx_fcs_ok && rx_ra_matches_ap &&
                          rx_response_required && station_in_range;

    wire [15:0] cts_duration =
        (rx_duration_us > CTS_SUBTRACT_US)
            ? rx_duration_us - CTS_SUBTRACT_US
            : 16'd0;

    wire decision_before_deadline =
        rx_decision_age_cycles < DECISION_BUDGET;
    wire [WAIT_WIDTH-1:0] remaining_wait_cycles =
        DECISION_BUDGET[WAIT_WIDTH-1:0] -
        rx_decision_age_cycles[WAIT_WIDTH-1:0];

    always @(posedge clk) begin
        if (!resetn) begin
            response_pending <= 1'b0;
            response_prepare <= 1'b0;
            response_start <= 1'b0;
            response_is_cts <= 1'b0;
            response_station <= {STATION_WIDTH{1'b0}};
            response_mac <= 48'd0;
            response_duration_us <= 16'd0;
            deadline_miss <= 1'b0;
            event_rejected <= 1'b0;
            response_count <= {COUNT_WIDTH{1'b0}};
            deadline_miss_count <= {COUNT_WIDTH{1'b0}};
            rejected_count <= {COUNT_WIDTH{1'b0}};
            wait_cycles <= {WAIT_WIDTH{1'b0}};
        end else begin
            response_prepare <= 1'b0;
            response_start <= 1'b0;
            deadline_miss <= 1'b0;
            event_rejected <= 1'b0;

            if (kill || !arm) begin
                response_pending <= 1'b0;
                wait_cycles <= {WAIT_WIDTH{1'b0}};
            end else begin
                if (response_pending) begin
                    if (wait_cycles > 1) begin
                        wait_cycles <= wait_cycles - 1'b1;
                    end else begin
                        // Exact deadline: start now or abandon this response.
                        response_pending <= 1'b0;
                        wait_cycles <= {WAIT_WIDTH{1'b0}};
                        if (response_path_ready) begin
                            response_start <= 1'b1;
                            response_count <= response_count + 1'b1;
                        end else begin
                            deadline_miss <= 1'b1;
                            deadline_miss_count <= deadline_miss_count + 1'b1;
                        end
                    end
                end

                if (rx_frame_end && rx_response_required) begin
                    if (!eligible_event || response_pending ||
                        response_path_busy) begin
                        event_rejected <= 1'b1;
                        rejected_count <= rejected_count + 1'b1;
                    end else if (!decision_before_deadline) begin
                        // The PHY decision arrived at or after the air SIFS
                        // boundary. Count it, but never transmit a late reply.
                        deadline_miss <= 1'b1;
                        deadline_miss_count <= deadline_miss_count + 1'b1;
                    end else begin
                        response_pending <= 1'b1;
                        response_prepare <= 1'b1;
                        wait_cycles <= remaining_wait_cycles;
                        response_is_cts <= rx_is_rts;
                        response_station <= rx_station;
                        response_mac <= rx_response_mac;
                        response_duration_us <= rx_is_rts
                            ? cts_duration : 16'd0;
                    end
                end
            end
        end
    end

endmodule
