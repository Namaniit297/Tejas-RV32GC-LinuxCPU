// ============================================================================
// Immediate Data Extractor for RISC-V
// ============================================================================
// Purpose:
//   - Extracts immediate values from 32-bit instructions.
//   - Supports I-type, S-type, B-type, U-type, and J-type.
//   - Sign-extends to 64 bits for RV64 pipeline.
//
// Inputs:
//   instruction : 32-bit RISC-V instruction
//
// Outputs:
//   imm_data    : 64-bit sign-extended immediate
//
// Notes:
//   - Used in the ID stage for ALU, branch target, load/store address.
//   - Imm formats (bits in [] are from instruction):
//       I-type : [31:20]
//       S-type : [31:25 | 11:7]
//       B-type : [31 | 7 | 30:25 | 11:8] << 1
//       U-type : [31:12] << 12
//       J-type : [31 | 19:12 | 20 | 30:21] << 1
// ============================================================================

module imm_extractor (
    input  wire [31:0] instruction,
    output reg  [63:0] imm_data
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-type (ADDI, LW, etc.)
            7'b0000011, // LOAD
            7'b0010011, // I-type ALU
            7'b1100111: // JALR
                imm_data = {{52{instruction[31]}}, instruction[31:20]};

            // S-type (SW, SH, SB)
            7'b0100011:
                imm_data = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type (BEQ, BNE, BLT, BGE, etc.)
            7'b1100011:
                imm_data = {{51{instruction[31]}}, instruction[31], instruction[7],
                            instruction[30:25], instruction[11:8], 1'b0};

            // U-type (LUI, AUIPC)
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_data = {{32{instruction[31]}}, instruction[31:12], 12'b0};

            // J-type (JAL)
            7'b1101111:
                imm_data = {{43{instruction[31]}}, instruction[31], instruction[19:12],
                            instruction[20], instruction[30:21], 1'b0};

            default:
                imm_data = 64'd0; // Default to 0 for unknown opcodes
        endcase
    end

endmodule
