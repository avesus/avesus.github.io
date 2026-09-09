// Brian Greenforest's fully retimed, bubbles-free low-word multiplier graph.
// Adapted from serial_multiplier_hitl/rtl/gf_logisim_mul64_low_full_retime.sv:
// 40 LSB-first bits/word, 40 active partials in the same six-level padded tree.
// The 40-bit result is exact modulo 2^40. Sign-extended 18x18 inputs therefore
// preserve the entire signed product, without a DSP or inferred wide multiply.
// First output bit follows first input bit by 13 clocks. No clock enable/gaps.
`timescale 1ns/1ps
`default_nettype none
module gf_serial_reg #(parameter INIT = 1'b0)(
    input wire clk, reset, d, output wire q
);
`ifdef SYNTHESIS
    generate if (INIT) begin : g_set
        (* DONT_TOUCH = "true" *) FDPE #(.INIT(1'b1)) r(.C(clk),.CE(1'b1),.PRE(reset),.D(d),.Q(q));
    end else begin : g_clear
        (* DONT_TOUCH = "true" *) FDCE #(.INIT(1'b0)) r(.C(clk),.CE(1'b1),.CLR(reset),.D(d),.Q(q));
    end endgenerate
`else
    // Match the explicit FDCE/FDPE INIT above, including time-zero values
    // observed by non-reset SRL histories before the first clock edge.
    reg value=INIT;
    always @(posedge clk or posedge reset)
        if (reset) value <= INIT; else value <= d;
    assign q = value;
`endif
endmodule

module gf_serial_lut #(parameter [15:0] INIT=16'd0)(
    input wire a,b,c,d, output wire q
);
`ifdef SYNTHESIS
    (* DONT_TOUCH = "true" *) LUT4 #(.INIT(INIT)) l(.I0(a),.I1(b),.I2(c),.I3(d),.O(q));
`else
    assign q = INIT[{d,c,b,a}];
`endif
endmodule

module gf_serial_fanout #(parameter N=32, parameter D=$clog2(N), parameter LIVE_LEAVES=N)(
    input wire clk,reset,bit_in, output wire [N-1:0] leaves
);
    wire [N-1:0] stage [0:D];
    initial if(LIVE_LEAVES<1 || LIVE_LEAVES>N || (1<<D)!=N)
        $error("Fanout requires a nonempty prefix of a power-of-two tree");
    gf_serial_reg root(.clk(clk),.reset(reset),.d(bit_in),.q(stage[0][0]));
    generate for(genvar level=1;level<=D;level=level+1) begin : g_level
        // Keep the original D+1 clocks on every live leaf. A prefix needs
        // only its ancestors, not the unused half-trees held by DONT_TOUCH.
        for(genvar node=0;node<((LIVE_LEAVES+(1<<(D-level))-1)>>(D-level));node=node+1) begin : g_node
            gf_serial_reg branch(.clk(clk),.reset(reset),
                .d(stage[level-1][node>>1]),.q(stage[level][node]));
        end
    end endgenerate
    assign leaves=stage[D];
    generate if(LIVE_LEAVES<N) begin:g_unused
        assign stage[D][N-1:LIVE_LEAVES]=0;
    end endgenerate
endmodule

module gf_serial_add_retimed(
    input wire clk,reset,clear_carry,x,y, output wire sum
);
    wire carry, sum_next, carry_next;
    gf_serial_lut #(.INIT(16'h9696)) sum_lut(.a(x),.b(y),.c(carry),.d(1'b0),.q(sum_next));
    gf_serial_lut #(.INIT(16'h00e8)) carry_lut(.a(x),.b(y),.c(carry),.d(clear_carry),.q(carry_next));
    gf_serial_reg sum_reg(.clk(clk),.reset(reset),.d(sum_next),.q(sum));
    gf_serial_reg carry_reg(.clk(clk),.reset(reset),.d(carry_next),.q(carry));
endmodule

