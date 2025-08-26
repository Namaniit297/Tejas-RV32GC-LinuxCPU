module BranchTargetBuffer (
    output reg [15:0] predictedTarget,
    output reg hit,
    output reg prediction,
    input [15:0] PC,
    input [15:0] wBIA,
    input [15:0] branchTarget,
    input PCSrc
);

    // BTB table: store target address and valid bit
    reg [15:0] BTB_Target [0:15];
    reg        BTB_Valid  [0:15];
    integer i;

    // Initialize BTB
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            BTB_Target[i] = 16'b0;
            BTB_Valid[i]  = 1'b0;
        end
    end

    // Lookup: check if entry exists for PC
    always @(PC) begin
        if (BTB_Valid[PC[3:0]]) begin
            predictedTarget = BTB_Target[PC[3:0]];
            hit = 1'b1;
        end else begin
            predictedTarget = 16'b0;
            hit = 1'b0;
        end
    end

    // Update BTB on branch resolution
    always @(wBIA or branchTarget or PCSrc) begin
        if (PCSrc) begin
            BTB_Target[wBIA[3:0]] = branchTarget;
            BTB_Valid[wBIA[3:0]]  = 1'b1;
        end
    end

    // Simplified prediction (always taken if hit)
    always @(hit) begin
        prediction = hit ? 1'b1 : 1'b0;
    end

endmodule
