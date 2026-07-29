/*
 * Lean 120 x 25 kHz synthesis channelizer, 106 occupied channels.
 *
 * Every occupied physical lane owns one independent 24-bit phase counter.
 * Eight shared 24-bit deterministic modulation counters provide distinct
 * rates.  Every active lane has a unique bank/rate-slice/profile tuple plus
 * its own 24-bit translation phase.  No pseudo-random source, waveform ROM,
 * runtime multiplier, or wide parallel lane arithmetic is used.
 *
 * Per-lane translation and both 128-leaf I/Q reductions are LSB-first serial
 * arithmetic at 108 MHz.  The rebuilt 24-bit complex composite feeds the
 * established 108 MHz SDM -> complete-word +7.5 MHz DDS -> published Weaver
 * selector -> single pMOS-switched N16 output-pin boundary.
 */
`default_nettype none

module gf_signed_sdm24_lean (
    input  wire               clk_i,
    input  wire               rst_i,
    input  wire signed [23:0] sample_i,
    output reg                bit_o
);
    reg signed [25:0] error_q;
    wire quantizer_d = !error_q[25];
    wire signed [26:0] feedback_d = quantizer_d
        ? 27'sd8388608 : -27'sd8388608;
    wire signed [26:0] corrected_d =
        $signed({error_q[25], error_q})
        + $signed({{3{sample_i[23]}}, sample_i}) - feedback_d;

    initial begin
        error_q = 26'sd0;
        bit_o = 1'b1;
    end
    always @(posedge clk_i) begin
        if (rst_i) begin
            error_q <= 26'sd0;
            bit_o <= 1'b1;
        end else begin
            error_q <= corrected_d[25:0];
            bit_o <= quantizer_d;
        end
    end
endmodule

/* At the 108 MHz serial-lane clock, a registered 8-way phase-state MUX is the
   entire deviation-selection path.  Selection is held for a complete word. */
module gf_serial_mux8_pipeline4 (
    input  wire       clk_i,
    input  wire       rst_i,
    input  wire [2:0] select_i,
    input  wire [7:0] bits_i,
    output reg        bit_o
);
    initial bit_o=0;
    always @(posedge clk_i) begin
        if(rst_i)
            bit_o<=0;
        else
            bit_o<=bits_i[select_i];
    end
endmodule

module gf_serial_mux16_pipeline4 (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire [3:0]  select_i,
    input  wire [15:0] bits_i,
    output reg         bit_o
);
    reg [7:0] stage0_q;
    reg [3:0] stage1_q;
    reg [1:0] stage2_q;
    reg [2:0] select1_q;
    reg [1:0] select2_q;
    reg select3_q;
    integer k;
    initial begin
        stage0_q=0; stage1_q=0; stage2_q=0; bit_o=0;
        select1_q=0; select2_q=0; select3_q=0;
    end
    always @(posedge clk_i) begin
        if(rst_i) begin
            stage0_q<=0; stage1_q<=0; stage2_q<=0; bit_o<=0;
            select1_q<=0; select2_q<=0; select3_q<=0;
        end else begin
            for(k=0;k<8;k=k+1)
                stage0_q[k]<=select_i[0]?bits_i[k*2+1]:bits_i[k*2];
            select1_q<=select_i[3:1];
            for(k=0;k<4;k=k+1)
                stage1_q[k]<=select1_q[0]?stage0_q[k*2+1]:stage0_q[k*2];
            select2_q<=select1_q[2:1];
            stage2_q[0]<=select2_q[0]?stage1_q[1]:stage1_q[0];
            stage2_q[1]<=select2_q[0]?stage1_q[3]:stage1_q[2];
            select3_q<=select2_q[1];
            bit_o<=select3_q?stage2_q[1]:stage2_q[0];
        end
    end
endmodule

module gf_pattern106_iq24_lean_channelizer #(
    parameter [119:0] ACTIVE_MASK =
        120'hfe3fffffffffffffffffffc7bf88fb
) (
    input  wire               clk_216_i,
    input  wire               rst_i,
    output reg signed [23:0]  composite_i_o,
    output reg signed [23:0]  composite_q_o,
    output reg                composite_strobe_o,
    output reg                sample_toggle_o,
    output wire               ready_o,
    output reg [15:0]         serial_word_epoch_o
);
    localparam integer PHYSICAL_LANES = 120;
    localparam integer TREE_LEAVES = 128;
    localparam integer TREE_LEVELS = 7;
    localparam integer WORD_BITS = 24;
    localparam integer MOD_BANKS = 8;

    /* Equal, full-safe constant-envelope lane amplitude. */
    localparam signed [23:0] AXIAL_POS = 24'sd65536;
    localparam signed [23:0] AXIAL_NEG = -AXIAL_POS;
    localparam signed [23:0] DIAG_POS = 24'sd46341;
    localparam signed [23:0] DIAG_NEG = -DIAG_POS;
    /* The registered tune selector and serial tune add consume two clocks;
       lane I/Q starts one clock after the phase snapshot.  These shared
       amplitude rings are pre-rotated by three so their bit zero is aligned to
       that lane-word boundary without a dynamic word-index lookup. */
    localparam [23:0] AXIAL_POS_ROT3={AXIAL_POS[20:0],AXIAL_POS[23:21]};
    localparam [23:0] AXIAL_NEG_ROT3={AXIAL_NEG[20:0],AXIAL_NEG[23:21]};
    localparam [23:0] DIAG_POS_ROT3={DIAG_POS[20:0],DIAG_POS[23:21]};
    localparam [23:0] DIAG_NEG_ROT3={DIAG_NEG[20:0],DIAG_NEG[23:21]};
    localparam [23:0] AXIAL_POS_ROT=AXIAL_POS_ROT3;
    localparam [23:0] AXIAL_NEG_ROT=AXIAL_NEG_ROT3;
    localparam [23:0] DIAG_POS_ROT=DIAG_POS_ROT3;
    localparam [23:0] DIAG_NEG_ROT=DIAG_NEG_ROT3;

    /* Eight equally spaced instantaneous offsets span 24.14 kHz.  They are
       phase-state constants, serialized by rotating registers rather than a
       word-indexed table. */
    localparam signed [23:0] DEV0=-24'sd45000;
    localparam signed [23:0] DEV1=-24'sd32142;
    localparam signed [23:0] DEV2=-24'sd19286;
    localparam signed [23:0] DEV3=-24'sd6428;
    localparam signed [23:0] DEV4= 24'sd6428;
    localparam signed [23:0] DEV5= 24'sd19286;
    localparam signed [23:0] DEV6= 24'sd32142;
    localparam signed [23:0] DEV7= 24'sd45000;

    function signed [23:0] tune_for_lane;
        input integer lane_index;
        integer bin;
        integer numerator;
        integer rounded;
        begin
            /* lane 0..119: -1.4875..+1.4875 MHz at 25 kHz spacing.
               Fs=4.5 MHz, 24-bit phase: tune = bin*2^24/360. */
            bin = -119 + lane_index * 2;
            numerator = bin * 16777216;
            if (numerator >= 0)
                rounded = (numerator + 180) / 360;
            else
                rounded = (numerator - 180) / 360;
            tune_for_lane = rounded;
        end
    endfunction

    function [2:0] triangle_state;
        input [2:0] state;
        begin
            case(state)
                3'd0:triangle_state=3'd0; 3'd1:triangle_state=3'd2;
                3'd2:triangle_state=3'd4; 3'd3:triangle_state=3'd6;
                3'd4:triangle_state=3'd7; 3'd5:triangle_state=3'd5;
                3'd6:triangle_state=3'd3; default:triangle_state=3'd1;
            endcase
        end
    endfunction

    function [2:0] sine_state;
        input [2:0] state;
        begin
            case(state)
                3'd0:sine_state=3'd3; 3'd1:sine_state=3'd5;
                3'd2:sine_state=3'd7; 3'd3:sine_state=3'd5;
                3'd4:sine_state=3'd3; 3'd5:sine_state=3'd1;
                3'd6:sine_state=3'd0; default:sine_state=3'd1;
            endcase
        end
    endfunction

    function select8_bit;
        input [2:0] state;
        input b0; input b1; input b2; input b3;
        input b4; input b5; input b6; input b7;
        begin
            case (state)
                3'd0: select8_bit = b0;
                3'd1: select8_bit = b1;
                3'd2: select8_bit = b2;
                3'd3: select8_bit = b3;
                3'd4: select8_bit = b4;
                3'd5: select8_bit = b5;
                3'd6: select8_bit = b6;
                default: select8_bit = b7;
            endcase
        end
    endfunction

    function select16_bit;
        input [3:0] state;
        input b0; input b1; input b2; input b3;
        input b4; input b5; input b6; input b7;
        input b8; input b9; input b10; input b11;
        input b12; input b13; input b14; input b15;
        begin
            case (state)
                4'd0: select16_bit=b0; 4'd1: select16_bit=b1;
                4'd2: select16_bit=b2; 4'd3: select16_bit=b3;
                4'd4: select16_bit=b4; 4'd5: select16_bit=b5;
                4'd6: select16_bit=b6; 4'd7: select16_bit=b7;
                4'd8: select16_bit=b8; 4'd9: select16_bit=b9;
                4'd10: select16_bit=b10; 4'd11: select16_bit=b11;
                4'd12: select16_bit=b12; 4'd13: select16_bit=b13;
                4'd14: select16_bit=b14; default: select16_bit=b15;
            endcase
        end
    endfunction

    function wave_i_bit;
        input [2:0] phase;
        input axial_positive; input axial_negative;
        input diagonal_positive; input diagonal_negative;
        begin
            case (phase)
                3'd0: wave_i_bit=axial_positive;
                3'd1: wave_i_bit=diagonal_positive;
                3'd2: wave_i_bit=1'b0;
                3'd3: wave_i_bit=diagonal_negative;
                3'd4: wave_i_bit=axial_negative;
                3'd5: wave_i_bit=diagonal_negative;
                3'd6: wave_i_bit=1'b0;
                default: wave_i_bit=diagonal_positive;
            endcase
        end
    endfunction

    function wave_q_bit;
        input [2:0] phase;
        input axial_positive; input axial_negative;
        input diagonal_positive; input diagonal_negative;
        begin
            case (phase)
                3'd0: wave_q_bit=1'b0;
                3'd1: wave_q_bit=diagonal_positive;
                3'd2: wave_q_bit=axial_positive;
                3'd3: wave_q_bit=diagonal_positive;
                3'd4: wave_q_bit=1'b0;
                3'd5: wave_q_bit=diagonal_negative;
                3'd6: wave_q_bit=axial_negative;
                default: wave_q_bit=diagonal_negative;
            endcase
        end
    endfunction

    reg [4:0] word_bit_q;
    wire word_start=(word_bit_q==5'd0);
    /* Kept only so the constant-false retired lookup architecture remains a
       valid parsed reference; it does not reach synthesis. */
    wire [4:0] word_bit_global=word_bit_q;
    initial word_bit_q = 5'd0;
    always @(posedge clk_216_i) begin
        if (rst_i)
            word_bit_q <= 5'd0;
        else if (word_bit_q == WORD_BITS-1)
            word_bit_q <= 5'd0;
        else
            word_bit_q <= word_bit_q + 1'b1;
    end
    /* The one-register selector and center serializer are valid before the
       first phase-consume edge; no chip-wide per-lane enable is required. */
    wire tune_pipeline_valid=1'b1;
    wire tune_word_start=(word_bit_q==5'd1);
    wire phase_word_start=(word_bit_q==5'd2);
    wire lane_word_start=(word_bit_q==5'd3);

    reg [23:0] dev0_q,dev1_q,dev2_q,dev3_q;
    reg [23:0] dev4_q,dev5_q,dev6_q,dev7_q;
    reg [23:0] axial_pos_q,axial_neg_q,diag_pos_q,diag_neg_q;
    initial begin
        dev0_q=DEV0; dev1_q=DEV1; dev2_q=DEV2; dev3_q=DEV3;
        dev4_q=DEV4; dev5_q=DEV5; dev6_q=DEV6; dev7_q=DEV7;
        axial_pos_q=AXIAL_POS_ROT3; axial_neg_q=AXIAL_NEG_ROT3;
        diag_pos_q=DIAG_POS_ROT3; diag_neg_q=DIAG_NEG_ROT3;
    end
    always @(posedge clk_216_i) begin
        if(rst_i) begin
            dev0_q<=DEV0; dev1_q<=DEV1; dev2_q<=DEV2; dev3_q<=DEV3;
            dev4_q<=DEV4; dev5_q<=DEV5; dev6_q<=DEV6; dev7_q<=DEV7;
            axial_pos_q<=AXIAL_POS_ROT3; axial_neg_q<=AXIAL_NEG_ROT3;
            diag_pos_q<=DIAG_POS_ROT3; diag_neg_q<=DIAG_NEG_ROT3;
        end else begin
            dev0_q<={dev0_q[0],dev0_q[23:1]};
            dev1_q<={dev1_q[0],dev1_q[23:1]};
            dev2_q<={dev2_q[0],dev2_q[23:1]};
            dev3_q<={dev3_q[0],dev3_q[23:1]};
            dev4_q<={dev4_q[0],dev4_q[23:1]};
            dev5_q<={dev5_q[0],dev5_q[23:1]};
            dev6_q<={dev6_q[0],dev6_q[23:1]};
            dev7_q<={dev7_q[0],dev7_q[23:1]};
            axial_pos_q<={axial_pos_q[0],axial_pos_q[23:1]};
            axial_neg_q<={axial_neg_q[0],axial_neg_q[23:1]};
            diag_pos_q<={diag_pos_q[0],diag_pos_q[23:1]};
            diag_neg_q<={diag_neg_q[0],diag_neg_q[23:1]};
        end
    end
    wire [7:0] deviation_bits={dev7_q[0],dev6_q[0],dev5_q[0],dev4_q[0],
        dev3_q[0],dev2_q[0],dev1_q[0],dev0_q[0]};

    /* Eight deterministic, bit-serial modulation timebases.  Their fundamental
       cycles span 4.5598 to 15.8251 Hz; rate slices reuse them at 1x/2x/4x/8x. */
    wire [5:0] modulation_phase [0:MOD_BANKS-1];
    genvar bank;
    generate
        for (bank=0; bank<MOD_BANKS; bank=bank+1) begin:g_mod_bank
            localparam integer STEP_MAG = 17 + bank*6;
            localparam signed [23:0] MOD_STEP = (bank%2)
                ? -STEP_MAG : STEP_MAG;
            localparam [23:0] MOD_INITIAL =
                24'h314159 + bank*24'h0f1e2d;
            reg [23:0] mod_q;
            reg [23:0] step_q;
            reg mod_carry_q;
            reg [5:0] phase_hold_q;
            wire carry_in = word_start ? 1'b0 : mod_carry_q;
            wire sum_d = mod_q[0] ^ step_q[0] ^ carry_in;
            wire carry_d = (mod_q[0] & step_q[0])
                | (mod_q[0] & carry_in)
                | (step_q[0] & carry_in);

            initial begin
                mod_q = MOD_INITIAL;
                step_q = MOD_STEP;
                mod_carry_q = 1'b0;
                phase_hold_q = MOD_INITIAL[23:18];
            end
            always @(posedge clk_216_i) begin
                if (rst_i) begin
                    mod_q <= MOD_INITIAL;
                    step_q <= MOD_STEP;
                    mod_carry_q <= 1'b0;
                    phase_hold_q <= MOD_INITIAL[23:18];
                end else begin
                    mod_q <= {sum_d, mod_q[23:1]};
                    step_q <= {step_q[0],step_q[23:1]};
                    mod_carry_q <= carry_d;
                    if (word_start)
                        phase_hold_q <= mod_q[23:18];
                end
            end
            /* Bit zero and bits 1..23 observe exactly the same old phase. */
            assign modulation_phase[bank] = word_start
                ? mod_q[23:18] : phase_hold_q;
        end
    endgenerate

    /* Fifteen local frame counters bound constant-serializer fanout to eight
       lanes.  They remain cycle-identical to word_bit_q after reset. */
    reg [4:0] cluster_word_q [0:14];
    integer cluster_index;
    initial begin
        for(cluster_index=0;cluster_index<15;cluster_index=cluster_index+1)
            cluster_word_q[cluster_index]=5'd0;
    end
    always @(posedge clk_216_i) begin
        if(rst_i) begin
            for(cluster_index=0;cluster_index<15;cluster_index=cluster_index+1)
                cluster_word_q[cluster_index]<=5'd0;
        end else begin
            for(cluster_index=0;cluster_index<15;cluster_index=cluster_index+1)
                cluster_word_q[cluster_index]<=
                    (cluster_word_q[cluster_index]==5'd23)
                    ?5'd0:cluster_word_q[cluster_index]+1'b1;
        end
    end

    wire [TREE_LEAVES-1:0] lane_i_bit;
    wire [TREE_LEAVES-1:0] lane_q_bit;
    genvar lane;
    generate
        if(1'b0) begin:g_retired_dynamic_lookup
        for (lane=0; lane<TREE_LEAVES; lane=lane+1) begin:g_lane
            if ((lane<PHYSICAL_LANES) && ACTIVE_MASK[lane]) begin:g_active
                localparam signed [23:0] CENTER_TUNE=tune_for_lane(lane);
                localparam integer MOD_BANK=lane%MOD_BANKS;
                localparam integer SECOND_BANK=(lane*5+3)%MOD_BANKS;
                localparam integer MODE=lane%8;
                localparam integer DEPTH_CLASS=(lane/16);
                localparam integer DIRECTION=(lane/8)%2;
                /* Edge lanes retain a 700 Hz instantaneous allocation guard;
                   all interior lanes span 96.5-98.2% of a 25 kHz slot. */
                localparam integer PEAK=((lane==0)||(lane==119))
                    ? 22000 : (22500+DEPTH_CLASS*60);
                localparam integer R1=(PEAK*5+3)/7;
                localparam integer R2=(PEAK*3+3)/7;
                localparam integer R3=(PEAK+3)/7;
                localparam integer HALF=(PEAK+1)/2;
                localparam integer SINE_DIAG=(PEAK*181+128)/256;
                localparam integer MIX_MAIN=(PEAK*2+1)/3;
                localparam integer MIX_SECOND=PEAK-MIX_MAIN;
                localparam integer MIX_DIAG=(MIX_MAIN*181+128)/256;
                localparam [23:0] INITIAL_PHASE=
                    24'h123456+lane*24'h9e3779;

                localparam signed [23:0] R0=CENTER_TUNE-PEAK;
                localparam signed [23:0] R1W=CENTER_TUNE-R1;
                localparam signed [23:0] R2W=CENTER_TUNE-R2;
                localparam signed [23:0] R3W=CENTER_TUNE-R3;
                localparam signed [23:0] R4W=CENTER_TUNE+R3;
                localparam signed [23:0] R5W=CENTER_TUNE+R2;
                localparam signed [23:0] R6W=CENTER_TUNE+R1;
                localparam signed [23:0] R7W=CENTER_TUNE+PEAK;

                localparam signed [23:0] T0=CENTER_TUNE-PEAK;
                localparam signed [23:0] T1=CENTER_TUNE-HALF;
                localparam signed [23:0] T2=CENTER_TUNE;
                localparam signed [23:0] T3=CENTER_TUNE+HALF;
                localparam signed [23:0] T4=CENTER_TUNE+PEAK;
                localparam signed [23:0] T5=CENTER_TUNE+HALF;
                localparam signed [23:0] T6=CENTER_TUNE;
                localparam signed [23:0] T7=CENTER_TUNE-HALF;

                localparam signed [23:0] S0=CENTER_TUNE;
                localparam signed [23:0] S1=CENTER_TUNE+SINE_DIAG;
                localparam signed [23:0] S2=CENTER_TUNE+PEAK;
                localparam signed [23:0] S3=CENTER_TUNE+SINE_DIAG;
                localparam signed [23:0] S4=CENTER_TUNE;
                localparam signed [23:0] S5=CENTER_TUNE-SINE_DIAG;
                localparam signed [23:0] S6=CENTER_TUNE-PEAK;
                localparam signed [23:0] S7=CENTER_TUNE-SINE_DIAG;

                localparam signed [23:0] MN0=CENTER_TUNE-MIX_SECOND;
                localparam signed [23:0] MN1=CENTER_TUNE+MIX_DIAG-MIX_SECOND;
                localparam signed [23:0] MN2=CENTER_TUNE+MIX_MAIN-MIX_SECOND;
                localparam signed [23:0] MN3=CENTER_TUNE+MIX_DIAG-MIX_SECOND;
                localparam signed [23:0] MN4=CENTER_TUNE-MIX_SECOND;
                localparam signed [23:0] MN5=CENTER_TUNE-MIX_DIAG-MIX_SECOND;
                localparam signed [23:0] MN6=CENTER_TUNE-MIX_MAIN-MIX_SECOND;
                localparam signed [23:0] MN7=CENTER_TUNE-MIX_DIAG-MIX_SECOND;
                localparam signed [23:0] MP0=CENTER_TUNE+MIX_SECOND;
                localparam signed [23:0] MP1=CENTER_TUNE+MIX_DIAG+MIX_SECOND;
                localparam signed [23:0] MP2=CENTER_TUNE+MIX_MAIN+MIX_SECOND;
                localparam signed [23:0] MP3=CENTER_TUNE+MIX_DIAG+MIX_SECOND;
                localparam signed [23:0] MP4=CENTER_TUNE+MIX_SECOND;
                localparam signed [23:0] MP5=CENTER_TUNE-MIX_DIAG+MIX_SECOND;
                localparam signed [23:0] MP6=CENTER_TUNE-MIX_MAIN+MIX_SECOND;
                localparam signed [23:0] MP7=CENTER_TUNE-MIX_DIAG+MIX_SECOND;

                wire [2:0] modulation_state=DIRECTION
                    ? ~modulation_phase[MOD_BANK] : modulation_phase[MOD_BANK];
                wire [3:0] mix_state={
                    modulation_phase[SECOND_BANK][2]^DIRECTION,
                    modulation_state};
                wire tune_bit;
                if ((MODE==0)||(MODE==1)||(MODE==4)||(MODE==5)) begin:g_ramp
                    wire [7:0] tune_bits={R7W[word_bit_global],R6W[word_bit_global],
                        R5W[word_bit_global],R4W[word_bit_global],R3W[word_bit_global],
                        R2W[word_bit_global],R1W[word_bit_global],R0[word_bit_global]};
                    gf_serial_mux8_pipeline4 tune_mux(.clk_i(clk_216_i),.rst_i(rst_i),
                        .select_i(modulation_state),.bits_i(tune_bits),.bit_o(tune_bit));
                end else if (MODE==2) begin:g_triangle
                    wire [7:0] tune_bits={T7[word_bit_global],T6[word_bit_global],
                        T5[word_bit_global],T4[word_bit_global],T3[word_bit_global],
                        T2[word_bit_global],T1[word_bit_global],T0[word_bit_global]};
                    gf_serial_mux8_pipeline4 tune_mux(.clk_i(clk_216_i),.rst_i(rst_i),
                        .select_i(modulation_state),.bits_i(tune_bits),.bit_o(tune_bit));
                end else if ((MODE==3)||(MODE==6)) begin:g_sine
                    wire [7:0] tune_bits={S7[word_bit_global],S6[word_bit_global],
                        S5[word_bit_global],S4[word_bit_global],S3[word_bit_global],
                        S2[word_bit_global],S1[word_bit_global],S0[word_bit_global]};
                    gf_serial_mux8_pipeline4 tune_mux(.clk_i(clk_216_i),.rst_i(rst_i),
                        .select_i(modulation_state),.bits_i(tune_bits),.bit_o(tune_bit));
                end else begin:g_mix
                    wire [15:0] tune_bits={
                        MP7[word_bit_global],MP6[word_bit_global],MP5[word_bit_global],
                        MP4[word_bit_global],MP3[word_bit_global],MP2[word_bit_global],
                        MP1[word_bit_global],MP0[word_bit_global],MN7[word_bit_global],
                        MN6[word_bit_global],MN5[word_bit_global],MN4[word_bit_global],
                        MN3[word_bit_global],MN2[word_bit_global],MN1[word_bit_global],
                        MN0[word_bit_global]};
                    gf_serial_mux16_pipeline4 tune_mux(.clk_i(clk_216_i),.rst_i(rst_i),
                        .select_i(mix_state),.bits_i(tune_bits),.bit_o(tune_bit));
                end

                reg [23:0] phase_q;
                reg phase_carry_q;
                reg [2:0] output_phase_q;
                reg lane_i_q;
                reg lane_q_q;
                wire phase_carry_in=phase_word_start?1'b0:phase_carry_q;
                wire phase_sum=phase_q[0]^tune_bit^phase_carry_in;
                wire phase_carry=(phase_q[0]&tune_bit)
                    |(phase_q[0]&phase_carry_in)
                    |(tune_bit&phase_carry_in);
                wire [2:0] waveform_phase=phase_word_start
                    ? phase_q[23:21] : output_phase_q;
                wire i_bit_d=wave_i_bit(waveform_phase,
                    AXIAL_POS_ROT[word_bit_global],AXIAL_NEG_ROT[word_bit_global],
                    DIAG_POS_ROT[word_bit_global],DIAG_NEG_ROT[word_bit_global]);
                wire q_bit_d=wave_q_bit(waveform_phase,
                    AXIAL_POS_ROT[word_bit_global],AXIAL_NEG_ROT[word_bit_global],
                    DIAG_POS_ROT[word_bit_global],DIAG_NEG_ROT[word_bit_global]);

                initial begin
                    phase_q=INITIAL_PHASE;
                    phase_carry_q=1'b0;
                    output_phase_q=INITIAL_PHASE[23:21];
                    lane_i_q=1'b0;
                    lane_q_q=1'b0;
                end
                always @(posedge clk_216_i) begin
                    if (rst_i) begin
                        phase_q<=INITIAL_PHASE;
                        phase_carry_q<=1'b0;
                        output_phase_q<=INITIAL_PHASE[23:21];
                        lane_i_q<=1'b0;
                        lane_q_q<=1'b0;
                    end else if(tune_pipeline_valid) begin
                        phase_q<={phase_sum,phase_q[23:1]};
                        phase_carry_q<=phase_carry;
                        if(phase_word_start)
                            output_phase_q<=phase_q[23:21];
                        lane_i_q<=i_bit_d;
                        lane_q_q<=q_bit_d;
                    end else begin
                        lane_i_q<=1'b0;
                        lane_q_q<=1'b0;
                    end
                end
                assign lane_i_bit[lane]=lane_i_q;
                assign lane_q_bit[lane]=lane_q_q;
            end else begin:g_off
                assign lane_i_bit[lane]=1'b0;
                assign lane_q_bit[lane]=1'b0;
            end
        end
        end
        for(lane=0;lane<TREE_LEAVES;lane=lane+1) begin:g_lane_ring
            if((lane<PHYSICAL_LANES)&&ACTIVE_MASK[lane]) begin:g_active
                localparam signed [23:0] CENTER_TUNE=tune_for_lane(lane);
                localparam [15:0] CENTER_LOW_LUT=CENTER_TUNE[15:0];
                localparam [15:0] CENTER_HIGH_LUT=
                    {CENTER_TUNE[23:16],CENTER_TUNE[23:16]};
                localparam [23:0] INITIAL_PHASE=24'h123456+lane*24'h9e3779;
                /* lane = bank + 8*rate_slice + 32*profile, so every physical
                   lane has a unique deterministic spectrum-profile tuple. */
                localparam integer MOD_BANK=lane%8;
                localparam integer RATE_SLICE=(lane/8)%4;
                localparam integer PROFILE=(lane/32)%4;
                localparam integer SECOND_BANK=(MOD_BANK+3+PROFILE)%8;
                wire [2:0] primary_state=
                    modulation_phase[MOD_BANK][(5-RATE_SLICE)-:3];
                wire [2:0] secondary_state=
                    modulation_phase[SECOND_BANK][(5-RATE_SLICE)-:3];
                wire [2:0] selected_state;
                if(PROFILE==0) begin:g_rising
                    assign selected_state=primary_state;
                end else if(PROFILE==1) begin:g_falling
                    assign selected_state=~primary_state;
                end else if(PROFILE==2) begin:g_triangle
                    assign selected_state=triangle_state(primary_state);
                end else if((lane%2)==0) begin:g_sine
                    assign selected_state=sine_state(primary_state);
                end else begin:g_mix
                    assign selected_state=primary_state+
                        {secondary_state[1:0],secondary_state[2]};
                end

                wire deviation_bit;
                gf_serial_mux8_pipeline4 deviation_mux(
                    .clk_i(clk_216_i),.rst_i(rst_i),
                    .select_i(selected_state),.bits_i(deviation_bits),
                    .bit_o(deviation_bit));

                wire [4:0] local_word=cluster_word_q[lane/8];
                wire center_low_d,center_high_d;
                SB_LUT4 #(.LUT_INIT(CENTER_LOW_LUT)) center_low_lut(
                    .I0(local_word[0]),.I1(local_word[1]),
                    .I2(local_word[2]),.I3(local_word[3]),.O(center_low_d));
                SB_LUT4 #(.LUT_INIT(CENTER_HIGH_LUT)) center_high_lut(
                    .I0(local_word[0]),.I1(local_word[1]),
                    .I2(local_word[2]),.I3(1'b0),.O(center_high_d));
                wire center_raw_d=local_word[4]?center_high_d:center_low_d;
                reg center_bit_q;
                initial center_bit_q=0;
                always @(posedge clk_216_i) begin
                    if(rst_i)
                        center_bit_q<=0;
                    else
                        center_bit_q<=center_raw_d;
                end

                wire tune_bit;
                gf_serial_add_cell_lean tune_add(
                    .clk_i(clk_216_i),.run_i(!rst_i),
                    .word_start_i(tune_word_start),
                    .x_bit_i(center_bit_q),.y_bit_i(deviation_bit),
                    .sum_bit_o(tune_bit));

                reg [23:0] phase_q;
                reg phase_carry_q;
                reg [2:0] output_phase_q;
                reg lane_i_q,lane_q_q;
                wire phase_carry_in=phase_word_start?1'b0:phase_carry_q;
                wire phase_sum=phase_q[0]^tune_bit^phase_carry_in;
                wire phase_carry=(phase_q[0]&tune_bit)
                    |(phase_q[0]&phase_carry_in)
                    |(tune_bit&phase_carry_in);
                wire i_bit_d=wave_i_bit(output_phase_q,
                    axial_pos_q[0],axial_neg_q[0],diag_pos_q[0],diag_neg_q[0]);
                wire q_bit_d=wave_q_bit(output_phase_q,
                    axial_pos_q[0],axial_neg_q[0],diag_pos_q[0],diag_neg_q[0]);
                initial begin
                    phase_q=INITIAL_PHASE; phase_carry_q=1'b0;
                    output_phase_q=INITIAL_PHASE[23:21];
                    lane_i_q=1'b0; lane_q_q=1'b0;
                end
                always @(posedge clk_216_i) begin
                    if(rst_i) begin
                        phase_q<=INITIAL_PHASE; phase_carry_q<=1'b0;
                        output_phase_q<=INITIAL_PHASE[23:21];
                        lane_i_q<=1'b0; lane_q_q<=1'b0;
                    end else if(tune_pipeline_valid) begin
                        phase_q<={phase_sum,phase_q[23:1]};
                        phase_carry_q<=phase_carry;
                        if(phase_word_start)
                            output_phase_q<=phase_q[23:21];
                        lane_i_q<=i_bit_d;
                        lane_q_q<=q_bit_d;
                    end else begin
                        lane_i_q<=1'b0; lane_q_q<=1'b0;
                    end
                end
                assign lane_i_bit[lane]=lane_i_q;
                assign lane_q_bit[lane]=lane_q_q;
            end else begin:g_off
                assign lane_i_bit[lane]=1'b0;
                assign lane_q_bit[lane]=1'b0;
            end
        end
    endgenerate

    wire [TREE_LEAVES-1:0] i_tree [0:TREE_LEVELS];
    wire [TREE_LEAVES-1:0] q_tree [0:TREE_LEVELS];
    reg [TREE_LEVELS:0] start_delay_q;
    assign i_tree[0]=lane_i_bit;
    assign q_tree[0]=lane_q_bit;
    integer di;
    initial start_delay_q=0;
    always @(posedge clk_216_i) begin
        if(rst_i)
            start_delay_q<=0;
        else begin
            start_delay_q[0]<=lane_word_start&&tune_pipeline_valid;
            for(di=1;di<=TREE_LEVELS;di=di+1)
                start_delay_q[di]<=start_delay_q[di-1];
        end
    end

    genvar level,node;
    generate
        for(level=0;level<TREE_LEVELS;level=level+1) begin:g_level
            for(node=0;node<TREE_LEAVES;node=node+1) begin:g_node
                if(node<(TREE_LEAVES>>(level+1))) begin:g_add
                    gf_serial_add_cell_lean ai(.clk_i(clk_216_i),.run_i(!rst_i),
                        .word_start_i(start_delay_q[level]),
                        .x_bit_i(i_tree[level][node<<1]),
                        .y_bit_i(i_tree[level][(node<<1)|1]),
                        .sum_bit_o(i_tree[level+1][node]));
                    gf_serial_add_cell_lean aq(.clk_i(clk_216_i),.run_i(!rst_i),
                        .word_start_i(start_delay_q[level]),
                        .x_bit_i(q_tree[level][node<<1]),
                        .y_bit_i(q_tree[level][(node<<1)|1]),
                        .sum_bit_o(q_tree[level+1][node]));
                end else begin:g_unused
                    assign i_tree[level+1][node]=1'b0;
                    assign q_tree[level+1][node]=1'b0;
                end
            end
        end
    endgenerate

    wire root_start=start_delay_q[TREE_LEVELS];
    wire root_i=i_tree[TREE_LEVELS][0];
    wire root_q=q_tree[TREE_LEVELS][0];
    reg [4:0] output_bit_q;
    reg [23:0] i_word_q;
    reg [23:0] q_word_q;
    reg ready_q;
    wire signed [23:0] completed_i=$signed({root_i,i_word_q[22:0]});
    wire signed [23:0] completed_q=$signed({root_q,q_word_q[22:0]});
    initial begin
        output_bit_q=0; i_word_q=0; q_word_q=0;
        composite_i_o=0; composite_q_o=0; composite_strobe_o=0;
        sample_toggle_o=0; ready_q=0; serial_word_epoch_o=0;
    end
    always @(posedge clk_216_i) begin
        if(rst_i) begin
            output_bit_q<=0; i_word_q<=0; q_word_q<=0;
            composite_i_o<=0; composite_q_o<=0; composite_strobe_o<=0;
            sample_toggle_o<=0; ready_q<=0; serial_word_epoch_o<=0;
        end else begin
            composite_strobe_o<=1'b0;
            if(root_start) begin
                output_bit_q<=0;
                i_word_q[0]<=root_i;
                q_word_q[0]<=root_q;
            end else begin
                output_bit_q<=output_bit_q+1'b1;
                i_word_q[output_bit_q+1'b1]<=root_i;
                q_word_q[output_bit_q+1'b1]<=root_q;
                if(output_bit_q==22) begin
                    composite_i_o<=completed_i;
                    composite_q_o<=completed_q;
                    composite_strobe_o<=1'b1;
                    sample_toggle_o<=~sample_toggle_o;
                    ready_q<=1'b1;
                    serial_word_epoch_o<=serial_word_epoch_o+1'b1;
                end
            end
        end
    end
    assign ready_o=ready_q;
endmodule

module top_pattern106_iq24_lean_mpsse_v3 #(
    parameter integer RF_COMPILE_ARMED=0,
    parameter integer BURST_CYCLES_108=108000000
) (
    (* clkbuf_inhibit *) input wire CRYSTAL_12MHZ,
    input wire MPSSE_SCLK,
    input wire MPSSE_MOSI,
    inout wire MPSSE_MISO,
    input wire MPSSE_CS_N,
    output wire RF_OUT,
    output wire LED_R
);
    localparam [7:0] PROFILE_ID=8'hb5;
    localparam [7:0] CONFIG_EPOCH=8'd7;
    localparam [119:0] CHANNEL_MASK=
        120'hfe3fffffffffffffffffffc7bf88fb;

    wire pll_216mhz,pll_216mhz_90,pll_lock;
    SB_PLL40_2F_CORE #(
        .FEEDBACK_PATH("PHASE_AND_DELAY"),.DIVF(7'd17),
        .FILTER_RANGE(3'd1),.DIVQ(3'd1),
        .DELAY_ADJUSTMENT_MODE_RELATIVE("DYNAMIC"),.DIVR(4'd0),
        .SHIFTREG_DIV_MODE(0),.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
        .FDA_FEEDBACK(4'b0000),.PLLOUT_SELECT_PORTA("SHIFTREG_90deg"),
        .PLLOUT_SELECT_PORTB("SHIFTREG_0deg"),.ENABLE_ICEGATE_PORTA(0),
        .ENABLE_ICEGATE_PORTB(0)
    ) pll2(
        .REFERENCECLK(CRYSTAL_12MHZ),.PLLOUTGLOBALA(pll_216mhz_90),
        .PLLOUTGLOBALB(pll_216mhz),.DYNAMICDELAY(8'd16),
        .RESETB(1'b1),.BYPASS(1'b0),.LATCHINPUTVALUE(1'b0),
        .LOCK(pll_lock),.SDI(1'b0),.SDO(),.SCLK(1'b0));

    reg clk108_div=1'b0;
    always @(posedge pll_216mhz)
        clk108_div<=~clk108_div;
    wire clk_108;
    SB_GB gb108(.USER_SIGNAL_TO_GLOBAL_BUFFER(clk108_div),
        .GLOBAL_BUFFER_OUTPUT(clk_108));

    reg pll_lock_sync1=1'b0,pll_lock_sync2=1'b0;
    reg [7:0] startup_q=8'd0;
    always @(posedge clk_108) begin
        pll_lock_sync1<=pll_lock;
        pll_lock_sync2<=pll_lock_sync1;
        if(!pll_lock_sync2)
            startup_q<=8'd0;
        else if(!&startup_q)
            startup_q<=startup_q+1'b1;
    end
    wire reset_pre=!&startup_q;
    wire reset;
    SB_GB reset_global_buffer(.USER_SIGNAL_TO_GLOBAL_BUFFER(reset_pre),
        .GLOBAL_BUFFER_OUTPUT(reset));

    wire signed [23:0] serial_i,serial_q;
    wire serial_strobe,serial_toggle,serial_ready;
    wire [15:0] serial_epoch;
    gf_pattern106_iq24_lean_channelizer #(.ACTIVE_MASK(CHANNEL_MASK)) channelizer(
        .clk_216_i(clk_108),.rst_i(1'b0),
        .composite_i_o(serial_i),.composite_q_o(serial_q),
        .composite_strobe_o(serial_strobe),.sample_toggle_o(serial_toggle),
        .ready_o(serial_ready),.serial_word_epoch_o(serial_epoch));

    reg toggle_sync1=1'b0,toggle_sync2=1'b0,toggle_seen=1'b0;
    reg signed [23:0] sample_i_108=24'sd0,sample_q_108=24'sd0;
    reg sample_strobe_108=1'b0,datapath_ready_108=1'b0;
    reg [15:0] serial_epoch_108=16'd0;
    always @(posedge clk_108) begin
        if(reset) begin
            toggle_sync1<=1'b0; toggle_sync2<=1'b0; toggle_seen<=1'b0;
            sample_i_108<=24'sd0; sample_q_108<=24'sd0;
            sample_strobe_108<=1'b0; datapath_ready_108<=1'b0;
            serial_epoch_108<=16'd0;
        end else begin
            toggle_sync1<=serial_toggle;
            toggle_sync2<=toggle_sync1;
            sample_strobe_108<=1'b0;
            if(toggle_sync2!=toggle_seen) begin
                toggle_seen<=toggle_sync2;
                sample_i_108<=serial_i;
                sample_q_108<=serial_q;
                serial_epoch_108<=serial_epoch;
                sample_strobe_108<=1'b1;
                datapath_ready_108<=serial_ready;
            end
        end
    end

    wire burst_active,burst_done;
    gf_one_shot_burst_gate #(.BURST_CYCLES_108(BURST_CYCLES_108)) burst_gate(
        .clk_108_i(clk_108),.rst_i(reset),.arm_i(RF_COMPILE_ARMED!=0),
        .datapath_ready_i(datapath_ready_108),.burst_active_o(burst_active),
        .burst_done_o(burst_done));

    wire i_sdm,q_sdm;
    gf_signed_sdm24_lean sdm_i(.clk_i(clk_108),.rst_i(reset),
        .sample_i(sample_i_108),.bit_o(i_sdm));
    wire signed [23:0] negative_q=-sample_q_108;
    gf_signed_sdm24_lean sdm_q(.clk_i(clk_108),.rst_i(reset),
        .sample_i(negative_q),.bit_o(q_sdm));

    wire sel_i,sel_q;
    wire [7:0] dds_unused;
    gf_gray_quadrant_dds_lean dds(.clk_216_i(pll_216mhz),.rst_i(reset),
        .i_sdm_bit_i(i_sdm),.q_sdm_bit_i(q_sdm),
        .selector_i_o(sel_i),.selector_q_o(sel_q),.dds_phase_o(dds_unused));
    wire modulated_rf;
    gf_published_four_phase_selector selector(
        .pll_216mhz_i(pll_216mhz),.pll_216mhz_90_i(pll_216mhz_90),
        .selector_i_i(sel_i),.selector_q_i(sel_q),
        .modulated_rf_o(modulated_rf));

    wire tx_window=(RF_COMPILE_ARMED!=0)&&pll_lock_sync2&&!reset
        &&datapath_ready_108&&burst_active;
    wire physical_enable=tx_window&&modulated_rf;
    SB_IO #(.PIN_TYPE(6'b101000),.IO_STANDARD("SB_LVCMOS"),.PULLUP(1'b0)) rf_io(
        .PACKAGE_PIN(RF_OUT),.D_OUT_0(1'b1),.OUTPUT_ENABLE(physical_enable));

    reg [31:0] consumed_q=32'd0;
    reg fault_q=1'b0;
    reg activity_seen_q=1'b0;
    always @(posedge clk_108) begin
        if(burst_active&&sample_strobe_108)
            consumed_q<=consumed_q+1'b1;
        if(tx_window)
            activity_seen_q<=1'b1;
        if((burst_active||burst_done)&&(!pll_lock_sync2||reset))
            fault_q<=1'b1;
    end
    assign LED_R=tx_window&&consumed_q[18];
    wire outputs_off=!tx_window&&!LED_R;
    wire [7:0] status={fault_q,activity_seen_q,outputs_off,burst_done,
        burst_active,datapath_ready_108,reset,pll_lock_sync2};
    wire [127:0] live_frame={32'h47464933,8'd3,8'd16,
        PROFILE_ID,CONFIG_EPOCH,consumed_q,serial_epoch_108,status,8'd106}; // Match this telemetry byte to CHANNEL_MASK edits.
    wire miso_data;
    gf_mpsse_snapshot16_lean telemetry(.source_clk_i(clk_108),
        .source_live_frame_i(live_frame),.mpsse_sclk_i(MPSSE_SCLK),
        .mpsse_cs_n_i(MPSSE_CS_N),.mpsse_miso_o(miso_data));
    SB_IO #(.PIN_TYPE(6'b101000),.IO_STANDARD("SB_LVCMOS"),.PULLUP(1'b0)) miso_io(
        .PACKAGE_PIN(MPSSE_MISO),.D_OUT_0(miso_data),
        .OUTPUT_ENABLE(!MPSSE_CS_N));
    wire unused_mosi=MPSSE_MOSI;
    wire unused_serial_strobe=serial_strobe;
endmodule

`default_nettype wire
