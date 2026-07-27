/*
 * Brian Greenforest's registered one-bit serial full-adder cell.
 *
 * This synthesizable cell is copied into the self-contained RF build.
 * Signal arithmetic is streamed LSB-first; no wide sample adder is inferred.
 * Its private source-location comment was removed for public distribution.
 * No synthesizable code was changed.
 */

`default_nettype none

module gf_serial_add_cell (
    input  wire clk_i,
    input  wire rst_i,
    input  wire word_start_i,
    input  wire x_bit_i,
    input  wire y_bit_i,
    output reg  sum_bit_o,
    output reg  word_start_o
);
    reg carry_q;
    wire sum_d = word_start_i
        ? (x_bit_i ^ y_bit_i)
        : (x_bit_i ^ y_bit_i ^ carry_q);
    wire carry_d = word_start_i
        ? (x_bit_i & y_bit_i)
        : ((x_bit_i & y_bit_i)
         | (x_bit_i & carry_q)
         | (y_bit_i & carry_q));

    always @(posedge clk_i) begin
        if (rst_i) begin
            carry_q      <= 1'b0;
            sum_bit_o    <= 1'b0;
            word_start_o <= 1'b0;
        end else begin
            carry_q      <= carry_d;
            sum_bit_o    <= sum_d;
            word_start_o <= word_start_i;
        end
    end
endmodule

/* One complete two's-complement word through the serial cell. */
module gf_serial_word_add #(
    parameter integer WORD_BITS = 16
) (
    input  wire                 clk_i,
    input  wire                 rst_i,
    input  wire                 start_i,
    input  wire [WORD_BITS-1:0] x_word_i,
    input  wire [WORD_BITS-1:0] y_word_i,
    output reg                  busy_o,
    output reg                  done_o,
    output reg  [WORD_BITS-1:0] sum_word_o
);
    localparam integer INDEX_BITS = (WORD_BITS <= 2) ? 1 : $clog2(WORD_BITS);

    reg [WORD_BITS-1:0] x_q;
    reg [WORD_BITS-1:0] y_q;
    reg [INDEX_BITS-1:0] feed_index_q;
    reg                  capture_valid_q;
    reg [INDEX_BITS-1:0] capture_index_q;

    wire cell_sum;
    wire cell_word_start;
    wire feed_word_start = busy_o && (feed_index_q == 0);

    gf_serial_add_cell u_cell (
        .clk_i        (clk_i),
        .rst_i        (rst_i),
        .word_start_i (feed_word_start),
        .x_bit_i      (busy_o ? x_q[feed_index_q] : 1'b0),
        .y_bit_i      (busy_o ? y_q[feed_index_q] : 1'b0),
        .sum_bit_o    (cell_sum),
        .word_start_o (cell_word_start)
    );

    always @(posedge clk_i) begin
        if (rst_i) begin
            x_q             <= {WORD_BITS{1'b0}};
            y_q             <= {WORD_BITS{1'b0}};
            feed_index_q    <= {INDEX_BITS{1'b0}};
            capture_valid_q <= 1'b0;
            capture_index_q <= {INDEX_BITS{1'b0}};
            busy_o          <= 1'b0;
            done_o          <= 1'b0;
            sum_word_o      <= {WORD_BITS{1'b0}};
        end else begin
            done_o <= 1'b0;

            if (capture_valid_q) begin
                sum_word_o[capture_index_q] <= cell_sum;
                if (capture_index_q == WORD_BITS-1) begin
                    done_o <= 1'b1;
                    capture_valid_q <= 1'b0;
                end
            end

            if (start_i && !busy_o && !capture_valid_q) begin
                x_q          <= x_word_i;
                y_q          <= y_word_i;
                feed_index_q <= {INDEX_BITS{1'b0}};
                busy_o       <= 1'b1;
            end else if (busy_o) begin
                capture_valid_q <= 1'b1;
                capture_index_q <= feed_index_q;
                if (feed_index_q == WORD_BITS-1) begin
                    busy_o <= 1'b0;
                end else begin
                    feed_index_q <= feed_index_q + 1'b1;
                end
            end
        end
    end
endmodule

`default_nettype wire
