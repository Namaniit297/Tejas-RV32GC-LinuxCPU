// ============================================================================
// Adder Module
// ============================================================================
// Purpose:
//   - Generic combinational adder.
//   - In RISC-V pipeline, often used as:
//       1) PC + 4   (sequential instruction fetch)
//       2) PC + immediate (branch/jump target calculation)
//
// Features:
//   - Parameterized width (default = 64 bits).
//   - Pure combinational logic (no clock).
//   - Synthesizable and portable.
//
// Inputs:
//   a   : First operand (e.g., current PC value)
//   b   : Second operand (e.g., constant 4 or branch offset)
// Outputs:
//   sum : Result of addition (a + b)
//
// Notes:
//   - In PC increment use, set b = 64'd4
//   - For branch target, b = immediate offset
// ============================================================================

module adder #(
    parameter WIDTH = 64
)(
    input  wire [WIDTH-1:0] a,    // first operand
    input  wire [WIDTH-1:0] b,    // second operand
    output wire [WIDTH-1:0] sum   // result
);

    // Combinational addition
    assign sum = a + b;

endmodule
