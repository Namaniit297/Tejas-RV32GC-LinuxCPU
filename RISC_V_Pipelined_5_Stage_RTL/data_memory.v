// ============================================================================
// Data Memory Module
// ============================================================================
// Purpose:
//   - Models byte-addressable data memory for a pipelined RISC-V processor.
//   - Supports load (read) and store (write) operations.
//   - Provides debug outputs for observing memory contents.
//
// Features:
//   - Parameterized depth and data width.
//   - Byte-addressable (64-bit aligned load/store).
//   - Synchronous write, combinational read.
//   - Clean reset and initialization for simulation.
//   - Debug signals allow monitoring of memory contents.
//
// Notes:
//   - Memory is small for simulation (default: 64 bytes).
//   - For synthesis on FPGA/ASIC, replace with block RAM/dual-port RAM.
//
// ============================================================================

module data_memory #(
    parameter DATA_WIDTH = 64,   // Default word size = 64 bits
    parameter ADDR_WIDTH = 6,    // Default: 64 bytes -> 6-bit address space
    parameter MEM_SIZE   = 64    // Total bytes
)(
    input  wire                     clk,          // Clock
    input  wire                     memorywrite,  // Write enable
    input  wire                     memoryread,   // Read enable
    input  wire [DATA_WIDTH-1:0]    write_data,   // Data to write
    input  wire [ADDR_WIDTH-1:0]    address,      // Byte address
    output reg  [DATA_WIDTH-1:0]    read_data,    // Data read
    output wire [DATA_WIDTH-1:0]    debug_word0,  // Debug output word[0]
    output wire [DATA_WIDTH-1:0]    debug_word1,  // Debug output word[1]
    output wire [DATA_WIDTH-1:0]    debug_word2,  // Debug output word[2]
    output wire [DATA_WIDTH-1:0]    debug_word3,  // Debug output word[3]
    output wire [DATA_WIDTH-1:0]    debug_word4,  // Debug output word[4]
    output wire [DATA_WIDTH-1:0]    debug_word5,  // Debug output word[5]
    output wire [DATA_WIDTH-1:0]    debug_word6,  // Debug output word[6]
    output wire [DATA_WIDTH-1:0]    debug_word7   // Debug output word[7]
);

    // Memory array (byte-addressable)
    reg [7:0] mem [0:MEM_SIZE-1];

    integer i;
    initial begin
        // Initialize memory to zero
        for (i = 0; i < MEM_SIZE; i = i + 1)
            mem[i] = 8'd0;

        // Example preload (like your version)
        mem[0]  = 8'd1;
        mem[8]  = 8'd2;
        mem[16] = 8'd3;
        mem[24] = 8'd4;
        mem[32] = 8'd5;
        mem[40] = 8'd6;
        mem[48] = 8'd7;
        mem[56] = 8'd8;
    end

    // -------------------
    // Combinational Read
    // -------------------
    always @(*) begin
        if (memoryread) begin
            read_data = {mem[address+7], mem[address+6], mem[address+5], mem[address+4],
                         mem[address+3], mem[address+2], mem[address+1], mem[address+0]};
        end else begin
            read_data = {DATA_WIDTH{1'b0}};
        end
    end

    // -------------------
    // Sequential Write
    // -------------------
    always @(posedge clk) begin
        if (memorywrite) begin
            mem[address+0] <= write_data[7:0];
            mem[address+1] <= write_data[15:8];
            mem[address+2] <= write_data[23:16];
            mem[address+3] <= write_data[31:24];
            mem[address+4] <= write_data[39:32];
            mem[address+5] <= write_data[47:40];
            mem[address+6] <= write_data[55:48];
            mem[address+7] <= write_data[63:56];
        end
    end

    // -------------------
    // Debug Outputs (monitor memory words)
    // -------------------
    assign debug_word0 = {mem[7],  mem[6],  mem[5],  mem[4],  mem[3],  mem[2],  mem[1],  mem[0]};
    assign debug_word1 = {mem[15], mem[14], mem[13], mem[12], mem[11], mem[10], mem[9],  mem[8]};
    assign debug_word2 = {mem[23], mem[22], mem[21], mem[20], mem[19], mem[18], mem[17], mem[16]};
    assign debug_word3 = {mem[31], mem[30], mem[29], mem[28], mem[27], mem[26], mem[25], mem[24]};
    assign debug_word4 = {mem[39], mem[38], mem[37], mem[36], mem[35], mem[34], mem[33], mem[32]};
    assign debug_word5 = {mem[47], mem[46], mem[45], mem[44], mem[43], mem[42], mem[41], mem[40]};
    assign debug_word6 = {mem[55], mem[54], mem[53], mem[52], mem[51], mem[50], mem[49], mem[48]};
    assign debug_word7 = {mem[63], mem[62], mem[61], mem[60], mem[59], mem[58], mem[57], mem[56]};

endmodule
