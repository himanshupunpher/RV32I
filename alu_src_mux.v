module alu_src_mux (
    input [31:0] rdata2,
    input [31:0] imm,
    input ALUSrc,
    output [31:0] alu_b
);
    assign alu_b = ALUSrc ? imm : rdata2;
endmodule