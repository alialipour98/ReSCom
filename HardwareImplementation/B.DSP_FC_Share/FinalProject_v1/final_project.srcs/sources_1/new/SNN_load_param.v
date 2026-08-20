`timescale 1ns / 1ps

module SNN_load_param
#
(
    parameter INPUT_NUM         = 256,
    parameter NEURON_NUM        = 256,
    parameter DATA_WIDTH        = 16,
    parameter WEIGHT_WIDTH      = 16,
    parameter THRESHOLD_WIDTH   = 16

)
(
    input  clk,
    input  rst,
    input  enable,
    input  ld_start,
    input  ld_w,
    input  ld_b,
    input  ld_a,
    input  ld_th,
    input  start,   // LFSR
    output ld,      // LFSR
    output ready,   // LFSR
    input  [1:0] mode,
    input  [DATA_WIDTH-1:0] beta,
    input  [DATA_WIDTH-1:0] alpha,
    input  [WEIGHT_WIDTH-1: 0] input_weight,
    input  [WEIGHT_WIDTH-1: 0] lfsr_in,
    input  [INPUT_NUM-1:0] spike,
    input  [NEURON_NUM-1:0] syn_valid,
    input  [THRESHOLD_WIDTH-1:0]   threshold,
    output ld_completed,
    output ldb_completed,
    output lda_completed,
    output ldth_completed,
    output [NEURON_NUM-1:0]                     spike_out,
    output [NEURON_NUM * DATA_WIDTH-1:0]        membrane_potential

);

    wire [INPUT_NUM * WEIGHT_WIDTH-1:0] neuron_weight [0:NEURON_NUM-1];
    wire [DATA_WIDTH-1:0] weight_neuron [0:NEURON_NUM-1];

    wire [(WEIGHT_WIDTH+$clog2(INPUT_NUM)) * NEURON_NUM-1:0] neuron_input_wire;

    wire [NEURON_NUM:0] ld_w_neuron;
    
    wire [NEURON_NUM * DATA_WIDTH-1:0] beta_wire;
    wire [NEURON_NUM * DATA_WIDTH-1:0] alpha_wire;

    wire [NEURON_NUM * THRESHOLD_WIDTH-1:0]   threshold_wire;
    
    genvar i, j;

    assign ld_w_neuron[1]   = ld_w_neuron[0];
    assign ld_completed     = ld_w_neuron[NEURON_NUM];

    generate
        for (i = 0; i < NEURON_NUM; i = i + 1) begin

            signed_adder_tree #(
                .INPUT_WIDTH(WEIGHT_WIDTH),
                .NUM_INPUTS(INPUT_NUM)
            )
                fc_layer 
            (
                .clk(clk),
                .rst(rst),
                .inputs(neuron_weight[i]),
                .spike(spike),
                .sum(neuron_input_wire[i * (WEIGHT_WIDTH + $clog2(INPUT_NUM)) +: (WEIGHT_WIDTH + $clog2(INPUT_NUM))])
            );
        end
    endgenerate
    
    SNN_top
    #
    (
        .NEURON_NUM(NEURON_NUM),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH + $clog2(INPUT_NUM)),
        .THRESHOLD_WIDTH(THRESHOLD_WIDTH)
    )
        snn_inst
    (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .mode(mode),
        .lfsr_in(lfsr_in),
        .start(start),
        .ld(ld),
        .ready(ready),
        .beta(beta_wire),
        .alpha(alpha_wire),
        .syn_valid(syn_valid),
        .syn_weight(neuron_input_wire),
        .threshold(threshold),
        .spike_out(spike_out),
        .membrane_potential(membrane_potential)
    );

    generate
        for (i = 0; i < NEURON_NUM; i = i + 1) begin

            if (i == 0) begin
                load_param
                #
                (
                    .PARAM_WIDTH(WEIGHT_WIDTH),
                    .INPUT_NUM(INPUT_NUM)
                )
                    ld_weight
                (
                    .clk(clk),
                    .rst(rst),
                    .start(ld_start),
                    .ld_w(ld_w),
                    .params(input_weight),
                    .ld_completed(ld_w_neuron[0]),
                    .out_params(neuron_weight[i])
                );
            end else begin
                load_param
                #
                (
                    .PARAM_WIDTH(WEIGHT_WIDTH),
                    .INPUT_NUM(INPUT_NUM)
                )
                    ld_weight
                (
                    .clk(clk),
                    .rst(rst),
                    .start(ld_w_neuron[i]),
                    .ld_w(ld_w),
                    .params(input_weight),
                    .ld_completed(ld_w_neuron[i+1]),
                    .out_params(neuron_weight[i])
                );
            end
        end
    endgenerate

    load_param
    #
    (
        .PARAM_WIDTH(DATA_WIDTH),
        .INPUT_NUM(NEURON_NUM)
    )
        ld_beta
    (
        .clk(clk),
        .rst(rst),
        .start(ld_start),
        .ld_w(ld_b),
        .params(beta),
        .ld_completed(ldb_completed),
        .out_params(beta_wire)
    );

    load_param
    #
    (
        .PARAM_WIDTH(DATA_WIDTH),
        .INPUT_NUM(NEURON_NUM)
    )
        ld_alpha
    (
        .clk(clk),
        .rst(rst),
        .start(ld_start),
        .ld_w(ld_a),
        .params(alpha),
        .ld_completed(lda_completed),
        .out_params(alpha_wire)
    );

    load_param
    #
    (
        .PARAM_WIDTH(THRESHOLD_WIDTH),
        .INPUT_NUM(NEURON_NUM)
    )
        ld_threshold
    (
        .clk(clk),
        .rst(rst),
        .start(ld_start),
        .ld_w(ld_th),
        .params(threshold),
        .ld_completed(ldth_completed),
        .out_params(threshold_wire)
    );

endmodule