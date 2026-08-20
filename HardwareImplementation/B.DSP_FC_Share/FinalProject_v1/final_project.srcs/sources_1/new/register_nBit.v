`timescale 1ns / 1ps

module register_nBit
#
(
    parameter num_bit = 8
)
(
    input       clk,
    input       rst,
    input       init,
    input       ld,
    input       [num_bit-1:0] in_reg,
    output reg  [num_bit-1:0] out_reg
);

    always@(posedge clk, posedge rst)
    begin
        if (rst)
            out_reg <= 'b0;
        else
        begin
            if (init)
                out_reg <= 'b0;
            else if (ld)
                out_reg <= in_reg;
            else
                out_reg <= out_reg;
        end
    end

endmodule
