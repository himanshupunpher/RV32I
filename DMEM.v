module DMEM (
    input clk,
    input we,
    input [9:0] addr,
    input [31:0] wdata,
    output [31:0] rdata
);
    reg [31:0] sdata [1023:0];
    always @(posedge clk ) begin
        if(we)
            sdata[addr] <= wdata;
    end
    assign rdata = sdata[addr];
endmodule