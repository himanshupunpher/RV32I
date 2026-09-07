module riscv_core (
    input clk,
    input reset
);
    wire [31:0] next_pc;
    wire [31:0] PC;
    wire [31:0] instruction;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] rdata1;
    wire [31:0] rdata2;
    wire [31:0] wdata;
    wire [31:0] imm;
    wire [31:0] alu_result;
    wire RegWrite;
    wire ALUSrc;
    wire MemRead;
    wire MemWrite;
    wire [1:0] MemtoReg;
    wire [1:0] ALUOp;
    wire [2:0] alu_ctrl;
    wire [31:0] b;
    wire we;
    wire zero;
    wire Branch;
    wire Jump;
    wire JumpType;
    wire [31:0] dmem_data;
    wire [31:0] pc_plus_4;
    wire [31:0] wb_data;

    assign pc_plus_4 = PC + 32'd4;

    pc_reg pc_reg_inst(
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .PC(PC)
    );

    IMEM IMEM_inst(
        .clk(clk),
        .we_a(1'b0),
        .addr_a(1'b0),     
        .data_a(1'b0),     
        .addr_b(PC[11:2]),      
        .data_b(instruction)
    );

    next_pc_logic next_pc_logic_inst(
        .PC(PC),
        .imm(imm),
        .alu_result(alu_result),
        .zero(zero),
        .funct3(funct3),
        .Branch(Branch),
        .Jump(Jump),
        .JumpType(JumpType),
        .next_pc(next_pc)
    );

    decoder decoder_inst(
        .instruction(instruction),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .funct7(funct7),
        .imm(imm)
    );  

    regfile regfile_inst(
        .clk(clk),
        .we(RegWrite),               
        .rs1(rs1),        
        .rs2(rs2),       
        .rd(rd),         
        .wdata(wb_data),     
        .rdata1(rdata1),   
        .rdata2(rdata2)    
    );

    control_unit control_unit_inst(
        .opcode(opcode),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Jump(Jump),
        .JumpType(JumpType),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp)
    );

    alu_control alu_control_inst(
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .alu_ctrl(alu_ctrl)
    );

    alu alu_inst(
        .a(rdata1),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    alu_src_mux alu_src_mux_inst(
        .rdata2(rdata2),
        .imm(imm),
        .ALUSrc(ALUSrc),
        .alu_b(b)
    );



    DMEM DMEM_inst(
        .clk(clk),
        .we(MemWrite),
        .addr(alu_result[11:2]),
        .wdata(rdata2),
        .rdata(dmem_data)
    );


    writeback_mux writeback_mux_inst(
        .alu_result(alu_result),
        .dmem_data(dmem_data),
        .pc_plus_4(pc_plus_4),
        .MemtoReg(MemtoReg),
        .wb_data(wb_data)
);

endmodule