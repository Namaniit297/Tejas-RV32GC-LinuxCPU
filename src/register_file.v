// Project_TEJAS -> Non_Pipelined_Multi_Cycle_RISC-V_Processor
// ISA -> RV32I

//------------------------------------------------------------------------------
// 1. Register File
//------------------------------------------------------------------------------
module register_file (
    input  wire        clock,
    input  wire        we,         // write enable
    input  wire [4:0]  rs1_addr,   // read port 1 address
    input  wire [4:0]  rs2_addr,   // read port 2 address
    input  wire [4:0]  rd_addr,    // write port address
    input  wire [31:0] rd_data,    // write port data
    output wire [31:0] rs1_data,   // read port 1 data
    output wire [31:0] rs2_data    // read port 2 data
);
    // 32 × 32-bit register array (x0–x31)
    reg [31:0] regs [0:31];

    // synchronous write, ignore writes to x0
    always @(posedge clock) begin
        if (we && rd_addr != 5'd0)
            regs[rd_addr] <= rd_data;
    end

    // asynchronous read, x0 always reads zero
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];
endmodule
