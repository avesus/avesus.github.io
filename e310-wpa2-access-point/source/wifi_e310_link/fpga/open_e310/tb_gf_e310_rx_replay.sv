// Replay retained hardware ADC samples through both receiver arithmetic paths.
// This is offline analysis of a physical recording, not a new RF reception.
`timescale 1ns/1ps
module tb_gf_e310_rx_replay;
    reg clk=0;
    always #12.5 clk=~clk;
    reg resetn=0, sample_valid=0;
    reg [31:0] iq=0;
    integer expect_one_frame=0;
    function automatic [31:0] crc32_byte(input [31:0] current, input [7:0] value);
        reg [31:0] crc;
        integer bit_number;
        begin
            crc=current ^ value;
            for(bit_number=0;bit_number<8;bit_number=bit_number+1)
                crc=(crc>>1) ^ (crc[0] ? 32'hedb88320 : 32'd0);
            crc32_byte=crc;
        end
    endfunction
    wire [31:0] sfd[0:1], plcp_ok[0:1], plcp_error[0:1], psdu_count[0:1];
    genvar model;
    generate for(model=0;model<2;model=model+1) begin: receivers
        wire first, valid, last;
        wire [7:0] byte_value;
        wire [15:0] age;
        wire active;
        reg [31:0] frame_crc=32'hffffffff;
        integer frame_bytes=0;
        gf_dsss_1mbps_rx #(.PIPELINED_DIFFERENTIAL(model)) receiver (
            .clk(clk), .resetn(resetn), .enable(1'b1),
            .rx_sample_valid(sample_valid), .rx_i($signed(iq[15:0])),
            .rx_q($signed(iq[31:16])), .psdu_start(first), .psdu_byte_valid(valid),
            .psdu_byte(byte_value), .psdu_byte_last(last), .psdu_end_age_cycles(age),
            .receiver_active(active), .sfd_count(sfd[model]),
            .plcp_ok_count(plcp_ok[model]), .plcp_error_count(plcp_error[model]),
            .psdu_count(psdu_count[model])
        );
        always @(negedge clk) if(valid) begin
            if(first) begin frame_crc=32'hffffffff; frame_bytes=0; end
            frame_crc=crc32_byte(frame_crc,byte_value);
            frame_bytes=frame_bytes+1;
            $display("REPLAY_BYTE model=%0d first=%0d last=%0d byte=%02x", model, first, last, byte_value);
            if(last) begin
                $display("REPLAY_FCS model=%0d bytes=%0d valid=%0d",model,frame_bytes,frame_crc==32'hdebb20e3);
                if(expect_one_frame && frame_crc!=32'hdebb20e3)
                    $fatal(1,"Decoded physical recording failed FCS");
            end
        end
        always @(negedge clk)
            if(resetn && sample_valid && receiver.receive_state==1 && receiver.phase_index==receiver.locked_phase && receiver.plcp_bit_index==47)
                $display("REPLAY_PLCP model=%0d signal=%02x service=%02x length=%0d received_crc=%04x expected_crc=%04x", model,
                    receiver.plcp_signal, receiver.plcp_service, receiver.plcp_length_us,
                    receiver.completed_plcp_crc, receiver.plcp_crc_state ^ 16'hffff);
    end endgenerate
    string filename;
    integer file_handle, result, count=0;
    reg [31:0] word_value;
    initial begin
        expect_one_frame=$test$plusargs("EXPECT_ONE_FRAME");
        if(!$value$plusargs("IQ_FILE=%s",filename)) $fatal(1,"IQ_FILE required");
        file_handle=$fopen(filename,"r");
        if(!file_handle) $fatal(1,"Cannot open retained IQ hex");
        repeat(6) @(negedge clk); resetn=1;
        while(!$feof(file_handle)) begin
            result=$fscanf(file_handle,"%h\n",word_value);
            if(result==1) begin
                @(negedge clk); iq=word_value; sample_valid=1;
                @(negedge clk); sample_valid=0; count=count+1;
            end else if(!$feof(file_handle)) $fatal(1,"Bad IQ hex");
        end
        $fclose(file_handle);
        repeat(50) @(negedge clk);
        $display("REPLAY_DONE samples=%0d physical_recording_only=true",count);
        $display("REPLAY_MODEL direct sfd=%0d plcp_ok=%0d plcp_error=%0d psdu=%0d",sfd[0],plcp_ok[0],plcp_error[0],psdu_count[0]);
        $display("REPLAY_MODEL pipelined sfd=%0d plcp_ok=%0d plcp_error=%0d psdu=%0d",sfd[1],plcp_ok[1],plcp_error[1],psdu_count[1]);
        if(expect_one_frame) begin
            if(sfd[0]!=1 || sfd[1]!=1 || plcp_ok[0]!=1 || plcp_ok[1]!=1 ||
               plcp_error[0]!=0 || plcp_error[1]!=0 || psdu_count[0]!=1 || psdu_count[1]!=1)
                $fatal(1,"Expected exactly one complete valid frame in both models");
            $display("REPLAY_ONE_FRAME_REGRESSION_PASS physical_recording_analysis_only=true");
        end
        $finish;
    end
endmodule
