module dual_port_cache #(
    parameter ADDR_WIDTH = 16,     // 64KB
    parameter DATA_WIDTH = 32
)(
    input                   clk,

    // === Instruction Fetch Port (Port A) ===
    input                   ena,
    input  [ADDR_WIDTH-1:0] addra,     // Byte address
    output reg [15:0]       inst_out,  // 16-bit output (support compressed)

    // === Data Access Port (Port B) ===
    input                   enb,
    input                   web,                      // Write Enable
    input  [3:0]            strobe,                   // Byte-enable
    input  [ADDR_WIDTH-1:0] addrb,                    // Byte address
    input  [DATA_WIDTH-1:0] data_in,                  // Write data
    output reg [DATA_WIDTH-1:0] data_out              // Read data
);

    reg [7:0] mem [(1 << ADDR_WIDTH)-1:0];  // Byte-addressable

    // === Port A: Instruction Fetch (16-bit compressed or part of 32-bit instr) ===
    always @(posedge clk) begin
        if (ena) begin
            inst_out <= {mem[addra + 1], mem[addra]};  // Little endian
        end
    end

    // === Port B: Data Load/Store (supports byte strobe) ===
    always @(posedge clk) begin
        if (enb) begin
            // Read data (always valid on enb)
            data_out <= {mem[addrb + 3], mem[addrb + 2], mem[addrb + 1], mem[addrb]};

            // Write data with byte strobes
            if (web) begin
                if (strobe[0]) mem[addrb]     <= data_in[7:0];
                if (strobe[1]) mem[addrb + 1] <= data_in[15:8];
                if (strobe[2]) mem[addrb + 2] <= data_in[23:16];
                if (strobe[3]) mem[addrb + 3] <= data_in[31:24];
            end
        end
    end

endmodule
