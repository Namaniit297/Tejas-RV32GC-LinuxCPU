module unified_cache #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter MEM_DEPTH  = 1 << ADDR_WIDTH
)(
    input clk,
    input rst,

    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] wdata,
    input [3:0] strobe,              // WSTRB-like byte-enable
    input write_en,
    input read_en,

    input [2:0] load_type,          // 000=LB, 001=LBU, 010=LH, 011=LHU, 100=LW
    output reg [31:0] rdata
);

    reg [7:0] mem [0:MEM_DEPTH-1];  // Byte-addressable

    // Internal read wires
    wire [7:0]  byte0 = mem[addr];
    wire [7:0]  byte1 = mem[addr+1];
    wire [7:0]  byte2 = mem[addr+2];
    wire [7:0]  byte3 = mem[addr+3];

    // Composing word
    wire [15:0] halfword = {byte1, byte0};
    wire [31:0] word     = {byte3, byte2, byte1, byte0};

    // Sign/Zero Extend
    always @(*) begin
        case (load_type)
            3'b000: rdata = {{24{byte0[7]}}, byte0};      // LB
            3'b001: rdata = {24'b0, byte0};               // LBU
            3'b010: rdata = {{16{halfword[15]}}, halfword}; // LH
            3'b011: rdata = {16'b0, halfword};            // LHU
            3'b100: rdata = word;                         // LW
            default: rdata = 32'b0;
        endcase
    end

    // WRITE on posedge clock
    always @(posedge clk) begin
        if (write_en) begin
            if (strobe[0]) mem[addr]     <= wdata[7:0];
            if (strobe[1]) mem[addr + 1] <= wdata[15:8];
            if (strobe[2]) mem[addr + 2] <= wdata[23:16];
            if (strobe[3]) mem[addr + 3] <= wdata[31:24];
        end
    end

endmodule
