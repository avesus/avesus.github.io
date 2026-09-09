`timescale 1ns/1ps
// Differential gate for the bounded PSDU contract, not physical RF evidence.
module tb_gf_header_index;
    reg clk=0;
    always #5 clk=~clk;
    reg resetn=0, start=0, valid=0, last=0, checked=0;
    reg [7:0] data=0;
    reg [15:0] age=0;
    reg [47:0] ap_mac=48'h024746415031;
    wire [199:0] observed [0:1];
    integer checks=0, frames=0;
    reg [31:0] rng=32'h167afd36;
    function automatic [31:0] next_random(input [31:0] x);
        reg [31:0] y;
        begin y=x^(x<<13); y=y^(y>>17); next_random=y^(y<<5); end
    endfunction
    generate for(genvar version=0;version<2;version=version+1) begin : g_version
        gf_low_mac_classifier #(.EXTERNAL_FCS(1),.SATURATING_HEADER_INDEX(version)) dut (
            .clk(clk),.resetn(resetn),.ap_mac(ap_mac),.psdu_start(start),
            .psdu_byte_valid(valid),.psdu_byte(data),.psdu_byte_last(last),
            .psdu_end_age_cycles(age),.checked_fcs_ok(checked),
            .decision_valid(observed[version][0]),
            .decision_age_cycles(observed[version][16:1]),
            .decision_fcs_ok(observed[version][17]),
            .decision_ra_matches_ap(observed[version][18]),
            .decision_response_required(observed[version][19]),
            .decision_is_rts(observed[version][20]),
            .decision_response_mac(observed[version][68:21]),
            .decision_duration_us(observed[version][84:69]),
            .decision_malformed(observed[version][85]),
            .frame_count(observed[version][117:86]),
            .fcs_ok_count(observed[version][149:118]),
            .response_candidate_count(observed[version][181:150]),
            .malformed_count()
        );
        assign observed[version][199:182]=0;
    end endgenerate
    task automatic compare;
        begin
            if(observed[0] !== observed[1] ||
               g_version[0].dut.malformed_count !== g_version[1].dut.malformed_count)
                $fatal(1,"HEADER_INDEX_MISMATCH frame=%0d checks=%0d old_idx=%0d new_idx=%0d old=%h new=%h",
                       frames,checks,g_version[0].dut.byte_index,g_version[1].dut.byte_index,observed[0],observed[1]);
            checks=checks+1;
        end
    endtask
    task automatic tick;
        begin #1; compare(); @(posedge clk); #1; compare(); @(negedge clk); end
    endtask
    task automatic frame(input integer length, input [7:0] fc, input integer variant);
        reg [47:0] receiver;
        integer i;
        begin
            receiver=(variant%3==0) ? ap_mac : (variant%3==1 ? 48'hffffffffffff : 48'h024746415032);
            for(i=0;i<length;i=i+1) begin
                rng=next_random(rng); data=rng[7:0]; age=rng[31:16];
                case(i)
                    0: data=fc;
                    2: data=8'h10;
                    3: data=variant[0] ? 8'hc0 : 8'h00;
                    4: data=receiver[47:40]; 5: data=receiver[39:32];
                    6: data=receiver[31:24]; 7: data=receiver[23:16];
                    8: data=receiver[15:8]; 9: data=receiver[7:0];
                    default: begin end
                endcase
                start=(i==0); valid=1; last=(i==length-1); checked=variant[1]; tick();
                // Gaps exercise the state hold; back-to-back bytes exercise
                // the strongest timing contract (real DSSS bytes are farther apart).
                if((rng & 63)==0) begin start=0; valid=0; last=0; tick(); end
            end
            frames=frames+1; start=0; valid=0; last=0; tick();
        end
    endtask
    initial begin
        @(negedge clk); tick(); resetn=1;
        // All FC type/subtype/version values around every header threshold.
        for(integer fc=0;fc<256;fc=fc+1)
            for(integer length=1;length<=35;length=length+1)
                frame(length,fc[7:0],fc+length);
        // Every supported PSDU length, with legal/malformed management,
        // data, RTS, PS-Poll, ACK and reserved frame controls in rotation.
        for(integer length=1;length<=4095;length=length+1) begin
            case(length%8)
                0: frame(length,8'h00,length); 1: frame(length,8'h08,length);
                2: frame(length,8'hb4,length); 3: frame(length,8'ha4,length);
                4: frame(length,8'hd4,length); 5: frame(length,8'h88,length);
                6: frame(length,8'hff,length); 7: frame(length,8'h40,length);
            endcase
        end
        // Interrupted frame / new start and explicit reset must forget a
        // saturated index. Last can coincide with the first byte.
        valid=1; start=1; last=0; data=8'h08; tick(); start=0;
        repeat(100) tick(); frame(20,8'ha4,3);
        resetn=0; valid=0; tick(); resetn=1; frame(1,8'h08,2); frame(4095,8'h08,3);
        $display("HEADER_INDEX_PASS checks=%0d frames=%0d all_lengths=1..4095 all_fc=256 exact_ps_poll=true physical_rf=false",checks,frames);
        $finish;
    end
endmodule
