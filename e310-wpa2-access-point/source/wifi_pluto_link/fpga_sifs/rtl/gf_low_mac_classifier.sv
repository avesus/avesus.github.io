// Minimum IEEE 802.11 low-MAC classifier for immediate ACK/CTS decisions.
//
// The RX PHY supplies decoded PSDU bytes, including the four FCS bytes. This
// block retains only the fields needed before SIFS expires: Frame Control,
// Duration, receiver address, transmitter address, and CRC-32 state. Full
// management, WPA2, IP, TCP, and payload handling remains on the host.
//
// MAC values use network display order: 48'h024746415031 corresponds to
// 02:47:46:41:50:31 and byte 0 occupies bits [47:40].

`timescale 1ns/1ps

module gf_low_mac_classifier #(
    parameter integer DECISION_AGE_WIDTH = 16,
    parameter integer COUNT_WIDTH = 32,
    parameter integer EXTERNAL_FCS = 0,
    // The PHY accepts at most 4095 PSDU bytes. Low MAC only distinguishes
    // header offsets 0..27 and "beyond the minimum header". Never count the
    // remaining payload here; Windows receives every byte independently.
    // Zero retains the old implementation for cycle-exact differential tests.
    parameter integer SATURATING_HEADER_INDEX = 1
) (
    input  wire                            clk,
    input  wire                            resetn,
    input  wire [47:0]                     ap_mac,

    // psdu_start may accompany the first valid byte. psdu_byte_last marks the
    // final FCS byte. psdu_end_age_cycles is the PHY's age of that decision
    // relative to the received PPDU end.
    input  wire                            psdu_start,
    input  wire                            psdu_byte_valid,
    input  wire [7:0]                      psdu_byte,
    input  wire                            psdu_byte_last,
    input  wire [DECISION_AGE_WIDTH-1:0]   psdu_end_age_cycles,
    input  wire                            checked_fcs_ok,

    // These signals are sampled on the clock edge where decision_valid is 1.
    output wire                            decision_valid,
    output wire [DECISION_AGE_WIDTH-1:0]   decision_age_cycles,
    output wire                            decision_fcs_ok,
    output wire                            decision_ra_matches_ap,
    output wire                            decision_response_required,
    output wire                            decision_is_rts,
    output wire [47:0]                     decision_response_mac,
    output wire [15:0]                     decision_duration_us,
    output wire                            decision_malformed,

    output reg  [COUNT_WIDTH-1:0]          frame_count,
    output reg  [COUNT_WIDTH-1:0]          fcs_ok_count,
    output reg  [COUNT_WIDTH-1:0]          response_candidate_count,
    output reg  [COUNT_WIDTH-1:0]          malformed_count
);

    localparam [31:0] GOOD_FCS_RESIDUE = 32'hdebb_20e3;

    reg frame_active;
    localparam integer INDEX_WIDTH = SATURATING_HEADER_INDEX ? 5 : 16;
    reg [INDEX_WIDTH-1:0] byte_index;
    reg [31:0] crc_state;
    reg [7:0] frame_control_0;
    reg [15:0] duration_us;
    reg [47:0] receiver_address;
    reg [47:0] transmitter_address;

    function automatic [31:0] crc32_byte;
        input [31:0] crc_in;
        input [7:0] data;
        integer bit_number;
        reg [31:0] value;
        begin
            value = crc_in ^ data;
            for (bit_number = 0; bit_number < 8;
                 bit_number = bit_number + 1) begin
                if (value[0])
                    value = (value >> 1) ^ 32'hedb8_8320;
                else
                    value = value >> 1;
            end
            crc32_byte = value;
        end
    endfunction

    wire accepting_byte = psdu_byte_valid && (frame_active || psdu_start);
    wire [INDEX_WIDTH-1:0] active_byte_index = psdu_start ? {INDEX_WIDTH{1'b0}} : byte_index;
    wire [31:0] active_crc_state = psdu_start
        ? 32'hffff_ffff : crc_state;
    wire [31:0] crc_after_byte = crc32_byte(active_crc_state, psdu_byte);

    wire version_valid = frame_control_0[1:0] == 2'b00;
    wire [1:0] frame_type = frame_control_0[3:2];
    wire [3:0] frame_subtype = frame_control_0[7:4];
    wire is_management = frame_type == 2'b00;
    wire is_control = frame_type == 2'b01;
    wire is_data = frame_type == 2'b10;
    wire is_rts = is_control && frame_subtype == 4'b1011;
    wire is_ps_poll = is_control && frame_subtype == 4'b1010;
    wire aid_marker_ok = !is_ps_poll || duration_us[15:14] == 2'b11;
    wire ordinary_ack_candidate = is_management || is_data;
    wire minimum_length_ok = is_ps_poll ? active_byte_index == 16'd19 : is_rts
        ? active_byte_index >= 16'd19
        : (ordinary_ack_candidate ? active_byte_index >= 16'd27 : 1'b0);
    wire unicast_receiver = !receiver_address[40];
    wire response_candidate = version_valid && minimum_length_ok &&
        aid_marker_ok && unicast_receiver &&
        (ordinary_ack_candidate || is_rts || is_ps_poll);
    wire malformed_header = !version_valid || !aid_marker_ok ||
        ((ordinary_ack_candidate || is_rts || is_ps_poll) && !minimum_length_ok);

    assign decision_valid = accepting_byte && psdu_byte_last;
    assign decision_age_cycles = psdu_end_age_cycles;
    assign decision_fcs_ok = EXTERNAL_FCS ? checked_fcs_ok :
        crc_after_byte == GOOD_FCS_RESIDUE;
    assign decision_ra_matches_ap = receiver_address == ap_mac;
    assign decision_response_required = response_candidate;
    assign decision_is_rts = is_rts;
    assign decision_response_mac = transmitter_address;
    assign decision_duration_us = duration_us;
    // PS-Poll receives an ordinary ACK (not CTS). Its Duration/ID value is
    // therefore never used as a NAV duration by the existing SIFS scheduler.
    // Association/AID ownership and buffered delivery remain host decisions.
    assign decision_malformed = malformed_header;

    always @(posedge clk) begin
        if (!resetn) begin
            frame_active <= 1'b0;
            byte_index <= 16'd0;
            if (!EXTERNAL_FCS) crc_state <= 32'hffff_ffff;
            frame_control_0 <= 8'd0;
            duration_us <= 16'd0;
            receiver_address <= 48'd0;
            transmitter_address <= 48'd0;
            frame_count <= {COUNT_WIDTH{1'b0}};
            fcs_ok_count <= {COUNT_WIDTH{1'b0}};
            response_candidate_count <= {COUNT_WIDTH{1'b0}};
            malformed_count <= {COUNT_WIDTH{1'b0}};
        end else begin
            if (psdu_start) begin
                frame_active <= 1'b1;
                byte_index <= 16'd0;
                if (!EXTERNAL_FCS) crc_state <= 32'hffff_ffff;
                frame_control_0 <= 8'd0;
                duration_us <= 16'd0;
                receiver_address <= 48'd0;
                transmitter_address <= 48'd0;
            end

            if (accepting_byte) begin
                if (!EXTERNAL_FCS) crc_state <= crc_after_byte;
                case (active_byte_index)
                    16'd0: frame_control_0 <= psdu_byte;
                    16'd2: duration_us[7:0] <= psdu_byte;
                    16'd3: duration_us[15:8] <= psdu_byte;
                    16'd4: receiver_address[47:40] <= psdu_byte;
                    16'd5: receiver_address[39:32] <= psdu_byte;
                    16'd6: receiver_address[31:24] <= psdu_byte;
                    16'd7: receiver_address[23:16] <= psdu_byte;
                    16'd8: receiver_address[15:8] <= psdu_byte;
                    16'd9: receiver_address[7:0] <= psdu_byte;
                    16'd10: transmitter_address[47:40] <= psdu_byte;
                    16'd11: transmitter_address[39:32] <= psdu_byte;
                    16'd12: transmitter_address[31:24] <= psdu_byte;
                    16'd13: transmitter_address[23:16] <= psdu_byte;
                    16'd14: transmitter_address[15:8] <= psdu_byte;
                    16'd15: transmitter_address[7:0] <= psdu_byte;
                    default: begin end
                endcase

                if (psdu_byte_last) begin
                    frame_active <= 1'b0;
                    byte_index <= 16'd0;
                    frame_count <= frame_count + 1'b1;
                    if (decision_fcs_ok)
                        fcs_ok_count <= fcs_ok_count + 1'b1;
                    if (response_candidate)
                        response_candidate_count <=
                            response_candidate_count + 1'b1;
                    if (malformed_header)
                        malformed_count <= malformed_count + 1'b1;
                end else begin
                    // Saturate at 28, not 19 or 27: PS-Poll must be exactly
                    // 20 bytes including FCS, while ordinary frames need at
                    // least 28. Longer data/RTS frames remain distinguishable
                    // from exact-length PS-Poll without payload-length state.
                    if (!SATURATING_HEADER_INDEX || active_byte_index < 28)
                        byte_index <= active_byte_index + 1'b1;
                end
            end
        end
    end

endmodule
