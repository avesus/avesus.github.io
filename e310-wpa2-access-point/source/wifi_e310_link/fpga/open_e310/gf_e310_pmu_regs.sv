// SPDX-License-Identifier: LGPL-3.0-or-later
// E310 board-management register/SPI contract, adapted from Ettus axi_pmu.v.
// No Wi-Fi protocol or RF sample processing lives here. The AVR supplies every
// reported power/battery value; there are no invented healthy-status values.
`timescale 1ns/1ps
module gf_e310_pmu_regs (
    input wire clk, reset,
    input wire spi_ss, spi_mosi, spi_sck,
    output wire spi_miso,
    input wire write_enable,
    input wire [7:0] write_address,
    input wire [31:0] write_data,
    input wire [3:0] write_strobe,
    output wire write_error,
    input wire [7:0] read_address,
    output reg [31:0] read_data,
    output wire irq
);
    wire spi_strobe;
    wire [63:0] spi_received;
    reg [63:0] spi_reply = 0;
    spi_slave spi (
        .clk(clk), .rst(reset), .ss(spi_ss), .mosi(spi_mosi),
        .sck(spi_sck), .miso(spi_miso), .parallel_stb(spi_strobe),
        .parallel_din(spi_reply), .parallel_dout(spi_received)
    );
    reg [63:0] status0 = 0, status1 = 0, status2 = 0;
    reg [7:0] irq_enable = 0;
    reg [31:0] shutdown = 0;
    reg [31:0] commands [0:31];
    reg [4:0] write_pointer = 0, read_pointer = 0;
    reg [5:0] command_count = 0;
    wire command_write = write_address == 0 || write_address > 4;
    wire pop = spi_strobe && command_count != 0;
    assign write_error = write_strobe != 4'hf ||
        (command_write && command_count == 32 && !pop);
    wire push = write_enable && !write_error && command_write;
    wire [31:0] command_word = write_address == 0 ?
        {write_data[23:0], 8'h00} :
        {write_data[7:0], write_data[15:8], write_address, 8'h01};

    always @(posedge clk) begin
        if (reset) begin
            status0 <= 0; status1 <= 0; status2 <= 0;
            spi_reply <= 0; irq_enable <= 0; shutdown <= 0;
            write_pointer <= 0; read_pointer <= 0; command_count <= 0;
        end else begin
            if (spi_strobe) begin
                case (spi_received[7:0])
                    0: status0 <= spi_received;
                    1: status1 <= spi_received;
                    2: status2 <= spi_received;
                endcase
                // Stock AVR polls pipelined 64-bit messages. Only a real
                // queued host write may set the valid bit in its reply.
                spi_reply <= pop ? {1'b1, 31'd0, commands[read_pointer]} : 64'd0;
            end
            if (push) begin
                commands[write_pointer] <= command_word;
                write_pointer <= write_pointer + 1'b1;
            end
            if (pop) read_pointer <= read_pointer + 1'b1;
            case ({push, pop})
                2'b10: command_count <= command_count + 1'b1;
                2'b01: command_count <= command_count - 1'b1;
            endcase
            if (write_enable && !write_error) begin
                if (write_address == 0) shutdown <= write_data;
                if (write_address == 4) irq_enable <= write_data[15:8];
            end
        end
    end

    assign irq = |(status1[63:56] & irq_enable);
    always @* begin
        read_data = 32'hdeadbeef;
        case (read_address)
            8'h00: read_data = shutdown;
            8'h04: read_data = {16'd0, irq_enable, status0[15:8]};
            8'h08: read_data = {8'd0, status0[55:48], status0[63:56], status0[47:40]};
            8'h0c: read_data = {27'd0, status0[33:32], status0[35], status0[37:36]};
            8'h10: read_data = {status1[31:24], status1[39:32], status1[15:8], status1[23:16]};
            8'h14: read_data = {8'd0, status1[63:56], status1[47:40], status1[55:48]};
            8'h18: read_data = {16'd0, status2[15:8], status2[23:16]};
            8'h1c: read_data = {24'd0, status2[31:24]};
        endcase
    end
endmodule
