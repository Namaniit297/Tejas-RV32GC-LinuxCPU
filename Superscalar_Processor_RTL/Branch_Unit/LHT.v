module LocalHistoryTable (
    output reg [3:0] lptIndex,
    output reg [3:0] wlptIndex,
    input [3:0] rPCindex,
    input [3:0] wPCindex,
    input taken
);

    reg [3:0] LHT [0:15];
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            LHT[i] = 4'b0000;
        end
    end

    // Read local history
    always @(rPCindex) begin
        lptIndex = LHT[rPCindex];
    end

    // Update local history on taken/not-taken outcome
    always @(wPCindex or taken) begin
        LHT[wPCindex] = {LHT[wPCindex][2:0], taken};
    end

endmodule
