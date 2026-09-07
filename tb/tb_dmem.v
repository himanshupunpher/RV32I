// tb_dmem.v
// Self-checking testbench for dmem.v (DMEM)
// Checks: synchronous write gated by we, combinational (always-on)
// read that tracks addr immediately, we=0 blocking writes, and
// read-after-write ordering (address bus is shared between the two,
// unlike IMEM's dual-port design).

`timescale 1ns/1ps

module tb_dmem;

    reg clk, we;
    reg  [9:0] addr;
    reg  [31:0] wdata;
    wire [31:0] rdata;

    integer errors = 0;
    integer checks = 0;

    DMEM dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    task check(input [31:0] exp, input string name);
        begin
            checks = checks + 1;
            if (rdata !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: rdata=%h (expected %h)", checks, name, rdata, exp);
            end
            else begin
                $display("PASS [%0d] %0s: rdata=%h", checks, name, rdata);
            end
        end
    endtask

    task write_word(input [9:0] a, input [31:0] d);
        begin
            addr = a; wdata = d; we = 1;
            @(posedge clk);
            #1;
            we = 0;
        end
    endtask

    initial begin
        $display("=== tb_dmem: starting ===");
        clk = 0; we = 0; addr = 0; wdata = 0;
        #1;

        // Basic write then read (read is combinational and "always active",
        // so as soon as addr points at a written location, rdata reflects it)
        write_word(10'd0, 32'hAAAABBBB);
        addr = 10'd0; #1;
        check(32'hAAAABBBB, "read-back after write at addr 0");

        // Different address, confirm no aliasing
        write_word(10'd4, 32'h11112222);
        addr = 10'd4; #1;
        check(32'h11112222, "read-back after write at addr 4");
        addr = 10'd0; #1;
        check(32'hAAAABBBB, "addr 0 still intact after write to addr 4");

        // rdata is combinational: sweeping addr with no writes must update
        // rdata immediately (models LW hitting a location written earlier
        // by an SW at a different point in the program).
        addr = 10'd4; #1;
        check(32'h11112222, "combinational read tracks addr change immediately, no clk edge");

        // we=0: write must not occur
        addr = 10'd0; wdata = 32'hDEADDEAD; we = 0;
        @(posedge clk); #1;
        addr = 10'd0; #1;
        check(32'hAAAABBBB, "we=0 blocks write; addr 0 unchanged");

        // Overwrite existing location (simulates SW to a location a
        // previous SW already used, e.g. a stack slot reused)
        write_word(10'd0, 32'hCAFEF00D);
        addr = 10'd0; #1;
        check(32'hCAFEF00D, "overwrite of addr 0 takes effect");

        // Top of address range
        write_word(10'd1023, 32'h5A5A5A5A);
        addr = 10'd1023; #1;
        check(32'h5A5A5A5A, "write/read at top address 1023 (4KB boundary)");

        // Read-during-write: rdata is driven combinationally from addr,
        // reflecting the memory's current (pre-edge) contents; the pending
        // synchronous write becomes visible only after the clock edge.
        write_word(10'd8, 32'h00000001); // seed
        addr = 10'd8; wdata = 32'h00000002; we = 1; #1;
        check(32'h00000001, "rdata shows OLD contents while a write to the same addr is pending (pre-edge)");
        @(posedge clk); #1;
        we = 0;
        addr = 10'd8; #1;
        check(32'h00000002, "rdata shows NEW contents after the clock edge completes the write");

        $display("=== tb_dmem: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_DMEM: ALL TESTS PASSED ***");
        else              $display("*** TB_DMEM: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
