// ============================================================================
// EX/MEM Pipeline Register
// ============================================================================
// Purpose:
//   - Holds the results from the Execute (EX) stage and forwards them
//     to the Memory (MEM) stage in a pipelined RISC-V processor.
//   - Buffers both data path signals (ALU results, memory data, branch target)
//     and control path signals (branch, memory access, regwrite).
//
// Features:
//   - Parameterized data width (default: 64-bit).
//   - Reset clears pipeline register to safe state.
//   - Flush input for pipeline control hazards.
//   - Clean synchronous design using non-blocking assignments.
//
// Inputs:
//   clk, reset, flush
//   ALU_result_in      : Result from ALU
//   write_data_in      : Register data forwarded to memory
//   branch_target_in   : Calculated branch target
//   rd_in              : Destination register index
//   branch_in          : Branch control
//   memread_in         : Memory read control
//   memtoreg_in        : Memory-to-register writeback control
//   memwrite_in        : Memory write control
//   regwrite_in        : Register write enable
//
// Outputs:
//   ALU_result_out, write_data_out, branch_target_out, rd_out
//   branch_out, memread_out, memtoreg_out, memwrite_out, regwrite_out
//
// ============================================================================

module EXMEM #(
    parameter WIDTH = 64   // Default data width
)(
    input  wire              clk,              // Clock signal
    input  wire              reset,            // Reset signal
    input  wire              flush,            // Flush signal

    // Data path signals
    input  wire [WIDTH-1:0]  ALU_result_in,    // ALU result input
    input  wire [WIDTH-1:0]  write_data_in,    // Data to write to memory
    input  wire [WIDTH-1:0]  branch_target_in, // Branch target address
    input  wire [4:0]        rd_in,            // Destination register index

    // Control signals
    input  wire              branch_in,
    input  wire              memread_in,
    input  wire              memtoreg_in,
    input  wire              memwrite_in,
    input  wire              regwrite_in,

    // Outputs
    output reg [WIDTH-1:0]   ALU_result_out,
    output reg [WIDTH-1:0]   write_data_out,
    output reg [WIDTH-1:0]   branch_target_out,
    output reg [4:0]         rd_out,
    output reg               branch_out,
    output reg               memread_out,
    output reg               memtoreg_out,
    output reg               memwrite_out,
    output reg               regwrite_out
);

    // Sequential logic for pipeline register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear everything on reset
            ALU_result_out   <= {WIDTH{1'b0}};
            write_data_out   <= {WIDTH{1'b0}};
            branch_target_out<= {WIDTH{1'b0}};
            rd_out           <= 5'b0;
            branch_out       <= 1'b0;
            memread_out      <= 1'b0;
            memtoreg_out     <= 1'b0;
            memwrite_out     <= 1'b0;
            regwrite_out     <= 1'b0;

        end else if (flush) begin
            // Same as reset, but for control hazards
            ALU_result_out   <= {WIDTH{1'b0}};
            write_data_out   <= {WIDTH{1'b0}};
            branch_target_out<= {WIDTH{1'b0}};
            rd_out           <= 5'b0;
            branch_out       <= 1'b0;
            memread_out      <= 1'b0;
            memtoreg_out     <= 1'b0;
            memwrite_out     <= 1'b0;
            regwrite_out     <= 1'b0;

        end else begin
            // Normal pipeline register update
            ALU_result_out   <= ALU_result_in;
            write_data_out   <= write_data_in;
            branch_target_out<= branch_target_in;
            rd_out           <= rd_in;
            branch_out       <= branch_in;
            memread_out      <= memread_in;
            memtoreg_out     <= memtoreg_in;
            memwrite_out     <= memwrite_in;
            regwrite_out     <= regwrite_in;
        end
    end

endmodule