module gf_serial_mul40(
    input wire clk,reset,a_bit,b_bit,
    output wire product_bit,product_word_end
);
    wire [31:0] a_leaf;
    gf_serial_fanout a_tree(.clk(clk),.reset(reset),.bit_in(a_bit),.leaves(a_leaf));
    wire [39:0] phase,phase_tap;
    wire [31:0] clear_leaf;
    gf_serial_fanout word_clear_tree(.clk(clk),.reset(reset),.bit_in(phase_tap[39]),.leaves(clear_leaf));
    gf_serial_reg #(.INIT(1'b1)) phase_zero(.clk(clk),.reset(reset),.d(phase[39]),.q(phase[0]));
    generate for(genvar p=1;p<40;p=p+1) begin : g_phase
        gf_serial_reg step(.clk(clk),.reset(reset),.d(phase[p-1]),.q(phase[p]));
    end endgenerate
    // A phase-ring node drives only its successor and one local tap. Advance
    // the chosen tap by one phase to compensate this registered duplication.
    generate for(genvar p=0;p<40;p=p+1) begin : g_phase_tap
        gf_serial_reg tap(.clk(clk),.reset(reset),.d(phase[p]),.q(phase_tap[p]));
    end endgenerate
    wire [39:0] a_hold,b_delay,partial;
    wire [5:0] b_input_delay;
    generate for(genvar b=0;b<6;b=b+1) begin : g_b_input
        if(b==0) begin
            gf_serial_reg r(.clk(clk),.reset(reset),.d(b_bit),.q(b_input_delay[b]));
        end else begin
            gf_serial_reg r(.clk(clk),.reset(reset),.d(b_input_delay[b-1]),.q(b_input_delay[b]));
        end
    end endgenerate
    generate for(genvar lane=0;lane<40;lane=lane+1) begin : g_lane
        wire load,hold_next,active,active_next;
        gf_serial_reg load_reg(.clk(clk),.reset(reset),.d(phase_tap[(lane+4)%40]),.q(load));
        gf_serial_lut #(.INIT(16'hcaca)) hold_mux(.a(a_hold[lane]),.b(a_leaf[lane>>1]),
            .c(load),.d(1'b0),.q(hold_next));
        gf_serial_reg hold_reg(.clk(clk),.reset(reset),.d(hold_next),.q(a_hold[lane]));
        // Retire the preceding word's high partials at bit zero. Each lane
        // becomes valid again with its new A bit; no inter-word idle clocks.
        // Registered clear fanout has the same six-edge delay as A.
        assign active_next = load | (active & ~clear_leaf[lane>>1]);
        gf_serial_reg active_reg(.clk(clk),.reset(reset),.d(active_next),.q(active));
        if(lane==0) begin
            gf_serial_reg b_reg(.clk(clk),.reset(reset),.d(b_input_delay[5]),.q(b_delay[lane]));
        end else begin
            gf_serial_reg b_reg(.clk(clk),.reset(reset),.d(b_delay[lane-1]),.q(b_delay[lane]));
        end
        gf_serial_reg partial_reg(.clk(clk),.reset(reset),.d(a_hold[lane]&b_delay[lane]&active),.q(partial[lane]));
    end endgenerate
    wire [63:0] tree [0:6];
    assign tree[0] = {24'd0,partial};
    generate for(genvar level=0;level<6;level=level+1) begin : g_reduce
        localparam N=32>>level;
        wire [N-1:0] clear;
        gf_serial_fanout #(.N(N),.D(5-level)) clear_tree(.clk(clk),.reset(reset),
            .bit_in(phase_tap[2*level]),.leaves(clear));
        for(genvar node=0;node<N;node=node+1) begin : g_node
            gf_serial_add_retimed add(.clk(clk),.reset(reset),.clear_carry(clear[node]),
                .x(tree[level][2*node]),.y(tree[level][2*node+1]),.sum(tree[level+1][node]));
        end
        assign tree[level+1][63:N] = 0;
    end endgenerate
    assign product_bit = tree[6][0];
    // A separate marker register avoids a third load on a phase tap when the
    // downstream dot adder and its end-marker register both consume this bit.
    gf_serial_reg marker_reg(.clk(clk),.reset(reset),.d(phase_tap[11]),.q(product_word_end));
endmodule

// Signed-18 specialization of the same bubbles-free graph. Input A must be
// sign-extended from 18 to 40 bits; B may be any 40-bit word. The output remains
// exact modulo 2^40. A = sum(A[i]*2^i, i=0..16) - A[17]*2^17: the 23 repeated
// sign rows collapse to ONE negative row, without discarding any input bits.
// A retimed sign-negation layer replaces one removed reduction-tree level,
// preserving the original 13-clock latency and 40-clock word initiation rate.
module gf_serial_mul18_to40 #(parameter integer PRUNE_ZERO_ROWS=1,
                            parameter integer COMPACT_FANOUT=0)(
    input wire clk,reset,a_bit,b_bit,
    output wire product_bit,product_word_end
);
    wire [31:0] a_leaf,clear_leaf;
    wire [39:0] phase,phase_tap;
    gf_serial_fanout #(.LIVE_LEAVES(COMPACT_FANOUT ? 9 : 32)) a_tree(.clk(clk),.reset(reset),.bit_in(a_bit),.leaves(a_leaf));
    gf_serial_fanout #(.LIVE_LEAVES(COMPACT_FANOUT ? 9 : 32)) word_clear_tree(.clk(clk),.reset(reset),.bit_in(phase_tap[39]),.leaves(clear_leaf));
    gf_serial_reg #(.INIT(1'b1)) phase_zero(.clk(clk),.reset(reset),.d(phase[39]),.q(phase[0]));
    generate for(genvar p=1;p<40;p=p+1)begin:g_phase
        gf_serial_reg step(.clk(clk),.reset(reset),.d(phase[p-1]),.q(phase[p]));
    end
    for(genvar p=0;p<40;p=p+1)begin:g_phase_tap
        gf_serial_reg tap(.clk(clk),.reset(reset),.d(phase[p]),.q(phase_tap[p]));
    end endgenerate
    wire [17:0] a_hold,b_delay,partial,prepared;
    wire [5:0] b_input_delay;
    generate for(genvar b=0;b<6;b=b+1)begin:g_b_input
        if(b==0)begin
            gf_serial_reg r(.clk(clk),.reset(reset),.d(b_bit),.q(b_input_delay[b]));
        end else begin
            gf_serial_reg r(.clk(clk),.reset(reset),.d(b_input_delay[b-1]),.q(b_input_delay[b]));
        end
    end
    for(genvar lane=0;lane<18;lane=lane+1)begin:g_lane
        wire load,hold_next,active,active_next;
        gf_serial_reg load_reg(.clk(clk),.reset(reset),.d(phase_tap[(lane+4)%40]),.q(load));
        gf_serial_lut #(.INIT(16'hcaca)) hold_mux(.a(a_hold[lane]),.b(a_leaf[lane>>1]),
            .c(load),.d(1'b0),.q(hold_next));
        gf_serial_reg hold_reg(.clk(clk),.reset(reset),.d(hold_next),.q(a_hold[lane]));
        assign active_next=load | (active & ~clear_leaf[lane>>1]);
        gf_serial_reg active_reg(.clk(clk),.reset(reset),.d(active_next),.q(active));
        if(lane==0)begin
            gf_serial_reg b_reg(.clk(clk),.reset(reset),.d(b_input_delay[5]),.q(b_delay[lane]));
        end else begin
            gf_serial_reg b_reg(.clk(clk),.reset(reset),.d(b_delay[lane-1]),.q(b_delay[lane]));
        end
        gf_serial_reg partial_reg(.clk(clk),.reset(reset),.d(a_hold[lane]&b_delay[lane]&active),.q(partial[lane]));
        if(lane<17)begin
            gf_serial_reg prepare(.clk(clk),.reset(reset),.d(partial[lane]),.q(prepared[lane]));
        end
    end endgenerate
    // LSB-first negation: leave bits through the first 1 unchanged, then invert.
    // Clear on the last bit of the partial word, so the next word starts clean.
    // The extra marker register avoids a third load on phase_tap[6].
    wire negative_seen,negative_next,negative_bit,negative_clear;
    gf_serial_reg negative_marker(.clk(clk),.reset(reset),.d(phase_tap[5]),.q(negative_clear));
    gf_serial_lut #(.INIT(16'h6666)) negate(.a(partial[17]),.b(negative_seen),.c(1'b0),.d(1'b0),.q(negative_bit));
    gf_serial_lut #(.INIT(16'h0e0e)) seen_next(.a(partial[17]),.b(negative_seen),.c(negative_clear),.d(1'b0),.q(negative_next));
    gf_serial_reg seen_reg(.clk(clk),.reset(reset),.d(negative_next),.q(negative_seen));
    gf_serial_reg negative_reg(.clk(clk),.reset(reset),.d(negative_bit),.q(prepared[17]));
    wire [31:0] tree[0:5];
    assign tree[0]={14'd0,prepared};
    generate for(genvar level=0;level<5;level=level+1)begin:g_reduce
        localparam N=16>>level;
        localparam LIVE_INPUTS=(18+(1<<level)-1)>>level;
        wire [N-1:0] clear;
        gf_serial_fanout #(.N(N),.D(4-level),
            .LIVE_LEAVES(COMPACT_FANOUT && PRUNE_ZERO_ROWS ? LIVE_INPUTS/2 : N)) clear_tree(.clk(clk),.reset(reset),
            .bit_in(phase_tap[2*level+2]),.leaves(clear));
        for(genvar node=0;node<N;node=node+1)begin:g_node
            if(!PRUNE_ZERO_ROWS || 2*node+1<LIVE_INPUTS)begin:g_pair
                gf_serial_add_retimed add(.clk(clk),.reset(reset),.clear_carry(clear[node]),
                    .x(tree[level][2*node]),.y(tree[level][2*node+1]),.sum(tree[level+1][node]));
            end else if(2*node<LIVE_INPUTS)begin:g_single
                // x+0 with reset carry=0 never creates a carry. Retain the
                // exact one-clock sum delay, without carry state or LUTs.
                gf_serial_reg delay(.clk(clk),.reset(reset),.d(tree[level][2*node]),.q(tree[level+1][node]));
            end else begin:g_zero
                // Both operands and reset carry are identically zero.
                assign tree[level+1][node]=1'b0;
            end
        end
        assign tree[level+1][31:N]=0;
    end endgenerate
    assign product_bit=tree[5][0];
    gf_serial_reg marker_reg(.clk(clk),.reset(reset),.d(phase_tap[11]),.q(product_word_end));
endmodule

// Two full signed products and their full signed sum, still a one-bit graph.
// Feed sign-extended 18-bit operands as 40-bit words. The 37-bit signed dot
// product is entirely preserved in the 40-bit result; bit 39 is its sign.
module gf_serial_dot18 #(parameter integer SIGNED18_ROWS=1, parameter integer PRUNE_ZERO_ROWS=1,
                        parameter integer COMPACT_FANOUT=0)(
    input wire clk,reset,ai,bi,aq,bq,
    output wire sum_bit,sum_word_end
);
    wire pi,pq,ei,eq_unused;
    generate if(SIGNED18_ROWS)begin:g_signed_rows
        gf_serial_mul18_to40 #(.PRUNE_ZERO_ROWS(PRUNE_ZERO_ROWS),.COMPACT_FANOUT(COMPACT_FANOUT)) mul_i(.clk(clk),.reset(reset),.a_bit(ai),.b_bit(bi),
            .product_bit(pi),.product_word_end(ei));
        gf_serial_mul18_to40 #(.PRUNE_ZERO_ROWS(PRUNE_ZERO_ROWS),.COMPACT_FANOUT(COMPACT_FANOUT)) mul_q(.clk(clk),.reset(reset),.a_bit(aq),.b_bit(bq),
            .product_bit(pq),.product_word_end(eq_unused));
    end else begin:g_generic_rows
        gf_serial_mul40 mul_i(.clk(clk),.reset(reset),.a_bit(ai),.b_bit(bi),
            .product_bit(pi),.product_word_end(ei));
        gf_serial_mul40 mul_q(.clk(clk),.reset(reset),.a_bit(aq),.b_bit(bq),
            .product_bit(pq),.product_word_end(eq_unused));
    end endgenerate
    gf_serial_add_retimed add(.clk(clk),.reset(reset),.clear_carry(ei),
        .x(pi),.y(pq),.sum(sum_bit));
    gf_serial_reg end_reg(.clk(clk),.reset(reset),.d(ei),.q(sum_word_end));
