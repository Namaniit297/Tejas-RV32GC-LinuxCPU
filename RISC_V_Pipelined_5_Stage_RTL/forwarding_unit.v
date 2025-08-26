// ============================================================================
// Forwarding Unit for RISC-V Pipeline
// ============================================================================
// Purpose:
//   - Resolves data hazards by forwarding results from EX/MEM or MEM/WB
//     pipeline stages to the EX stage inputs.
//   - Determines forwarding for ALU operand A and B separately.
//
// Inputs:
//   RS_1        : Source register 1 (ID/EX stage)
//   RS_2        : Source register 2 (ID/EX stage)
//   rdMem       : Destination register in EX/MEM
//   rdWb        : Destination register in MEM/WB
//   regWrite_Mem: EX/MEM.RegWrite signal
//   regWrite_Wb : MEM/WB.RegWrite signal
//
// Outputs:
//   Forward_A   : Control signal for ALU input A forwarding
//                 00 -> No forwarding (use ID/EX register value)
//                 10 -> Forward from EX/MEM stage
//                 01 -> Forward from MEM/WB stage
//   Forward_B   : Same as Forward_A, but for ALU input B
//
// Notes:
//   - EX hazard has higher priority than MEM hazard.
//   - Ensures register zero (x0) is never forwarded.
// ============================================================================

module forwarding_unit (
    input  wire [4:0] RS_1,       // ID/EX.RegisterRs1
    input  wire [4:0] RS_2,       // ID/EX.RegisterRs2
    input  wire [4:0] rdMem,      // EX/MEM.RegisterRd
    input  wire [4:0] rdWb,       // MEM/WB.RegisterRd
    input  wire       regWrite_Mem, // EX/MEM.RegWrite
    input  wire       regWrite_Wb,  // MEM/WB.RegWrite

    output reg  [1:0] Forward_A,
    output reg  [1:0] Forward_B
);

    always @(*) begin
        // Default: no forwarding
        Forward_A = 2'b00;
        Forward_B = 2'b00;

        // ------------------------------
        // Forwarding for ALU operand A
        // ------------------------------
        if (regWrite_Mem && (rdMem != 5'd0) && (rdMem == RS_1)) begin
            Forward_A = 2'b10;   // Forward from EX/MEM
        end
        else if (regWrite_Wb && (rdWb != 5'd0) && (rdWb == RS_1)) begin
            Forward_A = 2'b01;   // Forward from MEM/WB
        end

        // ------------------------------
        // Forwarding for ALU operand B
        // ------------------------------
        if (regWrite_Mem && (rdMem != 5'd0) && (rdMem == RS_2)) begin
            Forward_B = 2'b10;   // Forward from EX/MEM
        end
        else if (regWrite_Wb && (rdWb != 5'd0) && (rdWb == RS_2)) begin
            Forward_B = 2'b01;   // Forward from MEM/WB
        end
    end

endmodule
