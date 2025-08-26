// ============================================================================
// Branching Unit for RISC-V Pipeline
// ============================================================================
// Purpose:
//   - Evaluates branch conditions using funct3 from instruction.
//   - Supports BEQ, BNE, BLT, BGE, BLTU, BGEU (RV64I).
//   - Outputs a single control signal for branch decision.
//
// Inputs:
//   funct3     : [2:0] - Encodes branch type
//   readData1  : [63:0] - Source register 1
//   readData2  : [63:0] - Source register 2
//
// Outputs:
//   branch_taken : High (1) if branch condition is true, else 0
//
// Notes:
//   - Used in EX stage along with Branch Target Adder.
//   - Signed and unsigned comparisons handled separately.
// ============================================================================

module branching_unit (
    input  wire [2:0]  funct3,
    input  wire [63:0] readData1,
    input  wire [63:0] readData2,
    output reg         branch_taken
);

    always @(*) begin
        case (funct3)
            3'b000: // BEQ - Branch if Equal
                branch_taken = (readData1 == readData2);

            3'b001: // BNE - Branch if Not Equal
                branch_taken = (readData1 != readData2);

            3'b100: // BLT - Branch if Less Than (signed)
                branch_taken = ($signed(readData1) < $signed(readData2));

            3'b101: // BGE - Branch if Greater or Equal (signed)
                branch_taken = ($signed(readData1) >= $signed(readData2));

            3'b110: // BLTU - Branch if Less Than (unsigned)
                branch_taken = (readData1 < readData2);

            3'b111: // BGEU - Branch if Greater or Equal (unsigned)
                branch_taken = (readData1 >= readData2);

            default: // Unknown funct3 → no branch
                branch_taken = 1'b0;
        endcase
    end

endmodule
