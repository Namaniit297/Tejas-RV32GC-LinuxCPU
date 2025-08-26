module ExecuteBuffer (
    output reg [41:0] CDBData,
    output reg [1:0] entryTCout_I,
    output reg [1:0] entryTCout_LS,
    output reg [2:0] clearRSEntry,
    input  [20:0] int_datain,
    input  [20:0] MUL_datain,
    input  [20:0] LS_datain,
    input  [1:0]  entryTCin_I,
    input  [1:0]  entryTCin_LS,
    input         clk
);

    always @(posedge clk) begin
        // defaults
        CDBData        <= 42'b0;
        clearRSEntry   <= 3'b000;
        entryTCout_I   <= 2'b00;
        entryTCout_LS  <= 2'b00;

        // Priority: INT > LS > MUL
        if (int_datain[20]) begin
            // place INT in lower slot
            CDBData[20:0] <= int_datain;
            clearRSEntry[0] <= 1'b1;
            entryTCout_I <= entryTCin_I;

            // try to fill upper slot from LS else MUL
            if (LS_datain[20]) begin
                CDBData[41:21] <= LS_datain;
                clearRSEntry[1] <= 1'b1;
                entryTCout_LS <= entryTCin_LS;
            end else if (MUL_datain[20]) begin
                CDBData[41:21] <= MUL_datain;
                clearRSEntry[2] <= 1'b1;
            end
        end else if (LS_datain[20]) begin
            // place LS in lower slot
            CDBData[20:0] <= LS_datain;
            clearRSEntry[1] <= 1'b1;
            entryTCout_LS <= entryTCin_LS;

            // try to fill upper slot from MUL
            if (MUL_datain[20]) begin
                CDBData[41:21] <= MUL_datain;
                clearRSEntry[2] <= 1'b1;
            end
        end else if (MUL_datain[20]) begin
            // only MUL valid -> place in lower slot
            CDBData[20:0] <= MUL_datain;
            clearRSEntry[2] <= 1'b1;
        end
    end

endmodule
