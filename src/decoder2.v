module Decoder(
    input  wire [31:0] instr,
    output wire [6:0]  opcode,
    output wire [2:0]  funct3,
    output wire [6:0]  funct7,
    output reg  [31:0] imm,
    output reg         imm_valid  // high if imm is valid for this instr type
);

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    always @(*) begin
        case (instr[6:0])
            7'b0010011, // I-type ALU (addi, slti, ...)
            7'b0000011, // Load
            7'b1100111: // JALR
            begin
                // I-type immediate sign-extended
                imm_valid = 1'b1;
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            7'b0100011: // Store (S-type)
            begin
                imm_valid = 1'b1;
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            7'b1100011: // Branch (B-type)
            begin
                imm_valid = 1'b1;
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            7'b1101111: // JAL (J-type)
            begin
                imm_valid = 1'b1;
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            default:
            begin
                imm_valid = 1'b0;
                imm = 32'd0;
            end
        endcase
    end

endmodule
