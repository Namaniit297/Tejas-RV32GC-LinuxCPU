// ============================================================================
// Register File (32 x 64-bit) for RISC-V
// ============================================================================
// Purpose:
//   - Stores general-purpose registers (x0 - x31).
//   - Provides 2 read ports and 1 write port.
//   - x0 is always hardwired to 0 (cannot be written).
//
// Features:
//   - Parameterized width (default = 64).
//   - Asynchronous read, synchronous write.
//   - Debug outputs for selected registers.
//
// Inputs:
//   clk        : Clock
//   reset      : Reset (clears all registers to 0)
//   rs1, rs2   : Source register indices
//   rd         : Destination register index
//   writedata  : Data to be written to rd
//   reg_write  : Write enable
//
// Outputs:
//   readdata1  : Data from rs1
//   readdata2  : Data from rs2
//   r8, r19..r22 : Debug outputs (optional for waveform inspection)
// ============================================================================

module register_file #(
    parameter WIDTH = 64,
    parameter REG_COUNT = 32
)(
    input  wire              clk,
    input  wire              reset,
    input  wire [4:0]        rs1,
    input  wire [4:0]        rs2,
    input  wire [4:0]        rd,
    input  wire [WIDTH-1:0]  writedata,
    input  wire              reg_write,

    output wire [WIDTH-1:0]  readdata1,
    output wire [WIDTH-1:0]  readdata2,

    // Debug signals
    output wire [WIDTH-1:0]  r8,
    output wire [WIDTH-1:0]  r19,
    output wire [WIDTH-1:0]  r20,
    output wire [WIDTH-1:0]  r21,
    output wire [WIDTH-1:0]  r22
);

    // Register file array
    reg [WIDTH-1:0] registers [0:REG_COUNT-1];
    integer i;

    // Reset: clear all registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < REG_COUNT; i = i + 1)
                registers[i] <= {WIDTH{1'b0}};
        end
        else if (reg_write && (rd != 5'd0)) begin
            // Write to register rd (except x0 which is always 0)
            registers[rd] <= writedata;
        end
    end

    // Asynchronous read
    assign readdata1 = (rs1 == 5'd0) ? {WIDTH{1'b0}} : registers[rs1];
    assign readdata2 = (rs2 == 5'd0) ? {WIDTH{1'b0}} : registers[rs2];

    // Debug outputs
    assign r8  = registers[8];
    assign r19 = registers[19];
    assign r20 = registers[20];
    assign r21 = registers[21];
    assign r22 = registers[22];

endmodule
