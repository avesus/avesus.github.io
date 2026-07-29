/*
 * Lean coherent 16-byte telemetry snapshot for FT2232H MPSSE SPI mode 0.
 *
 * Byte-order contract: each 128-clock frame is sent MSB first.  Host byte 0
 * is source_live_frame_i[127:120], host byte 15 is [7:0], and bit 7 of each
 * byte is sampled first.  The first frame after configuration is zero; each
 * completed frame makes the snapshot requested at that frame's first clock
 * available to the following frame.
 */
`default_nettype none

module gf_mpsse_snapshot16_lean (
    input  wire         source_clk_i,
    input  wire [127:0] source_live_frame_i,
    input  wire         mpsse_sclk_i,
    input  wire         mpsse_cs_n_i,
    output wire         mpsse_miso_o
);
    /*
     * The MPSSE domain launches one toggle request at the first bit of every
     * 128-bit frame.  The source domain atomically captures the live frame
     * and returns the same toggle as its acknowledgement.  source_snapshot_q
     * then remains unchanged until the next request, so the destination can
     * copy the bundled bus only after the synchronized acknowledgement.
     */
    reg request_toggle_q = 1'b0;

    (* async_reg = "true" *) reg request_sync1_q = 1'b0;
    (* async_reg = "true" *) reg request_sync2_q = 1'b0;
    reg acknowledge_toggle_q = 1'b0;
    reg [127:0] source_snapshot_q = 128'd0;

    always @(posedge source_clk_i) begin
        request_sync1_q <= request_toggle_q;
        request_sync2_q <= request_sync1_q;

        if (request_sync2_q != acknowledge_toggle_q) begin
            source_snapshot_q    <= source_live_frame_i;
            acknowledge_toggle_q <= request_sync2_q;
        end
    end

    (* async_reg = "true" *) reg acknowledge_sync1_q = 1'b0;
    (* async_reg = "true" *) reg acknowledge_sync2_q = 1'b0;
    reg [127:0] transmit_frame_q = 128'd0;
    reg [6:0] bit_index_q = 7'd0;

    always @(posedge mpsse_sclk_i or posedge mpsse_cs_n_i) begin
        if (mpsse_cs_n_i) begin
            bit_index_q <= 7'd0;
        end else begin
            acknowledge_sync1_q <= acknowledge_toggle_q;
            acknowledge_sync2_q <= acknowledge_sync1_q;

            if (bit_index_q == 7'd0)
                request_toggle_q <= ~request_toggle_q;

            if (bit_index_q == 7'd127) begin
                bit_index_q <= 7'd0;

                /* At 30 MHz SCLK and 108 MHz source clock, the round trip
                   completes long before this boundary.  Equality identifies
                   the acknowledgement for this frame's request. */
                if (acknowledge_sync2_q == request_toggle_q)
                    transmit_frame_q <= source_snapshot_q;
            end else begin
                bit_index_q <= bit_index_q + 1'b1;
            end
        end
    end

    /* SPI mode 0 samples MISO on each rising SCLK edge.  The old bit index is
       therefore the bit sampled on that edge; the next bit settles afterward. */
    assign mpsse_miso_o = transmit_frame_q[7'd127 - bit_index_q];
endmodule

`default_nettype wire
