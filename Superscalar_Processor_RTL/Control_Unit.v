module ControlUnit (
    input  [5:0] opcode,
    input  [5:0] functCode,
    output reg   sw,
    output reg   lw,
    output reg   r,
    output reg   branch,
    output reg   jmp,
    output reg   hlt,
    output reg [2:0] func   // 1xx - mul, 000 - ADD, 001 - SUB, 010 - AND, 011 - OR
);

    // Opcode encodings
    parameter R   = 6'b000000;
    parameter LW  = 6'b100011;
    parameter SW  = 6'b101011;
    parameter BEQ = 6'b000100;
    parameter HLT = 6'b111111;
    parameter JMP = 6'b000010;

    // Function-field encodings (for R-type)
    parameter ADD = 6'b100000;
    parameter SUB = 6'b100010;
    parameter ANDF= 6'b100100;
    parameter ORF = 6'b100101;
    parameter SLT = 6'b101010;
    parameter MUL = 6'b100001;

    // Combinational control logic
    always @(*) begin
        // defaults to avoid latches
        sw     = 1'b0;
        lw     = 1'b0;
        r      = 1'b0;
        branch = 1'b0;
        jmp    = 1'b0;
        hlt    = 1'b0;
        func   = 3'b000;

        case (opcode)
            R: begin
                r = 1'b1;
                // set func based on functCode
                case (functCode)
                    ADD:  func = 3'b000;
                    SUB:  func = 3'b001;
                    ANDF: func = 3'b010;
                    ORF:  func = 3'b011;
                    MUL:  func = 3'b100;
                    default: func = 3'b000;
                endcase
            end

            LW: begin
                lw = 1'b1;
            end

            SW: begin
                sw = 1'b1;
            end

            BEQ: begin
                branch = 1'b1;
            end

            JMP: begin
                jmp = 1'b1;
            end

            HLT: begin
                hlt = 1'b1;
            end

            default: begin
                // leave defaults (no-op)
            end
        endcase
    end

endmodule
