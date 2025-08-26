`include "mux1bit.v"
`include "BranchPredictor.v"

module InstructionMemory (
    input [15:0] PC,
    input en,
    output reg [31:0] instr1,
    output reg [31:0] instr2
);

    reg [31:0] instructions [0:1023];

    // Instruction fetch
    always @(PC) begin
        if (en) begin
            instr1 <= instructions[PC];
            instr2 <= instructions[PC + 1];
        end
    end

    // Load instructions from memory file
    initial begin
        $readmemh("dataDep.dat", instructions);
    end

endmodule
