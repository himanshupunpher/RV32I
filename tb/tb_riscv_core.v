// tb_riscv_core.v
// Integration testbench for the full riscv_core single-cycle datapath.
// Preloads IMEM directly (hierarchical reference into the DUT's
// IMEM_inst.sdata array) since the top-level module has no external
// load path yet -- addr_a/data_a are tied off in riscv_core.v pending
// the UART bootloader mentioned in imem.v's header comment.
//
// The test program below exercises, in one straight-line run:
//   ADDI, ADD, SUB, AND, OR, XOR, SLT, SW, LW, BEQ (taken),
//   BNE (taken), JAL, JALR
// and checks:
//   - not-taken-vs-taken branch/jump control flow (skipped instructions
//     must never execute / must never corrupt their target register)
//   - correct ALU results for every supported op
//   - a store followed by a load round-trips through DMEM
//   - JAL/JALR link-register (PC+4) values are correct
//   - registers that are never written stay at their reset value of 0
//
// See assemble.py (not part of the deliverable, used only to generate
// the machine code below) for the corresponding assembly source.

`timescale 1ns/1ps

module tb_riscv_core;

    reg clk, reset;

    integer errors = 0;
    integer checks = 0;

    riscv_core dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    // Preload one instruction word into the DUT's instruction memory array.
    // byte_addr is a normal RV32 byte address (must be 4-byte aligned);
    // sdata[] is word-indexed (matches the core's PC[11:2] fetch address),
    // so we convert here.
    task imem_preload(input [11:0] byte_addr, input [31:0] instr);
        begin
            dut.IMEM_inst.sdata[byte_addr[11:2]] = instr;
        end
    endtask

    task check_reg(input [4:0] regnum, input [31:0] exp, input string name);
        reg [31:0] actual;
        begin
            checks = checks + 1;
            actual = dut.regfile_inst.regs[regnum];
            if (actual !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: x%0d=%h (expected %h)", checks, name, regnum, actual, exp);
            end
            else begin
                $display("PASS [%0d] %0s: x%0d=%h", checks, name, regnum, actual);
            end
        end
    endtask

    task check_mem(input [9:0] word_addr, input [31:0] exp, input string name);
        reg [31:0] actual;
        begin
            checks = checks + 1;
            actual = dut.DMEM_inst.sdata[word_addr];
            if (actual !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: mem[%0d]=%h (expected %h)", checks, name, word_addr, actual, exp);
            end
            else begin
                $display("PASS [%0d] %0s: mem[%0d]=%h", checks, name, word_addr, actual);
            end
        end
    endtask

    initial begin
        $display("=== tb_riscv_core: starting ===");

        clk = 0;
        reset = 1;

        // ---- load test program into instruction memory ----
        imem_preload(  0, 32'h00500093); // ADDI x1, x0, 5
        imem_preload(  4, 32'h00A00113); // ADDI x2, x0, 10
        imem_preload(  8, 32'h002081B3); // ADD  x3, x1, x2
        imem_preload( 12, 32'h40110233); // SUB  x4, x2, x1
        imem_preload( 16, 32'h0020F2B3); // AND  x5, x1, x2
        imem_preload( 20, 32'h0020E333); // OR   x6, x1, x2
        imem_preload( 24, 32'h0020C3B3); // XOR  x7, x1, x2
        imem_preload( 28, 32'h0020A433); // SLT  x8, x1, x2
        imem_preload( 32, 32'h00302023); // SW   x3, 0(x0)
        imem_preload( 36, 32'h00002483); // LW   x9, 0(x0)
        imem_preload( 40, 32'h00108463); // BEQ  x1, x1, +8   (taken)
        imem_preload( 44, 32'h3E700513); // ADDI x10, x0, 999 (must be skipped)
        imem_preload( 48, 32'h06F00513); // ADDI x10, x0, 111 (branch target)
        imem_preload( 52, 32'h00209463); // BNE  x1, x2, +8   (taken)
        imem_preload( 56, 32'h3E700593); // ADDI x11, x0, 999 (must be skipped)
        imem_preload( 60, 32'h0DE00593); // ADDI x11, x0, 222 (branch target)
        imem_preload( 64, 32'h0080066F); // JAL  x12, +8
        imem_preload( 68, 32'h3E700693); // ADDI x13, x0, 999 (must be skipped)
        imem_preload( 72, 32'h05400713); // ADDI x14, x0, 84  (JALR target addr)
        imem_preload( 76, 32'h000707E7); // JALR x15, 0(x14)
        imem_preload( 80, 32'h3E700813); // ADDI x16, x0, 999 (must be skipped)
        imem_preload( 84, 32'h14D00893); // ADDI x17, x0, 333 (JALR landing pad)
        imem_preload( 88, 32'h0000006F); // JAL  x0, 0        (halt: self-loop)

        // Release reset synchronously with the clock, PC starts at 0
        @(negedge clk);
        reset = 0;

        // 23 instructions before the halt loop; run extra cycles to be safe,
        // then land on the halt loop and let it settle.
        repeat (30) @(negedge clk);

        $display("-- Final PC check --");
        checks = checks + 1;
        if (dut.PC !== 32'd88) begin
            errors = errors + 1;
            $display("FAIL [%0d] PC parked on halt loop at addr 88: PC=%h (expected 00000058)", checks, dut.PC);
        end else begin
            $display("PASS [%0d] PC parked on halt loop at addr 88: PC=%h", checks, dut.PC);
        end

        $display("-- ALU op results (ADDI/ADD/SUB/AND/OR/XOR/SLT) --");
        check_reg(1,  32'd5,   "x1 = ADDI 5");
        check_reg(2,  32'd10,  "x2 = ADDI 10");
        check_reg(3,  32'd15,  "x3 = ADD x1+x2 = 15");
        check_reg(4,  32'd5,   "x4 = SUB x2-x1 = 5");
        check_reg(5,  32'd0,   "x5 = AND(5,10) = 0");
        check_reg(6,  32'd15,  "x6 = OR(5,10) = 15");
        check_reg(7,  32'd15,  "x7 = XOR(5,10) = 15");
        check_reg(8,  32'd1,   "x8 = SLT(5,10) = 1");

        $display("-- Load/Store round-trip --");
        check_mem(0, 32'd15, "DMEM[0] = 15 (from SW x3)");
        check_reg(9, 32'd15, "x9 = LW from DMEM[0] = 15");

        $display("-- Control flow: BEQ/BNE taken, skipped instructions never executed --");
        check_reg(10, 32'd111, "x10 = 111 (BEQ taken -> skipped ADDI x10,999 never ran)");
        check_reg(11, 32'd222, "x11 = 222 (BNE taken -> skipped ADDI x11,999 never ran)");

        $display("-- JAL / JALR link register and target --");
        check_reg(12, 32'd68,  "x12 = PC+4 = 68 (JAL link register, ADDI x13,999 at 68 skipped)");
        check_reg(13, 32'd0,   "x13 = 0 (never executed, must remain reset value)");
        check_reg(14, 32'd84,  "x14 = 84 (JALR target address literal)");
        check_reg(15, 32'd80,  "x15 = PC+4 = 80 (JALR link register, ADDI x16,999 at 80 skipped)");
        check_reg(16, 32'd0,   "x16 = 0 (never executed, must remain reset value)");
        check_reg(17, 32'd333, "x17 = 333 (JALR landing pad reached correctly)");

        $display("-- x0 sanity --");
        check_reg(0, 32'd0, "x0 always reads 0 (hardwired, JAL x0 as halt link never corrupts it)");

        $display("=== tb_riscv_core: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_RISCV_CORE: ALL TESTS PASSED ***");
        else              $display("*** TB_RISCV_CORE: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

    // Safety watchdog in case the core hangs somewhere unexpected
    initial begin
        #2000;
        if (!$test$plusargs("no_timeout")) begin
            $display("!!! WATCHDOG TIMEOUT: simulation did not finish in time !!!");
            $finish;
        end
    end

endmodule
