// ============================================================================
// 64-bit Parameterized Adder for RISC-V Pipeline
// ============================================================================
// Purpose:
//   - Computes the sum of two operands (e.g., Program Counter + immediate).
//   - Used in PC update logic (sequential execution or branch target).
//   - Provides carry-out and overflow detection for debugging / exception handling.
//
// Features:
//   - Parameterized width (default: 64-bit).
//   - Pure combinational addition (no latency).
//   - Optional pipeline register (can be enabled with parameter).
//   - Carry-out + Signed overflow flag.
//
// Inputs:
//   p, q : Operands to be added (PC, offset, immediate, etc.)
//
// Outputs:
//   sum       : Result of addition
//   carry_out : Carry-out of MSB (for unsigned addition check)
//   overflow  : Overflow flag (for signed operations)
//
// ============================================================================

module adder #(
    parameter WIDTH = 64,        // Configurable width (default 64-bit)
    parameter PIPELINED = 0      // 0 = combinational, 1 = pipelined
)(
    input  wire                  clk,      // Clock (used only if pipelined)
    input  wire [WIDTH-1:0]      p,        // Operand 1 (e.g., PC)
    input  wire [WIDTH-1:0]      q,        // Operand 2 (e.g., immediate)
    output reg  [WIDTH-1:0]      sum,      // Sum output
    output reg                   carry_out,// Carry-out (unsigned overflow)
    output reg                   overflow  // Signed overflow flag
);

    // Internal wires
    wire [WIDTH:0] temp_sum;   // One bit wider to capture carry
    assign temp_sum = {1'b0, p} + {1'b0, q};

    // Detect overflow (signed add overflow rule)
    wire signed_overflow = 
        (p[WIDTH-1] == q[WIDTH-1]) && (temp_sum[WIDTH-1] != p[WIDTH-1]);

    generate
        if (PIPELINED == 1) begin : pipelined_adder
            // Synchronous pipeline register
            always @(posedge clk) begin
                sum       <= temp_sum[WIDTH-1:0];
                carry_out <= temp_sum[WIDTH];
                overflow  <= signed_overflow;
            end
        end else begin : comb_adder
            // Pure combinational adder
            always @(*) begin
                sum       = temp_sum[WIDTH-1:0];
                carry_out = temp_sum[WIDTH];
                overflow  = signed_overflow;
            end
        end
    endgenerate

endmodule
