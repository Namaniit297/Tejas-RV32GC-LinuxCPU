module SourceRead (
    output reg [15:0] srcData,
    output reg [3:0]  srcTag,
    input  [16:0]     regData,
    input  [16:0]     robData,
    input  [3:0]      robTag,
    input             W
);

    // Combinational selection:
    // - If W is asserted and the architectural register has a pending tag (regData[16]==1),
    //   check ROB: if ROB has the value (robData[16]==1) forward it, otherwise return the tag.
    // - Otherwise return the register value and a zero tag.
    always @(*) begin
        if (W) begin
            if (regData[16]) begin
                if (robData[16]) begin
                    srcData = robData[15:0];
                    srcTag  = 4'b0000;
                end else begin
                    srcData = 16'b0;
                    srcTag  = robTag;
                end
            end else begin
                srcData = regData[15:0];
                srcTag  = 4'b0000;
            end
        end else begin
            // default when W is low: provide register value
            srcData = regData[15:0];
            srcTag  = 4'b0000;
        end
    end

endmodule
