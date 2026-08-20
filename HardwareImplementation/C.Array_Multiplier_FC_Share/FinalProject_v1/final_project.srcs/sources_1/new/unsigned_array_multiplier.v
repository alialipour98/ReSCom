`timescale 1ns / 1ps
module unsigned_array_multiplier #(
    parameter N = 8
)(
    input  [N-1:0]          x,
    input  [N-1:0]          y,
    output [(2*N)-1:0]      p
);
    // Partial product rows (combinational ANDs)
    wire [N-1:0] pp [N-1:0];
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_pp
            assign pp[i] = x & {N{y[i]}};
        end
    endgenerate

    // Accumulate with ripple adders (2N bits wide)
    wire [(2*N)-1:0] acc [N-1:0];

    // Stage 0: zero-extend the first row
    assign acc[0] = {{N{1'b0}}, pp[0]};

    genvar r;
    generate
        for (r = 1; r < N; r = r + 1) begin : gen_accum
            // Shift current pp row by r into 2N width
            wire [(2*N)-1:0] shifted = {{N{1'b0}}, pp[r]} << r;
            wire [(2*N)-1:0] sum_r;
            wire carry_out_unused;
            adder_sub_nBit #(.num_bit(2*N)) add_stage (
                .A(acc[r-1]),
                .B(shifted),
                .add_sub(1'b0),
                .sum(sum_r),
                .carry_out(carry_out_unused)
            );
            assign acc[r] = sum_r;
        end
    endgenerate

    assign p = acc[N-1];
endmodule
