// SPDX-License-Identifier: MIT
// Small dual-clock FIFO used to carry decoded PSDU bytes to the E310 ARM.
//
// Optional synchronous look-ahead read permits block RAM inference without
// a generated vendor FIFO core. The legacy asynchronous path is preserved.
// Gray pointers alone convey occupancy between the two clock domains.

`timescale 1ns/1ps

module gf_e310_async_fifo #(
    parameter integer WIDTH = 10,
    parameter integer ADDRESS_WIDTH = 12,
    parameter integer USE_BLOCK_RAM = 0
) (
    input  wire                         write_clk,
    input  wire                         write_reset,
    input  wire [WIDTH-1:0]             write_data,
    input  wire                         write_enable,
    output wire                         write_ready,
    output wire                         write_overflow,

    input  wire                         read_clk,
    input  wire                         read_reset,
    output wire [WIDTH-1:0]             read_data,
    output wire                         read_valid,
    input  wire                         read_pop
);
    localparam integer POINTER_WIDTH = ADDRESS_WIDTH + 1;

    initial begin
        if (ADDRESS_WIDTH < 2)
            $error("gf_e310_async_fifo ADDRESS_WIDTH must be at least two");
    end

    (* ram_style = USE_BLOCK_RAM ? "block" : "distributed" *)
    reg [WIDTH-1:0] memory [0:(1 << ADDRESS_WIDTH)-1];

    reg [POINTER_WIDTH-1:0] write_binary = {POINTER_WIDTH{1'b0}};
    reg [POINTER_WIDTH-1:0] write_gray = {POINTER_WIDTH{1'b0}};
    reg write_full = 1'b0;
    reg [POINTER_WIDTH-1:0] read_binary = {POINTER_WIDTH{1'b0}};
    reg [POINTER_WIDTH-1:0] read_gray = {POINTER_WIDTH{1'b0}};

    (* ASYNC_REG = "TRUE" *) reg [POINTER_WIDTH-1:0]
        read_gray_write_sync_1 = {POINTER_WIDTH{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [POINTER_WIDTH-1:0]
        read_gray_write_sync_2 = {POINTER_WIDTH{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [POINTER_WIDTH-1:0]
        write_gray_read_sync_1 = {POINTER_WIDTH{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [POINTER_WIDTH-1:0]
        write_gray_read_sync_2 = {POINTER_WIDTH{1'b0}};

    wire write_accept = write_enable && !write_full;
    wire read_accept = read_pop && read_valid;
    wire [POINTER_WIDTH-1:0] write_binary_next =
        write_binary + write_accept;
    wire [POINTER_WIDTH-1:0] write_gray_next =
        (write_binary_next >> 1) ^ write_binary_next;
    wire [POINTER_WIDTH-1:0] read_binary_next =
        read_binary + read_accept;
    wire [POINTER_WIDTH-1:0] read_gray_next =
        (read_binary_next >> 1) ^ read_binary_next;

    // A full FIFO has reached the synchronized read pointer with both wrap
    // bits inverted.  Empty is an exact Gray-pointer match.
    wire [POINTER_WIDTH-1:0] full_compare = {
        ~read_gray_write_sync_2[POINTER_WIDTH-1:POINTER_WIDTH-2],
        read_gray_write_sync_2[POINTER_WIDTH-3:0]
    };
    wire write_full_next = write_gray_next == full_compare;
    wire empty = read_gray == write_gray_read_sync_2;

    assign write_ready = !write_full;
    assign write_overflow = write_enable && !write_ready;
    generate if(USE_BLOCK_RAM) begin: block_read
        reg [WIDTH-1:0] next_word;
        reg output_valid=1'b0;
        // Keep the current word while stalled, or fetch its successor on a
        // pop. The RAM read register has no reset, so it can map into BRAM.
        // Occupancy retains the current word until consumption: full capacity
        // is exactly 2**ADDRESS_WIDTH, not that amount plus a hidden slot.
        always @(posedge read_clk)
            next_word <= memory[read_binary_next[ADDRESS_WIDTH-1:0]];
        always @(posedge read_clk)
            if(read_reset) output_valid<=1'b0;
            else output_valid <= read_gray_next != write_gray_read_sync_2;
        assign read_data=next_word;
        assign read_valid=output_valid;
    end else begin: asynchronous_read
        assign read_valid = !empty;
        assign read_data = memory[read_binary[ADDRESS_WIDTH-1:0]];
    end endgenerate

    always @(posedge write_clk) begin
        if (write_reset) begin
            write_binary <= {POINTER_WIDTH{1'b0}};
            write_gray <= {POINTER_WIDTH{1'b0}};
            write_full <= 1'b0;
            read_gray_write_sync_1 <= {POINTER_WIDTH{1'b0}};
            read_gray_write_sync_2 <= {POINTER_WIDTH{1'b0}};
        end else begin
            read_gray_write_sync_1 <= read_gray;
            read_gray_write_sync_2 <= read_gray_write_sync_1;
            write_full <= write_full_next;
            if (write_accept) begin
                memory[write_binary[ADDRESS_WIDTH-1:0]] <= write_data;
                write_binary <= write_binary_next;
                write_gray <= write_gray_next;
            end
        end
    end

    always @(posedge read_clk) begin
        if (read_reset) begin
            read_binary <= {POINTER_WIDTH{1'b0}};
            read_gray <= {POINTER_WIDTH{1'b0}};
            write_gray_read_sync_1 <= {POINTER_WIDTH{1'b0}};
            write_gray_read_sync_2 <= {POINTER_WIDTH{1'b0}};
        end else begin
            write_gray_read_sync_1 <= write_gray;
            write_gray_read_sync_2 <= write_gray_read_sync_1;
            if (read_accept) begin
                read_binary <= read_binary_next;
                read_gray <= read_gray_next;
            end
        end
    end
endmodule
