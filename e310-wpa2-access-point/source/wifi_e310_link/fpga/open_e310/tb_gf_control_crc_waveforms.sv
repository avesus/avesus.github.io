`timescale 1ns/1ps
module tb_gf_control_crc_waveforms;
    reg clk=0,resetn=0,arm=0,kill=0,prepare=0,start=0,is_cts=0,ready=1;
    always #5 clk=~clk;
    reg [15:0] duration=0;
    reg [47:0] mac=0;
    integer cycle=0,tick_mode=0,parity=0,frame=0,samples=0,fd,frames=0,total_samples=0;
    reg capture=0;
    reg [31:0] rng=32'h9049eacd;
    wire tick=tick_mode==0 || (tick_mode==1 && cycle%2==parity) || (tick_mode==2 && cycle%3==parity);
    always @(posedge clk)cycle<=cycle+1;
    wire [1:0] path_ready,active,iq_valid,done,abort;
    wire [31:0] iq[0:1],abort_count[0:1];
    genvar m;
    generate for(m=0;m<2;m=m+1)begin:paths
        gf_dsss_1mbps_control_tx #(.SERIAL_CONTROL_CRC(m)) tx (
            .clk(clk),.resetn(resetn),.arm(arm),.kill(kill),
            .response_prepare(prepare),.response_start(start),.response_is_cts(is_cts),
            .response_duration_us(duration),.response_station_mac(mac),
            .tx_sample_tick(tick),.tx_sink_ready(ready),.response_path_ready(path_ready[m]),
            .response_active(active[m]),.tx_override_valid(iq_valid[m]),.tx_override_iq(iq[m]),
            .response_done(done[m]),.stream_abort(abort[m]),.stream_abort_count(abort_count[m])
        );
    end endgenerate
    always @(posedge clk)if(resetn)begin
        if(path_ready[0]!==path_ready[1] || active[0]!==active[1] ||
           iq_valid[0]!==iq_valid[1] || done[0]!==done[1] || abort[0]!==abort[1] ||
           abort_count[0]!==abort_count[1])$fatal(1,"formatter handshake difference");
        if(iq_valid[0] && tick && ready)begin
            if(iq[0]!==iq[1])$fatal(1,"formatter sample difference frame=%0d sample=%0d",frame,samples);
            if(capture)begin
                $fdisplay(fd,"%08x",iq[1]);samples=samples+1;total_samples=total_samples+1;
            end
        end
    end
    task prepare_start;
        begin
            @(negedge clk);prepare=1;
            @(negedge clk);prepare=0;
            repeat(frame%7)@(negedge clk);
            if(path_ready!==2'b11)$fatal(1,"preparation readiness moved");
            start=1;@(negedge clk);start=0;
        end
    endtask
    task interrupt_prefix(input integer mode);
        begin
            capture=0;prepare_start();
            wait(paths[1].tx.crc_header_bit);@(posedge clk);#1;
            if(mode==0)kill=1;
            else if(mode==1)ready=0;
            else resetn=0;
            repeat(12)@(negedge clk);
            if(iq_valid!==0 || active!==0)$fatal(1,"interrupt left transmitter active");
            kill=0;ready=1;resetn=1;
            repeat(8)@(negedge clk);
        end
    endtask
    string output_path;
    initial begin
        if(!$value$plusargs("OUTPUT=%s",output_path))$fatal(1,"OUTPUT required");
        fd=$fopen(output_path,"w");if(!fd)$fatal(1,"cannot create waveform batch");
        repeat(6)@(negedge clk);resetn=1;arm=1;
        for(frame=0;frame<64;frame=frame+1)begin
            tick_mode=frame%3;parity=frame%2;
            rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);
            mac=(frame==0)?48'd0:(frame==1)?48'hffffffffffff:{rng,rng[15:0]};
            duration=(frame<32)?(16'd1<<(frame/2)):(frame<34)?16'hffff:rng[15:0];
            is_cts=frame%2;
            if(frame==4)interrupt_prefix(0);
            if(frame==8)interrupt_prefix(1);
            if(frame==12)interrupt_prefix(2);
            samples=0;capture=1;
            $fdisplay(fd,"FRAME %0d %0d %012x",is_cts,duration,mac);
            prepare_start();wait(done==2'b11);@(negedge clk);capture=0;
            if(samples!=6080)$fatal(1,"wrong control waveform length");
            frames=frames+1;
            repeat(3)@(negedge clk);
        end
        $fclose(fd);
        $display("CONTROL_CRC_WAVEFORMS_PASS frames=%0d samples=%0d exact_ab=true kill_stall_reset=true physical_rf=false",frames,total_samples);
        $finish;
    end
    initial begin #50000000;$fatal(1,"control waveform test timeout");end
endmodule
