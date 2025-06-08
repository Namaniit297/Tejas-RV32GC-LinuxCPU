module alu_optimized_onehot (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [6:0]  s_one_hot,   // one-hot encoded select: only one bit is '1'
    output wire [31:0] result
);

    // Single adder/subtractor block that handles ADD and SUB
    wire is_sub = s_one_hot[1]; // s_one_hot[1] is SUB
    wire [32:0] add_sub_full = {1'b0, A} + {1'b0, (is_sub ? ~B : B)} + is_sub;
    wire [31:0] add_sub_res = add_sub_full[31:0];

    // XOR operation
    wire [31:0] xor_res = A ^ B;

    // OR operation
    wire [31:0] or_res = A | B;

    // AND operation
    wire [31:0] and_res = A & B;

    // Right shift
    wire [31:0] shr_res = A >> B[4:0];

    // Left shift
    wire [31:0] shl_res = A << B[4:0];

    // Select each operation result with one-hot signal, else 0
    wire [31:0] t0 = s_one_hot[0] ? add_sub_res : 32'd0; // ADD
    wire [31:0] t1 = s_one_hot[1] ? add_sub_res : 32'd0; // SUB (same circuit as add)
    wire [31:0] t2 = s_one_hot[2] ? xor_res     : 32'd0; // XOR
    wire [31:0] t3 = s_one_hot[3] ? or_res      : 32'd0; // OR
    wire [31:0] t4 = s_one_hot[4] ? and_res     : 32'd0; // AND
    wire [31:0] t5 = s_one_hot[5] ? shr_res     : 32'd0; // SHR
    wire [31:0] t6 = s_one_hot[6] ? shl_res     : 32'd0; // SHL

    // XOR all partial results to get the final output
    assign result = t0 ^ t1 ^ t2 ^ t3 ^ t4 ^ t5 ^ t6;

endmodule

