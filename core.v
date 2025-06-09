module top_rv32i_core (
    input  wire        clk,
    input  wire        resetn
);

    // === Internal Wires ===
    wire [31:0] pc, instr, pc_next;

    // === Decoding Fields ===
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [4:0]  rs1, rs2, rd;
    wire [31:0] imm_I, imm_S, imm_B, imm_J;

    // === Register File Wires ===
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] write_data;

    // === Control Signals ===
    wire        regwrite, memread, memwrite, memtoreg;
    wire        sel_a, sel_b;
    wire [3:0]  alu_control;
    wire        sgn;
    wire        branch, instr_jal, instr_jalr;
    wire        zero_flag, less_flag;

    // === ALU input mux ===
    wire [31:0] alu_in_a = sel_a ? rs1_data : pc;
    wire [31:0] alu_in_b = sel_b ? imm_I : rs2_data;

    // === ALU Result ===
    wire [31:0] alu_result;

    // === Memory I/O ===
    wire [31:0] mem_rdata;
    wire [3:0]  strobe;
    wire [2:0]  load_type;
    wire [2:0]  store_type = funct3;
    wire [1:0]  addr_offset = alu_result[1:0];

    // === Writeback mux ===
    wire [31:0] wb_data = memread ? mem_rdata : alu_result;

    // === Fetch ===
    fetch fetch_u (
        .clk(clk), .resetn(resetn),
        .Branch(branch), .Zero(zero_flag),
        .instr_jal(instr_jal), .instr_jalr(instr_jalr),
        .imm_B(imm_B), .imm_J(imm_J), .imm_I(imm_I),
        .rs1_data(rs1_data),
        .pc(pc), .instr(instr), .pc_next(pc_next)
    );

    // === Decoder ===
    decoder decoder_u (
        .instr(instr),
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .imm_I(imm_I), .imm_S(imm_S), .imm_B(imm_B), .imm_J(imm_J)
    );

    // === Register File ===
    register_file #(.WIDTH(32)) regfile (
        .clk(clk),
        .we(regwrite),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .wd(wb_data),
        .rd1(rs1_data), .rd2(rs2_data)
    );

    // === Control Unit ===
    control_unit ctrl_u (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .regwrite(regwrite),
        .memread(memread),
        .memwrite(memwrite),
        .memtoreg(memtoreg),
        .sel_a(sel_a),
        .sel_b(sel_b),
        .alu_control(alu_control),
        .sgn(sgn),
        .branch(branch),
        .instr_jal(instr_jal),
        .instr_jalr(instr_jalr)
    );

    // === ALU ===
    ALU_RV32I alu_u (
        .A(alu_in_a),
        .B(alu_in_b),
        .alu_control(alu_control),
        .sgn(sgn),
        .alu_result(alu_result),
        .zero_flag(zero_flag),
        .less_flag(less_flag)
    );

    // === Unified Cache (Dual Port, Byte Addressable) ===
    unified_cache #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(16)  // Adjust based on memory depth needed
    ) unified_mem (
        .clk(clk),
        .rst(~resetn),

        // Dual Role Port: both instr fetch + data access
        .addr(memread || memwrite ? alu_result : pc),
        .wdata(rs2_data),
        .strobe(strobe),
        .write_en(memwrite),
        .read_en(memread || ~memwrite),  // also allow read for instr fetch
        .load_type(memread ? funct3 : 3'b100),  // default LW for instr
        .rdata(mem_rdata)
    );

    // === Byte Strobe Generator ===
    assign strobe = (store_type == 3'b000) ? (4'b0001 << addr_offset) : // SB
                    (store_type == 3'b001) ? (addr_offset[1] ? 4'b1100 : 4'b0011) : // SH
                    (store_type == 3'b010) ? 4'b1111 : 4'b0000; // SW

endmodule
