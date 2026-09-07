// tb_alu_control.v
// Self-checking testbench for alu_control.v
// Verifies ALUOp=00 -> ADD, ALUOp=01 -> SUB regardless of funct3/funct7,
// and ALUOp=10 -> correct funct3/funct7 decode for every R/I-type op
// this design supports (ADD/SUB, AND, OR, XOR, SLT), plus an
// unrecognized funct3 under ALUOp=10 and an unused ALUOp encoding.

`timescale 1ns/1ps

module tb_alu_control;

    reg  [1:0] ALUOp;
    reg  [2:0] funct3;
    reg  [6:0] funct7;
    wire [2:0] alu_ctrl;

    integer errors = 0;
    integer checks = 0;

    localparam ADD = 3'b000,
               SUB = 3'b001,
               AND = 3'b010,
               OR  = 3'b011,
               XOR = 3'b100,
               SLT = 3'b101;

    alu_control dut (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .alu_ctrl(alu_ctrl)
    );

    task check(input [2:0] exp, input string name);
        begin
            checks = checks + 1;
            if (alu_ctrl !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: ALUOp=%b funct3=%b funct7=%b -> alu_ctrl=%b (expected %b)",
                          checks, name, ALUOp, funct3, funct7, alu_ctrl, exp);
            end
            else begin
                $display("PASS [%0d] %0s: ALUOp=%b funct3=%b funct7=%b -> alu_ctrl=%b",
                          checks, name, ALUOp, funct3, funct7, alu_ctrl);
            end
        end
    endtask

    initial begin
        $display("=== tb_alu_control: starting ===");

        // ALUOp = 00 (memory address calc): always ADD, funct3/funct7 don't matter
        ALUOp = 2'b00; funct3 = 3'b111; funct7 = 7'b1111111; #1;
        check(ADD, "ALUOp=00 (LW/SW addr) -> ADD, ignores funct3/funct7");

        ALUOp = 2'b00; funct3 = 3'b000; funct7 = 7'b0000000; #1;
        check(ADD, "ALUOp=00 with funct3/funct7=0 -> ADD");

        // ALUOp = 01 (branch compare): always SUB, funct3/funct7 don't matter
        ALUOp = 2'b01; funct3 = 3'b000; funct7 = 7'b0000000; #1;
        check(SUB, "ALUOp=01 funct3=000 (BEQ) -> SUB");

        ALUOp = 2'b01; funct3 = 3'b001; funct7 = 7'b1111111; #1;
        check(SUB, "ALUOp=01 funct3=001 (BNE) -> SUB, ignores funct7");

        // ALUOp = 10 (R/I-type): decode via funct3/funct7
        // funct3=000, funct7[5]=0 -> ADD (covers ADD and ADDI, since
        // ADDI's funct7 field doesn't exist / decoder forces it to 0)
        ALUOp = 2'b10; funct3 = 3'b000; funct7 = 7'b0000000; #1;
        check(ADD, "ALUOp=10 funct3=000 funct7[5]=0 -> ADD");

        // funct3=000, funct7[5]=1 -> SUB (R-type SUB only; funct7[5]=1
        // never occurs for ADDI since decoder zeroes funct7 for I-type)
        ALUOp = 2'b10; funct3 = 3'b000; funct7 = 7'b0100000; #1;
        check(SUB, "ALUOp=10 funct3=000 funct7[5]=1 -> SUB");

        // funct3=000, other funct7 bits set but bit5=0 -> still ADD
        ALUOp = 2'b10; funct3 = 3'b000; funct7 = 7'b0011011; #1;
        check(ADD, "ALUOp=10 funct3=000 funct7[5]=0 (other bits set) -> ADD");

        // AND: funct3 = 111
        ALUOp = 2'b10; funct3 = 3'b111; funct7 = 7'b0000000; #1;
        check(AND, "ALUOp=10 funct3=111 -> AND");

        // OR: funct3 = 110
        ALUOp = 2'b10; funct3 = 3'b110; funct7 = 7'b0000000; #1;
        check(OR, "ALUOp=10 funct3=110 -> OR");

        // XOR: funct3 = 100
        ALUOp = 2'b10; funct3 = 3'b100; funct7 = 7'b0000000; #1;
        check(XOR, "ALUOp=10 funct3=100 -> XOR");

        // SLT: funct3 = 010
        ALUOp = 2'b10; funct3 = 3'b010; funct7 = 7'b0000000; #1;
        check(SLT, "ALUOp=10 funct3=010 -> SLT");

        // Unsupported funct3 under ALUOp=10 (e.g. 011=SLTU, 001=SLL,
        // 101=SRL/SRA) -> falls to default -> ADD. This design does not
        // implement these RV32I ops; documents current (incomplete) behavior.
        ALUOp = 2'b10; funct3 = 3'b011; funct7 = 7'b0000000; #1;
        check(ADD, "ALUOp=10 funct3=011 (SLTU, unimplemented) -> default ADD");

        ALUOp = 2'b10; funct3 = 3'b001; funct7 = 7'b0000000; #1;
        check(ADD, "ALUOp=10 funct3=001 (SLL, unimplemented) -> default ADD");

        ALUOp = 2'b10; funct3 = 3'b101; funct7 = 7'b0000000; #1;
        check(ADD, "ALUOp=10 funct3=101 (SRL/SRA, unimplemented) -> default ADD");

        // Unused ALUOp encoding (2'b11) -> default -> ADD
        ALUOp = 2'b11; funct3 = 3'b111; funct7 = 7'b1111111; #1;
        check(ADD, "ALUOp=11 (unused encoding) -> default ADD");

        $display("=== tb_alu_control: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_ALU_CONTROL: ALL TESTS PASSED ***");
        else              $display("*** TB_ALU_CONTROL: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
