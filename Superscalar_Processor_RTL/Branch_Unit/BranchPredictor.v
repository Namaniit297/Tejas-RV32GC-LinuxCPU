module BranchPredictor (
    output prediction,
    input [31:0] PC,
    input [3:0] wPCindex,
    input taken
);

    wire [3:0] lhtIndex, wlhtIndex;
    wire [1:0] localPrediction, globalPrediction, combinedPrediction;
    wire [1:0] localHistory, globalHistory;

    // Global History Shift Register
    reg [31:0] GHSR;
    always @(wPCindex or taken) begin
        GHSR <= {GHSR[30:0], taken};
    end

    // Local History Table
    LocalHistoryTable lht (
        .rPCindex(PC[3:0]),
        .wPCindex(wPCindex),
        .taken(taken),
        .lptIndex(lhtIndex),
        .wlptIndex(wlhtIndex)
    );

    // Local Prediction Table
    PredictionTable lpt (
        .takenOut(localPrediction),
        .index(lhtIndex),
        .wIndex(wlhtIndex),
        .takenIn(taken)
    );

    // Global Prediction Table
    PredictionTable gpt (
        .takenOut(globalPrediction),
        .index(GHSR[3:0]),
        .wIndex(GHSR[3:0]),
        .takenIn(taken)
    );

    // Combined Prediction Table
    PredictionTable cpt (
        .takenOut(combinedPrediction),
        .index({GHSR[3:0], lhtIndex}),
        .wIndex({GHSR[3:0], lhtIndex}),
        .takenIn(taken)
    );

    // Final multiplexer to select prediction
    mux1bit mux (
        .out(prediction),
        .i0(localPrediction),
        .i1(globalPrediction),
        .sel(combinedPrediction)
    );

endmodule
