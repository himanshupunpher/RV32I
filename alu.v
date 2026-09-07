module alu (
    input [31:0] a,
    input [31:0] b,
    input [2:0] alu_ctrl,
    output reg[31:0] result,
    output zero
);
    localparam ADD = 3'b000,
               SUB = 3'b001,
               AND = 3'b010,
               OR = 3'b011,
               XOR = 3'b100,
               SLT = 3'b101;

    always@(*) begin
        case (alu_ctrl)
            ADD : result = a + b;
            SUB : result = a - b;
            AND : result = a & b;
            OR  : result = a | b;
            XOR : result = a ^ b;
            SLT : result = ($signed(a) < $signed(b)) ? 1 : 0;
        endcase
    end
    assign zero = (result == 0) ? 1 : 0;

endmodule