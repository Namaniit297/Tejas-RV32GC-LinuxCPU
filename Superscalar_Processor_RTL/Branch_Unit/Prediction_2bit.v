module Prediction_2bit (
    output reg [1:0] NS,
    output reg takenOut,
    input [1:0] CS_read,
    input [1:0] CS_update,
    input taken
);

    parameter ST  = 2'b00,  // Strongly Taken
              T   = 2'b01,  // Taken
              NT  = 2'b10,  // Not Taken
              SNT = 2'b11;  // Strongly Not Taken

    // Prediction output based on current state
    always @(CS_read) begin
        case (CS_read)
            ST, T:   takenOut = 1;
            NT, SNT: takenOut = 0;
        endcase
    end

    // Update state based on outcome
    always @(CS_update or taken) begin
        case (CS_update)
            ST:   NS = taken ? ST  : T;
            T:    NS = taken ? ST  : SNT;
            NT:   NS = taken ? ST  : SNT;
            SNT:  NS = taken ? NT  : SNT;
        endcase
    end

endmodule
