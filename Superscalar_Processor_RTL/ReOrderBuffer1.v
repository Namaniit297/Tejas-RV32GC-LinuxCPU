module ReOrderBuffer1 (
    input         clk,
    input         flush,         // global flush (e.g. on reset/mispredict)
    input         correction,    // branch correction signal
    input  [3:0]  tag1, tag2, tag3, tag4, // tags used for matching writebacks (tag3/tag4 optional)
    input  [15:0] wData1, wData2,         // writeback data corresponding to tag1/tag2
    input  [4:0]  dest1, dest2,           // destination register indices for new ROB entries
    input  [1:0]  type1, type2,           // type fields for new ROB entries
    input  [3:0]  correctionIndex,        // index to rollback to on correction
    output reg [27:0] data1, data2, data3, data4, // snapshot outputs of ROB entries (for debug/inspection)
    output reg [3:0]  index1, index2,             // indices being committed this cycle (if any)
    output reg [1:0]  wbType1, wbType2,           // types to write back
    output reg [20:0] wbData1, wbData2,           // writeback payload: {valid, tag[3:0], data[15:0]}
    output reg        stall                       // ROB full indicator
);

    // Entry format (28 bits):
    // [27]    valid
    // [26]    ready
    // [25:22] tag  (4 bits)
    // [21:17] dest (5 bits)
    // [16:15] type (2 bits)
    // [15:0]  data (16 bits)
    reg [27:0] robEntries [0:15];

    reg [3:0] head; // oldest entry to commit
    reg [3:0] tail; // next free slot (points to first invalid)
    integer   count;
    integer i;

    // Helper: pack wbData
    function [20:0] pack_wb;
        input valid_bit;
        input [3:0] tag;
        input [15:0] data;
        begin
            pack_wb = {valid_bit, tag, data}; // 1 + 4 + 16 = 21 bits
        end
    endfunction

    // Initialization
    initial begin
        for (i = 0; i < 16; i = i + 1)
            robEntries[i] = 28'b0;
        head  = 4'd0;
        tail  = 4'd0;
        count = 0;
        stall = 1'b0;
        index1 = 4'b0;
        index2 = 4'b0;
        data1 = 28'b0;
        data2 = 28'b0;
        data3 = 28'b0;
        data4 = 28'b0;
        wbType1 = 2'b00;
        wbType2 = 2'b00;
        wbData1 = 21'b0;
        wbData2 = 21'b0;
    end

    // Main sequential logic
    always @(posedge clk) begin
        // Default outputs each cycle
        index1 <= 4'b0;
        index2 <= 4'b0;
        data1  <= 28'b0;
        data2  <= 28'b0;
        data3  <= 28'b0;
        data4  <= 28'b0;
        wbType1 <= 2'b00;
        wbType2 <= 2'b00;
        wbData1 <= 21'b0;
        wbData2 <= 21'b0;

        // Handle flush: clear all entries, reset pointers
        if (flush) begin
            for (i = 0; i < 16; i = i + 1)
                robEntries[i] <= 28'b0;
            head  <= 4'd0;
            tail  <= 4'd0;
            count <= 0;
            stall <= 1'b0;
        end else if (correction) begin
            // Conservative correction handling:
            // Reset ROB and set tail/head to correctionIndex (caller is expected to re-insert older entries).
            for (i = 0; i < 16; i = i + 1)
                robEntries[i] <= 28'b0;
            head  <= correctionIndex;
            tail  <= correctionIndex;
            count <= 0;
            stall <= 1'b0;
        end else begin
            // 1) Writeback matching: mark entries ready and store data when tag matches tag1/tag2
            // Search all entries and update if tag matches.
            for (i = 0; i < 16; i = i + 1) begin
                if (robEntries[i][27]) begin // valid entry
                    if (robEntries[i][25:22] == tag1) begin
                        // tag1 -> wData1
                        robEntries[i][26] <= 1'b1;                  // ready
                        robEntries[i][15:0] <= wData1;              // store data
                    end
                    if (robEntries[i][25:22] == tag2) begin
                        // tag2 -> wData2
                        robEntries[i][26] <= 1'b1;
                        robEntries[i][15:0] <= wData2;
                    end
                    // optional tag3/tag4: mark ready but no associated data bus provided
                    if (robEntries[i][25:22] == tag3) begin
                        robEntries[i][26] <= 1'b1;
                        // leave data unchanged (or zero)
                    end
                    if (robEntries[i][25:22] == tag4) begin
                        robEntries[i][26] <= 1'b1;
                    end
                end
            end

            // 2) Commit up to two entries from head if they are valid and ready
            // Commit first entry if available
            if ((count > 0) && (robEntries[head][27] == 1'b1) && (robEntries[head][26] == 1'b1)) begin
                index1 <= head;
                data1  <= robEntries[head];
                wbType1 <= robEntries[head][16:15];
                wbData1 <= pack_wb(robEntries[head][27], robEntries[head][25:22], robEntries[head][15:0]);
                // clear entry after commit
                robEntries[head] <= 28'b0;
                head <= head + 4'd1;
                count <= count - 1;
            end

            // Try to commit a second entry (new head after the first commit)
            if ((count > 0) && (robEntries[head][27] == 1'b1) && (robEntries[head][26] == 1'b1)) begin
                index2 <= head;
                data2  <= robEntries[head];
                wbType2 <= robEntries[head][16:15];
                wbData2 <= pack_wb(robEntries[head][27], robEntries[head][25:22], robEntries[head][15:0]);
                robEntries[head] <= 28'b0;
                head <= head + 4'd1;
                count <= count - 1;
            end

            // 3) Enqueue new entries if there is space.
            // The module ports do not include explicit enqueue valid signals;
            // to keep compatibility with the user's earlier style, we interpret
            // 'dest1/type1/tag1...' as an implicit enqueue attempt when tag1/tag2 != 0.
            // If tail slot is free, insert a new entry for (tag1,dest1,type1) and/or (tag2,dest2,type2).
            // NOTE: In your real design you might have explicit allocation signals; adapt this as needed.

            // Enqueue first new entry if provided (we use tag1 as the allocation tag indicator
            // and avoid overriding when full)
            if ((count < 16) && (tag1 != 4'b0000)) begin
                robEntries[tail] <= {
                    1'b1,                 // valid
                    1'b0,                 // ready initially false
                    tag1,                 // [25:22] tag
                    dest1[4:0],           // [21:17] dest
                    type1[1:0],           // [16:15] type
                    16'b0                 // [15:0] data (will be filled on writeback)
                };
                tail <= tail + 4'd1;
                count <= count + 1;
            end

            // Enqueue second new entry if provided and space remains
            if ((count < 16) && (tag2 != 4'b0000)) begin
                robEntries[tail] <= {
                    1'b1,
                    1'b0,
                    tag2,
                    dest2[4:0],
                    type2[1:0],
                    16'b0
                };
                tail <= tail + 4'd1;
                count <= count + 1;
            end

            // Update stall flag (ROB full)
            stall <= (count >= 16);
        end
    end

endmodule
