module BranchUnit (
    output reg PCSrc,                  // Branch taken signal
    output reg [15:0] branchTarget,    // Computed branch target
    input [15:0] a, b,                 // Source operands for comparison
    input [15:0] PC, imm,              // Current PC and immediate offset
    input issued                       // Instruction issued flag
);

    always @(*) begin
        if (issued && (a == b)) begin
            PCSrc = 1'b1; 
            branchTarget = PC + imm;   // branch target = PC + offset
        end 
        else begin
            PCSrc = 1'b0;
            branchTarget = PC;         // No branch → next PC = sequential
        end
    end

endmodule
