module PCReg (
    output reg [15:0] PCOut,
    input [15:0] PCIn,
    input clk,
    input rst,
    input PCWrite
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            PCOut <= 16'b0000000000000000;
        else if (PCWrite)
            PCOut <= PCIn;
    end

endmodule
