`timescale 1ns / 1ps

module BitStream_gen_tb();

    parameter num_bit = 16;
    parameter num_cnt = 16;

    reg clk;
    reg rst;
    reg start;
    
    reg  [num_bit - 1 : 0] seed;
    reg  [num_bit - 1 : 0] poly;
    reg  [num_bit - 1 : 0] stch_input;

    wire ready;
    wire [num_bit - 1 : 0] bitstream;

    BitStream_gen #( .num_bit(num_bit), .num_cnt(num_cnt)) uut
    (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ready(ready),
        .seed(seed),
        .poly(poly),
        .stch_input(stch_input),
        .bitstream(bitstream)
    );

    initial
    begin
        clk         = 0;
        rst         = 1;
        start       = 0;
        seed        = $random(1224);
        poly        = {num_bit{1'b1}};
        stch_input  = 'hD32DA351;       // 0.82491513
        #10
        rst         = 0;
        #10
        start       = 1;
        #10
        start       = 0;
        #200
        seed        = $random(1224);
        poly        = {num_bit{1'b1}};
        stch_input  = 'hD32DA351;       // 0.82491513
        #10
        rst         = 0;
        #10
        start       = 1;
        #10
        start       = 0;

    end

    always #5 clk = ~clk;
    
endmodule