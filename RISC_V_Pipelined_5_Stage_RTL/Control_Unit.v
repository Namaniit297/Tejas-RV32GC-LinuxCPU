// ============================================================================
// Control Unit (CU) for RISC-V Pipeline
// ============================================================================
// Purpose:
//   - Generates control signals for datapath elements based on the opcode.
//   - Works in the Instruction Decode (ID) stage.
//   - Handles Load, Store, R-type, Branch, and I-type instructions.
//   - Includes stall override: when stall=1, all signals are neutralized.
//
// Features:
//   - Parameterized opcode values for readability.
//   - Safe default values for all outputs.
//   - Combinational logic (synthesizable).
//   - Easy to extend for new instruction types.
//
// Inputs:
//   opcode : [6:0] - Instruction opcode from instruction_parser
//   stall  :       - Pipeline stall signal (1=freeze control outputs)
//
// Outputs:
//   branch   : Branch signal for Branch Unit
//   memread  : Enable data memory read
//   memtoreg : Select between ALU result and memory data for register write-back
//   memwrite : Enable data memory write
//   aluSrc   : Select ALU second operand (0=register, 1=immediate)
//   regwrite : Enable register file write
//   Aluop    : [1:0] ALU operation code (passed to ALU Control)
// ============================================================================

module CU (
    input  wire [6:0] opcode,
    input  wire       stall,

    output reg        branch,
    output reg        memread,
    output reg        memtoreg,
    output reg        memwrite,
    output reg        aluSrc,
    output reg        regwrite,
    output reg  [1:0] Aluop
);

    // ------------------------------------------------------------------------
    // RISC-V Base Opcodes (RV32I / RV64I)
    // ------------------------------------------------------------------------
    localparam OPCODE_LOAD    = 7'b0000011; // I-type: LW, LH, LB, LHU, LBU
    localparam OPCODE_STORE   = 7'b0100011; // S-type: SW, SH, SB
    localparam OPCODE_RTYPE   = 7'b0110011; // R-type: ADD, SUB, AND, OR, etc.
    localparam OPCODE_BRANCH  = 7'b1100011; // B-type: BEQ, BNE, etc.
    localparam OPCODE_ITYPE   = 7'b0010011; // I-type ALU ops: ADDI, ANDI, ORI, etc.

    always @(*) begin
        // Default values (safe "NOP" state)
        aluSrc    = 1'b0;
        memtoreg  = 1'b0;
        regwrite  = 1'b0;
        memread   = 1'b0;
        memwrite  = 1'b0;
        branch    = 1'b0;
        Aluop     = 2'b00;

        if (stall) begin
            // Stall override: all signals neutralized
            aluSrc    = 1'b0;
            memtoreg  = 1'b0;
            regwrite  = 1'b0;
            memread   = 1'b0;
            memwrite  = 1'b0;
            branch    = 1'b0;
            Aluop     = 2'b00;
        end
        else begin
            case (opcode)
                // -------------------------
                // LOAD (I-type, e.g. LW)
                // -------------------------
                OPCODE_LOAD: begin
                    aluSrc    = 1'b1;  // use immediate for address calc
                    memtoreg  = 1'b1;  // data comes from memory
                    regwrite  = 1'b1;  // write to register file
                    memread   = 1'b1;  // enable memory read
                    memwrite  = 1'b0;
                    branch    = 1'b0;
                    Aluop     = 2'b00; // ALU performs ADD
                end

                // -------------------------
                // STORE (S-type, e.g. SW)
                // -------------------------
                OPCODE_STORE: begin
                    aluSrc    = 1'b1;  // use immediate for address calc
                    memtoreg  = 1'b0;  // don't care
                    regwrite  = 1'b0;  // no reg write
                    memread   = 1'b0;
                    memwrite  = 1'b1;  // enable memory write
                    branch    = 1'b0;
                    Aluop     = 2'b00; // ALU performs ADD
                end

                // -------------------------
                // R-TYPE (ADD, SUB, AND, OR, etc.)
                // -------------------------
                OPCODE_RTYPE: begin
                    aluSrc    = 1'b0;  // operand2 = register
                    memtoreg  = 1'b0;  // result from ALU
                    regwrite  = 1'b1;  // write result to register
                    memread   = 1'b0;
                    memwrite  = 1'b0;
                    branch    = 1'b0;
                    Aluop     = 2'b10; // ALUControl uses funct3/funct7
                end

                // -------------------------
                // BRANCH (BEQ, BNE, etc.)
                // -------------------------
                OPCODE_BRANCH: begin
                    aluSrc    = 1'b0;  // use registers for compare
                    memtoreg  = 1'b0;  // don't care
                    regwrite  = 1'b0;  // no reg write
                    memread   = 1'b0;
                    memwrite  = 1'b0;
                    branch    = 1'b1;  // signal branch decision
                    Aluop     = 2'b01; // ALU performs SUB for comparison
                end

                // -------------------------
                // I-TYPE (ADDI, ANDI, ORI, etc.)
                // -------------------------
                OPCODE_ITYPE: begin
                    aluSrc    = 1'b1;  // operand2 = immediate
                    memtoreg  = 1'b0;  // result from ALU
                    regwrite  = 1'b1;  // write result
                    memread   = 1'b0;
                    memwrite  = 1'b0;
                    branch    = 1'b0;
                    Aluop     = 2'b00; // ALU performs ADD/logic
                end

                // -------------------------
                // DEFAULT: treat as NOP
                // -------------------------
                default: begin
                    aluSrc    = 1'b0;
                    memtoreg  = 1'b0;
                    regwrite  = 1'b0;
                    memread   = 1'b0;
                    memwrite  = 1'b0;
                    branch    = 1'b0;
                    Aluop     = 2'b00;
                end
            endcase
        end
    end

endmodule
