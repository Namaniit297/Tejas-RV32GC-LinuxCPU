// Top-level superscalar processor (cleaned, self-contained, simplified stubs for some blocks)
module SuperScalarProcessor (
    input clk,
    input rst
);

    // Parameters
    parameter PC_WIDTH    = 16;
    parameter DATA_WIDTH  = 16;
    parameter INSTR_WIDTH = 32;
    parameter MEM_SIZE    = 1024; // words

    // --- PC and control signals ---
    reg  [PC_WIDTH-1:0] PC;
    wire [PC_WIDTH-1:0] NPC;
    wire [PC_WIDTH-1:0] PCOut;
    reg  PCWrite, IFIDWrite, dispatchWrite;
    reg  flush;             // pipeline flush on mispredict/commit
    reg  IFFlush;

    // --- Instruction memory / fetch wires ---
    wire [INSTR_WIDTH-1:0] instr1, instr2;         // fetched
    wire [INSTR_WIDTH-1:0] instr1Out, instr2Out;   // after IF/ID
    wire [PC_WIDTH-1:0]    PCplus2, PCplus2Out;
    wire                   nextPC_sel_f, nextPC_sel_IFID;
    wire                   PCSrc;                  // branch resolution signal (from branch unit)
    wire [PC_WIDTH-1:0]    branchTarget;
    reg  [PC_WIDTH-1:0]    branchTarget_reg;

    // Simple reset / PC update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= {PC_WIDTH{1'b0}};
        end else if (PCWrite) begin
            PC <= NPC;
        end
    end

    // ----------------------------------------
    // PC register instantiation (simple)
    // PCReg(PCOut, PCIn, clk, rst, PCWrite)
    PCReg pc_reg (
        .PCOut(PCOut),
        .PCIn(PC),
        .clk(clk),
        .rst(rst),
        .PCWrite(PCWrite)
    );

    // Instruction Memory (simple behavioral memory)
    // Re-using your InstructionMemory module interface:
    // InstructionMemory(imPC, en, instr1, instr2)
    InstructionMemory imem (
        .PC(PCOut),
        .en(1'b1),
        .instr1(instr1),
        .instr2(instr2)
    );

    // Simple next-PC generation: choose sequential or branchTarget (will be controlled later)
    assign PCplus2 = PCOut + 2;   // two words per 32-bit instruction pair model

    // Simple Fetch -> IF/ID register
    // IFIDReg(PCplus4Out, instrOut1, instrOut2, nextPC_selOut, PCplus4In, instrIn1, instrIn2, clk, IFIDWrite, IFFlush, nextPC_selIn)
    IFIDReg if_id (
        .PCplus4Out(PCplus2Out),
        .instrOut1(instr1Out),
        .instrOut2(instr2Out),
        .nextPC_selOut(nextPC_sel_IFID),
        .PCplus4In(PCplus2),
        .instrIn1(instr1),
        .instrIn2(instr2),
        .clk(clk),
        .IFIDWrite(IFIDWrite),
        .IFFlush(IFFlush),
        .nextPC_selIn(nextPC_sel_f)
    );

    // For this simplified top, nextPC_sel_f chooses between sequential PCplus2 and branchTarget_reg
    // We'll compute NPC based on branch resolution (PCSrc) and predictor results in a simplified way:
    wire predicted_taken = 1'b0; // replace by predictor when integrated
    assign NPC = (PCSrc ? branchTarget_reg : PCplus2);

    // -------------------------------------------------
    // Decode stage
    // The decode module defined earlier has interface:
    // decode(instr1, instr2, rs1, rt1, rd1, rs2, rt2, rd2, imm1, imm2, ctrl1, ctrl2, func1, func2, spec1, spec2)
    wire [4:0] rs1, rt1, rd1, rs2, rt2, rd2;
    wire [5:0] ctrl1, ctrl2;
    wire [2:0] func1, func2;
    wire [15:0] imm1, imm2;
    wire spec1, spec2;

    decode decode_unit (
        .instr1(instr1Out),
        .instr2(instr2Out),
        .rs1(rs1), .rt1(rt1), .rd1(rd1),
        .rs2(rs2), .rt2(rt2), .rd2(rd2),
        .ctrl1(ctrl1), .ctrl2(ctrl2),
        .func1(func1), .func2(func2),
        .immediate1(imm1), .immediate2(imm2),
        .spec1(), .spec2()    // decode already sets speculative bits internally; we don't use them here
    );

    // -------------------------------------------------
    // Register file and source read
    // We will use simplified RegisterFile with the signature used earlier.
    // Note: the earlier RegisterFile expects many ports; we'll use a simplified minimal wrapper here.

    // Minimal Register File (simple behavioral storage with tags)
    reg [DATA_WIDTH-1:0] ARF [0:31];
    reg [4:0]            destReg1, destReg2;
    reg [DATA_WIDTH-1:0] regWData1, regWData2;
    reg [1:0]            regWrite;   // two write enables

    // read ports
    wire [DATA_WIDTH-1:0] rf_read1 = ARF[rs1];
    wire [DATA_WIDTH-1:0] rf_read2 = ARF[rt1];
    wire [DATA_WIDTH-1:0] rf_read3 = ARF[rs2];
    wire [DATA_WIDTH-1:0] rf_read4 = ARF[rt2];

    // simple synchronous writes
    always @(posedge clk) begin
        if (regWrite[0]) ARF[destReg1] <= regWData1;
        if (regWrite[1]) ARF[destReg2] <= regWData2;
    end

    // SourceRead stubs (forwarding) - just read RF for now
    wire [15:0] dataRs1 = rf_read1;
    wire [15:0] dataRt1 = rf_read2;
    wire [15:0] dataRs2 = rf_read3;
    wire [15:0] dataRt2 = rf_read4;

    // -------------------------------------------------
    // Dispatch (very simplified)
    // We'll implement a tiny dual-entry dispatch queue that passes operands to RS stubs.
    // In your full design, replace this with the DispatchBuffer module implementation.

    // Dispatch outputs to reservation stations (two-issue)
    reg  [3:0] rstag1, rstag2, rstag3, rstag4;
    reg  [15:0] d_dataRs1, d_dataRt1, d_dataRs2, d_dataRt2;
    reg  [5:0]  d_ctrl1, d_ctrl2;
    reg  [15:0] d_imm1, d_imm2;
    reg         dispatch_valid;

    always @(posedge clk) begin
        if (flush) begin
            dispatch_valid <= 1'b0;
        end else if (dispatchWrite) begin
            // capture decoded values
            d_dataRs1 <= dataRs1;
            d_dataRt1 <= dataRt1;
            d_dataRs2 <= dataRs2;
            d_dataRt2 <= dataRt2;
            d_ctrl1   <= ctrl1;
            d_ctrl2   <= ctrl2;
            d_imm1    <= imm1;
            d_imm2    <= imm2;
            // destination register selection (use rd for R-type, rt for I-type)
            destReg1 <= (ctrl1[3] ? rd1 : rt1);
            destReg2 <= (ctrl2[3] ? rd2 : rt2);
            dispatch_valid <= 1'b1;
        end
    end

    // -------------------------------------------------
    // Reservation Station stubs + simple issue logic
    // We'll have simple RS queues for integer, multiply and load/store and branch.
    // When an FU is free and RS entry ready, issue to FU and broadcast on CDB.

    // Simple busy flags for functional units
    reg FU_int_busy, FU_mul_busy, FU_ls_busy, FU_br_busy;

    // Simple ready-valid interfaces to FUs
    reg [15:0] int_a, int_b;
    reg [1:0]  int_ctrl;
    reg [3:0]  int_destTag;
    reg        int_issued;

    reg [7:0] mul_a, mul_b;
    reg [3:0] mul_destTag;
    reg       mul_issued;

    reg [15:0] ls_addr, ls_storeData;
    reg        ls_load; // 1 => load, 0 => store
    reg [3:0]  ls_destTag;
    reg        ls_issued;

    reg [15:0] br_rs, br_rt;
    reg [15:0] br_imm;
    reg [3:0]  br_destTag;
    reg        br_issued;

    // CDB: wide enough to hold two slots (lower and upper)
    wire [41:0] CDBData;
    reg  [41:0] CDB_reg;
    assign CDBData = CDB_reg;

    // Simple issue: when dispatch_valid, route first instruction to integer except when it's multiply/ls/branch
    always @(posedge clk) begin
        // default: clear issued flags
        int_issued <= 1'b0;
        mul_issued <= 1'b0;
        ls_issued  <= 1'b0;
        br_issued  <= 1'b0;

        if (dispatch_valid) begin
            // Determine type using ctrl[3..0] fields heuristically:
            // ctrl[3] == R-type, ctrl[2] == branch, ctrl[4] == load, ctrl[5] == store (as in ControlUnit)
            // Route first slot
            if (d_ctrl1[4] || d_ctrl1[5]) begin
                // load/store -> LS FU
                ls_addr <= d_dataRs1 + d_imm1;
                ls_storeData <= d_dataRt1;
                ls_load <= d_ctrl1[4];
                ls_destTag <= 4'd1; // small tag assignment; in full design use ROB tag
                ls_issued <= 1'b1;
            end else if (d_ctrl1[3]) begin
                // R-type -> integer or multiply depending on func bit (func1[2] == 1 => mul)
                if (func1[2] == 1'b1) begin
                    mul_a <= d_dataRs1[7:0];
                    mul_b <= d_dataRt1[7:0];
                    mul_destTag <= 4'd2;
                    mul_issued <= 1'b1;
                end else begin
                    int_a <= d_dataRs1;
                    int_b <= d_dataRt1;
                    int_ctrl <= d_ctrl1[1:0]; // simplified mapping
                    int_destTag <= 4'd3;
                    int_issued <= 1'b1;
                end
            end else if (d_ctrl1[2]) begin
                // branch
                br_rs <= d_dataRs1;
                br_rt <= d_dataRt1;
                br_imm <= d_imm1;
                br_destTag <= 4'd4;
                br_issued <= 1'b1;
            end else begin
                // default -> integer
                int_a <= d_dataRs1;
                int_b <= d_dataRt1;
                int_ctrl <= d_ctrl1[1:0];
                int_destTag <= 4'd3;
                int_issued <= 1'b1;
            end

            // route second slot similarly (d_ctrl2)
            if (d_ctrl2[4] || d_ctrl2[5]) begin
                ls_addr <= d_dataRs2 + d_imm2;
                ls_storeData <= d_dataRt2;
                ls_load <= d_ctrl2[4];
                ls_destTag <= 4'd5;
                ls_issued <= 1'b1;
            end else if (d_ctrl2[3]) begin
                if (func2[2] == 1'b1) begin
                    mul_a <= d_dataRs2[7:0];
                    mul_b <= d_dataRt2[7:0];
                    mul_destTag <= 4'd6;
                    mul_issued <= 1'b1;
                end else begin
                    int_a <= d_dataRs2;
                    int_b <= d_dataRt2;
                    int_ctrl <= d_ctrl2[1:0];
                    int_destTag <= 4'd7;
                    int_issued <= 1'b1;
                end
            end else if (d_ctrl2[2]) begin
                br_rs <= d_dataRs2;
                br_rt <= d_dataRt2;
                br_imm <= d_imm2;
                br_destTag <= 4'd8;
                br_issued <= 1'b1;
            end else begin
                int_a <= d_dataRs2;
                int_b <= d_dataRt2;
                int_ctrl <= d_ctrl2[1:0];
                int_destTag <= 4'd7;
                int_issued <= 1'b1;
            end

            dispatch_valid <= 1'b0;
        end
    end

    // -------------------------------------------------
    // Functional units (simple behavioral instantiations)
    // Integer ALU (combinational)
    wire [20:0] int_CDB;
    IntALU int_alu (
        .a(int_a),
        .b(int_b),
        .ctrl(int_ctrl),
        .destTag(int_destTag),
        .issued(int_issued),
        .CDBout(int_CDB)
    );

    // Multiply unit (uses the multiply module you provided earlier)
    wire [20:0] mul_CDB;
    multiply mul_unit (
        .a(mul_a),
        .b(mul_b),
        .issued(mul_issued),
        .destTag(mul_destTag),
        .CDBout(mul_CDB)
    );

    // Load/Store address generation unit
    wire [15:0] ls_addr_out;
    LoadStore ls_unit (
        .a(ls_addr),
        .b(16'b0),
        .out(ls_addr_out)
    );

    // Branch unit - simple comparator
    reg branch_taken;
    reg [PC_WIDTH-1:0] branch_target_local;
    always @(*) begin
        // simple equality branch (BEQ): compare br_rs and br_rt
        if (br_issued && (br_rs == br_rt)) begin
            branch_taken = 1'b1;
            branch_target_local = PCOut + br_imm; // simple target calculation
        end else begin
            branch_taken = 1'b0;
            branch_target_local = PCOut;
        end
    end

    // If branch issued and taken, register branchTarget_reg and set PCSrc
    assign PCSrc = branch_taken;
    always @(posedge clk) begin
        if (branch_taken) branchTarget_reg <= branch_target_local;
    end

    // -------------------------------------------------
    // Simple CDB construction (we put one of the FU results onto CDB each cycle with priority)
    // CDBData is 42 bits: [41] valid upper, [40:37] tag upper, [36:21] data upper,
    //                         [20] valid lower, [19:16] tag lower, [15:0] data lower
    always @(posedge clk) begin
        // default clear
        CDB_reg <= 42'b0;

        // Priority: int -> mul -> ls -> branch (for simplicity)
        if (int_issued) begin
            // place integer ALU result in lower slot
            CDB_reg[20]    <= int_CDB[20];
            CDB_reg[19:16] <= int_CDB[19:16];
            CDB_reg[15:0]  <= int_CDB[15:0];
        end

        if (mul_issued) begin
            // place mul in upper slot
            CDB_reg[41]    <= mul_CDB[20];
            CDB_reg[40:37] <= mul_CDB[19:16];
            CDB_reg[36:21] <= mul_CDB[15:0];
        end

        // For load/store we will broadcast the load result after an assumed memory latency
        // For the simplified model we don't implement the full store buffer here
    end

    // -------------------------------------------------
    // Simple ROB model (very small, to generate writeback info)
    // We'll commit results immediately from CDB to register file for this simplified top.
    // Build wbData/wbType signals expected by original style
    reg [20:0] wbData1, wbData2;
    reg [1:0]  wbType1, wbType2; // 00 -> reg write, 01 -> mem write
    always @(posedge clk) begin
        // default
        wbData1 <= 21'b0;
        wbData2 <= 21'b0;
        wbType1 <= 2'b00;
        wbType2 <= 2'b00;

        // If lower slot valid -> commit to reg file
        if (CDB_reg[20]) begin
            // pack as {valid, tag[3:0], data[15:0]}
            wbData1 <= {1'b1, CDB_reg[19:16], CDB_reg[15:0]};
            wbType1 <= 2'b00; // writeback to register
            // write into ARF directly (very simplified)
            // find destination register from tag mapping (we used destTag as small numbers); map to reg indices
            destReg1 <= {1'b0, CDB_reg[19:16][3:0]};     // crude mapping for demo only
            regWData1 <= CDB_reg[15:0];
            regWrite[0] <= 1'b1;
        end else begin
            regWrite[0] <= 1'b0;
        end

        if (CDB_reg[41]) begin
            wbData2 <= {1'b1, CDB_reg[40:37], CDB_reg[36:21]};
            wbType2 <= 2'b00;
            destReg2 <= {1'b0, CDB_reg[40:37][3:0]};
            regWData2 <= CDB_reg[36:21];
            regWrite[1] <= 1'b1;
        end else begin
            regWrite[1] <= 1'b0;
        end
    end

    // -------------------------------------------------
    // Simple stall / control logic
    // If both write ports are active, it's fine. If ARF writes collide, stall (not implemented).
    always @(*) begin
        // default: allow progress
        IFIDWrite     = 1'b1;
        PCWrite       = 1'b1;
        dispatchWrite = 1'b1;
    end

    // Simple debug printing on CDB changes (simulation)
    always @(CDB_reg) begin
        $display("%0t : CDB lower data=%0d tag=%0d upper data=%0d tag=%0d",
                 $time,
                 CDB_reg[15:0], CDB_reg[19:16],
                 CDB_reg[36:21], CDB_reg[40:37]);
    end

endmodule
