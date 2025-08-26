// ============================================================================
// ALU Control Unit for RISC-V Pipeline
// ============================================================================
// Purpose:
//   - Generates specific ALU operation codes based on ALUOp (from CU)
//     and funct7/funct3 fields (from instruction).
//
// Inputs:
//   AluOp    : 2-bit signal from Control Unit
//              00 -> Load/Store (ADD)
//              01 -> Branch     (SUB)
//              10 -> R-type/I-type (Use funct fields)
//   funct7   : Bit [30] of instruction (to distinguish ADD/SUB, SRL/SRA)
//   funct3   : Instruction[14:12] (to select operation)
//
// Outputs:
//   alu_control : 4-bit ALU operation code
//
// Encoding (example):
//   0000 -> AND
//   0001 -> OR
//   0010 -> ADD
//   0110 -> SUB
//   0011 -> XOR
//   0100 -> SLL
//   0101 -> SRL
//   0111 -> SLT
//   1000 -> SLTU
//   1001 -> SRA
// ============================================================================

module alu_control (
    input  wire [1:0] AluOp,       // Control signal from CU
    input  wire [6:0] funct7,      // funct7 from instruction
    input  wire [2:0] funct3,      // funct3 from instruction
    output reg  [3:0] alu_control  // ALU operation selector
);

    always @(*) begin
        case (AluOp)
            2'b00: alu_control = 4'b0010; // Load/Store -> ADD
            2'b01: alu_control = 4'b0110; // Branch    -> SUB
            2'b10: begin
                case (funct3)
                    3'b000: alu_control = (funct7[5] ? 4'b0110 : 4'b0010); // SUB : ADD
                    3'b111: alu_control = 4'b0000; // AND
                    3'b110: alu_control = 4'b0001; // OR
                    3'b100: alu_control = 4'b0011; // XOR
                    3'b001: alu_control = 4'b0100; // SLL
                    3'b101: alu_control = (funct7[5] ? 4'b1001 : 4'b0101); // SRA : SRL
                    3'b010: alu_control = 4'b0111; // SLT
                    3'b011: alu_control = 4'b1000; // SLTU
                    default: alu_control = 4'b1111; // INVALID
                endcase
            end
            default: alu_control = 4'b1111; // Safe fallback
        endcase
    end

endmodule
