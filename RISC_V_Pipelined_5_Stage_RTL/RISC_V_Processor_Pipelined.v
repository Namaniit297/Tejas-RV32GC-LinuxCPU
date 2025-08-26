// ============================================================================
// Top-level Pipelined RISC-V Processor (RV64 default)
// ============================================================================
// - Professional, parameterized, FPGA-friendly top module that wires together
//   the IF, ID, EX, MEM and WB stages with forwarding, hazard detection and
//   pipeline flush support.
// - Assumes the presence of submodules implemented in the repo with the
//   interfaces used here (see comments).
// ============================================================================

module RISC_V_Processor #(
    parameter DATA_WIDTH  = 64,    // 64 for RV64, set 32 for RV32
    parameter ADDR_WIDTH  = 64,    // PC and addresses width
    parameter INSTR_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    stall,       // external stall (e.g., from HDU)
    input  wire                    flush,       // external flush (e.g., pipeline_flush)
    // optional memory preload/debug ports (8 words) — pass to data_memory as debug
    input  wire [DATA_WIDTH-1:0]   element1,
    input  wire [DATA_WIDTH-1:0]   element2,
    input  wire [DATA_WIDTH-1:0]   element3,
    input  wire [DATA_WIDTH-1:0]   element4,
    input  wire [DATA_WIDTH-1:0]   element5,
    input  wire [DATA_WIDTH-1:0]   element6,
    input  wire [DATA_WIDTH-1:0]   element7,
    input  wire [DATA_WIDTH-1:0]   element8
);

    // ------------------------------------------------------------------
    // IF stage signals
    // ------------------------------------------------------------------
    wire [ADDR_WIDTH-1:0] pc_in;
    wire [ADDR_WIDTH-1:0] pc_out;
    wire [INSTR_WIDTH-1:0] instruction;

    // sequential PC + 4
    wire [ADDR_WIDTH-1:0] pc_plus4;

    // ------------------------------------------------------------------
    // ID stage signals (IF/ID outputs)
    // ------------------------------------------------------------------
    wire [INSTR_WIDTH-1:0] ifid_inst;
    wire [ADDR_WIDTH-1:0]  ifid_pc;

    // parsed fields
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [2:0]  funct3;
    wire [6:0]  funct7;

    // control signals from CU
    wire branch;
    wire memread;
    wire memtoreg;
    wire memwrite;
    wire aluSrc;
    wire regwrite;
    wire [1:0] Aluop;

    // immediate (sign-extended)
    wire [DATA_WIDTH-1:0] imm_data;

    // register-file outputs
    wire [DATA_WIDTH-1:0] regfile_rdata1;
    wire [DATA_WIDTH-1:0] regfile_rdata2;

    // debug outputs (optional)
    wire [DATA_WIDTH-1:0] r8, r19, r20, r21, r22;

    // ------------------------------------------------------------------
    // ID/EX stage signals
    // ------------------------------------------------------------------
    // Data-path forwarded into EX stage
    wire [DATA_WIDTH-1:0] idex_pc;
    wire [DATA_WIDTH-1:0] idex_readdata1;
    wire [DATA_WIDTH-1:0] idex_readdata2;
    wire [DATA_WIDTH-1:0] idex_imm;
    wire [4:0] idex_rs1, idex_rs2, idex_rd;
    wire [3:0] idex_funct4; // we used funct4 representation earlier (bit30 + funct3)

    // id/ex control signals
    wire idex_branch, idex_memread, idex_memtoreg, idex_memwrite, idex_regwrite, idex_alusrc;
    wire [1:0] idex_aluop;

    // ------------------------------------------------------------------
    // EX stage signals
    // ------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] ex_alu_in_a;
    wire [DATA_WIDTH-1:0] ex_alu_in_b;
    wire [DATA_WIDTH-1:0] ex_alu_result;
    wire ex_zero_flag;
    wire [3:0] ex_alu_operation;

    // forwarding signals
    wire [1:0] forwardA, forwardB;

    // outputs from forwarding muxes
    wire [DATA_WIDTH-1:0] forward_mux_out_a;
    wire [DATA_WIDTH-1:0] forward_mux_out_b;

    // adder for branch target
    wire [DATA_WIDTH-1:0] branch_target;

    // EX/MEM outputs
    wire [DATA_WIDTH-1:0] exmem_alu_result;
    wire [DATA_WIDTH-1:0] exmem_write_data;
    wire [DATA_WIDTH-1:0] exmem_branch_target;
    wire [4:0] exmem_rd;
    wire exmem_branch, exmem_memread, exmem_memtoreg, exmem_memwrite, exmem_regwrite;

    // ------------------------------------------------------------------
    // MEM stage signals
    // ------------------------------------------------------------------
    wire [DATA_WIDTH-1:0] mem_read_data;

    // MEM/WB outputs
    wire [DATA_WIDTH-1:0] memwb_read_data;
    wire [DATA_WIDTH-1:0] memwb_alu_result;
    wire [4:0] memwb_rd;
    wire memwb_memtoreg;
    wire memwb_regwrite;

    // WB stage writeback data
    wire [DATA_WIDTH-1:0] writeback_data;

    // ------------------------------------------------------------------
    // Control and hazard signals
    // ------------------------------------------------------------------
    wire pipeline_flush_sig;
    wire hdu_stall; // hazard detection unit stall output

    // Combine external stall with internal HDU stall
    wire effective_stall = stall | hdu_stall;

    // Branch decision: EX branch unit driving this (ex branch result)
    // We'll use 'branch_taken' as final branch decision before updating PC
    wire branch_taken;

    // ------------------------------------------------------------------
    // Program Counter
    // ------------------------------------------------------------------
    // program_counter: (PC_in, clk, reset, stall, PC_out)
    program_counter #(.PC_WIDTH(ADDR_WIDTH)) pc_inst (
        .clk   (clk),
        .reset (reset),
        .stall (effective_stall),
        .PC_in (pc_in),
        .PC_out(pc_out)
    );

    // instruction memory read
    // instruction_memory: (inst_address, instruction)
    instruction_memory imem (
        .inst_address(pc_out),
        .instruction(instruction)
    );

    // PC + 4 adder
    adder #(.WIDTH(DATA_WIDTH), .PIPELINED(0)) pc_adder (
        .clk(), // not used for combinational version
        .p(pc_out),
        .q({{(DATA_WIDTH-32){1'b0}},32'd4}), // 4 as 64-bit
        .sum(pc_plus4),
        .carry_out(), .overflow()
    );

    // ------------------------------------------------------------------
    // IF/ID register
    // ------------------------------------------------------------------
    // IFID signature we used: IFID(clk, reset, flush, IFIDWrite, inst_in, pc_in, inst_out, pc_out)
    IFID #(.INSTR_WIDTH(INSTR_WIDTH), .PC_WIDTH(ADDR_WIDTH)) ifid_inst (
        .clk       (clk),
        .reset     (reset),
        .flush     (pipeline_flush_sig | flush),
        .IFIDWrite (!effective_stall), // write when not stalled
        .inst_in   (instruction),
        .pc_in     (pc_out),
        .inst_out  (ifid_inst),
        .pc_out    (ifid_pc)
    );

    // ------------------------------------------------------------------
    // Instruction Parser + Control + Immediate + Register File
    // ------------------------------------------------------------------
    instruction_parser parser_inst (
        .instruction(ifid_inst),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7)
    );

    // Control Unit (combinational)
    CU cu_inst (
        .opcode(opcode),
        .stall(effective_stall),
        .branch(branch),
        .memread(memread),
        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .aluSrc(aluSrc),
        .regwrite(regwrite),
        .Aluop(Aluop)
    );

    // Immediate extractor (supports I/S/B/U/J types)
    imm_extractor imm_inst (
        .instruction(ifid_inst),
        .imm_data(imm_data)
    );

    // Register file: (clk, reset, rs1, rs2, rd, writedata, reg_write, readdata1, readdata2, r8..)
    register_file #(.WIDTH(DATA_WIDTH)) regfile_inst (
        .clk(clk),
        .reset(reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(memwb_rd),               // write-back destination
        .writedata(writeback_data),  // write-back data
        .reg_write(memwb_regwrite),  // write enable from MEMWB
        .readdata1(regfile_rdata1),
        .readdata2(regfile_rdata2),
        .r8(r8), .r19(r19), .r20(r20), .r21(r21), .r22(r22)
    );

    // ------------------------------------------------------------------
    // Hazard Detection & Pipeline Flush logic
    // (hazard_detection_unit and pipeline_flush assumed implemented)
    // ------------------------------------------------------------------
    hazard_detection_unit hdu_inst (
        .Memread(idex_memread),   // check if ID/EX is a load
        .inst(ifid_inst),         // instruction in IFID
        .Rd(idex_rd),             // destination reg in ID/EX
        .stall(hdu_stall)
    );

    // pipeline_flush: a small unit that asserts flush when branch_taken
    // You can replace this block with your pipeline flush logic module if available.
    // Here, pipeline_flush_sig is asserted when an EX branch is taken.
    // pipeline_flush(.branch(branch_final & BRANCH), .flush(...)) in original — simplified:
    assign pipeline_flush_sig = exmem_branch & exmem_branch; // placeholder: exmem branch decision already resolved

    // ------------------------------------------------------------------
    // ID/EX Register
    // id_ex port list follows the id_ex we defined previously:
    // (clk, reset, flush, enable, pc_in, readdata1_in, readdata2_in,
    //  imm_data_in, rs1_in, rs2_in, rd_in, funct4_in,
    //  branch_in, memread_in, memtoreg_in, memwrite_in, alusrc_in, regwrite_in, aluop_in,
    //  outputs ... )
    // ------------------------------------------------------------------

    // Build 4-bit funct4 input: bit30 and funct3[2:0]
    wire [3:0] funct4_in = {ifid_inst[30], ifid_inst[14:12]};

    id_ex #(.DATA_WIDTH(DATA_WIDTH)) idex_inst (
        .clk(clk),
        .reset(reset),
        .flush(pipeline_flush_sig | flush),
        .enable(!effective_stall),
        // data
        .pc_in(ifid_pc),
        .readdata1_in(regfile_rdata1),
        .readdata2_in(regfile_rdata2),
        .imm_data_in(imm_data),
        .rs1_in(rs1),
        .rs2_in(rs2),
        .rd_in(rd),
        .funct4_in(funct4_in),
        // control
        .branch_in(branch),
        .memread_in(memread),
        .memtoreg_in(memtoreg),
        .memwrite_in(memwrite),
        .alusrc_in(aluSrc),
        .regwrite_in(regwrite),
        .aluop_in(Aluop),

        // outputs
        .pc_out(idex_pc),
        .readdata1_out(idex_readdata1),
        .readdata2_out(idex_readdata2),
        .imm_data_out(idex_imm),
        .rs1_out(idex_rs1),
        .rs2_out(idex_rs2),
        .rd_out(idex_rd),
        .funct4_out(idex_funct4),
        .branch_out(idex_branch),
        .memread_out(idex_memread),
        .memtoreg_out(idex_memtoreg),
        .memwrite_out(idex_memwrite),
        .alusrc_out(idex_alusrc),
        .regwrite_out(idex_regwrite),
        .aluop_out(idex_aluop)
    );

    // ------------------------------------------------------------------
    // EX stage
    // - Forwarding muxes choose correct sources for ALU operands
    // ------------------------------------------------------------------

    // Forwarding unit decides forwarding control signals using EX/MEM and MEM/WB destinations
    forwarding_unit fwd_inst (
        .RS_1(idex_rs1),
        .RS_2(idex_rs2),
        .rdMem(exmem_rd),
        .rdWb(memwb_rd),
        .regWrite_Mem(exmem_regwrite),
        .regWrite_Wb(memwb_regwrite),
        .Forward_A(forwardA),
        .Forward_B(forwardB)
    );

    // 3:1 mux for ALU input A: (ID/EX.readdata1, EX/MEM.ALU_result, MEM/WB.writeback)
    ThreebyOneMux mux_forward_a (
        .a(idex_readdata1),
        .b(exmem_alu_result),
        .c(memwb_regwrite ? writeback_data : memwb_alu_result), // safe fallback
        .sel(forwardA),
        .out(forward_mux_out_a)
    );

    // 3:1 mux for ALU input B
    ThreebyOneMux mux_forward_b (
        .a(idex_readdata2),
        .b(exmem_alu_result),
        .c(memwb_regwrite ? writeback_data : memwb_alu_result),
        .sel(forwardB),
        .out(forward_mux_out_b)
    );

    // ALU second operand selection (immediate vs register)
    twox1Mux alu_src_mux (
        .A(forward_mux_out_b),
        .B(idex_imm),
        .SEL(idex_alusrc),
        .Y(ex_alu_in_b)
    );

    // ALU first operand is forward_mux_out_a
    assign ex_alu_in_a = forward_mux_out_a;

    // ALU Control: generate ALU operation code from ALUop and funct fields
    // Note: our alu_control expects AluOp (2), funct7 (or funct4). We pass idex_funct4 here.
    // Our alu_control signature was: (AluOp, funct7, funct3) or (AluOp, funct4) depending on earlier design.
    // We'll pass idex_funct4 as funct field (4-bit: bit30 + funct3)
    alu_control alu_ctrl (
        .AluOp(idex_aluop),
        .funct7({3'b0, idex_funct4}), // expand to 7 bits if your implementation expects funct7
        .funct3(idex_funct4[2:0]),
        .alu_control(ex_alu_operation)
    );

    // ALU
    Alu64 alu_inst (
        .a(ex_alu_in_a),
        .b(ex_alu_in_b),
        .ALuop(ex_alu_operation),
        .Result(ex_alu_result),
        .zero(ex_zero_flag)
    );

    // Branch unit (evaluates branch condition)
    branching_unit branch_unit_inst (
        .funct3(idex_funct4[2:0]),
        .readData1(forward_mux_out_a),
        .readData2(ex_alu_in_b), // comparison against second operand
        .branch_taken(branch_taken)
    );

    // Branch target adder: pc + (imm << 1) or imm depending on extractor style
    adder #(.WIDTH(DATA_WIDTH), .PIPELINED(0)) branch_target_adder (
        .clk(),
        .p(idex_pc),
        .q({{(DATA_WIDTH-32){1'b0}}, 32'd0} + (idex_imm << 1)), // using imm<<1 for B-type as earlier
        .sum(branch_target),
        .carry_out(), .overflow()
    );

    // ------------------------------------------------------------------
    // EX/MEM Register
    // ------------------------------------------------------------------
    EXMEM #(.WIDTH(DATA_WIDTH)) exmem_inst (
        .clk(clk),
        .reset(reset),
        .flush(pipeline_flush_sig | flush),
        .ALU_result_in(ex_alu_result),
        .write_data_in(forward_mux_out_b),
        .branch_target_in(branch_target),
        .rd_in(idex_rd),
        .branch_in(idex_branch & branch_taken), // send actual taken
        .memread_in(idex_memread),
        .memtoreg_in(idex_memtoreg),
        .memwrite_in(idex_memwrite),
        .regwrite_in(idex_regwrite),

        .ALU_result_out(exmem_alu_result),
        .write_data_out(exmem_write_data),
        .branch_target_out(exmem_branch_target),
        .rd_out(exmem_rd),
        .branch_out(exmem_branch),
        .memread_out(exmem_memread),
        .memtoreg_out(exmem_memtoreg),
        .memwrite_out(exmem_memwrite),
        .regwrite_out(exmem_regwrite)
    );

    // ------------------------------------------------------------------
    // MEM stage: Data memory
    // ------------------------------------------------------------------
    data_memory #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(6), .MEM_SIZE(64)) datamem_inst (
        .clk(clk),
        .memorywrite(exmem_memwrite),
        .memoryread(exmem_memread),
        .write_data(exmem_write_data),
        .address(exmem_alu_result[ADDR_WIDTH-1:0]), // low bits as byte address
        .read_data(mem_read_data),
        .debug_word0(element1),
        .debug_word1(element2),
        .debug_word2(element3),
        .debug_word3(element4),
        .debug_word4(element5),
        .debug_word5(element6),
        .debug_word6(element7),
        .debug_word7(element8)
    );

    // ------------------------------------------------------------------
    // MEM/WB register
    // ------------------------------------------------------------------
    MEMWB memwb_inst (
        .clk(clk),
        .reset(reset),
        .flush(pipeline_flush_sig | flush),
        .read_data_in(mem_read_data),
        .result_alu_in(exmem_alu_result),
        .Rd_in(exmem_rd),
        .memtoreg_in(exmem_memtoreg),
        .regwrite_in(exmem_regwrite),

        .readdata(memwb_read_data),
        .result_alu_out(memwb_alu_result),
        .rd(memwb_rd),
        .Memtoreg(memwb_memtoreg),
        .Regwrite(memwb_regwrite)
    );

    // ------------------------------------------------------------------
    // Write Back (select memory or alu result)
    // ------------------------------------------------------------------
    // mux: if memtoreg then use mem read data else ALU result
    twox1Mux wb_mux (
        .A(memwb_alu_result),
        .B(memwb_read_data),
        .SEL(memwb_memtoreg),
        .Y(writeback_data)
    );

    // ------------------------------------------------------------------
    // Connect writeback to register file done earlier via regfile_inst wiring
    // ------------------------------------------------------------------

    // ------------------------------------------------------------------
    // Branch PC selection: the final next PC (pc_in)
    // - choose between pc_plus4 and branch_target when branch is taken
    // - NOTE: branch decision is often resolved at EX stage; this chooses EX/MEM branch
    //   or idex branch depending on your pipeline design. Here we use exmem_branch (resolved)
    // ------------------------------------------------------------------
    twox1Mux pc_mux (
        .A(pc_plus4),
        .B(exmem_branch_target),
        .SEL(exmem_branch), // when EX/MEM branch taken, choose branch target
        .Y(pc_in)
    );

endmodule
