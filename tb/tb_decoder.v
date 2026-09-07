// tb_decoder.v
// Self-checking testbench for decoder.v
// Feeds one real encoded instruction per supported format (R/I/S/B/J)
// plus a default/unsupported-opcode case, and checks every decoded
// field including immediate sign-extension.

`timescale 1ns/1ps

module tb_decoder;

    reg  [31:0] instruction;
    wire [6:0]  opcode;
    wire [4:0]  rs1, rs2, rd;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] imm;

    integer errors = 0;
    integer checks = 0;

    decoder dut (
        .instruction(instruction),
        .opcode(opcode),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .funct3(funct3),
        .funct7(funct7),
        .imm(imm)
    );

    task check_field(input [31:0] actual, input [31:0] exp, input string name);
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

    initial begin
        $display("=== tb_decoder: starting ===");

        // ---- R-type: ADD x3, x1, x2  (opcode 0110011, funct3 000, funct7 0000000)
        // funct7 rs2  rs1 f3  rd    opcode
        // 0000000 00010 00001 000 00011 0110011
        instruction = 32'b0000000_00010_00001_000_00011_0110011; #1;
        $display("-- R-type: ADD x3, x1, x2 --");
        check_field(opcode, 7'b0110011, "R-type opcode");
        check_field(rs1, 5'd1, "R-type rs1");
        check_field(rs2, 5'd2, "R-type rs2");
        check_field(rd,  5'd3, "R-type rd");
        check_field(funct3, 3'b000, "R-type funct3");
        check_field(funct7, 7'b0000000, "R-type funct7");
        check_field(imm, 32'd0, "R-type imm (unused, must be 0)");

        // ---- R-type: SUB x5, x6, x7 (funct7 0100000, funct3 000)
        instruction = 32'b0100000_00111_00110_000_00101_0110011; #1;
        $display("-- R-type: SUB x5, x6, x7 --");
        check_field(rs1, 5'd6, "SUB rs1");
        check_field(rs2, 5'd7, "SUB rs2");
        check_field(rd,  5'd5, "SUB rd");
        check_field(funct7, 7'b0100000, "SUB funct7 (distinguishes from ADD)");

        // ---- I-type: ADDI x4, x1, -5 (imm=-5 = 12'hFFB)
        // imm[11:0]=111111111011  rs1=00001 f3=000 rd=00100 opcode=0010011
        instruction = {12'hFFB, 5'd1, 3'b000, 5'd4, 7'b0010011}; #1;
        $display("-- I-type: ADDI x4, x1, -5 --");
        check_field(opcode, 7'b0010011, "ADDI opcode");
        check_field(rs1, 5'd1, "ADDI rs1");
        check_field(rs2, 5'd0, "ADDI rs2 (must be 0, unused for I-type)");
        check_field(rd,  5'd4, "ADDI rd");
        check_field(funct3, 3'b000, "ADDI funct3");
        check_field(funct7, 7'b0, "ADDI funct7 (must be 0, no funct7 in I-type)");
        check_field(imm, -32'sd5, "ADDI imm sign-extended -5");

        // ---- I-type: LW x2, 100(x8)  (imm=100=12'h064)
        instruction = {12'd100, 5'd8, 3'b010, 5'd2, 7'b0000011}; #1;
        $display("-- I-type: LW x2, 100(x8) --");
        check_field(opcode, 7'b0000011, "LW opcode");
        check_field(rs1, 5'd8, "LW rs1 (base)");
        check_field(rd,  5'd2, "LW rd");
        check_field(imm, 32'd100, "LW imm positive, no sign-extension needed");

        // ---- I-type: JALR x1, 0(x5)
        instruction = {12'd0, 5'd5, 3'b000, 5'd1, 7'b1100111}; #1;
        $display("-- I-type: JALR x1, 0(x5) --");
        check_field(opcode, 7'b1100111, "JALR opcode");
        check_field(rs1, 5'd5, "JALR rs1");
        check_field(rd,  5'd1, "JALR rd");
        check_field(imm, 32'd0, "JALR imm 0");

        // ---- S-type: SW x9, -4(x10)
        // imm = -4 = 12'hFFC -> imm[11:5]=1111111, imm[4:0]=11100
        instruction = {7'b1111111, 5'd9, 5'd10, 3'b010, 5'b11100, 7'b0100011}; #1;
        $display("-- S-type: SW x9, -4(x10) --");
        check_field(opcode, 7'b0100011, "SW opcode");
        check_field(rs1, 5'd10, "SW rs1 (base)");
        check_field(rs2, 5'd9, "SW rs2 (source)");
        check_field(rd, 5'd0, "SW rd (must be 0, no dest for S-type)");
        check_field(funct7, 7'b0, "SW funct7 forced to 0");
        check_field(imm, -32'sd4, "SW imm sign-extended -4");

        // ---- B-type: BEQ x1, x2, +16
        // byte offset 16 = 0b10000; imm[12]=0 imm[11]=0 imm[10:5]=000000 imm[4:1]=1000 imm[0]=0(implicit)
        // encoding: imm[12]=b31, imm[10:5]=b30:25, imm[4:1]=b11:8, imm[11]=b7
        instruction = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b1000, 1'b0, 7'b1100011}; #1;
        $display("-- B-type: BEQ x1, x2, +16 --");
        check_field(opcode, 7'b1100011, "BEQ opcode");
        check_field(rs1, 5'd1, "BEQ rs1");
        check_field(rs2, 5'd2, "BEQ rs2");
        check_field(rd, 5'd0, "BEQ rd (must be 0, no dest for B-type)");
        check_field(funct3, 3'b000, "BEQ funct3");
        check_field(imm, 32'd16, "BEQ imm = +16 bytes");

        // ---- B-type: BNE x3, x4, -8
        // byte offset -8 = ...11111000 (13-bit signed: imm[12:0] = 1_1111111_1100_0)
        // imm[12]=1 imm[11]=1 imm[10:5]=111111 imm[4:1]=1100 imm[0]=0
        instruction = {1'b1, 6'b111111, 5'd4, 5'd3, 3'b001, 4'b1100, 1'b1, 7'b1100011}; #1;
        $display("-- B-type: BNE x3, x4, -8 --");
        check_field(opcode, 7'b1100011, "BNE opcode");
        check_field(rs1, 5'd3, "BNE rs1");
        check_field(rs2, 5'd4, "BNE rs2");
        check_field(funct3, 3'b001, "BNE funct3");
        check_field(imm, -32'sd8, "BNE imm = -8 bytes, sign-extended");

        // ---- J-type: JAL x1, +2048
        // byte offset 2048 = imm[11]=1, all other imm bits 0.
        // Field layout is {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode}
        instruction = {1'b0, 10'b0000000000, 1'b1, 8'b00000000, 5'd1, 7'b1101111}; #1;
        $display("-- J-type: JAL x1, +2048 --");
        check_field(opcode, 7'b1101111, "JAL opcode");
        check_field(rs1, 5'd0, "JAL rs1 (must be 0, unused)");
        check_field(rs2, 5'd0, "JAL rs2 (must be 0, unused)");
        check_field(rd, 5'd1, "JAL rd");
        check_field(funct3, 3'b0, "JAL funct3 forced to 0");
        check_field(imm, 32'd2048, "JAL imm = +2048 bytes");

        // ---- J-type: JAL x0, -4 (common "infinite loop" idiom, negative imm)
        // byte offset -4 = 21-bit signed ...111111100
        // imm[20]=1 imm[19:12]=11111111 imm[11]=1 imm[10:1]=1111111110
        instruction = {1'b1, 10'b1111111110, 1'b1, 8'b11111111, 5'd0, 7'b1101111}; #1;
        $display("-- J-type: JAL x0, -4 --");
        check_field(rd, 5'd0, "JAL x0 rd");
        check_field(imm, -32'sd4, "JAL imm = -4 bytes, sign-extended");

        // ---- Unsupported/default opcode -> all fields forced to 0
        instruction = 32'b1111111_11111_11111_111_11111_1111111; #1;
        $display("-- default: unsupported opcode --");
        check_field(rs1, 5'd0, "default rs1 = 0");
        check_field(rs2, 5'd0, "default rs2 = 0");
        check_field(rd,  5'd0, "default rd = 0");
        check_field(funct3, 3'b0, "default funct3 = 0");
        check_field(funct7, 7'b0, "default funct7 = 0");
        check_field(imm, 32'd0, "default imm = 0");

        $display("=== tb_decoder: %0d checks, %0d errors ===", checks, errors);
        if (errors == 0) $display("*** TB_DECODER: ALL TESTS PASSED ***");
        else              $display("*** TB_DECODER: %0d TEST(S) FAILED ***", errors);
        $finish;
    end

endmodule
