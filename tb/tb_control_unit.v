// tb_control_unit.v
// Self-checking testbench for control_unit.v
// Checks the full control-signal vector for every supported opcode
// (R-type, ADDI, LW, SW, BEQ/BNE, JAL, JALR) plus an unsupported
// opcode (default case, all signals must be safely de-asserted).

`timescale 1ns/1ps

module tb_control_unit;

    reg  [6:0] opcode;
    wire RegWrite, ALUSrc, MemRead, MemWrite, Branch, Jump, JumpType;
    wire [1:0] MemtoReg, ALUOp;

    integer errors = 0;
    integer checks = 0;

    control_unit dut (
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

    task check(
        input exp_RegWrite, input exp_ALUSrc, input exp_MemRead, input exp_MemWrite,
        input exp_Branch, input exp_Jump, input exp_JumpType,
        input [1:0] exp_MemtoReg, input [1:0] exp_ALUOp, input string name
    );
        reg pass;
        begin
            checks = checks + 1;
            pass = (RegWrite === exp_RegWrite) && (ALUSrc === exp_ALUSrc) &&
                   (MemRead === exp_MemRead) && (MemWrite === exp_MemWrite) &&
                   (Branch === exp_Branch) && (Jump === exp_Jump) &&
                   (JumpType === exp_JumpType) && (MemtoReg === exp_MemtoReg) &&
                   (ALUOp === exp_ALUOp);
            if (!pass) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: opcode=%b", checks, name, opcode);
                $display("       got     : RegWrite=%b ALUSrc=%b MemRead=%b MemWrite=%b Branch=%b Jump=%b JumpType=%b MemtoReg=%b ALUOp=%b",
                          RegWrite, ALUSrc, MemRead, MemWrite, Branch, Jump, JumpType, MemtoReg, ALUOp);
                $display("       expected: RegWrite=%b ALUSrc=%b MemRead=%b MemWrite=%b Branch=%b Jump=%b JumpType=%b MemtoReg=%b ALUOp=%b",
                          exp_RegWrite, exp_ALUSrc, exp_MemRead, exp_MemWrite, exp_Branch, exp_Jump, exp_JumpType, exp_MemtoReg, exp_ALUOp);
            end
            else begin
                $display("PASS [%0d] %0s: opcode=%b -> RegWrite=%b ALUSrc=%b MemRead=%b MemWrite=%b Branch=%b Jump=%b JumpType=%b MemtoReg=%b ALUOp=%b",
                          checks, name, opcode, RegWrite, ALUSrc, MemRead, MemWrite, Branch, Jump, JumpType, MemtoReg, ALUOp);
            end
        end
    endtask

    initial begin
        $display("=== tb_control_unit: starting ===");

        // R-type
        opcode = 7'b0110011; #1;
        check(1,0,0,0, 0,0,0, 2'b00, 2'b10, "R-type (ADD/SUB/AND/OR/XOR/SLT)");

        // ADDI (I-type ALU)
        opcode = 7'b0010011; #1;
        check(1,1,0,0, 0,0,0, 2'b00, 2'b10, "ADDI");

        // LW
        opcode = 7'b0000011; #1;
        check(1,1,1,0, 0,0,0, 2'b01, 2'b00, "LW");

        // SW
        opcode = 7'b0100011; #1;
        check(0,1,0,1, 0,0,0, 2'b00, 2'b00, "SW");

        // BEQ/BNE (B-type; opcode alone doesn't distinguish, funct3 does downstream)
        opcode = 7'b1100011; #1;
        check(0,0,0,0, 1,0,0, 2'b00, 2'b01, "BEQ/BNE (B-type)");

        // JAL
        opcode = 7'b1101111; #1;
        check(1,0,0,0, 0,1,0, 2'b10, 2'b00, "JAL");

        // JALR
        opcode = 7'b1100111; #1;
        check(1,1,0,0, 0,1,1, 2'b10, 2'b00, "JALR");

        // Unsupported opcode -> default: everything safely off
        opcode = 7'b1111111; #1;
        check(0,0,0,0, 0,0,0, 2'b00, 2'b00, "unsupported opcode -> all signals de-asserted");

        // Another unsupported opcode (all zeros)
        opcode = 7'b0000000; #1;
        check(0,0,0,0, 0,0,0, 2'b00, 2'b00, "opcode=0000000 -> default (RegWrite must stay 0, no spurious writes)");

        $display("=== tb_control_unit: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_CONTROL_UNIT: ALL TESTS PASSED ***");
        else              $display("*** TB_CONTROL_UNIT: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
