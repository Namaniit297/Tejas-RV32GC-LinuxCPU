module IntALU (
    input  [15:0] a,
    input  [15:0] b,
    input  [1:0]  ctrl,
    input  [3:0]  destTag,
    input         issued,
    output [20:0] CDBout
);

    reg [15:0] out;

    // Pack result into Common Data Bus (CDB) format: {valid, tag, data}
    assign CDBout = {issued, destTag, out};

    always @(*) begin
        case (ctrl)
            2'b00: out = a + b;
            2'b01: out = a - b;
            2'b10: out = a & b;
            2'b11: out = a | b;
            default: out = 16'b0;
        endcase
    end

endmodule
