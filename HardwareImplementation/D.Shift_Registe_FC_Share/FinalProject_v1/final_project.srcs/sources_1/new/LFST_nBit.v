`timescale 1ns / 1ps

module LFST_nBit
#(
    parameter num_bit = 8
)
(
    clk,
    rst,
    ld,
    seed,
    poly,
    out   
);

    input  clk;
    input  rst;
    input  ld;
    input  [num_bit-1 : 0] seed;
    input  [num_bit-1 : 0] poly;
    output [num_bit-1 : 0] out;

    wire [num_bit-1:0] q;
    wire [num_bit-2:0] and_wire;
    wire [num_bit-2:0] xor_wire;

    genvar i;

    assign out = q;

    ////////////////////////////////////////////////////////
    DFF D0
    (
        .clk(clk),
        .rst(rst),
        .ld(ld),
        .ld_input(seed[num_bit-2]),
        .d(xor_wire[num_bit-2]),
        .q(q[0])
    );
    ////////////////////////////////////////////////////////
	generate
		for (i = 1; i < num_bit; i = i + 1) begin
            DFF DN
            (
                .clk(clk),
                .rst(rst),
                .ld(ld),
                .ld_input(seed[i-1]),
                .d(q[i-1]),
                .q(q[i])
            );
        end
	endgenerate
    ////////////////////////////////////////////////////////
    assign xor_wire[0] = and_wire[0] & q[0];
	generate
		for (i = 1; i < num_bit-1; i = i + 1) begin
		  assign xor_wire[i] = and_wire[i] ^ xor_wire[i-1];
        end
	endgenerate
    ////////////////////////////////////////////////////////
	generate
		for (i = 0; i < num_bit-1; i = i + 1) begin
		  assign and_wire[i] = q[i+1] & poly[i];
        end
	endgenerate
    ////////////////////////////////////////////////////////
 
endmodule
