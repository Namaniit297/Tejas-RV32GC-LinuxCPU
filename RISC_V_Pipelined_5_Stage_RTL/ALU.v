// ============================================================================
// 64-bit Arithmetic Logic Unit (ALU) for RISC-V Pipeline
// ============================================================================
// Purpose:
//   - Executes integer operations based on ALU control signals.
//   - Supports RISC-V base integer operations (ADD, SUB, AND, OR, XOR, shifts,
//     set-less-than signed/unsigned, NOR).
//
// Inputs:
//   a, b     : 64-bit operands
//   ALuop    : 4-bit ALU operation code (from ALU Control Unit)
//
// Outputs:
//   Result   : 64-bit computation result
//   zero     : High if Result == 0 (used for branches)
//
// Supported ALUop Encoding (example):
//   0000 -> AND
//   0001 -> OR
//   0010 -> ADD
//   0110 -> SUB
//   0011 -> XOR
//   0100 -> SLL
//   0101 -> SRL
//   0111 -> SLT  (signed)
//   1000 -> SLTU (unsigned)
//   1001 -> SRA
//   1100 -> NOR
//   1111 -> NOP/Invalid
// ============================================================================

module Alu64 (
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire [3:0]  ALuop,
    output reg  [63:0] Result,
    output reg         zero
);

    always @(*) begin
        case (ALuop)
            4'b0000: Result = a & b;                        // AND
            4'b0001: Result = a | b;                        // OR
            4'b0010: Result = a + b;                        // ADD
            4'b0110: Result = a - b;                        // SUB
            4'b0011: Result = a ^ b;                        // XOR
            4'b0100: Result = a << b[5:0];                  // SLL (shift left logical, lower 6 bits for RV64)
            4'b0101: Result = a >> b[5:0];                  // SRL (shift right logical)
            4'b1001: Result = $signed(a) >>> b[5:0];        // SRA (shift right arithmetic)
            4'b0111: Result = ($signed(a) < $signed(b)) ? 64'd1 : 64'd0; // SLT
            4'b1000: Result = (a < b) ? 64'd1 : 64'd0;      // SLTU
            4'b1100: Result = ~(a | b);                     // NOR
            default: Result = 64'd0;                        // Default/NOP
        endcase

        // Zero flag (used in BEQ/BNE)
        zero = (Result == 64'd0);
    end

endmodule
