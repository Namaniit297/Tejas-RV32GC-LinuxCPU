module DispatchBuffer (
    output reg [3:0] rstag1out, rstag2out, rstag3out, rstag4out,
    output reg [15:0] dataRs1out, dataRt1out, dataRs2out, dataRt2out, imm1out, imm2out, PCplus2out,
    output reg [5:0] ctrl1out, ctrl2out,
    output reg [3:0] robDest1out, robDest2out,
    output reg [2:0] func1out, func2out,
    output reg spec1out, spec2out, nextPC_selOut,
    input [3:0] rstag1in, rstag2in, rstag3in, rstag4in,
    input [15:0] dataRs1in, dataRt1in, dataRs2in, dataRt2in, imm1in, imm2in, PCplus2in,
    input [5:0] ctrl1in, ctrl2in,
    input [3:0] robDest1in, robDest2in,
    input [2:0] func1in, func2in,
    input clk,
    input flush,
    input spec1in, spec2in,
    input nextPC_selIn,
    input dispatchWrite
);

    always @(posedge clk) begin
        if (dispatchWrite) begin
            if (flush) begin
                rstag1out  <= 4'b0000;
                rstag2out  <= 4'b0000;
                rstag3out  <= 4'b0000;
                rstag4out  <= 4'b0000;
                dataRs1out  <= 16'b0;
                dataRt1out  <= 16'b0;
                dataRs2out  <= 16'b0;
                dataRt2out  <= 16'b0;
                imm1out     <= 16'b0;
                imm2out     <= 16'b0;
                PCplus2out  <= 16'b0;
                ctrl1out    <= 6'b000000;
                ctrl2out    <= 6'b000000;
                robDest1out <= 4'b0000;
                robDest2out <= 4'b0000;
                func1out    <= 3'b000;
                func2out    <= 3'b000;
                spec1out    <= 1'b1;
                spec2out    <= 1'b1;
            end else begin
                rstag1out  <= rstag1in;
                rstag2out  <= rstag2in;
                rstag3out  <= rstag3in;
                rstag4out  <= rstag4in;
                dataRs1out  <= dataRs1in;
                dataRt1out  <= dataRt1in;
                dataRs2out  <= dataRs2in;
                dataRt2out  <= dataRt2in;
                imm1out     <= imm1in;
                imm2out     <= imm2in;
                PCplus2out  <= PCplus2in;
                ctrl1out    <= ctrl1in;
                ctrl2out    <= ctrl2in;
                robDest1out <= robDest1in;
                robDest2out <= robDest2in;
                func1out    <= func1in;
                func2out    <= func2in;
                spec1out    <= spec1in;
                spec2out    <= spec2in;
            end
            nextPC_selOut <= nextPC_selIn;
        end
    end

endmodule
