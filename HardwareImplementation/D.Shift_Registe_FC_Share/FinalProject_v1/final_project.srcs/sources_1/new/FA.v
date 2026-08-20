`timescale 1ns / 1ps

module FA
(
    a,
    b,
    c,
    sum,
    carry
);

    input  a;
    input  b;
    input  c;
    
    output sum;
    output carry;

    assign sum   = a ^ b ^ c;
    assign carry = a & b | a & c | b & c; 

endmodule
