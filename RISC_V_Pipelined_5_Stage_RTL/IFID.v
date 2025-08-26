// -----------------------------------------------------------------------------
// IF/ID Pipeline Register
// -----------------------------------------------------------------------------
// This module forms the pipeline register between the Instruction Fetch (IF)
// stage and the Instruction Decode (ID) stage in a RISC-V processor pipeline.
//
// Features:
//   - Stores the fetched instruction and the current Program Counter (PC).
//   - Supports synchronous reset and flush operations.
//   - Controlled by IFIDWrite signal to allow pipeline stalls.
//
// Inputs:
//   clk        : System clock
//   reset      : Synchronous reset (active high)
//   flush      : Clears pipeline register (e.g., branch misprediction)
//   IFIDWrite  : Write enable (0 = write, 1 = stall pipeline)
//   instruction: 32-bit instruction from instruction memory
//   pc_in      : 64-bit Program Counter value
//
// Outputs:
//   inst_out   : 32-bit stored instruction for ID stage
//   pc_out     : 64-bit stored PC value for ID stage
// -----------------------------------------------------------------------------

module IFID #(
    parameter INSTR_WIDTH = 32,
    parameter PC_WIDTH    = 64
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  flush,
    input  wire                  IFIDWrite,
    input  wire [INSTR_WIDTH-1:0] instruction,
    input  wire [PC_WIDTH-1:0]    pc_in,
    output reg  [INSTR_WIDTH-1:0] inst_out,
    output reg  [PC_WIDTH-1:0]    pc_out
);

    always @(posedge clk) begin
        if (reset || flush) begin
            // On reset or flush → clear pipeline register
            inst_out <= {INSTR_WIDTH{1'b0}};
            pc_out   <= {PC_WIDTH{1'b0}};
        end 
        else if (!IFIDWrite) begin
            // Write only if not stalled
            inst_out <= instruction;
            pc_out   <= pc_in;
        end
        // If IFIDWrite = 1 → retain previous values (stall)
    end

endmodule
