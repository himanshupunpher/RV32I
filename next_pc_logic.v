module next_pc_logic (
    input [31:0] PC,
    input [31:0] imm,
    input [31:0] alu_result,
    input zero,
    input [2:0] funct3,
    input Branch,
    input Jump,
    input JumpType,
    output reg [31:0] next_pc
);
    reg branch_taken;
    always @(*) begin
        branch_taken = (funct3[0]==0) ? zero : ~zero;
        if (Jump) begin
            next_pc = JumpType ? alu_result : (PC + imm);
        end
        else if (Branch && branch_taken) begin
            next_pc = PC + imm;
        end
        else begin
            next_pc = PC + 4;
        end
    end
    
endmodule