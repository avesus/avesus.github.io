`timescale 1ns/1ps

module lane_parity (
    input  logic [7:0] memory [0:3],
    output logic [3:0] parity
);
    always_comb begin
        for (int lane = 0; lane < 4; lane++) begin
            parity[lane] = ^memory[lane];
        end
    end
endmodule

module arrays_and_checks_tb;
    logic [7:0] memory [0:3];
    logic [3:0] parity;

    lane_parity dut (
        .memory(memory),
        .parity(parity)
    );

    initial begin
        memory[0] = 8'b0000_0001;
        memory[1] = 8'b0000_0011;
        memory[2] = 8'b1010_1010;
        memory[3] = 8'b1111_1111;

        #1;
        assert (parity === 4'b0001)
            else $fatal(1, "unexpected parity vector: %b", parity);

        $display("PASS: packed words, unpacked memory, loop, and assertion");
        $finish;
    end
endmodule
