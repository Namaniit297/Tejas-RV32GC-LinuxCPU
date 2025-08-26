module Fetch (
    input PCSrc,
    input hlt,
    input PCWrite,
    input [15:0] PC,
    input [15:0] branchTarget,
    input [15:0] wBIA,
    output [31:0] instr1,
    output [31:0] instr2,
    output [15:0] NPC
);

    parameter PC_WIDTH = 16;

    reg [PC_WIDTH-1:0] nxtPC;
    reg en = 0;
    wire [PC_WIDTH-1:0] nextPC;
    wire prediction;
    wire [15:0] predictedTarget;
    reg [15:0] target;
    reg nextPC_sel;
    wire hit;

    // Next PC generation logic
    always @(*) begin
        if (hlt) begin
            en = 0;
            nxtPC = PC;
        end else if (PCWrite) begin
            nxtPC = PC + 2;
            en = 1;
        end else begin
            nxtPC = PC;
            en = 0;
        end
    end

    // Instruction memory
    InstructionMemory im (
        .PC(PC),
        .en(en),
        .instr1(instr1),
        .instr2(instr2)
    );

    // PC multiplexer (choose between sequential or branch target)
    mux16bit mux (
        .out(NPC),
        .i0(nxtPC),
        .i1(target),
        .sel(nextPC_sel)
    );

    // Target selection based on BTB + branch resolution
    always @(branchTarget or predictedTarget or hit) begin
        if (PCSrc) begin
            target = branchTarget;
            nextPC_sel = PCSrc;
        end else begin
            target = predictedTarget;
            if (hit) begin
                nextPC_sel = prediction;
            end else begin
                nextPC_sel = 0;
            end
        end
    end

    // Branch Target Buffer
    BTB btb (
        .BTB_Target(predictedTarget),
        .PC(PC),
        .BTB_Addr(wBIA),
        .BTB_Entry(branchTarget)
    );

endmodule
