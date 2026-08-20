`timescale 1ns / 1ps

module comparator_nBit
#
(
    parameter num_bit = 8
)
(
    A,
    B,
    cmp
);

    // A > B Investigation

    input [num_bit - 1 : 0] A;
    input [num_bit - 1 : 0] B;
    output                  cmp;

    // B - A Calculation
    adder_sub_nBit #( .num_bit(num_bit) ) adder_sub
    (
        .A(B),
        .B(A),
        .add_sub(0'b1),
        .carry_out(cmp)
    );

endmodule
