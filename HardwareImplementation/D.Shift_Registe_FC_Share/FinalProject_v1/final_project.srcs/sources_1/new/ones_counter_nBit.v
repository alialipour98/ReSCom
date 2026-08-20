`timescale 1ns / 1ps

module ones_counter_nBit
#
(
    parameter num_bit = 15,
    parameter out_bit = $clog2( num_bit + 1 )
)
(
    input_1,
    counts
);

    input       [num_bit - 1 : 0] input_1;
    output reg  [out_bit - 1 : 0] counts;

    integer i;

    always@( input_1 )
    begin
        counts = 0;
        for (i = 0; i < num_bit; i = i + 1)
        begin
            if ( input_1[i] == 1'b1)
                counts = counts + 1;
        end
    end

endmodule