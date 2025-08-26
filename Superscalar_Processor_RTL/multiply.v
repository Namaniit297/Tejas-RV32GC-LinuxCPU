module multiply (
    input  [7:0]  a,
    input  [7:0]  b,
    input         issued,
    input  [3:0]  destTag,
    output [20:0] CDBout
);

    wire [15:0] tmp;

    // Multiply operands
    assign tmp = a * b;

    // Send result on CDB after 40 time units (simulation delay)
    assign #40 CDBout = {issued, destTag, tmp};

endmodule
