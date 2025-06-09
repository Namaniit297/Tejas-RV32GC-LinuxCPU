//------------------------------------------------------------------------------
// fetch.v
// Fetch Unit: PC register, next-PC logic, and instruction memory.
//------------------------------------------------------------------------------

module fetch (
    input  wire        clk,
    input  wire        resetn,

    // control signals from decode/control
    input  wire        Branch,        // conditional branch
    input  wire        Zero,          // ALU zero flag for BEQ/BNE etc.
    input  wire        instr_jal,     // JAL
    input  wire        instr_jalr,    // JALR

    // immediates from decoder
    input  wire [31:0] imm_B,         // branch offset
    input  wire [31:0] imm_J,         // JAL offset
    input  wire [31:0] imm_I,         // JALR immediate

    // for JALR: base register value (rs1)
    input  wire [31:0] rs1_data,

    // outputs
    output wire [31:0] pc,            // current PC
    output wire [31:0] instr,         // fetched instruction
    output wire [31:0] pc_next        // computed next PC
);

    // Program Counter register
    reg [31:0] pc_reg;
    assign pc = pc_reg;

    // PC + 4 for normal flow
    wire [31:0] pc_plus_4 = pc_reg + 32'd4;

    // Branch target = PC + imm_B
    wire [31:0] branch_pc = pc_reg + imm_B;

    // JAL target = PC + imm_J
    wire [31:0] jal_pc    = pc_reg + imm_J;

    // JALR target = (rs1_data + imm_I) & ~1
    wire [31:0] jalr_pc   = (rs1_data + imm_I) & 32'hFFFFFFFE;

    // Next PC MUX
    assign pc_next =
        instr_jal   ? jal_pc   :
        instr_jalr  ? jalr_pc  :
        (Branch && Zero) ? branch_pc :
        pc_plus_4;

    // Update PC register
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            pc_reg <= 32'd0;
        else
            pc_reg <= pc_next;
    end

    // Unified Cache for instruction memory
    wire [31:0] rdata;
    wire [9:0] addr; // Address for the cache
    wire read_en = 1'b1; // Always read for instruction fetch
    wire [3:0] strobe = 4'b1111; // Enable all bytes for word access

    // Instantiate the unified_cache
    unified_cache #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10)
    ) cache (
        .clk(clk),
        .rst(~resetn), // Active low reset
        .addr(pc_reg[9:0]), // Use lower 10 bits of PC for address
        .wdata(32'b0), // No write data for instruction fetch
        .strobe(strobe),
        .write_en(1'b0), // No write enable for instruction fetch
        .read_en(read_en),
        .load_type(3'b100), // Load word
        .rdata(instr) // Output fetched instruction
    );

endmodule
