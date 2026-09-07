// tb_next_pc_logic.v
// Self-checking testbench for next_pc_logic.v
// Checks priority (Jump > Branch-taken > PC+4), JAL vs JALR target
// calc, BEQ (funct3[0]=0, wants zero=1) vs BNE (funct3[0]=1, wants
// zero=0) taken/not-taken combinations, and that Branch=0 or a
// not-taken branch falls through to PC+4.

`timescale 1ns/1ps

module tb_next_pc_logic;

    reg  [31:0] PC, imm, alu_result;
    reg  zero;
    reg  [2:0] funct3;
    reg  Branch, Jump, JumpType;
    wire [31:0] next_pc;

    integer errors = 0;
    integer checks = 0;

    next_pc_logic dut (
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

    task check(input [31:0] exp, input string name);
        begin
            checks = checks + 1;
            if (next_pc !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: next_pc=%h (expected %h)", checks, name, next_pc, exp);
            end
            else begin
                $display("PASS [%0d] %0s: next_pc=%h", checks, name, next_pc);
            end
        end
    endtask

    initial begin
        $display("=== tb_next_pc_logic: starting ===");

        // Default fall-through: no jump, no branch -> PC+4
        PC = 32'h1000; imm = 32'h100; alu_result = 32'hFFFF0000; zero = 0;
        funct3 = 3'b000; Branch = 0; Jump = 0; JumpType = 0; #1;
        check(32'h1004, "no Jump/Branch -> PC+4");

        // Branch=1 but not taken (BEQ, zero=0) -> PC+4
        PC = 32'h2000; imm = 32'h40; zero = 0; funct3 = 3'b000; // BEQ wants zero=1
        Branch = 1; Jump = 0; #1;
        check(32'h2004, "BEQ not taken (zero=0) -> PC+4");

        // Branch=1, taken (BEQ, zero=1) -> PC+imm
        PC = 32'h2000; imm = 32'h40; zero = 1; funct3 = 3'b000;
        Branch = 1; Jump = 0; #1;
        check(32'h2040, "BEQ taken (zero=1) -> PC+imm");

        // BNE: funct3[0]=1, wants zero=0 to take the branch
        PC = 32'h3000; imm = -32'sd8; zero = 0; funct3 = 3'b001; // BNE, not equal
        Branch = 1; Jump = 0; #1;
        check(32'h2FF8, "BNE taken (zero=0) -> PC+imm (negative offset, backward branch)");

        // BNE not taken: zero=1 means operands were equal, BNE should not branch
        PC = 32'h3000; imm = -32'sd8; zero = 1; funct3 = 3'b001;
        Branch = 1; Jump = 0; #1;
        check(32'h3004, "BNE not taken (zero=1, operands equal) -> PC+4");

        // Jump=1, JumpType=0 (JAL): target = PC + imm, alu_result ignored
        PC = 32'h4000; imm = 32'h200; alu_result = 32'hBAD0BAD0;
        Jump = 1; JumpType = 0; Branch = 0; #1;
        check(32'h4200, "JAL: target = PC + imm (alu_result ignored)");

        // Jump=1, JumpType=1 (JALR): target = alu_result (rs1+imm computed by ALU), PC/imm ignored for target
        PC = 32'h5000; imm = 32'hDEAD; alu_result = 32'h0000_6000;
        Jump = 1; JumpType = 1; Branch = 0; #1;
        check(32'h0000_6000, "JALR: target = alu_result (PC/imm not used directly)");

        // Priority: Jump=1 AND Branch=1 simultaneously -> Jump wins
        // (control unit never asserts both at once in practice, but this
        // checks the priority encoding is implemented as documented)
        PC = 32'h7000; imm = 32'h10; alu_result = 32'h9999_0000; zero = 1;
        funct3 = 3'b000; Branch = 1; Jump = 1; JumpType = 1; #1;
        check(32'h9999_0000, "Jump takes priority over Branch when both asserted");

        // JALR target with alu_result = 0 (edge case, e.g. return-to-address-0)
        PC = 32'h8000; alu_result = 32'h0; Jump = 1; JumpType = 1; Branch = 0; #1;
        check(32'h0, "JALR target can be address 0");

        // Branch taken with imm=0 (degenerate self-loop branch)
        PC = 32'hA000; imm = 32'h0; zero = 1; funct3 = 3'b000;
        Jump = 0; Branch = 1; #1;
        check(32'hA000, "BEQ taken with imm=0 -> next_pc = PC (self-loop)");

        $display("=== tb_next_pc_logic: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_NEXT_PC_LOGIC: ALL TESTS PASSED ***");
        else              $display("*** TB_NEXT_PC_LOGIC: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
