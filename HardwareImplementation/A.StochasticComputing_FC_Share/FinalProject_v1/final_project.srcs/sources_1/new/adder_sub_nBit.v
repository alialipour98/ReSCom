`timescale 1ns / 1ps

module adder_sub_nBit
#
(
    parameter num_bit = 8
)
(
    A,
    B,
    add_sub,
    carry_out,
    sum
);

    input  [num_bit-1:0] A;
    input  [num_bit-1:0] B;
    input  add_sub;
    
    output carry_out;
    output [num_bit-1:0]sum;

    genvar i;

    wire [num_bit-1:0] xor_wire;
    wire [num_bit-1:0] carry_wire;
    
    assign carry_out = carry_wire[num_bit-1];
    
    ///////////////////////////////////////////////
	generate
		for (i = 0; i < num_bit; i = i + 1) begin
		  assign xor_wire[i] = B[i] ^ add_sub;
        end
	endgenerate
    ///////////////////////////////////////////////
    FA FA_0
    (
        .a(A[0]),
        .b(xor_wire[0]),
        .c(add_sub),
        .sum(sum[0]),
        .carry(carry_wire[0])
    );
	generate
		for (i = 1; i < num_bit; i = i + 1) begin
            FA FA_inst
            (
                .a(A[i]),
                .b(xor_wire[i]),
                .c(carry_wire[i-1]),
                .sum(sum[i]),
                .carry(carry_wire[i])
            );
        end
	endgenerate
    ///////////////////////////////////////////////

endmodule







