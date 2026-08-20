module twos_complement #(
    parameter W = 8
)(
    input  [W-1:0] x,
    output [W-1:0] y
);
    wire [W-1:0] xinv = ~x;
    wire [W-1:0] one  = {{(W-1){1'b0}}, 1'b1};
    wire [W-1:0] sum;
    wire cout_unused;

    adder_sub_nBit #(.num_bit(W)) add1 (
        .A(xinv), .B(one), .add_sub(1'b0), .sum(sum), .carry_out(cout_unused)
    );

    assign y = sum;
endmodule