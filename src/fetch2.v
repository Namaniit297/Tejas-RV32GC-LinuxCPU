module fetch (
    input  wire        clk,
    input  wire        resetn,

    // Control signals for next PC selection
    input  wire        Branch,
    input  wire        Zero,
    input  wire        instr_jal,
    input  wire        instr_jalr,

    // ALU-calculated next PC addresses for branch/jump
    input  wire [31:0] branch_target,
    input  wire [31:0] jal_target,
    input  wire [31:0] jalr_target,

    output reg  [31:0] pc
);

    wire [31:0] pc_plus_4;
    wire [31:0] pc_next;

    // Calculate pc + 4 internally
    assign pc_plus_4 = pc + 4;

    // Mux to select next PC based on control signals
    assign pc_next = instr_jal    ? jal_target    :
                     instr_jalr   ? jalr_target   :
                     (Branch && Zero) ? branch_target :
                     pc_plus_4;

    // PC register update
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

endmodule
