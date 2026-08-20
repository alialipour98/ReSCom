`timescale 1ns / 1ps

module SNN_ML
#
(
    parameter INPUT_NUM_L1      = 256,
    parameter NEURON_NUM_L1     = 256,
    parameter INPUT_NUM_L2      = 256,
    parameter NEURON_NUM_L2     = 10,
    parameter DATA_WIDTH        = 8,
    parameter WEIGHT_WIDTH      = 8,
    parameter THRESHOLD_WIDTH   = 8
)
(
    input                       clk,
    input                       rst,
    input                       enable,
    input                       ld_start,
    input                       start,
    input                       ldw_l1,
    input                       ldw_l2,
    input                       ldb_l1,
    input                       ldb_l2,
    input                       lda_l1,
    input                       lda_l2,
    input                       ldth_l1,
    input                       ldth_l2,
    input [1:0]                 mode,
    input [DATA_WIDTH-1:0]      beta,
    input [DATA_WIDTH-1:0]      alpha,
    input [WEIGHT_WIDTH-1: 0]   input_weight,
    input [WEIGHT_WIDTH-1: 0]   seed,
    input [WEIGHT_WIDTH-1: 0]   poly,
    input [INPUT_NUM_L1-1:0]    spike,
    input [NEURON_NUM_L1-1:0]   syn_valid_l1,
    input [NEURON_NUM_L1-1:0]   syn_valid_l2,
    input [THRESHOLD_WIDTH-1:0] threshold,
    
    output                      ready,
    output                      ld_completed_l1,
    output                      ldb_completed_l1,
    output                      lda_completed_l1,
    output                      ldth_completed_l1,
    output                      ld_completed_l2,
    output                      ldb_completed_l2,
    output                      lda_completed_l2,
    output                      ldth_completed_l2,
    output [NEURON_NUM_L2-1:0]  spike_out
);

    wire [NEURON_NUM_L1-1:0]                spike_out_l1;
    wire [NEURON_NUM_L2-1:0]                spike_out_l2;
    wire [NEURON_NUM_L1 * DATA_WIDTH-1:0]   membrane_potential_l1;
    wire [NEURON_NUM_L2 * DATA_WIDTH-1:0]   membrane_potential_l2;

    wire ld;
    wire [WEIGHT_WIDTH-1: 0]                lfsr_in;

    assign spike_out = spike_out_l2;
    
    LFST_nBit
    #(
        .num_bit(WEIGHT_WIDTH)
    )
        snn_lfsr
    (
        .clk(clk),
        .rst(rst),
        .ld(ld),
        .seed(seed),
        .poly(poly),
        .out(lfsr_in)
    );
    
    SNN_load_param
    #
    (
        .INPUT_NUM(INPUT_NUM_L1),
        .NEURON_NUM(NEURON_NUM_L1),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .THRESHOLD_WIDTH(THRESHOLD_WIDTH)
    )
        layer_1
    (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start(start),
        .ready(ready),
        .ld_start(ld_start),
        .ld_w(ldw_l1),
        .ld_b(ldb_l1),
        .ld_a(lda_l1),
        .ld_th(ldth_l1),
        .mode(mode),
        .beta(beta),
        .alpha(alpha),
        .input_weight(input_weight),
        .lfsr_in(lfsr_in),
        .spike(spike),
        .syn_valid(syn_valid_l1),
        .threshold(threshold),
        .ld(ld),
        .ld_completed(ld_completed_l1),
        .ldb_completed(ldb_completed_l1),
        .lda_completed(lda_completed_l1),
        .ldth_completed(ldth_completed_l1),
        .spike_out(spike_out_l1),
        .membrane_potential(membrane_potential_l1)
    );

    SNN_load_param
    #
    (
        .INPUT_NUM(INPUT_NUM_L2),
        .NEURON_NUM(NEURON_NUM_L2),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .THRESHOLD_WIDTH(THRESHOLD_WIDTH)
    )
        layer_2
    (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .start(start),
        .ready(ready),
        .ld_start(ld_completed_l1),
        .ld_w(ldw_l2),
        .ld_b(ldb_l2),
        .ld_a(lda_l2),
        .ld_th(ldth_l2),
        .mode(mode),
        .beta(beta),
        .alpha(alpha),
        .input_weight(input_weight),
        .lfsr_in(lfsr_in),
        .spike(spike_out_l1),
        .syn_valid(syn_valid_l2),
        .threshold(threshold),
        .ld_completed(ld_completed_l2),
        .ldb_completed(ldb_completed_l2),
        .lda_completed(lda_completed_l2),
        .ldth_completed(ldth_completed_l2),
        .spike_out(spike_out_l2),
        .membrane_potential(membrane_potential_l2)
    );

endmodule
