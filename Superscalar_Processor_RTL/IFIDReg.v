module IFIDReg (
    output reg [15:0] PCplus4Out,
    output reg [31:0] instrOut1, instrOut2,
    output reg nextPC_selOut,
    input [15:0] PCplus4In,
    input [31:0] instrIn1, instrIn2,
    input clk,
    input IFIDWrite,
    input IFFlush,
    input nextPC_selIn
);

    always @(posedge clk) begin
        if (IFIDWrite) begin
            if (IFFlush) begin
                instrOut1 <= 32'b0;
                instrOut2 <= 32'b0;
            end else begin
                instrOut1 <= instrIn1;
                instrOut2 <= instrIn2;
            end
            PCplus4Out <= PCplus4In;
            nextPC_selOut <= nextPC_selIn;
        end
    end

endmodule
