// tb_alu.v
// Self-checking testbench for alu.v
// Exercises every alu_ctrl opcode (ADD, SUB, AND, OR, XOR, SLT) with
// directed corner cases (overflow/underflow, negative operands, zero
// result) plus the default/unused-code case, and checks the zero flag.

`timescale 1ns/1ps

module tb_alu;

    reg  [31:0] a, b;
    reg  [2:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    integer errors = 0;
    integer checks = 0;

    localparam ADD = 3'b000,
               SUB = 3'b001,
               AND = 3'b010,
               OR  = 3'b011,
               XOR = 3'b100,
               SLT = 3'b101,
               UNUSED = 3'b110;

    alu dut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    task check(input [31:0] exp_result, input exp_zero, input string name);
        begin
            checks = checks + 1;
            if (result !== exp_result || zero !== exp_zero) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: a=%h b=%h ctrl=%b -> result=%h zero=%b (expected result=%h zero=%b)",
                          checks, name, a, b, alu_ctrl, result, zero, exp_result, exp_zero);
            end
            else begin
                $display("PASS [%0d] %0s: a=%h b=%h ctrl=%b -> result=%h zero=%b",
                          checks, name, a, b, alu_ctrl, result, zero);
            end
        end
    endtask

    initial begin
        $display("=== tb_alu: starting ===");

        // ADD: simple
        a = 32'd10; b = 32'd20; alu_ctrl = ADD; #1;
        check(32'd30, 1'b0, "ADD 10+20");

        // ADD: overflow wraps (unsigned arithmetic mod 2^32)
        a = 32'hFFFFFFFF; b = 32'd1; alu_ctrl = ADD; #1;
        check(32'h00000000, 1'b1, "ADD wraparound -1+1=0");

        // ADD: negative + negative
        a = -32'sd5; b = -32'sd7; alu_ctrl = ADD; #1;
        check(-32'sd12, 1'b0, "ADD -5+-7");

        // SUB: simple
        a = 32'd50; b = 32'd20; alu_ctrl = SUB; #1;
        check(32'd30, 1'b0, "SUB 50-20");

        // SUB: result zero (used by BEQ)
        a = 32'd77; b = 32'd77; alu_ctrl = SUB; #1;
        check(32'd0, 1'b1, "SUB equal operands -> zero flag");

        // SUB: negative result (used by BNE, result nonzero)
        a = 32'd5; b = 32'd10; alu_ctrl = SUB; #1;
        check(-32'sd5, 1'b0, "SUB 5-10 negative result");

        // AND
        a = 32'hFF00FF00; b = 32'h0F0F0F0F; alu_ctrl = AND; #1;
        check(32'h0F000F00, 1'b0, "AND");

        // AND -> zero
        a = 32'hFF00FF00; b = 32'h00FF00FF; alu_ctrl = AND; #1;
        check(32'h00000000, 1'b1, "AND disjoint bits -> zero");

        // OR
        a = 32'hFF00FF00; b = 32'h00FF00FF; alu_ctrl = OR; #1;
        check(32'hFFFFFFFF, 1'b0, "OR");

        // XOR
        a = 32'hAAAAAAAA; b = 32'h55555555; alu_ctrl = XOR; #1;
        check(32'hFFFFFFFF, 1'b0, "XOR alternating bits");

        // XOR -> zero (identical operands)
        a = 32'hDEADBEEF; b = 32'hDEADBEEF; alu_ctrl = XOR; #1;
        check(32'h00000000, 1'b1, "XOR identical -> zero");

        // SLT: signed less-than true
        a = -32'sd1; b = 32'd1; alu_ctrl = SLT; #1;
        check(32'd1, 1'b0, "SLT -1 < 1 (signed) -> 1");

        // SLT: signed comparison, not unsigned.
        // a = 0xFFFFFFFF is -1 when interpreted as signed, so -1 < 0 is TRUE.
        // (An unsigned comparator would wrongly say 0xFFFFFFFF > 0 -> false.)
        a = 32'hFFFFFFFF; b = 32'h00000000; alu_ctrl = SLT; #1;
        check(32'd1, 1'b0, "SLT signed -1 < 0 -> 1 (must not be treated as unsigned)");

        // SLT: false case, positive > positive
        a = 32'd100; b = 32'd50; alu_ctrl = SLT; #1;
        check(32'd0, 1'b1, "SLT 100 < 50 -> 0 (zero flag: result==0)");

        // SLT: equal operands -> false (not strictly less than)
        a = 32'd42; b = 32'd42; alu_ctrl = SLT; #1;
        check(32'd0, 1'b1, "SLT equal operands -> 0");

        // Default/unused alu_ctrl code -> result forced to 0
        a = 32'hDEADBEEF; b = 32'hCAFEBABE; alu_ctrl = UNUSED; #1;
        check(32'd0, 1'b1, "Unused alu_ctrl code -> default result 0");

        $display("=== tb_alu: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_ALU: ALL TESTS PASSED ***");
        else              $display("*** TB_ALU: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
