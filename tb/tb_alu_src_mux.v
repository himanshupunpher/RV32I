// tb_alu_src_mux.v
// Self-checking testbench for alu_src_mux.v

`timescale 1ns/1ps

module tb_alu_src_mux;

    reg  [31:0] rdata2, imm;
    reg  ALUSrc;
    wire [31:0] alu_b;

    integer errors = 0;
    integer checks = 0;

    alu_src_mux dut (
        .rdata2(rdata2),
        .imm(imm),
        .ALUSrc(ALUSrc),
        .alu_b(alu_b)
    );

    task check(input [31:0] exp, input string name);
        begin
            checks = checks + 1;
            if (alu_b !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: rdata2=%h imm=%h ALUSrc=%b -> alu_b=%h (expected %h)",
                          checks, name, rdata2, imm, ALUSrc, alu_b, exp);
            end
            else begin
                $display("PASS [%0d] %0s: rdata2=%h imm=%h ALUSrc=%b -> alu_b=%h",
                          checks, name, rdata2, imm, ALUSrc, alu_b);
            end
        end
    endtask

    initial begin
        $display("=== tb_alu_src_mux: starting ===");

        rdata2 = 32'hAAAA_AAAA; imm = 32'h5555_5555; ALUSrc = 0; #1;
        check(32'hAAAA_AAAA, "ALUSrc=0 selects rdata2 (R-type)");

        rdata2 = 32'hAAAA_AAAA; imm = 32'h5555_5555; ALUSrc = 1; #1;
        check(32'h5555_5555, "ALUSrc=1 selects imm (I-type/LW/SW)");

        rdata2 = 32'h0; imm = -32'sd1; ALUSrc = 1; #1;
        check(32'hFFFF_FFFF, "ALUSrc=1 passes through negative imm unchanged");

        rdata2 = 32'hFFFF_FFFF; imm = 32'h0; ALUSrc = 0; #1;
        check(32'hFFFF_FFFF, "ALUSrc=0 passes through rdata2 unchanged");

        $display("=== tb_alu_src_mux: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_ALU_SRC_MUX: ALL TESTS PASSED ***");
        else              $display("*** TB_ALU_SRC_MUX: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
