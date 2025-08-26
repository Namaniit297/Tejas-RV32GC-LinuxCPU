module decode (
    input  [31:0] instr1,
    input  [31:0] instr2,
    output [4:0]  rs1, rt1, rd1,
    output [4:0]  rs2, rt2, rd2,
    output [5:0]  ctrl1, ctrl2,
    output [2:0]  func1, func2,
    output [15:0] immediate1, immediate2,
    output reg    spec1,
    output reg    spec2
);

    // Internal wires
    wire [5:0]  opcode1, opcode2;
    wire [15:0] imm1, imm2;
    reg  speculative;

    // Field extraction
    assign opcode1     = instr1[31:26];
    assign imm1        = instr1[15:0];
    assign rs1         = instr1[25:21];
    assign rt1         = instr1[20:16];
    assign rd1         = instr1[15:11];

    assign opcode2     = instr2[31:26];
    assign imm2        = instr2[15:0];
    assign rs2         = instr2[25:21];
    assign rt2         = instr2[20:16];
    assign rd2         = instr2[15:11];

    // Expose immediates to outside
    assign immediate1 = imm1;
    assign immediate2 = imm2;

    // Control units (named-port mapping to avoid positional mistakes)
    ControlUnit CU1 (
        .opcode   (opcode1),
        .functCode(instr1[5:0]),
        .sw       (ctrl1[5]),
        .lw       (ctrl1[4]),
        .r        (ctrl1[3]),
        .branch   (ctrl1[2]),
        .jmp      (ctrl1[1]),
        .hlt      (ctrl1[0]),
        .func     (func1)
    );

    ControlUnit CU2 (
        .opcode   (opcode2),
        .functCode(instr2[5:0]),
        .sw       (ctrl2[5]),
        .lw       (ctrl2[4]),
        .r        (ctrl2[3]),
        .branch   (ctrl2[2]),
        .jmp      (ctrl2[1]),
        .hlt      (ctrl2[0]),
        .func     (func2)
    );

    initial begin
        speculative = 1'b0;
        spec1 = 1'b0;
        spec2 = 1'b0;
    end

    // Decide speculation flags based on decoded control signals
    // ctrl[2] is 'branch' (see ControlUnit), so we check that bit.
    always @(*) begin
        if (speculative == 1'b0) begin
            if (ctrl1[2]) begin            // first instruction is a branch
                spec1 = 1'b0;
                spec2 = 1'b1;
                speculative = 1'b1;
            end else if (ctrl2[2]) begin   // second instruction is a branch
                speculative = 1'b1;
                spec1 = 1'b0;
                spec2 = 1'b0;
            end else begin
                speculative = 1'b0;
                spec1 = 1'b0;
                spec2 = 1'b0;
            end
        end else begin
            // already speculative: mark both as speculative
            spec1 = 1'b1;
            spec2 = 1'b1;
        end
    end

endmodule
