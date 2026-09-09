// Unit check of supported PLCP fields; not a physical RF experiment.
`timescale 1ns/1ps
module tb_gf_dsss_plcp_service;
    reg clk = 0;
    always #12.5 clk = ~clk;
    gf_dsss_1mbps_rx receiver (
        .clk(clk), .resetn(1'b0), .enable(1'b0),
        .rx_sample_valid(1'b0), .rx_i(16'sd0), .rx_q(16'sd0)
    );
    integer service;
    initial begin
        force receiver.plcp_signal = 8'h0a;
        force receiver.plcp_length_us = 16'd360;
        for (service = 0; service < 256; service = service + 1) begin
            force receiver.plcp_service = service;
            #1;
            if (receiver.plcp_fields_valid !== (service == 0 || service == 4))
                $fatal(1, "Incorrect supported SERVICE mask: %02x", service);
        end
        force receiver.plcp_service = 8'h04;
        force receiver.plcp_signal = 8'h14;
        #1; if (receiver.plcp_fields_valid) $fatal(1, "Unsupported rate accepted");
        force receiver.plcp_signal = 8'h0a;
        force receiver.plcp_length_us = 16'd0;
        #1; if (receiver.plcp_fields_valid) $fatal(1, "Zero length accepted");
        force receiver.plcp_length_us = 16'd361;
        #1; if (receiver.plcp_fields_valid) $fatal(1, "Unaligned length accepted");
        force receiver.plcp_length_us = 16'd32768;
        #1; if (receiver.plcp_fields_valid) $fatal(1, "Oversize length accepted");
        $display("DSSS_PLCP_SERVICE_FIELDS_PASS service00=true service04=true other_service_bits_rejected=true");
        $finish;
    end
endmodule
