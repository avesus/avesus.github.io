// Offline replay of retained physical ADC samples, not new RF evidence.
`timescale 1ns/1fs
module tb_gf_rx_single_phase #(parameter SERIAL_COMPARE=0, parameter SCORE_RAM_COMPARE=0, parameter RECURSIVE_COMPARE=0, parameter SERIAL_BARKER_COMPARE=0, parameter BRIDGE_COMPARE=0);
    localparam integer BARKER_AGE=BRIDGE_COMPARE?7:6;
    reg clk=0,resetn=0,valid=0;
    always #12.5 clk=~clk;
    reg [31:0] iq=0;
    wire external_valid;
    wire bridge_resetn;
    wire signed [23:0] external_i,external_q;
    reg [5:0] delayed_resetn=0;
    always @(posedge clk)begin
        if(!resetn)delayed_resetn<=0;else delayed_resetn<={delayed_resetn[4:0],1'b1};
    end
    generate if(SERIAL_BARKER_COMPARE)begin:g_serial_barker_source
        reg fast_clk=0,fast_reset=1;
        always #1.5625 fast_clk=~fast_clk;
        if(BRIDGE_COMPARE)begin:g_actual_bridge
            wire fault;
            gf_barker_radio_bridge bridge(clk,fast_clk,resetn,1'b1,1'b1,valid,
                $signed(iq[15:0]),$signed(iq[31:16]),bridge_resetn,external_valid,fault,external_i,external_q);
            always @(posedge clk)if(resetn && fault)$fatal(1,"implemented bridge replay cadence fault");
        end else begin:g_ideal_bridge
        wire slot,fault,correlation_valid;
        wire signed [31:0] ci,cq;
        gf_barker_serial_iq graph(fast_clk,fast_reset,slot&valid,$signed(iq[15:0]),$signed(iq[31:16]),
            slot,fault,correlation_valid,ci,cq);
        initial begin
            wait(resetn && valid);@(posedge clk);#0.1;
            @(negedge fast_clk);fast_reset=0;
        end
        // TESTBENCH delivery into the 40-MHz same-clock receiver boundary.
        // This deliberately does not claim an implemented hardware CDC. The
        // implemented fast graph consumes the actual parallel sample stream.
        reg toggle=0,seen=0;
        reg signed [23:0] held_i=0,held_q=0;
        always @(posedge fast_clk)if(!fast_reset)begin
            if(fault)$fatal(1,"serial Barker replay sample cadence fault");
            if(correlation_valid)begin
                if(ci[31:24]!=={8{ci[23]}} || cq[31:24]!=={8{cq[23]}})
                    $fatal(1,"serial correlation not representable at unchanged 24-bit receiver boundary");
                held_i<=ci[23:0];held_q<=cq[23:0];toggle<=~toggle;
            end
        end
        always @(posedge clk)seen<=toggle;
        assign external_valid=toggle!=seen;
        assign external_i=held_i;assign external_q=held_q;
        assign bridge_resetn=delayed_resetn[5];
        end
    end else begin:g_no_external
        assign external_valid=0;assign external_i=0;assign external_q=0;
        assign bridge_resetn=resetn;
    end endgenerate
    integer bytes_seen[0:1],frames[0:1];
    reg [9:0] decoded[0:1][0:8191];
    time end_time[0:1];
    integer end_age[0:1];
    reg [31:0] crc[0:1];
    function automatic [31:0] crc_byte(input [31:0] old,input [7:0] b);
        reg [31:0] c;integer n;
        begin c=old^b;for(n=0;n<8;n=n+1)c=(c>>1)^(c[0]?32'hedb88320:0);crc_byte=c;end
    endfunction
    genvar m;
    generate for(m=0;m<2;m=m+1) begin: paths
        wire first,byte_valid,last,active;
        wire [7:0] b;
        wire [15:0] age;
        wire [31:0] sfd,plcp_ok,plcp_error,psdu;
        // Keep the serial detector's word epoch shifted with its input path.
        // Otherwise its fixed word boundaries quantize the added latency and
        // frame-end feedback can run against a different sample position.
        wire rx_resetn=(SERIAL_BARKER_COMPARE && m==1)?bridge_resetn:resetn;
        reg [31:0] prior_plcp_ok=0;
        gf_dsss_1mbps_rx #(.PIPELINED_DIFFERENTIAL(1),.SINGLE_PHASE_RX((SERIAL_COMPARE || SCORE_RAM_COMPARE || RECURSIVE_COMPARE || SERIAL_BARKER_COMPARE) ? 1 : m),
                          .SERIAL_DIFFERENTIAL(SERIAL_BARKER_COMPARE || RECURSIVE_COMPARE || SCORE_RAM_COMPARE || (SERIAL_COMPARE && m==1)),
                          .TIMING_SCORE_RAM(SERIAL_BARKER_COMPARE || RECURSIVE_COMPARE || (SCORE_RAM_COMPARE && m==1)),
                          .RECURSIVE_CORRELATOR(RECURSIVE_COMPARE && m==1),
                          .EXTERNAL_CORRELATOR(SERIAL_BARKER_COMPARE && m==1),.EXTERNAL_CORRELATOR_LATENCY(BARKER_AGE)) rx (
            .clk(clk),.resetn(rx_resetn),.enable(1'b1),.rx_sample_valid(valid),
            .rx_i($signed(iq[15:0])),.rx_q($signed(iq[31:16])),
            .psdu_start(first),.psdu_byte_valid(byte_valid),.psdu_byte(b),.psdu_byte_last(last),
            .psdu_end_age_cycles(age),.receiver_active(active),
            .sfd_count(sfd),.plcp_ok_count(plcp_ok),.plcp_error_count(plcp_error),.psdu_count(psdu),
            .external_correlation_valid(external_valid),.external_correlation_i(external_i),.external_correlation_q(external_q)
        );
        initial begin bytes_seen[m]=0;frames[m]=0;crc[m]=32'hffffffff;end
        // Optional diagnostic only. It does not weaken the complete-frame gate.
        always @(negedge clk) begin
            if($test$plusargs("PACKET_TRACE") && plcp_ok!=prior_plcp_ok)
                $display("RX_PLCP_TRACE path=%0d sample=%0d signal=%h length_us=%0d expected_bytes=%0d plcp_ok=%0d plcp_error=%0d",
                    m,samples,rx.plcp_signal,rx.plcp_length_us,rx.plcp_length_us>>3,plcp_ok,plcp_error);
            prior_plcp_ok=plcp_ok;
        end
        always @(negedge clk) if(byte_valid) begin
            if($test$plusargs("PACKET_TRACE"))
                $display("RX_BYTE_TRACE path=%0d sample=%0d index=%0d byte=%h first=%0d last=%0d",m,samples,bytes_seen[m],b,first,last);
            if(bytes_seen[m]>=8192)$fatal(1,"excess replay bytes");
            decoded[m][bytes_seen[m]]={first,last,b};bytes_seen[m]=bytes_seen[m]+1;
            if(first)crc[m]=32'hffffffff;
            crc[m]=crc_byte(crc[m],b);
            if(last) begin
                frames[m]=frames[m]+1;end_time[m]=$time;end_age[m]=age;
                $display("RX_PHASE_FRAME single=%0d bytes=%0d fcs=%0d phase=%0d end_ns=%0d age=%0d",m,bytes_seen[m],crc[m]==32'hdebb20e3,rx.locked_phase,$time,age);
                if(crc[m]!=32'hdebb20e3)$fatal(1,"physical-recording frame FCS failed");
            end
        end
    end endgenerate
    generate if(SERIAL_BARKER_COMPARE) begin:g_serial_barker_alignment
        reg [119:0] baseline_operands[0:BARKER_AGE-1];
        reg baseline_request[0:BARKER_AGE-1];
        wire request=paths[1].rx.selected_sample && paths[1].rx.phase_has_previous[0] && !paths[1].rx.serial_overflow;
        integer p;
        always @(posedge clk)begin
            baseline_operands[0]<={paths[0].rx.decision_correlation_i,paths[0].rx.decision_correlation_q,
                paths[0].rx.g_serial_differential.ai_pipe,paths[0].rx.g_serial_differential.bi_pipe,
                paths[0].rx.g_serial_differential.aq_pipe,paths[0].rx.g_serial_differential.bq_pipe};
            baseline_request[0]<=paths[0].rx.selected_sample && paths[0].rx.phase_has_previous[0] && !paths[0].rx.serial_overflow;
            for(p=1;p<BARKER_AGE;p=p+1)begin baseline_operands[p]<=baseline_operands[p-1];baseline_request[p]<=baseline_request[p-1];end
            if(resetn && paths[1].rx.process_sample_valid && paths[1].rx.window_fill>=20)begin
                if({paths[1].rx.decision_correlation_i,paths[1].rx.decision_correlation_q}!==baseline_operands[BARKER_AGE-1][119:72])
                    $fatal(1,"serial Barker correlation age mismatch sample=%0d",samples);
                if(request!==baseline_request[BARKER_AGE-1])$fatal(1,"serial Barker detector request mismatch sample=%0d",samples);
                // The first incomplete differential operand is not consumed:
                // phase_has_previous is false. Compare ALL actual requests,
                // including both current and previous I/Q signed operands.
                if(request && {paths[1].rx.g_serial_differential.ai_pipe,paths[1].rx.g_serial_differential.bi_pipe,
                    paths[1].rx.g_serial_differential.aq_pipe,paths[1].rx.g_serial_differential.bq_pipe}!==baseline_operands[BARKER_AGE-1][71:0])
                    $fatal(1,"serial Barker consumed operand mismatch sample=%0d",samples);
            end
        end
    end endgenerate
    string file_name;
    integer fd,result,n,samples=0,leading=0;
    reg [31:0] word_value;
    time delta;
    reg [4:0] prior_candidate=0;
    reg prior_hold=0;
    generate if(RECURSIVE_COMPARE) begin : g_recursive_alignment
    reg [83:0] baseline_operands[0:11];
    integer pipe_index;
    always @(posedge clk) begin
        baseline_operands[0]<={paths[0].rx.decision_correlation_i,
            paths[0].rx.decision_correlation_q,paths[0].rx.g_serial_differential.ai_pipe,
            paths[0].rx.g_serial_differential.aq_pipe};
        for(pipe_index=1;pipe_index<12;pipe_index=pipe_index+1)
            baseline_operands[pipe_index]<=baseline_operands[pipe_index-1];
        if(resetn && paths[1].rx.process_sample_valid && paths[1].rx.window_fill>=20 &&
            {paths[1].rx.decision_correlation_i,paths[1].rx.decision_correlation_q,
             paths[1].rx.g_serial_differential.ai_pipe,paths[1].rx.g_serial_differential.aq_pipe}
             !== baseline_operands[11])
            $fatal(1,"recursive correlation/operand alignment mismatch sample=%0d",samples);
    end
    end endgenerate
    always @(negedge clk) if (resetn && SCORE_RAM_COMPARE) begin
        if (paths[0].rx.current_timing_score !== paths[1].rx.current_timing_score ||
            paths[0].rx.timing_best_score !== paths[1].rx.timing_best_score ||
            paths[0].rx.timing_best_phase !== paths[1].rx.timing_best_phase ||
            paths[0].rx.candidate_phase !== paths[1].rx.candidate_phase)
            $fatal(1,"timing score RAM cycle-equivalence mismatch sample=%0d",samples);
    end
    always @(negedge clk) if($test$plusargs("PHASE_TRACE") && valid) begin
        if(samples>=1000 && samples<=4400 &&
           (paths[1].rx.candidate_phase!=prior_candidate || paths[1].rx.candidate_hold!=prior_hold))
            $display("PHASE_TRACE sample=%0d candidate=%0d best=%0d hold=%0d ones=%0d budget=%0d",samples,
                paths[1].rx.candidate_phase,paths[1].rx.timing_best_phase,paths[1].rx.candidate_hold,
                paths[1].rx.lane_one_run[0],paths[1].rx.lane_sfd_budget[0]);
        prior_candidate=paths[1].rx.candidate_phase;prior_hold=paths[1].rx.candidate_hold;
    end
    initial begin
        if(!$value$plusargs("IQ_FILE=%s",file_name))$fatal(1,"IQ_FILE required");
        result=$value$plusargs("LEADING_SAMPLES=%d",leading);
        fd=$fopen(file_name,"r");if(!fd)$fatal(1,"cannot open recording");
        repeat(6)@(negedge clk);resetn=1;
        repeat(leading) begin
            @(negedge clk);iq=0;valid=1;
            @(negedge clk);valid=0;samples=samples+1;
        end
        while(!$feof(fd))begin
            result=$fscanf(fd,"%h\n",word_value);
            if(result==1)begin
                @(negedge clk);iq=word_value;valid=1;
                @(negedge clk);valid=0;samples=samples+1;
            end else if(!$feof(fd))$fatal(1,"malformed retained hex");
        end
        $fclose(fd);
        if(SERIAL_BARKER_COMPARE)begin
            repeat(40)begin @(negedge clk);iq=0;valid=1;@(negedge clk);valid=0;end
        end else repeat(80)@(negedge clk);
        $display("RX_PHASE_REPLAY samples=%0d baseline_frames=%0d single_frames=%0d baseline_bytes=%0d single_bytes=%0d",samples,frames[0],frames[1],bytes_seen[0],bytes_seen[1]);
        if(frames[0]<1 || frames[1]!=frames[0] || bytes_seen[0]!=bytes_seen[1])$fatal(1,"phase acquisition/frame count mismatch");
        for(n=0;n<bytes_seen[0];n=n+1)if(decoded[0][n]!==decoded[1][n])$fatal(1,"PSDU mismatch index=%0d",n);
        if(SERIAL_COMPARE || RECURSIVE_COMPARE || SERIAL_BARKER_COMPARE) begin
            // Compare reconstructed decision boundaries from measured RTL
            // clock age; arithmetic latency itself is deliberately nonzero.
            delta=(end_time[0]-25*end_age[0])>(end_time[1]-25*end_age[1]) ?
                (end_time[0]-25*end_age[0])-(end_time[1]-25*end_age[1]) :
                (end_time[1]-25*end_age[1])-(end_time[0]-25*end_age[0]);
        end else delta=end_time[0]>end_time[1]?end_time[0]-end_time[1]:end_time[1]-end_time[0];
        // A deliberately tight A/B gate, not a claimed RF timing measurement.
        if(delta>100)$fatal(1,"phase-selection boundary moved more than 100 ns");
        if((SERIAL_COMPARE || SCORE_RAM_COMPARE || RECURSIVE_COMPARE || SERIAL_BARKER_COMPARE) && delta!=0)$fatal(1,"end-age/boundary mismatch");
        $display("RX_SINGLE_PHASE_REPLAY_PASS identical_psdu=true boundary_delta_ns=%0d new_rf=false",delta);
        $finish;
    end
endmodule
