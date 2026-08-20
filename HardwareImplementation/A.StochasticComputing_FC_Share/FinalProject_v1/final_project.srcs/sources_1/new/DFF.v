`timescale 1ns / 1ps

module DFF
(
    clk,
    rst,
    ld,
    ld_input,
    d,
    q
);

    input  clk;
    input  rst;
    input  ld;
    input  ld_input;
    input  d;
    output q;

    reg q_int = 0;

    assign q = q_int;
    
    always@(posedge clk, posedge rst)
    begin
        if (rst)
            q_int   <=  0;
        else
        begin
            if (ld)
                q_int <= ld_input;
            else
                q_int   <=  d;
        end
    end

endmodule
