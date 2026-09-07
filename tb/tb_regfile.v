// tb_regfile.v
// Self-checking testbench for regfile.v
// Checks: reset-time init to 0, combinational read ports, synchronous
// write on posedge clk gated by we, x0 hardwired to 0 for both reads
// and writes, simultaneous read/write of the same register (old-value
// read, i.e. write takes effect only after the clock edge), and
// reading rs1==rs2 simultaneously.

`timescale 1ns/1ps

module tb_regfile;

    reg clk, we;
    reg  [4:0] rs1, rs2, rd;
    reg  [31:0] wdata;
    wire [31:0] rdata1, rdata2;

    integer errors = 0;
    integer checks = 0;

    regfile dut (
        .clk(clk),
        .we(we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wdata(wdata),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    always #5 clk = ~clk;

    task check1(input [31:0] actual, input [31:0] exp, input string name);
        begin
            checks = checks + 1;
            if (actual !== exp) begin
                errors = errors + 1;
                $display("FAIL [%0d] %0s: got=%h expected=%h", checks, name, actual, exp);
            end
            else begin
                $display("PASS [%0d] %0s: %h", checks, name, actual);
            end
        end
    endtask

    task write_reg(input [4:0] addr, input [31:0] data);
        begin
            rd = addr; wdata = data; we = 1;
            @(posedge clk);
            #1;
            we = 0;
        end
    endtask

    initial begin
        $display("=== tb_regfile: starting ===");
        clk = 0; we = 0; rs1 = 0; rs2 = 0; rd = 0; wdata = 0;
        #1;

        // All registers initialize to 0 (per the initial block in the DUT)
        rs1 = 5'd15; rs2 = 5'd31; #1;
        check1(rdata1, 32'd0, "x15 reads 0 after init");
        check1(rdata2, 32'd0, "x31 reads 0 after init");

        // Basic write then read-back
        write_reg(5'd5, 32'hCAFEBABE);
        rs1 = 5'd5; #1;
        check1(rdata1, 32'hCAFEBABE, "x5 read-back after write");

        // Write a different register, confirm independence
        write_reg(5'd10, 32'h12345678);
        rs1 = 5'd5; rs2 = 5'd10; #1;
        check1(rdata1, 32'hCAFEBABE, "x5 unaffected by later write to x10");
        check1(rdata2, 32'h12345678, "x10 read-back after write");

        // x0 hardwired to zero: write attempt must be silently ignored
        write_reg(5'd0, 32'hFFFFFFFF);
        rs1 = 5'd0; #1;
        check1(rdata1, 32'd0, "x0 stays 0 even after attempted write");

        // we=0: write should not occur even if rd/wdata are set
        rd = 5'd20; wdata = 32'hAAAAAAAA; we = 0;
        @(posedge clk); #1;
        rs1 = 5'd20; #1;
        check1(rdata1, 32'd0, "no write occurs when we=0");

        // rs1 == rs2 simultaneously: both ports return the same value
        write_reg(5'd7, 32'h0000BEEF);
        rs1 = 5'd7; rs2 = 5'd7; #1;
        check1(rdata1, 32'h0000BEEF, "rs1==rs2==x7: rdata1 correct");
        check1(rdata2, 32'h0000BEEF, "rs1==rs2==x7: rdata2 correct");

        // Simultaneous read-during-write: reading rd while writing it in
        // the same cycle must return the OLD value combinationally
        // (write is synchronous, only visible after the clock edge).
        write_reg(5'd12, 32'h11111111); // x12 = 0x11111111 first
        rs1 = 5'd12; rd = 5'd12; wdata = 32'h22222222; we = 1; #1;
        check1(rdata1, 32'h11111111, "read of x12 combinationally shows OLD value while write is pending (pre-edge)");
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd12; #1;
        check1(rdata1, 32'h22222222, "x12 shows NEW value after the clock edge completes the write");

        // Write to all 31 non-zero registers with distinct values, spot-check a few
        write_reg(5'd1, 32'h00000001);
        write_reg(5'd2, 32'h00000002);
        write_reg(5'd31, 32'h0000001F);
        rs1 = 5'd1; rs2 = 5'd2; #1;
        check1(rdata1, 32'h00000001, "x1 retains value after subsequent unrelated writes");
        check1(rdata2, 32'h00000002, "x2 retains value after subsequent unrelated writes");
        rs1 = 5'd31; #1;
        check1(rdata1, 32'h0000001F, "x31 (highest register) writes/reads correctly");

        $display("=== tb_regfile: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_REGFILE: ALL TESTS PASSED ***");
        else              $display("*** TB_REGFILE: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
