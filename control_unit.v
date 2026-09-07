module control_unit (
    input [6:0] opcode,
    output reg RegWrite,
    output reg ALUSrc,
    output reg MemRead,
    output reg MemWrite,
    output reg Branch,
    output reg Jump,
    output reg JumpType,
    output reg [1:0] MemtoReg,
    output reg [1:0] ALUOp
);
    always@(*) begin
        case (opcode)
            7'b0110011: begin //R-type
                RegWrite = 1;
                ALUSrc = 0;
                MemRead = 0;
                MemWrite = 0;
                MemtoReg = 2'b00;
                Branch = 0;
                Jump = 0;
                JumpType = 0;
                ALUOp = 2'b10;
            end
            7'b0010011: begin //ADDI
                RegWrite = 1;
                ALUSrc = 1;
                MemRead = 0;
                MemWrite = 0;
                MemtoReg = 2'b00;
                Branch = 0;
                Jump = 0;
                JumpType = 0;
                ALUOp = 2'b10;
            end
            7'b0000011: begin //LW
                RegWrite = 1;
                ALUSrc = 1;
                MemRead = 1;
                MemWrite = 0;
                MemtoReg = 2'b01;
                Branch = 0;
                Jump = 0;
                JumpType = 0;
                ALUOp = 2'b00;
            end
            7'b0100011: begin //SW
                RegWrite = 0;
                ALUSrc = 1;
                MemRead = 0;
                MemWrite = 1;
                MemtoReg = 2'b00;
                Branch = 0;
                Jump = 0;
                JumpType = 0;
                ALUOp = 2'b00;
            end
            7'b1100011: begin //BEQ/BNE
                RegWrite = 0;
                ALUSrc = 0;
                MemRead = 0;
                MemWrite = 0;
                MemtoReg = 2'b00;
                Branch = 1;
                Jump = 0;
                JumpType = 0;
                ALUOp = 2'b01;
            end
            7'b1101111: begin //JAl
                RegWrite = 1;
                ALUSrc = 0;
                MemRead = 0;
                MemWrite = 0;
                MemtoReg = 2'b10;
                Branch = 0;
                Jump = 1;
                JumpType = 0;
                ALUOp = 2'b00;
            end
            7'b1100111: begin //JAlR
                RegWrite = 1;
                ALUSrc = 1;
                MemRead = 0;
                MemWrite = 0;
                MemtoReg = 2'b10;
                Branch = 0;
                Jump = 1;
                JumpType = 1;
                ALUOp = 2'b00;
            end
            default: begin
                RegWrite = 0;
                ALUSrc = 0;
                MemRead = 0;
                MemWrite = 0;
                MemtoReg = 2'b00;
                Branch = 0;
                Jump = 0;
                JumpType = 0;
                ALUOp = 2'b00;
            end
        endcase
    end
    
endmodule