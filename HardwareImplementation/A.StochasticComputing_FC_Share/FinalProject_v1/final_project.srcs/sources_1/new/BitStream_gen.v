`timescale 1ns / 1ps

module BitStream_gen
#
(
    parameter num_bit = 8,
    parameter num_cnt = num_bit
)
(
    clk,
    rst,
    start,
    ready,
    ld,
    stch_input,
    lfsr_out,
    bitstream
);

    input                       clk;
    input                       rst;
    input                       start;
    input  [num_bit - 1 : 0]    stch_input;
    input  [num_bit - 1 : 0]    lfsr_out;

    output [num_bit - 1 : 0]    bitstream;
    output ready;
    output ld;

    wire sht;
    wire co;
    wire init_cnt;
    wire inc_cnt;

    controller ctrl
    (
        .clk(clk),
        .rst(rst),
        .ld(ld),
        .sht(sht),
        .start(start),
        .co(co),
        .init_cnt(init_cnt),
        .inc_cnt(inc_cnt)
    );

    BTSC# ( .num_bit(num_bit), .num_cnt(num_cnt)) datapath
    (
        .clk(clk),
        .rst(rst),
        .sht(sht),
        .ready(ready),
        .init_cnt(init_cnt),
        .inc_cnt(inc_cnt),
        .stch_input(stch_input),
        .lfsr_out(lfsr_out),
        .co(co),
        .stch_output(bitstream)
    );

endmodule