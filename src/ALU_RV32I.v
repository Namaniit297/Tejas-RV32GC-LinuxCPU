module ALU_RV32I (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  alu_control,
    input  wire        sgn,
    output reg  [31:0] alu_result,
    output reg         zero_flag,
    output reg         less_flag
);

    wire is_sub_or_slt = (alu_control == 4'b0100) || (alu_control == 4'b1000);
    wire [32:0] sum_ext = {1'b0, A} + {1'b0, (is_sub_or_slt ? ~B : B)} + (is_sub_or_slt ? 1'b1 : 1'b0);
    wire [31:0] sum = sum_ext[31:0];

    always @(*) begin
        alu_result = 32'd0;
        zero_flag  = 1'b0;
        less_flag  = 1'b0;

        case (alu_control)
            4'b0000: alu_result = A & B;                // AND
            4'b0001: alu_result = A | B;                // OR
            4'b0010: alu_result = sum;                  // ADD
            4'b0100: alu_result = sum;                  // SUB
            4'b0111: alu_result = A ^ B;                // XOR
            4'b0011: alu_result = A << B[4:0];          // SLL
            4'b0101: alu_result = sgn ? $signed(A) >>> B[4:0] : A >> B[4:0]; // SRL/SRA
            4'b1000: begin                               // SLT or SLTU
                if (sgn)
                    less_flag = (A[31] != B[31]) ? A[31] : sum[31];
                else
                    less_flag = ~sum_ext[32]; // Borrow detection
                alu_result = {31'd0, less_flag};
            end
            default: alu_result = 32'd0;
        endcase

        zero_flag = (alu_result == 32'd0);
    end

endmodule
