`timescale 1ns/1ps
// Uses AMD's installed UNISIM MMCM model, not a replacement clock generator.
// This is a digital model test of the reset supervisor, not physical RF proof.
module tb_gf_e310_serial_clock;
    reg radio=0,control=0,run_radio=1,request=1;
    wire fast,locked;
    always #5 control=~control;
    always #12.5 if(run_radio)radio=~radio;else radio=0;
    gf_e310_serial_clock dut(radio,control,request,fast,locked);
    integer fast_edges=0,begin_edges,cycles;
    always @(posedge fast)if(locked)fast_edges=fast_edges+1;
    task automatic await_lock;
        begin
            cycles=0;
            while(!locked && cycles<20000)begin @(posedge control);cycles=cycles+1;end
            if(!locked)$fatal(1,"MMCM failed to lock");
            repeat(50)@(posedge radio);
            begin_edges=fast_edges;
            repeat(100)@(posedge radio);
            #0.01;
            if(fast_edges-begin_edges<799 || fast_edges-begin_edges>801)
                $fatal(1,"40:320 ratio failed: %0d",fast_edges-begin_edges);
        end
    endtask
    initial begin
        #250;request=0;
        await_lock();
        // A stopped input must drop lock and provoke a reset from the existing
        // 100-MHz control clock; no software or board reset is supplied.
        @(negedge radio);run_radio=0;
        cycles=0;
        while(locked && cycles<20000)begin @(posedge control);cycles=cycles+1;end
        if(locked)$fatal(1,"UNISIM did not report input-clock loss");
        cycles=0;
        while(!dut.mmcm_reset && cycles<20)begin @(posedge control);cycles=cycles+1;end
        if(!dut.mmcm_reset)$fatal(1,"No autonomous reset after lock loss");
        repeat(30)@(posedge control);
        run_radio=1;
        await_lock();
        request=1;#0.01;
        if(locked || !dut.mmcm_reset)$fatal(1,"Asynchronous reset veto failed");
        repeat(8)@(posedge control);request=0;
        await_lock();
        $display("E310_SERIAL_CLOCK_PASS vendor_model=UNISIM ratio=8 startup=true stopped_input_recovery=true explicit_reset=true physical_rf=false");
        $finish;
    end
    initial begin #800000;$fatal(1,"Clock test timeout");end
endmodule
