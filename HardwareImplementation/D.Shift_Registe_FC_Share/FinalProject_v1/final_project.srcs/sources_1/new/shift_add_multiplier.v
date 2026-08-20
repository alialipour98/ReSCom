module shift_add_multiplier 
#
(
    parameter WIDTH = 8
)
(
    input  wire signed [WIDTH-1:0] A,
    input  wire signed [WIDTH-1:0] B,
    output reg  signed [2*WIDTH-1:0] P
);
    integer i;

    // Magnitudes (unsigned containers)
    reg [WIDTH-1:0] a_mag, b_mag;

    // Accumulator for unsigned product
    reg [2*WIDTH-1:0] prod_u;

    wire sign_neg = A[WIDTH-1] ^ B[WIDTH-1];

    always @* begin
        // absolute value in WIDTH bits (OK even for -2^(WIDTH-1))
        a_mag = A[WIDTH-1] ? (~A + 1'b1) : A[WIDTH-1:0];
        b_mag = B[WIDTH-1] ? (~B + 1'b1) : B[WIDTH-1:0];

        prod_u = {2*WIDTH{1'b0}};

        // classic shift-add over multiplier bits
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (b_mag[i])
                prod_u = prod_u + ( { {WIDTH{1'b0}}, a_mag } << i );
        end

        // apply sign
        P = sign_neg ? -$signed(prod_u) : $signed(prod_u);
    end
endmodule
