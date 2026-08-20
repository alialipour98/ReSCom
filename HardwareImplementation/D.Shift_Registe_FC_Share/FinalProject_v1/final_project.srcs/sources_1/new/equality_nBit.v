`timescale 1ns / 1ps

module equality_nBit
#
(
    parameter num_bit = 8 
)
(
    A,
    B,
    eq
);

    input [num_bit - 1 : 0] A;
    input [num_bit - 1 : 0] B;
    
    output eq;

    assign eq = (A == B) ? 1'b1 : 1'b0;

endmodule
