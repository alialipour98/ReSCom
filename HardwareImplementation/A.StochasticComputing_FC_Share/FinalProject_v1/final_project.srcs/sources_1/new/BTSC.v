`timescale 1ns / 1ps

module BTSC
#
(
    parameter num_bit = 8,
    parameter num_cnt = 8
)
(
    clk,
    rst,
    sht,
    lfsr_out,
    ready,
    init_cnt,
    inc_cnt,
    stch_input,
    co,
    stch_output
);

    input clk;
    input rst;
    input init_cnt;
    input inc_cnt;
    input sht;
    input [num_bit - 1 : 0] lfsr_out;

    input  [num_bit - 1 : 0] stch_input;

    output co;
    output ready;
    output [num_bit - 1 : 0] stch_output;

    wire [num_bit - 1 : 0] cnt_out;
    wire [num_bit - 1 : 0] B_signal = $unsigned(num_bit);

    wire cmp;

    assign ready = (cnt_out == (num_bit+1)) ? 1'b1 : 1'b0;

//    LFST_nBit #( .num_bit(num_bit)) lfsr 
//    (
//        .clk(clk),
//        .rst(rst),
//        .ld(ld),
//        .seed(seed),
//        .poly(poly),
//        .out(lfsr_out)
//    );

    shift_register_nBit# (.num_bit(num_bit)) SR
    (
        .clk(clk),
        .rst(rst),
        .sht(sht),
        .sht_input(cmp),
        .sht_output(stch_output)
    );

    comparator_nBit #( .num_bit(num_bit)) cmp_stch
    (
        .A(lfsr_out),
        .B(stch_input),
        .cmp(cmp)
    );

    counter_nBit# ( .num_bit(num_bit)) cnt
    (
        .clk(clk),
        .rst(rst),
        .init(init_cnt),
        .inc(inc_cnt),
        .cnt_out(cnt_out)
    );

    equality_nBit# ( .num_bit(num_bit)) equal_cnt 
    (
        .A(cnt_out),
        .B(B_signal),
        .eq(co)
    );

endmodule