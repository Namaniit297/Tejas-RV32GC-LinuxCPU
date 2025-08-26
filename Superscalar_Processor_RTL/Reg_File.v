module RegisterFile (
    input        regRead,
    input        clk,
    input        hlt,
    input        busy1,
    input        busy2,
    input  [1:0] regWrite,
    input  [4:0] readAddr1,
    input  [4:0] readAddr2,
    input  [4:0] readAddr3,
    input  [4:0] readAddr4,
    input  [4:0] writeAddr1,
    input  [4:0] writeAddr2,
    input  [4:0] destBT1,
    input  [4:0] destBT2,
    input  [3:0] tag1,
    input  [3:0] tag2,
    input [15:0] writeData1,
    input [15:0] writeData2,
    output reg [20:0] readData1,
    output reg [20:0] readData2,
    output reg [20:0] readData3,
    output reg [20:0] readData4,
    output reg read
);

    parameter DATA_WIDTH = 16;
    parameter ARF_WIDTH  = DATA_WIDTH + 5; // 21

    // Architectural Register File: each entry = [20:0] (16-bit data + 5 tag/busy)
    reg [ARF_WIDTH-1:0] registers [0:31];
    integer i;

    // Initialize read flag and registers
    initial begin
        read = 1'b0;
        for (i = 0; i < 32; i = i + 1)
            registers[i] = {ARF_WIDTH{1'b0}};
        // optional preload (file should contain 21-bit hex values per line)
        $readmemh("loadReg1.dat", registers);
    end

    // Synchronous read and tag/busy update (on read enable)
    always @(posedge clk) begin
        if (regRead) begin
            readData1 <= registers[readAddr1];
            readData2 <= registers[readAddr2];
            readData3 <= registers[readAddr3];
            readData4 <= registers[readAddr4];

            // update tag(4) + busy(1) bits for destination BT entries
            registers[destBT1][20:16] <= {tag1, busy1};
            registers[destBT2][20:16] <= {tag2, busy2};

            read <= ~read;
        end
    end

    // Write ports (two independent write enables)
    always @(posedge clk) begin
        if (regWrite[0])
            registers[writeAddr1][15:0] <= writeData1;
    end

    always @(posedge clk) begin
        if (regWrite[1])
            registers[writeAddr2][15:0] <= writeData2;
    end

    // Simulation-only monitors (kept from original for debug)
    initial begin
        for (i = 0; i < 14; i = i + 1)
            $display("%0t  reg %0d = %0d", $time, i, registers[i][15:0]);
        #200;
        for (i = 1; i < 12; i = i + 1)
            $display("%0t  reg %0d = %0d", $time, i, registers[i][15:0]);
    end

    always @(registers[7])
        $display("%0t  reg 7 = %0d", $time, registers[7][15:0]);

    always @(registers[11])
        $display("%0t  reg 11 = %0d", $time, registers[11][15:0]);

    always @(registers[8])
        $display("%0t  reg 8 = %0d", $time, registers[8][15:0]);

    always @(registers[5])
        $display("%0t  reg 5 = %0d", $time, registers[5][15:0]);

    always @(registers[2])
        $display("%0t  reg 2 = %0d", $time, registers[2][15:0]);

endmodule
