module regfile (
    input clk,
    input we,               //write enable
    input [4:0] rs1,        //input reg 1
    input [4:0] rs2,        //input reg 2
    input [4:0] rd,         //output reg
    input [31:0] wdata,     //write data
    output reg [31:0] rdata1,   //read data 1
    output reg [31:0] rdata2    //read data 2
);
    reg [31:0] sdata [31:0]; //regs data storing array
    always @(*) begin
        rdata1 = (rs1==5'd0) ? 0 : sdata[rs1];
        rdata2 = (rs2==5'd0) ? 0 : sdata[rs2];
    end

    always @(posedge clk ) begin
        if(we && (rd != 5'd0))begin
            sdata[rd] <= wdata;
        end
    end
endmodule