// tb_writeback_mux.v
// Self-checking testbench for writeback_mux.v
// Covers all 3 used MemtoReg encodings (00/01/10) plus the unused
// 11 encoding to confirm it falls through to the pc_plus_4 branch
// (documents current behavior of the ternary chain, not a spec requirement).

`timescale 1ns/1ps

module tb_writeback_mux;

    reg  [31:0] alu_result, dmem_data, pc_plus_4;
    reg  [1:0]  MemtoReg;
    wire [31:0] wb_data;

    integer errors = 0;
    integer checks = 0;

    writeback_mux dut (
        .alu_result(alu_result),
        .dmem_data(dmem_data),
        .pc_plus_4(pc_plus_4),
        .MemtoReg(MemtoReg),
        .wb_data(wb_data)
    );

    task check(input [31:0] exp, input string name);
        begin
            checks = checks + 1;
            if (wb_data !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: MemtoReg=%b -> wb_data=%h (expected %h)",
                          checks, name, MemtoReg, wb_data, exp);
            end
            else begin
                $display("PASS [%0d] %0s: MemtoReg=%b -> wb_data=%h",
                          checks, name, MemtoReg, wb_data);
            end
        end
    endtask

    initial begin
        $display("=== tb_writeback_mux: starting ===");

        alu_result = 32'h1111_1111;
        dmem_data  = 32'h2222_2222;
        pc_plus_4  = 32'h3333_3333;

        MemtoReg = 2'b00; #1;
        check(32'h1111_1111, "MemtoReg=00 selects alu_result (R-type/I-type ALU)");

        MemtoReg = 2'b01; #1;
        check(32'h2222_2222, "MemtoReg=01 selects dmem_data (LW)");

        MemtoReg = 2'b10; #1;
        check(32'h3333_3333, "MemtoReg=10 selects pc_plus_4 (JAL/JALR)");

        MemtoReg = 2'b11; #1;
        check(32'h3333_3333, "MemtoReg=11 (unused) falls through to pc_plus_4");

        $display("=== tb_writeback_mux: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_WRITEBACK_MUX: ALL TESTS PASSED ***");
        else              $display("*** TB_WRITEBACK_MUX: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
