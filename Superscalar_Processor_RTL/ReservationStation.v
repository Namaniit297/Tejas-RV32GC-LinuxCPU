module ReservationStationInt (
    output reg [15:0] rsOut,
    output reg [15:0] rtOut,
    output reg [3:0]  robTagOut,
    output reg [1:0]  funcOut,
    output reg [1:0]  entryToBeClearedOut,
    output reg        stall,
    output reg        issued,

    input  [15:0] rs1in,
    input  [15:0] rt1in,
    input  [15:0] rs2in,
    input  [15:0] rt2in,

    input  [3:0]  tag_rs1in,
    input  [3:0]  tag_rt1in,
    input  [3:0]  tag_rs2in,
    input  [3:0]  tag_rt2in,

    input  [1:0]  func1in,
    input  [1:0]  func2in,

    input  [1:0]  load,                  // load[0] -> first entry allocation, load[1] -> second
    input  [1:0]  entryToBeClearedIn,    // which entry to clear (2-bit index)

    input  [3:0]  robDest1,
    input  [3:0]  robDest2,

    input         clk,
    input         clearRSEntry,
    input         flush,

    input  [41:0] CDBData
);

    // Layout of each reservation entry (bits 48 downto 0 = 49 bits):
    // [48]      : spec (1)
    // [47]      : busy (1)
    // [46:45]   : func (2)
    // [44:41]   : robTag (4)
    // [40:37]   : tag_rt (4)
    // [36:21]   : rt (16)
    // [20:17]   : tag_rs (4)
    // [16:1]    : rs (16)
    // [0]       : ready flag (1)  -- 1 means ready to issue

    reg [48:0] resEntries [0:3];
    reg spec1;
    reg spec2;
    reg [1:0] head;

    wire [3:0] busyBits;
    wire [1:0] index1, index2;
    wire [1:0] full;

    // Forwarded operand wires (produced by tagMatch units)
    wire [15:0] oper01, oper02, oper11, oper12, oper21, oper22, oper31, oper32;

    // Initialize
    integer i;
    initial begin
        spec1 = 1'b0;
        spec2 = 1'b0;
        for (i = 0; i < 4; i = i + 1)
            resEntries[i] = 49'b0;
        head = 2'b00;
        stall = 1'b0;
        issued = 1'b0;
    end

    // busyBits: ordered from oldest to newest relative to head
    assign busyBits = {
        resEntries[(head + 2'd3) & 2'b11][47],
        resEntries[(head + 2'd2) & 2'b11][47],
        resEntries[(head + 2'd1) & 2'b11][47],
        resEntries[head][47]
    };

    // Allocation unit (external) -- provides indices and full status
    // allocateUnit au ( index1 , index2 , full , busyBits , clk );
    // Keep as positional instantiation to match user's module if desired:
    allocateUnit au (
        .index1(index1),
        .index2(index2),
        .full(full),
        .busyBits(busyBits),
        .clk(clk)
    );

    // Allocation / insertion into reservation station (sequential)
    always @(posedge clk) begin
        // Allocation for entry 0 (first issue slot)
        if (load[0] && (full == 2'b00 || full == 2'b01)) begin
            // Determine ready: both tags zero means operands already available
            resEntries[index1] <= {
                1'b0,                // spec bit (currently using single-bit spec; 0 = not speculative)
                1'b1,                // busy
                func1in,             // [46:45]
                robDest1,            // [44:41] (4 bits)
                tag_rt1in,           // [40:37] (4 bits)
                rt1in,               // [36:21] (16 bits)
                tag_rs1in,           // [20:17] (4 bits)
                rs1in,               // [16:1]  (16 bits)
                ((tag_rs1in == 4'b0000 && tag_rt1in == 4'b0000) ? 1'b1 : 1'b0) // ready bit [0]
            };
            head <= (head + 1) & 2'b11;
        end

        // Allocation for entry 1 (second issue slot)
        if (load[1] && (full == 2'b00)) begin
            resEntries[index2] <= {
                1'b0,
                1'b1,
                func2in,
                robDest2,
                tag_rt2in,
                rt2in,
                tag_rs2in,
                rs2in,
                ((tag_rs2in == 4'b0000 && tag_rt2in == 4'b0000) ? 1'b1 : 1'b0)
            };
            head <= (head + 1) & 2'b11;
        end
    end

    // Flush: clear all entries
    always @(posedge clk) begin
        if (flush) begin
            for (i = 0; i < 4; i = i + 1)
                resEntries[i] <= 49'b0;
        end
    end

    // Stall signal depends on full indicator
    always @(*) begin
        stall = (full == 2'b11);
    end

    // Clear a specific RS entry (e.g., after commit)
    always @(posedge clk) begin
        if (clearRSEntry) begin
            resEntries[entryToBeClearedIn][47] <= 1'b0;   // clear busy
            resEntries[entryToBeClearedIn][0]  <= 1'b0;   // clear ready
        end
    end

    // Issue logic (priority encoder) - sample at clock edge
    always @(posedge clk) begin
        issued <= 1'b0;
        // Look for ready entries in order 0..3 (same order user used)
        casex ({ resEntries[3][0], resEntries[2][0], resEntries[1][0], resEntries[0][0] })
            4'bxxx1: begin
                rsOut <= resEntries[0][16:1];
                rtOut <= resEntries[0][36:21];
                robTagOut <= resEntries[0][44:41];
                funcOut <= resEntries[0][46:45];
                entryToBeClearedOut <= 2'b00;
                issued <= 1'b1;
            end

            4'bxx10: begin
                rsOut <= resEntries[1][16:1];
                rtOut <= resEntries[1][36:21];
                robTagOut <= resEntries[1][44:41];
                funcOut <= resEntries[1][46:45];
                entryToBeClearedOut <= 2'b01;
                issued <= 1'b1;
            end

            4'bx100: begin
                rsOut <= resEntries[2][16:1];
                rtOut <= resEntries[2][36:21];
                robTagOut <= resEntries[2][44:41];
                funcOut <= resEntries[2][46:45];
                entryToBeClearedOut <= 2'b10;
                issued <= 1'b1;
            end

            4'b1000: begin
                rsOut <= resEntries[3][16:1];
                rtOut <= resEntries[3][36:21];
                robTagOut <= resEntries[3][44:41];
                funcOut <= resEntries[3][46:45];
                entryToBeClearedOut <= 2'b11;
                issued <= 1'b1;
            end

            default: begin
                rsOut <= 16'b0;
                rtOut <= 16'b0;
                robTagOut <= 4'b0;
                funcOut <= 2'b00;
                entryToBeClearedOut <= 2'b00;
                issued <= 1'b0;
            end
        endcase
    end

    // Tag-match forwarders: external module 'tagMatch' is expected to compare tags and forward data from CDB.
    // Instantiations (one per operand per entry):
    tagMatch tm1  ( .out(oper01), .tag(resEntries[0][20:17]), .CDB(CDBData) );
    tagMatch tm2  ( .out(oper02), .tag(resEntries[0][40:37]), .CDB(CDBData) );
    tagMatch tm3  ( .out(oper11), .tag(resEntries[1][20:17]), .CDB(CDBData) );
    tagMatch tm4  ( .out(oper12), .tag(resEntries[1][40:37]), .CDB(CDBData) );
    tagMatch tm5  ( .out(oper21), .tag(resEntries[2][20:17]), .CDB(CDBData) );
    tagMatch tm6  ( .out(oper22), .tag(resEntries[2][40:37]), .CDB(CDBData) );
    tagMatch tm7  ( .out(oper31), .tag(resEntries[3][20:17]), .CDB(CDBData) );
    tagMatch tm8  ( .out(oper32), .tag(resEntries[3][40:37]), .CDB(CDBData) );

    // Perform forwarding updates on clock edge (if tagMatch produced valid forwarded operand)
    // Update both operand fields (tag cleared and value written) per-entry when forwarded data is available.
    always @(posedge clk) begin
        // Entry 0 updates
        if (|oper01) begin
            // write tag_rs = 0 and rs = oper01
            resEntries[0][20:1] <= {4'b0000, oper01};
        end
        if (|oper02) begin
            // write tag_rt = 0 and rt = oper02
            resEntries[0][40:21] <= {4'b0000, oper02};
        end
        // Entry 1 updates
        if (|oper11) resEntries[1][20:1] <= {4'b0000, oper11};
        if (|oper12) resEntries[1][40:21] <= {4'b0000, oper12};
        // Entry 2 updates
        if (|oper21) resEntries[2][20:1] <= {4'b0000, oper21};
        if (|oper22) resEntries[2][40:21] <= {4'b0000, oper22};
        // Entry 3 updates
        if (|oper31) resEntries[3][20:1] <= {4'b0000, oper31};
        if (|oper32) resEntries[3][40:21] <= {4'b0000, oper32};

        // Recompute ready bits for all entries after potential updates
        for (i = 0; i < 4; i = i + 1) begin
            resEntries[i][0] <= (resEntries[i][20:17] == 4'b0000 && resEntries[i][40:37] == 4'b0000) ? 1'b1 : resEntries[i][0];
        end
    end

endmodule
