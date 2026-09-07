// tb_pc_reg.v
// Self-checking testbench for pc_reg.v
// Checks: async reset forces PC to 0 immediately (independent of clk edge),
// normal synchronous load of next_pc on posedge clk, reset asserted mid-run
// asynchronously interrupts a pending update, and reset release behavior.

`timescale 1ns/1ps

module tb_pc_reg;

    reg clk, reset;
    reg  [31:0] next_pc;
    wire [31:0] PC;

    integer errors = 0;
    integer checks = 0;

    pc_reg dut (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .PC(PC)
    );

    always #5 clk = ~clk;

    task check(input [31:0] exp, input string name);
        begin
            checks = checks + 1;
            if (PC !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: PC=%h (expected %h) at time %0t", checks, name, PC, exp, $time);
            end
            else begin
                $display("PASS [%0d] %0s: PC=%h at time %0t", checks, name, PC, $time);
            end
        end
    endtask

    initial begin
        $display("=== tb_pc_reg: starting ===");
        clk = 0; reset = 0; next_pc = 32'hDEAD_BEEF;

        // Async reset asserted before any clock edge: PC must go to 0
        // immediately, without waiting for a clock edge.
        reset = 1; #1;
        check(32'h0, "async reset forces PC=0 immediately (no clk edge needed)");

        // Hold reset through a couple of clock edges: PC must stay 0
        // regardless of next_pc value.
        @(posedge clk); #1;
        check(32'h0, "PC stays 0 while reset held, even across posedge clk");

        // Release reset; PC should still be 0 until next posedge clk
        reset = 0; #1;
        check(32'h0, "PC stays 0 immediately after reset deasserted (no clk edge yet)");

        // Next posedge clk should load next_pc
        next_pc = 32'h0000_1000;
        @(posedge clk); #1;
        check(32'h0000_1000, "PC loads next_pc on first posedge clk after reset release");

        // Sequential loads
        next_pc = 32'h0000_1004;
        @(posedge clk); #1;
        check(32'h0000_1004, "PC loads next_pc on subsequent posedge clk");

        next_pc = 32'h0000_1008;
        @(posedge clk); #1;
        check(32'h0000_1008, "PC continues tracking next_pc each cycle");

        // Async reset mid-run: assert reset between clock edges (not at
        // a posedge) and confirm PC drops to 0 immediately, not on next edge.
        next_pc = 32'hFFFF_FFFF;
        @(negedge clk); // now safely between edges
        reset = 1; #1;
        check(32'h0, "mid-cycle async reset forces PC=0 without waiting for posedge clk");

        reset = 0;
        next_pc = 32'h0000_2000;
        @(posedge clk); #1;
        check(32'h0000_2000, "PC resumes loading next_pc after reset released again");

        $display("=== tb_pc_reg: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_PC_REG: ALL TESTS PASSED ***");
        else              $display("*** TB_PC_REG: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
