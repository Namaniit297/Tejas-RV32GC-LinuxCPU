// ============================================================================
// Instruction Parser Module
// ============================================================================
// Purpose:
//   - Extracts fields from a 32-bit RISC-V instruction.
//   - Provides opcode, destination register, source registers, funct3, funct7.
//   - Used in the Instruction Decode (ID) stage of the pipeline.
//
// Instruction Format (R-type example):
//   31 -------- 25 24 --- 20 19 --- 15 14 - 12 11 --- 7 6 ------ 0
//   | funct7     |  rs2   |  rs1   | funct3 |   rd   |  opcode |
// 
// Inputs:
//   instruction : 32-bit RISC-V instruction
//
// Outputs:
//   opcode : [6:0]  - Identifies instruction type (e.g., load/store/branch)
//   rd     : [4:0]  - Destination register
//   rs1    : [4:0]  - Source register 1
//   rs2    : [4:0]  - Source register 2 (if used)
//   funct3 : [2:0]  - Function bits (differentiate instructions under same opcode)
//   funct7 : [6:0]  - Additional function bits (e.g., distinguishes ADD vs SUB)
//
// Notes:
//   - Works for R-type, I-type, S-type, B-type, U-type, J-type formats.
//   - Some outputs may be unused for certain formats.
// ============================================================================

module instruction_parser #(
    parameter INSTR_WIDTH = 32,
    parameter OPCODE_WIDTH = 7,
    parameter REG_ADDR_WIDTH = 5,
    parameter FUNCT3_WIDTH = 3,
    parameter FUNCT7_WIDTH = 7
)(
    input  wire [INSTR_WIDTH-1:0] instruction,

    output wire [OPCODE_WIDTH-1:0]   opcode,
    output wire [REG_ADDR_WIDTH-1:0] rd,
    output wire [REG_ADDR_WIDTH-1:0] rs1,
    output wire [REG_ADDR_WIDTH-1:0] rs2,
    output wire [FUNCT3_WIDTH-1:0]   funct3,
    output wire [FUNCT7_WIDTH-1:0]   funct7
);

    // Field extraction from RISC-V instruction encoding
    assign opcode = instruction[6:0];     // [6:0]   : opcode
    assign rd     = instruction[11:7];    // [11:7]  : destination register
    assign funct3 = instruction[14:12];   // [14:12] : funct3 field
    assign rs1    = instruction[19:15];   // [19:15] : source register 1
    assign rs2    = instruction[24:20];   // [24:20] : source register 2
    assign funct7 = instruction[31:25];   // [31:25] : funct7 field

endmodule
