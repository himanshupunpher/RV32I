module writeback_mux (
    input [31:0] alu_result,
    input [31:0] dmem_data,
    input [31:0] pc_plus_4,
    input [1:0] MemtoReg,
    output [31:0] wb_data
);
    assign wb_data = (MemtoReg==2'b00) ? alu_result : ((MemtoReg==2'b01) ? dmem_data : pc_plus_4);
endmodule