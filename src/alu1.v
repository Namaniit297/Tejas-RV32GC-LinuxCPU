module alu_optimized_case (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [2:0]  control,     // 3-bit control input to select operation
    output reg  [31:0] result
);

    // Internal signals for operations
    wire [32:0] add_sub_full;
    wire [31:0] add_sub_res;
    wire is_sub;

    // Single adder/subtractor block that handles ADD and SUB
    is_sub = (control == 3'b001); // Control for SUB operation
    add_sub_full = {1'b0, A} + {1'b0, (is_sub ? ~B : B)} + is_sub;
    add_sub_res = add_sub_full[31:0];

    // ALU operation based on control input
    always @(*) begin
        case (control)
            3'b000: result = add_sub_res; // ADD
            3'b001: result = add_sub_res; // SUB (same circuit as add)
            3'b010: result = A ^ B;        // XOR
            3'b011: result = A | B;        // OR
            3'b100: result = A & B;        // AND
            3'b101: result = A >> B[4:0];  // SHR
            3'b110: result = A << B[4:0];  // SHL
            default: result = 32'd0;        // Default case
        endcase
    end

endmodule
