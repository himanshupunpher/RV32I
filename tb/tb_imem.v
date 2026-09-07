// tb_imem.v
// Self-checking testbench for imem.v (IMEM)
// Checks: port A synchronous write (bootloader path), port B
// combinational read (core fetch path, must reflect writes with no
// clock edge needed), independence of the two ports at different
// addresses, we_a=0 blocking writes, and read-your-write ordering.

`timescale 1ns/1ps

module tb_imem;

    reg clk;
    reg we_a;
    reg  [9:0] addr_a;
    reg  [31:0] data_a;
    reg  [9:0] addr_b;
    wire [31:0] data_b;

    integer errors = 0;
    integer checks = 0;

    IMEM dut (
        .clk(clk),
        .we_a(we_a),
        .addr_a(addr_a),
        .data_a(data_a),
        .addr_b(addr_b),
        .data_b(data_b)
    );

    always #5 clk = ~clk;

    task check(input [31:0] exp, input string name);
        begin
            checks = checks + 1;
            if (data_b !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: data_b=%h (expected %h)", checks, name, data_b, exp);
            end
            else begin
                $display("PASS [%0d] %0s: data_b=%h", checks, name, data_b);
            end
        end
    endtask

    task write_word(input [9:0] addr, input [31:0] data);
        begin
            addr_a = addr; data_a = data; we_a = 1;
            @(posedge clk);
            #1;
            we_a = 0;
        end
    endtask

    initial begin
        $display("=== tb_imem: starting ===");
        clk = 0; we_a = 0; addr_a = 0; data_a = 0; addr_b = 0;
        #1;

        // Unwritten location: memory is not initialized by the DUT itself,
        // so we write known values everywhere we check rather than assume
        // a power-on state (avoids relying on simulator X/0 default, which
        // is not something real hardware guarantees either).

        // Write instruction word 0x00A00093 (ADDI x1,x0,10) at word address 0
        write_word(10'd0, 32'h00A00093);
        addr_b = 10'd0; #1;
        check(32'h00A00093, "port B combinationally reads word just written via port A, addr=0");

        // Write a second instruction at a different address
        write_word(10'd1, 32'h00100113); // ADDI x2,x0,1 (word addr 1 = byte addr 4)
        addr_b = 10'd1; #1;
        check(32'h00100113, "port B reads second instruction at addr=1");

        // Confirm first word is still intact (no aliasing between addresses)
        addr_b = 10'd0; #1;
        check(32'h00A00093, "first instruction unaffected by second write");

        // Port B read is purely combinational: changing addr_b must update
        // data_b immediately without waiting for a clock edge.
        addr_b = 10'd1; #1;
        check(32'h00100113, "port B read updates immediately on addr_b change (no clk edge)");

        // we_a=0 must not write, even if addr_a/data_a happen to be driven
        addr_a = 10'd0; data_a = 32'hFFFFFFFF; we_a = 0;
        @(posedge clk); #1;
        addr_b = 10'd0; #1;
        check(32'h00A00093, "we_a=0 blocks write; addr 0 retains original instruction");

        // Write at the top of the address range (addr_a is 10 bits -> max 1023)
        write_word(10'd1023, 32'hDEADC0DE);
        addr_b = 10'd1023; #1;
        check(32'hDEADC0DE, "write/read at top address 1023 (4KB boundary) works");

        // Overwrite an existing location with a new value
        write_word(10'd0, 32'h00000013); // NOP (ADDI x0,x0,0)
        addr_b = 10'd0; #1;
        check(32'h00000013, "overwrite of addr 0 takes effect (new instruction replaces old)");

        $display("=== tb_imem: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_IMEM: ALL TESTS PASSED ***");
        else              $display("*** TB_IMEM: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
