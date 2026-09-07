module alu_control (
    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg [2:0] alu_ctrl
);
    localparam ADD = 3'b000,
               SUB = 3'b001,
               AND = 3'b010,
               OR = 3'b011,
               XOR = 3'b100,
               SLT = 3'b101;

    always@(*)begin
        case(ALUOp)
        2'b00: alu_ctrl = ADD;
        2'b01: alu_ctrl = SUB;
        2'b10: begin
            case(funct3)
                3'b000: alu_ctrl = (funct7[5]) ? SUB : ADD;
                3'b111: alu_ctrl = AND;
                3'b110: alu_ctrl = OR;
                3'b100: alu_ctrl = XOR;
                3'b010: alu_ctrl = SLT;
                default: alu_ctrl = ADD;
            endcase
        end
        default: alu_ctrl = ADD;
        endcase
    end
endmodule