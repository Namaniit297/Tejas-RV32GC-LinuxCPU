// ============================================================================
// ID/EX Pipeline Register
// ============================================================================
// Purpose:
//   - Holds instruction decode results and forwards them to EX stage.
//   - Latches both data signals (operands, immediates, PC) and control signals.
//   - Supports reset, flush, and pipeline stall.
//
// Features:
//   - Parameterized data width (default: 64).
//   - Non-blocking assignments for safe synchronous design.
//   - Clear separation of datapath vs control signals.
//   - Flush clears control/data signals (pipeline bubble).
//   - Optional stall: holds values when asserted.
// ============================================================================

module id_ex #(
    parameter DATA_WIDTH = 64
)(
    input  wire                  clk,
    input  wire                  reset,
    input  wire                  flush,
    input  wire                  enable,   // pipeline write enable (stall handling)

    // Data inputs
    input  wire [DATA_WIDTH-1:0] pc_in,
    input  wire [DATA_WIDTH-1:0] readdata1_in,
    input  wire [DATA_WIDTH-1:0] readdata2_in,
    input  wire [DATA_WIDTH-1:0] imm_data_in,
    input  wire [4:0]            rs1_in,
    input  wire [4:0]            rs2_in,
    input  wire [4:0]            rd_in,
    input  wire [3:0]            funct4_in,

    // Control inputs
    input  wire                  branch_in,
    input  wire                  memread_in,
    input  wire                  memtoreg_in,
    input  wire                  memwrite_in,
    input  wire                  alusrc_in,
    input  wire                  regwrite_in,
    input  wire [1:0]            aluop_in,

    // Data outputs
    output reg [DATA_WIDTH-1:0]  pc_out,
    output reg [DATA_WIDTH-1:0]  readdata1_out,
    output reg [DATA_WIDTH-1:0]  readdata2_out,
    output reg [DATA_WIDTH-1:0]  imm_data_out,
    output reg [4:0]             rs1_out,
    output reg [4:0]             rs2_out,
    output reg [4:0]             rd_out,
    output reg [3:0]             funct4_out,

    // Control outputs
    output reg                   branch_out,
    output reg                   memread_out,
    output reg                   memtoreg_out,
    output reg                   memwrite_out,
    output reg                   alusrc_out,
    output reg                   regwrite_out,
    output reg [1:0]             aluop_out
);

    // Synchronous logic
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            // Pipeline bubble on reset/flush
            pc_out         <= {DATA_WIDTH{1'b0}};
            readdata1_out  <= {DATA_WIDTH{1'b0}};
            readdata2_out  <= {DATA_WIDTH{1'b0}};
            imm_data_out   <= {DATA_WIDTH{1'b0}};
            rs1_out        <= 5'd0;
            rs2_out        <= 5'd0;
            rd_out         <= 5'd0;
            funct4_out     <= 4'd0;

            branch_out     <= 1'b0;
            memread_out    <= 1'b0;
            memtoreg_out   <= 1'b0;
            memwrite_out   <= 1'b0;
            alusrc_out     <= 1'b0;
            regwrite_out   <= 1'b0;
            aluop_out      <= 2'b00;
        end
        else if (enable) begin
            // Normal pipeline operation
            pc_out         <= pc_in;
            readdata1_out  <= readdata1_in;
            readdata2_out  <= readdata2_in;
            imm_data_out   <= imm_data_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct4_out     <= funct4_in;

            branch_out     <= branch_in;
            memread_out    <= memread_in;
            memtoreg_out   <= memtoreg_in;
            memwrite_out   <= memwrite_in;
            alusrc_out     <= alusrc_in;
            regwrite_out   <= regwrite_in;
            aluop_out      <= aluop_in;
        end
        // else: hold values (stall)
    end

endmodule
