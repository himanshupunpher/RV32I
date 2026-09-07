module IMEM (
    input clk,
    input we_a,
    input [9:0] addr_a,      //port a - required for bootloader
    input [31:0] data_a,     //port a - write only port
    input [9:0] addr_b,      //port b - to fetch instructions to execute
    output [31:0] data_b
);
    reg [31:0] sdata [1023:0];
    always @(posedge clk ) begin
        if(we_a)
            sdata[addr_a] <= data_a;
    end
    assign data_b = sdata[addr_b];
endmodule