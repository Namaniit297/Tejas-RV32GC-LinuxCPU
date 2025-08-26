module LoadStore (
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] out
);

    // Simple address calculation (base + offset)
    assign out = a + b;

endmodule
