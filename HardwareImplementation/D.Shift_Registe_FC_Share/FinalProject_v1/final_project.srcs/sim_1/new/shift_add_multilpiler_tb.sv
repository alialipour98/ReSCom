`timescale 1ns / 1ps

module shift_add_multilpiler_tb();

    parameter WIDTH = 8;

    reg signed [WIDTH-1:0]     A;
    reg signed [WIDTH-1:0]     B;
    wire signed [2*WIDTH-1:0]  P;

    shift_add_multiplier 
    #
    (
        .WIDTH(WIDTH)
    )
        uut
    (
        .A(A),
        .B(B),
        .P(P)
    );

    initial
    begin
        A = -'d12;
        B = 'd13;
    end

endmodule
