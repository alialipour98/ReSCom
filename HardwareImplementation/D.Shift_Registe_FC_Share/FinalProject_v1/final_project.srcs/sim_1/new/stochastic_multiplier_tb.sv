`timescale 1ns / 1ps

module stochastic_multiplier_tb();

    parameter num_bit       = 16;
    parameter WEIGHT_WIDTH  = 16;

    reg clk;
    reg rst;
    reg start;
    
    reg  [num_bit - 1 : 0] seed;
    reg  [num_bit - 1 : 0] poly;
    reg  [num_bit - 1 : 0] lfsr_out;
    reg  [num_bit - 1 : 0] stch_input_1;
    reg  [num_bit - 1 : 0] stch_input_2;

    wire [num_bit - 1 : 0] bitstream_1;
    wire [num_bit - 1 : 0] bitstream_2;
    
    wire [WEIGHT_WIDTH - 1 : 0] mult_out;
    
    wire ready_1;
    wire ready_2;
    
    wire ld;

    LFST_nBit #( .num_bit(num_bit)) lfsr 
    (
        .clk(clk),
        .rst(rst),
        .ld(ld),
        .seed(seed),
        .poly(poly),
        .out(lfsr_out)
    );

    BitStream_gen #( .num_bit(num_bit)) gen1
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ld(ld),
        .ready(ready_1),
        .stch_input(stch_input_1),
        .lfsr_out(lfsr_out),
        .bitstream(bitstream_1)
    );

    BitStream_gen #( .num_bit(num_bit)) gen2
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ready(ready_2),
        .stch_input(stch_input_2),
        .lfsr_out(lfsr_out),
        .bitstream(bitstream_2)
    );

    stochastic_multiplier
    #
    (
        .NUM_BIT(num_bit),
        .WEIGHT_WIDTH(WEIGHT_WIDTH)
    )
        uut
    (
        .clk(clk),
        .rst(rst),
        .ld(ready_1),
        .A(bitstream_1),
        .B(bitstream_2),
        .C(mult_out)
    );
    
    initial
    begin
        clk          = 0;
        rst          = 1;
        start        = 0;
        seed         = $random($time);
        poly         = {num_bit{1'b1}};
        stch_input_1 = 'd16384;       // 0.25
        stch_input_2 = 'd32768;       // 0.5
        #10
        rst         = 0;
        #10
        start       = 1;
        #10
        start       = 0;
    end

    always@(negedge ready_1)
    begin
        $display("Test Case 1: 0.25 * 0.5");
        $display("Input A: %f (%d/65536)", stch_input_1/65536.0, stch_input_1);
        $display("Input B: %f (%d/65536)", stch_input_2/65536.0, stch_input_2);
        $display("Output:  %f (%d/65536)", mult_out/65536.0, mult_out);
        $display("Expected: 0.125000 (8192/65536)");
        $display("Error: %f%%", 100*( (mult_out/65536.0) - 0.125 )/0.125);
    end

    always #5 clk = ~clk;

endmodule
