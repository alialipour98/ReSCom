module array_multiplier #(
    parameter N = 8  // operand width
)(
    input  signed [N-1:0]        a,
    input  signed [N-1:0]        b,
    output signed [(2*N)-1:0]    p
);
    // Determine sign of result
    wire sign = a[N-1] ^ b[N-1];

    // Magnitudes via two's complement (built from FA/HA)
    wire [N-1:0] a_mag, b_mag;
    wire [N-1:0] a_neg, b_neg;

    twos_complement #(.W(N)) neg_a(.x(a[N-1:0]), .y(a_neg));
    twos_complement #(.W(N)) neg_b(.x(b[N-1:0]), .y(b_neg));

    assign a_mag = a[N-1] ? a_neg : a[N-1:0];
    assign b_mag = b[N-1] ? b_neg : b[N-1:0];

    // Unsigned multiply with FA/HA array
    wire [(2*N)-1:0] uprod;
    unsigned_array_multiplier #(.N(N)) u_mul (
        .x(a_mag), .y(b_mag), .p(uprod)
    );

    // Apply sign at the end: two's complement 2N-bit wide when sign=1
    wire [(2*N)-1:0] uprod_neg;
    twos_complement #(.W(2*N)) neg_p(.x(uprod), .y(uprod_neg));

    assign p = sign ? $signed(uprod_neg) : $signed(uprod);
endmodule
