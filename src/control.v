
//------------------------------------------------------------------------------
// rv32i_control_unit.v
// Combinational control unit for non-pipelined RV32I core.
//------------------------------------------------------------------------------
module rv32i_control_unit (
    // one-hot instruction flags from decoder
    input  wire instr_lui,
    input  wire instr_auipc,
    input  wire instr_jal,
    input  wire instr_jalr,
    input  wire instr_beq,
    input  wire instr_bne,
    input  wire instr_blt,
    input  wire instr_bge,
    input  wire instr_bltu,
    input  wire instr_bgeu,
    input  wire instr_lb,
    input  wire instr_lh,
    input  wire instr_lw,
    input  wire instr_lbu,
    input  wire instr_lhu,
    input  wire instr_sb,
    input  wire instr_sh,
    input  wire instr_sw,
    input  wire instr_addi,
    input  wire instr_slti,
    input  wire instr_sltiu,
    input  wire instr_xori,
    input  wire instr_ori,
    input  wire instr_andi,
    input  wire instr_slli,
    input  wire instr_srli,
    input  wire instr_srai,
    input  wire instr_add,
    input  wire instr_sub,
    input  wire instr_sll,
    input  wire instr_slt,
    input  wire instr_sltu,
    input  wire instr_xor,
    input  wire instr_srl,
    input  wire instr_sra,
    input  wire instr_or,
    input  wire instr_and,
    input  wire instr_fence,
    input  wire instr_fence_tso,
    input  wire instr_pause,
    input  wire instr_ecall,
    input  wire instr_ebreak,
    input  wire instr_csrrw,
    input  wire instr_csrrs,
    input  wire instr_csrrc,
    input  wire instr_csrrwi,
    input  wire instr_csrrsi,
    input  wire instr_csrrci,

    // outputs to datapath
    output wire RegWrite,
    output wire MemRead,
    output wire MemWrite,
    output wire MemToReg,
    output wire ALUSrc,
    output wire Branch,
    output wire Jump,
    output wire LUI_AUIPC,
    output wire [3:0] ALUOp,
    output wire Fence,
    output wire Ecall,
    output wire Ebreak,
    output wire Pause,
    output wire FenceTSO,
    output wire CSR
);

    // write-back occurs for:
    //   R-type, I-type ALU, loads, JAL/JALR, LUI/AUIPC, CSR writes
    assign RegWrite =
           instr_add  | instr_sub  | instr_sll  | instr_slt  | instr_sltu
        | instr_xor  | instr_srl  | instr_sra  | instr_or   | instr_and
        | instr_addi | instr_slti | instr_sltiu| instr_xori| instr_ori
        | instr_andi| instr_slli | instr_srli | instr_srai
        | instr_lb   | instr_lh   | instr_lw   | instr_lbu  | instr_lhu
        | instr_jal  | instr_jalr | instr_lui  | instr_auipc
        | instr_csrrw | instr_csrrs | instr_csrrc
        | instr_csrrwi| instr_csrrsi| instr_csrrci;

    // memory read for loads only
    assign MemRead  = instr_lb | instr_lh | instr_lw | instr_lbu | instr_lhu;

    // memory write for stores only
    assign MemWrite = instr_sb | instr_sh | instr_sw;

    // write-back data comes from memory only on loads
    assign MemToReg = MemRead;

    // ALU second operand is immediate for:
    //   I-type ALU, loads, stores, JALR, AUIPC
    assign ALUSrc =
           instr_addi | instr_slti | instr_sltiu | instr_xori
        | instr_ori   | instr_andi | instr_slli   | instr_srli | instr_srai
        | MemRead     | MemWrite    | instr_jalr  | instr_auipc;

    // any branch instruction
    assign Branch = instr_beq  | instr_bne
                  | instr_blt  | instr_bge
                  | instr_bltu | instr_bgeu;

    // any jump
    assign Jump = instr_jal | instr_jalr;

    // select U-type path (in EX stage you’ll use imm_U)
    assign LUI_AUIPC = instr_lui | instr_auipc;

    // ALU operation code
    // (must match your ALU’s case encoding)
    // priority: use R-type/ I-type ALU functions
    wire isR = instr_add|instr_sub|instr_sll|instr_slt|instr_sltu
            |instr_xor|instr_srl|instr_sra|instr_or|instr_and;
    wire isI = instr_addi|instr_slti|instr_sltiu|instr_xori
            |instr_ori|instr_andi|instr_slli|instr_srli|instr_srai;
    wire isCMP = instr_slt|instr_sltu|instr_slti|instr_sltiu;
    wire isSHIFT = instr_sll|instr_srl|instr_sra
                |instr_slli|instr_srli|instr_srai;

    assign ALUOp = 
           (instr_add | instr_addi) ? 4'h2 :  // ADD
           (instr_sub)               ? 4'h6 :  // SUB
           (instr_and | instr_andi)  ? 4'h4 :  // AND
           (instr_or  | instr_ori)   ? 4'h5 :  // OR
           (instr_xor | instr_xori)  ? 4'h1 :  // XOR
           (instr_sll | instr_slli)  ? 4'h0 :  // SLL
           (instr_srl | instr_srli)  ? 4'h3 :  // SRL
           (instr_sra | instr_srai)  ? 4'hB :  // SRA
           (instr_slt | instr_slti)  ? 4'h7 :  // SLT
           (instr_sltu| instr_sltiu) ? 4'h8 :  // SLTU
           4'h2;                              // default ADD

    // pass-through special signals
    assign Fence     = instr_fence;
    assign FenceTSO  = instr_fence_tso;
    assign Pause     = instr_pause;
    assign Ecall     = instr_ecall;
    assign Ebreak    = instr_ebreak;
    assign CSR       = instr_csrrw|instr_csrrs|instr_csrrc
                     |instr_csrrwi|instr_csrrsi|instr_csrrci;

endmodule
