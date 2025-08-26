// ============================================================================
// Program Counter (PC) Module
// ============================================================================
// Purpose:
//   - Maintains the current program counter value.
//   - Updates with the next PC (PC_in) every cycle unless stalled.
//   - Supports asynchronous reset to zero (PC starts at address 0).
//
// Features:
//   - Parameterized width (default 64 bits).
//   - Asynchronous reset (active high) initializes PC to 0.
//   - Stall control: when stall=1, PC holds its current value.
//   - Synthesizable, safe coding style (non-blocking assignments).
//
// Inputs:
//   clk    : System clock (positive edge triggered).
//   reset  : Asynchronous reset (active high).
//   stall  : Pipeline stall signal (1=hold PC, 0=update).
//   PC_in  : Next PC value to load.
//
// Outputs:
//   PC_out : Current PC value (registered).
// ============================================================================

module program_counter #(
    parameter PC_WIDTH = 64
)(
    input  wire                  clk,
    input  wire                  reset,    // asynchronous active-high reset
    input  wire                  stall,    // 1=stall, 0=update
    input  wire [PC_WIDTH-1:0]   PC_in,
    output reg  [PC_WIDTH-1:0]   PC_out
);

    // Sequential process: async reset, otherwise update on clock edge
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset PC to 0
            PC_out <= {PC_WIDTH{1'b0}};
        end 
        else if (!stall) begin
            // Update PC only if not stalled
            PC_out <= PC_in;
        end
        else begin
            // Stall: retain current PC_out
            PC_out <= PC_out;
        end
    end

endmodule
