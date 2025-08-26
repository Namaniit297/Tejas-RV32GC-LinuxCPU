module allocateUnit (
    input        clk,
    input  [3:0] busyBits,    // 1 = busy, 0 = free (bit[0] = entry0, bit[1] = entry1, ...)
    output reg [1:0] index1,
    output reg [1:0] index2,
    output reg [1:0] full      // encoding: 2'b00 => >=2 free, 2'b01 => exactly 1 free, 2'b11 => full (0 free)
);

    integer i;
    reg [1:0] free_count;
    reg [1:0] first_free;
    reg [1:0] second_free;
    always @(negedge clk) begin
        // default outputs
        index1 <= 2'b00;
        index2 <= 2'b00;
        full   <= 2'b11; // assume full until computed

        free_count  = 0;
        first_free  = 2'b00;
        second_free = 2'b00;

        // scan for free entries (busyBits bit == 0)
        for (i = 0; i < 4; i = i + 1) begin
            if (busyBits[i] == 1'b0) begin
                if (free_count == 0) first_free = i[1:0];
                else if (free_count == 1) second_free = i[1:0];
                free_count = free_count + 1;
            end
        end

        // set outputs based on number of free entries
        if (free_count >= 2) begin
            full   <= 2'b00;      // >=2 free
            index1 <= first_free;
            index2 <= second_free;
        end else if (free_count == 1) begin
            full   <= 2'b01;      // exactly 1 free
            index1 <= first_free;
            index2 <= first_free; // second is don't-care; repeat first
        end else begin
            full   <= 2'b11;      // no free entries (full)
            index1 <= 2'b00;
            index2 <= 2'b00;
        end
    end

endmodule


module tagMatch (
    output reg [15:0] operand,
    input      [3:0]  tag,
    input      [41:0] CDBData
);
    // CDBData layout (as used elsewhere):
    // lower slot:  CDBData[20] = valid, [19:16] = tag, [15:0] = data
    // upper slot:  CDBData[41] = valid, [40:37] = tag, [36:21] = data

    always @(*) begin
        operand = 16'b0;
        // check lower slot tag
        if (tag == CDBData[19:16] && CDBData[20]) begin
            operand = CDBData[15:0];
        end
        // else check upper slot tag
        else if (tag == CDBData[40:37] && CDBData[41]) begin
            operand = CDBData[36:21];
        end
    end

endmodule
