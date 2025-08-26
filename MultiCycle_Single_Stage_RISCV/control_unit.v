module control_unit(
    input  wire [6:0]  opcode,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    input  wire        imm_valid,

    output reg  [3:0]  alu_control,
    output reg         sgn,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         branch,
    output reg         jump,
    output reg         alu_src,
    output reg  [1:0]  pc_src
);

    always @(*) begin
        // Default values
        alu_control = 4'b0000;
        sgn         = 1'b0;
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        alu_src     = 1'b0;  // 0 = reg, 1 = imm
        pc_src      = 2'b00; // 00 = PC+4 default

        case(opcode)
            7'b0110011: begin // R-type (ADD, SUB, AND, OR, etc)
                reg_write = 1'b1;
                alu_src   = 1'b0; // ALU second operand from reg

                case(funct3)
                    3'b000: alu_control = (funct7 == 7'b0100000) ? 4'b0100 : 4'b0010; // SUB : ADD
                    3'b111: alu_control = 4'b0000; // AND
                    3'b110: alu_control = 4'b0001; // OR
                    3'b100: alu_control = 4'b0111; // XOR
                    3'b001: alu_control = 4'b0011; // SLL
                    3'b101: begin
                        alu_control = 4'b0101; 
                        sgn = (funct7 == 7'b0100000); // SRL/SRA signed if funct7 = 0x20
                    end
                    3'b010: begin
                        alu_control = 4'b1000; 
                        sgn = 1'b1; // SLT signed
                    end
                    3'b011: begin
                        alu_control = 4'b1000; 
                        sgn = 1'b0; // SLTU unsigned
                    end
                    default: alu_control = 4'b0000;
                endcase
            end

            7'b0010011: begin // I-type ALU (ADDI, SLTI, etc)
                reg_write = 1'b1;
                alu_src   = 1'b1; // ALU second operand from imm

                case(funct3)
                    3'b000: alu_control = 4'b0010; // ADDI
                    3'b111: alu_control = 4'b0000; // ANDI
                    3'b110: alu_control = 4'b0001; // ORI
                    3'b100: alu_control = 4'b0111; // XORI
                    3'b001: alu_control = 4'b0011; // SLLI
                    3'b101: begin
                        alu_control = 4'b0101; 
                        sgn = (funct7 == 7'b0100000); // SRLI/SRAI
                    end
                    3'b010: begin
                        alu_control = 4'b1000; 
                        sgn = 1'b1; // SLTI
                    end
                    3'b011: begin
                        alu_control = 4'b1000; 
                        sgn = 1'b0; // SLTIU
                    end
                    default: alu_control = 4'b0000;
                endcase
            end

            7'b0000011: begin // Load
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;  // address = reg + imm
                alu_control = 4'b0010; // ADD to calculate address
            end

            7'b0100011: begin // Store
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_control = 4'b0010; // ADD to calculate address
            end

            7'b1100011: begin // Branch
                branch = 1'b1;
                alu_src = 1'b0; // compare reg-reg
                alu_control = 4'b1000; // set less than for comparison (or you can customize)
                pc_src = 2'b01; // branch taken address
            end

            7'b1101111: begin // JAL
                jump = 1'b1;
                reg_write = 1'b1;
                alu_src = 1'b1; // use imm for PC calculation
                pc_src = 2'b10; // jump target
            end

            7'b1100111: begin // JALR
                jump = 1'b1;
                reg_write = 1'b1;
                alu_src = 1'b1;
                pc_src = 2'b10;
            end

            default: begin
                // default no-op
            end
        endcase
    end
endmodule
