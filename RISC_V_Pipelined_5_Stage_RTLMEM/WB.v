// ============================================================================
// MEM/WB Pipeline Register
// ============================================================================
// Purpose:
//   - Latches data from Memory (MEM) stage into Write-Back (WB) stage.
//   - Holds memory read data, ALU result, destination register, and control signals.
//   - Ensures proper pipelined execution.
//
// Notes:
//   - Uses synchronous reset.
//   - Optional flush input can be added if you want to clear this stage
//     (e.g., after a mispredicted branch).
// ============================================================================

module MEMWB (
    input  wire        clk,           // Clock signal
    input  wire        reset,         // Reset signal (synchronous)
    input  wire        flush,         // Flush signal (optional, clears stage)
    input  wire [63:0] read_data_in,  // Data from memory stage
    input  wire [63:0] result_alu_in, // ALU result from EX/MEM
    input  wire [4:0]  Rd_in,         // Destination register
    input  wire        memtoreg_in,   // Control: select memory/ALU data
    input  wire        regwrite_in,   // Control: register write enable

    output reg  [63:0] readdata,      // Latched memory read data
    output reg  [63:0] result_alu_out,// Latched ALU result
    output reg  [4:0]  rd,            //
