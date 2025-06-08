//------------------------------------------------------------------------------
// rv32i_decoder_extended.v
// RV32I + FENCE / PAUSE / ECALL / EBREAK decoder, pure combinational.
//------------------------------------------------------------------------------

module rv32i_decoder_extended (
    input  wire [31:0] instr,

    // raw instruction fields
    output wire [6:0]  opcode,
    output wire [2:0]  funct3,
    output wire [6:0]  funct7,
    output wire [4:0]  rd,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,

    // one-hot instruction flags (base 40 + extras)
    output reg         instr_lui,
    output reg         instr_auipc,
    output reg         instr_jal,
    output reg         instr_jalr,
    output reg         instr_beq,
    output reg         instr_bne,
    output reg         instr_blt,
    output reg         instr_bge,
    output reg         instr_bltu,
    output reg         instr_bgeu,
    output reg         instr_lb,
    output reg         instr_lh,
    output reg         instr_lw,
    output reg         instr_lbu,
    output reg         instr_lhu,
    output reg         instr_sb,
    output reg         instr_sh,
    output reg         instr_sw,
    output reg         instr_addi,
    output reg         instr_slti,
    output reg         instr_sltiu,
    output reg         instr_xori,
    output reg         instr_ori,
    output reg         instr_andi,
    output reg         instr_slli,
    output reg         instr_srli,
    output reg         instr_srai,
    output reg         instr_add,
    output reg         instr_sub,
    output reg         instr_sll,
    output reg         instr_slt,
    output reg         instr_sltu,
    output reg         instr_xor,
    output reg         instr_srl,
    output reg         instr_sra,
    output reg         instr_or,
    output reg         instr_and,
    // extras
    output reg         instr_fence,
    output reg         instr_fence_tso,
    output reg         instr_pause,
    output reg         instr_ecall,
    output reg         instr_ebreak,

    // immediate fields
    output reg  [31:0] imm_I,
    output reg  [31:0] imm_S,
    output reg  [31:0] imm_B,
    output reg  [31:0] imm_U,
    output reg  [31:0] imm_J,

    // trap indicator
    output reg         illegal
);

    //----- raw fields -----
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    //----- compute all immediates -----
    always @* begin
        imm_I = {{20{instr[31]}}, instr[31:20]};                                        // I-type
        imm_S = {{20{instr[31]}}, instr[31:25], instr[11:7]};                           // S-type
        imm_B = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type, <<1
        imm_U = {instr[31:12], 12'd0};                                                  // U-type
        imm_J = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type, <<1
    end

    //----- decode all instructions -----
    always @* begin
        // default all flags low
        { instr_lui, instr_auipc, instr_jal, instr_jalr,
          instr_beq, instr_bne, instr_blt, instr_bge, instr_bltu, instr_bgeu,
          instr_lb, instr_lh, instr_lw, instr_lbu, instr_lhu,
          instr_sb, instr_sh, instr_sw,
          instr_addi, instr_slti, instr_sltiu, instr_xori, instr_ori, instr_andi,
          instr_slli, instr_srli, instr_srai,
          instr_add, instr_sub, instr_sll, instr_slt, instr_sltu,
          instr_xor, instr_srl, instr_sra, instr_or, instr_and,
          instr_fence, instr_fence_tso, instr_pause,
          instr_ecall, instr_ebreak } = 0;
        illegal = 0;

        case (opcode)
            // U-type
            7'b0110111: instr_lui    = 1;               // LUI
            7'b0010111: instr_auipc  = 1;               // AUIPC

            // J-type
            7'b1101111: instr_jal    = 1;               // JAL
            7'b1100111:                           // JALR
                if (funct3 == 3'b000) instr_jalr = 1;
                else                   illegal   = 1;

            // B-type
            7'b1100011: begin
                case (funct3)
                    3'b000: instr_beq  = 1;
                    3'b001: instr_bne  = 1;
                    3'b100: instr_blt  = 1;
                    3'b101: instr_bge  = 1;
                    3'b110: instr_bltu = 1;
                    3'b111: instr_bgeu = 1;
                    default: illegal   = 1;
                endcase
            end

            // I-type loads
            7'b0000011: begin
                case (funct3)
                    3'b000: instr_lb  = 1;
                    3'b001: instr_lh  = 1;
                    3'b010: instr_lw  = 1;
                    3'b100: instr_lbu = 1;
                    3'b101: instr_lhu = 1;
                    default: illegal  = 1;
                endcase
            end

            // S-type stores
            7'b0100011: begin
                case (funct3)
                    3'b000: instr_sb = 1;
                    3'b001: instr_sh = 1;
                    3'b010: instr_sw = 1;
                    default: illegal = 1;
                endcase
            end

            // I-type ALU
            7'b0010011: begin
                case (funct3)
                    3'b000: instr_addi  = 1;
                    3'b010: instr_slti  = 1;
                    3'b011: instr_sltiu = 1;
                    3'b100: instr_xori  = 1;
                    3'b110: instr_ori   = 1;
                    3'b111: instr_andi  = 1;
                    3'b001: instr_slli  = 1;
                    3'b101:
                        if      (funct7==7'b0000000) instr_srli = 1;
                        else if (funct7==7'b0100000) instr_srai = 1;
                        else                         illegal   = 1;
                    default: illegal = 1;
                endcase
            end

            // R-type ALU
            7'b0110011: begin
                case ({funct7,funct3})
                    {7'b0000000,3'b000}: instr_add  = 1;
                    {7'b0100000,3'b000}: instr_sub  = 1;
                    {7'b0000000,3'b001}: instr_sll  = 1;
                    {7'b0000000,3'b010}: instr_slt  = 1;
                    {7'b0000000,3'b011}: instr_sltu = 1;
                    {7'b0000000,3'b100}: instr_xor  = 1;
                    {7'b0000000,3'b101}: instr_srl  = 1;
                    {7'b0100000,3'b101}: instr_sra  = 1;
                    {7'b0000000,3'b110}: instr_or   = 1;
                    {7'b0000000,3'b111}: instr_and  = 1;
                    default:               illegal   = 1;
                endcase
            end

            // FENCE, FENCE.TSO, PAUSE
            7'b0001111: begin
                // FENCE with funct3=000, rs1=0, rd=0
                if ({funct3, rs1, rd} == {3'b000,5'd0,5'd0})           instr_fence     = 1;
                else if (instr[31:28]==4'b1000 && funct3==3'b000)     instr_fence_tso = 1; // FENCE.TSO uses fm=1000
                else if ({funct3, rs1, rd} == {3'b001,5'd0,5'd0})     instr_pause     = 1; // PAUSE (fm=0000,pred=0001,succ=0000)
                else                                                   illegal       = 1;
            end

            // SYSTEM: ECALL, EBREAK
            7'b1110011: begin
                if ({instr[31:20],funct3} == {12'd0,3'b000})          instr_ecall     = 1;
                else if ({instr[31:20],funct3} == {12'd1,3'b000})     instr_ebreak    = 1;
                else                                                   illegal       = 1;
            end

            default: illegal = 1;
        endcase
    end

endmodule

