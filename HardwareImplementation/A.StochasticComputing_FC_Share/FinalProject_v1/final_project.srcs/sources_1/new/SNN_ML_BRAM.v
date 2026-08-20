`timescale 1ns / 1ps

module SNN_ML_BRAM
#
(
    parameter ADDR_WIDTH        = 16,
    parameter WEIGHT_NUM_L1     = 700,
    parameter WEIGHT_NUM_L2     = 256,
    parameter WEIGHT_WIDTH      = 16,
    parameter NEURON_NUM_L1     = 256,
    parameter NEURON_NUM_L2     = 20,
    parameter DELAY             = 10
)
(
    input                                               clk,
    input                                               rst,
    input                                               init,
    input                                               enable,
    input                                               start,
    input                                               start_param,
    input                                               start_gen,
    input                                               ld_gen,
    input                                               ready_gen,
    input  [1:0]                                        mode,
    input                                               ld_seed,
    input  [WEIGHT_WIDTH + $clog2(WEIGHT_NUM_L1)-1: 0]  seed,
    input  [WEIGHT_WIDTH + $clog2(WEIGHT_NUM_L1)-1: 0]  poly,
    input  [WEIGHT_WIDTH-1:0]                           alpha,
    input  [WEIGHT_WIDTH-1:0]                           beta,
    input  [WEIGHT_WIDTH-1:0]                           threshold,
    input  [WEIGHT_NUM_L1-1:0]                          spike,
    output [NEURON_NUM_L2-1:0]                          spike_out,
    output [WEIGHT_NUM_L2 * WEIGHT_WIDTH -1:0]          membrane_potential
);

    wire end_process_layer_1;
    wire [NEURON_NUM_L1-1:0] spike_out_layer_1;
    wire [WEIGHT_NUM_L1 * WEIGHT_WIDTH -1:0] membrane_potential_layer_1;

    wire end_process_layer_2;
    wire [NEURON_NUM_L2-1:0] spike_out_layer_2;
    wire [WEIGHT_NUM_L2 * WEIGHT_WIDTH -1:0] membrane_potential_layer_2;

    wire [WEIGHT_WIDTH-1: 0]                lfsr_in;

    assign spike_out            = spike_out_layer_2;
    assign membrane_potential   = membrane_potential_layer_2;

    LFST_nBit
    #(
        .num_bit(WEIGHT_WIDTH + $clog2(WEIGHT_NUM_L1))
    )
        snn_lfsr
    (
        .clk(clk),
        .rst(rst),
        .ld(ld_seed),
        .seed(seed),
        .poly(poly),
        .out(lfsr_in)
    );

    load_from_rom
    #
    (
        .ADDR_WIDTH(ADDR_WIDTH),
        .WEIGHT_NUM(WEIGHT_NUM_L1),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .NEURON_NUM(NEURON_NUM_L1),
        .DELAY(DELAY)
    )
        layer_1
    (
        .clk(clk),
        .rst(rst),
        .init(init),
        .enable(enable),
        .start(start),
        .start_param(start_param),
        .start_gen(start_gen),
        .ld_gen(ld_gen),
        .ready_gen(ready_gen),
        .mode(mode),
        .alpha(alpha),
        .beta(beta),
        .threshold(threshold),
        .lfsr_in(lfsr_in),
        .spike(spike),
        .end_process(end_process_layer_1),
        .spike_out(spike_out_layer_1),
        .membrane_potential(membrane_potential_layer_1)
    );

    load_from_rom
    #
    (
        .ADDR_WIDTH(ADDR_WIDTH),
        .WEIGHT_NUM(WEIGHT_NUM_L2),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .NEURON_NUM(NEURON_NUM_L2)
    )
        layer_2
    (
        .clk(clk),
        .rst(rst),
        .init(init),
        .enable(enable),
        .start(end_process_layer_1),
        .start_param(end_process_layer_1),
        .start_gen(end_process_layer_1),
        .ld_gen(ld_gen),
        .ready_gen(ready_gen),
        .mode(mode),
        .alpha(alpha),
        .beta(beta),
        .threshold(threshold),
        .lfsr_in(lfsr_in),
        .spike(spike_out_layer_1),
        .end_process(end_process_layer_2),
        .spike_out(spike_out_layer_2),
        .membrane_potential(membrane_potential_layer_2)
    );

endmodule
