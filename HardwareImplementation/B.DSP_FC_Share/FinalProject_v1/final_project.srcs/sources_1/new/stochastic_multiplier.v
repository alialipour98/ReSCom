`timescale 1ns / 1ps

module stochastic_multiplier
#
(
    parameter NUM_BIT       = 8,
    parameter WEIGHT_WIDTH  = 10

)
(
    input   clk,
    input   rst,
    input   ld,
    input   [NUM_BIT-1:0] A,
    input   [NUM_BIT-1:0] B,
    output  [WEIGHT_WIDTH-1:0] C
);

    integer i;

    reg [NUM_BIT-1:0] stochastic_out;
    wire [$clog2(NUM_BIT+1)-1:0] counts;
    
    assign C = {{(WEIGHT_WIDTH-$clog2(NUM_BIT+1)){1'b0}}, counts} << (NUM_BIT-$clog2(NUM_BIT+1)-1);
    
    ones_counter_nBit
    #
    (
        .num_bit(NUM_BIT)
    )
        ones_cnt
    (
        .input_1(stochastic_out),
        .counts(counts)
    );

    always@(posedge clk, posedge rst)
    begin
        if (rst)
            stochastic_out <= 'b0;
        else
            if (ld)
            begin
                for (i = 0; i < NUM_BIT; i = i + 1)
                begin
                    stochastic_out[i] <= A[i] & B[i];
                end
            end
    end

endmodule
