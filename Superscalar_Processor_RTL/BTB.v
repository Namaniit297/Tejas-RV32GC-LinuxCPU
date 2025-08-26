module BTB (
    output reg [31:0] BTB_Target,
    input [31:0] PC,
    input [31:0] BTB_Addr,
    input [31:0] BTB_Entry
);

    reg [31:0] BTB_Table [0:15];
    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            BTB_Table[i] = 32'b0;
        end
    end

    always @(PC) begin
        BTB_Target = BTB_Table[PC[3:0]];
    end

    always @(BTB_Addr or BTB_Entry) begin
        BTB_Table[BTB_Addr[3:0]] = BTB_Entry; // Update the BTB entry
    end

endmodule
