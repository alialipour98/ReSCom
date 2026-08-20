`timescale 1ns / 1ps

module shift_register_nBit
#
(
    num_bit = 8
)
(
    clk,
    rst,
    sht,
    sht_input,
    sht_output
);

    input clk;
    input rst;
    input sht;
    input sht_input;
    output [num_bit - 1 : 0] sht_output;

    reg [num_bit - 1 : 0] sht_reg = 0;

    assign sht_output = sht_reg;

    always@(posedge clk, posedge rst)
    begin
        if (rst)
            sht_reg <= 'b0;
        else
        begin
            if (sht)
                sht_reg <= {sht_input, sht_reg[num_bit - 1 : 1]};
        end
    end

endmodule
