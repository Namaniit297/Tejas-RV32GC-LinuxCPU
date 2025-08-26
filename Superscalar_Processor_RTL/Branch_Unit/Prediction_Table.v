module PredictionTable (
    output takenOut,
    input [3:0] index,
    input [3:0] wIndex,
    input takenIn
);

    reg [1:0] PT [0:15];
    reg [1:0] CS, CS_update;
    wire [1:0] NS;
    integer i;

    initial begin
        for (i = 0; i <= 15; i = i + 1) begin
            PT[i] = 2'b10; // Initial state
        end
    end

    always @(index) begin
        CS = PT[index];
    end

    always @(wIndex) begin
        CS_update = PT[wIndex];
    end

    always @(NS or wIndex) begin
        PT[wIndex] = NS;
    end

    Prediction_2bit pred (
        .NS(NS),
        .takenOut(takenOut),
        .taken(takenIn),
        .CS_read(CS),
        .CS_update(CS_update)
    );

endmodule
