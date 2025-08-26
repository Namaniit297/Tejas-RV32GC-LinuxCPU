module mux1bit (
    output out,
    input i0,
    input i1,
    input sel
);

    assign out = sel ? i1 : i0;

endmodule