endmodule

// Fit-only registered interface. Package I/O timing is excluded by the fit
// constraints; every arithmetic launch/capture path uses the routed clock.
module gf_serial_dot18_fit_top #(parameter integer SIGNED18_ROWS=1, parameter integer PRUNE_ZERO_ROWS=1,
                                parameter integer COMPACT_FANOUT=0)(
    input wire clk,reset,ai,bi,aq,bq,
    output wire sum_bit,sum_word_end
);
    wire air,bir,aqr,bqr,s,e;
    gf_serial_reg in_ai(.clk(clk),.reset(reset),.d(ai),.q(air));
    gf_serial_reg in_bi(.clk(clk),.reset(reset),.d(bi),.q(bir));
    gf_serial_reg in_aq(.clk(clk),.reset(reset),.d(aq),.q(aqr));
    gf_serial_reg in_bq(.clk(clk),.reset(reset),.d(bq),.q(bqr));
    gf_serial_dot18 #(.SIGNED18_ROWS(SIGNED18_ROWS),.PRUNE_ZERO_ROWS(PRUNE_ZERO_ROWS),.COMPACT_FANOUT(COMPACT_FANOUT)) graph(.clk(clk),.reset(reset),.ai(air),.bi(bir),.aq(aqr),.bq(bqr),
        .sum_bit(s),.sum_word_end(e));
    gf_serial_reg out_sum(.clk(clk),.reset(reset),.d(s),.q(sum_bit));
    gf_serial_reg out_end(.clk(clk),.reset(reset),.d(e),.q(sum_word_end));
endmodule
`default_nettype wire
