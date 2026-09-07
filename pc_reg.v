module pc_reg (
    input clk,
    input reset,
    input [31:0] next_pc,
    output reg [31:0] PC
);
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            PC <= 32'b0;
        end
        else begin
            PC <= next_pc;
        end
    end
    
endmodule