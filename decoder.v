module decoder (
    input [31:0] instruction,
    output [6:0] opcode,
    output reg [4:0] rs1,
    output reg[4:0] rs2,
    output reg[4:0] rd,
    output reg[2:0] funct3,
    output reg[6:0] funct7,
    output reg[31:0] imm
);  
    assign opcode = instruction[6:0];
    always @(*) begin
    case (opcode)
        7'b0110011: begin // R-type
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            rd  = instruction[11:7];
            funct3 = instruction[14:12];
            funct7 = instruction[31:25];
            imm = 32'b0;
        end
        7'b0010011, 7'b0000011, 7'b1100111: begin // I-type
            rs1 = instruction[19:15];
            rs2 = 5'b0;
            rd  = instruction[11:7];
            funct3 = instruction[14:12];
            funct7 = 7'b0;
            imm = {{20{instruction[31]}}, instruction[31:20]};
        end
        7'b0100011: begin //S-type
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            rd = 0;
            funct3 = instruction[14:12];
            funct7 = 0;
            imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        end
        7'b1100011: begin //B-type
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            rd = 0;
            funct3 = instruction[14:12];
            funct7 = 0;
            imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        end
        7'b1101111: begin //J-type
            rs1 = 0;
            rs2 = 0;
            rd = instruction[11:7];
            funct3 = 0;
            funct7 = 0;
            imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        end
        default: begin
            rs1 = 0;
            rs2 = 0;
            rd = 0;
            funct3 = 0;
            funct7 = 0;
            imm = 0;
        end
    endcase
end
endmodule
