module fetch (
    input  wire        clk,
    input  wire        resetn,
    input  wire        Branch,
    input  wire        Zero,
    input  wire        instr_jal,
    input  wire        instr_jalr,
    input  wire [31:0] imm_B,
    input  wire [31:0] imm_J,
    input  wire [31:0] imm_I,
    input  wire [31:0] rs1_data,
    output reg  [31:0] pc,
    output wire [31:0] instr,
    output reg  [31:0] pc_next
);

    reg [31:0] pc_reg;

    // Instruction Memory Interface (via unified_cache in top)

    // For simplicity, instr is a wire connected outside; here we just output pc

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            pc <= 0;
        end else begin
            pc <= pc_next;
        end
    end

    always @(*) begin
        // Default PC+4
        pc_next = pc + 4;

        // Branch Taken?
        if (Branch) begin
            if (Zero) begin
                pc_next = pc + imm_B;
            end
        end

        // JAL
        if (instr_jal) begin
            pc_next = pc + imm_J;
        end

        // JALR
        if (instr_jalr) begin
            pc_next = (rs1_data + imm_I) & 32'hfffffffe;
        end
    end

endmodule
