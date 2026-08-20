`timescale 1ns / 1ps

module SNN_top
#
(
    parameter NEURON_NUM        = 1,
    parameter DATA_WIDTH        = 16,    // Q1.15 membrane potential
    parameter WEIGHT_WIDTH      = 8,     // input weight width
    parameter THRESHOLD_WIDTH   = 16     // Q1.15 threshold
)
(
    input  wire                                     clk,
    input  wire                                     rst,
    input  wire                                     enable,

    // BistreamGen
    input [WEIGHT_WIDTH-1:0]            lfsr_in,
    input start,
    output ld,
    output ready,

    // Mode selector
    input  wire [1:0]                               mode,           // 00: IF, 10: Synaptic

    // Decay factors (Q1.15)
    input  wire [NEURON_NUM * DATA_WIDTH-1:0]       beta,           // synaptic current decay
    input  wire [NEURON_NUM * DATA_WIDTH-1:0]       alpha,          // membrane potential decay

    // Input spike & weight
    input  wire [NEURON_NUM-1:0]                    syn_valid,       // spike input
    input  wire [NEURON_NUM * WEIGHT_WIDTH-1:0]     syn_weight,      // unsigned weight

    // Parameters
    input  wire [NEURON_NUM * THRESHOLD_WIDTH-1:0]  threshold,

    // Outputs
    output wire [NEURON_NUM-1:0]                    spike_out,
    output wire [NEURON_NUM * DATA_WIDTH-1:0]       membrane_potential
);

    wire [DATA_WIDTH-1:0]       beta_wire  [0:NEURON_NUM-1];
    wire [DATA_WIDTH-1:0]       alpha_wire [0:NEURON_NUM-1];

    wire [NEURON_NUM-1:0]       syn_valid_wire;
    wire [WEIGHT_WIDTH-1:0]     syn_weight_wire [0:NEURON_NUM-1];

    wire [THRESHOLD_WIDTH-1:0]  threshold_wire [0:NEURON_NUM-1];

    genvar i;

    generate
        for (i = 0; i < NEURON_NUM; i = i + 1) begin
            assign beta_wire[i]         = beta[i*DATA_WIDTH +: DATA_WIDTH];
            assign alpha_wire[i]        = alpha[i*DATA_WIDTH +: DATA_WIDTH];
            assign syn_weight_wire[i]   = syn_weight[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];
            assign threshold_wire[i]    = threshold[i*THRESHOLD_WIDTH +: THRESHOLD_WIDTH];
        end
    endgenerate
        
    generate
        for (i = 0; i < NEURON_NUM; i = i + 1) begin
            snntorch_model 
            #
            (
                .NEURON_ID(i),
                .DATA_WIDTH(DATA_WIDTH),
                .WEIGHT_WIDTH(WEIGHT_WIDTH),
                .THRESHOLD_WIDTH(THRESHOLD_WIDTH)
            )
                snn_model_inst
            (
                .clk(clk),
                .rst(rst),
                .enable(enable),
                .mode(mode),
                .lfsr_in(lfsr_in),
                .start(start),
                .ld(ld),
                .ready(ready),
                .beta(beta_wire[i]),
                .alpha(alpha_wire[i]),
                .syn_valid(syn_valid[i]),
                .syn_weight(syn_weight_wire[i]),
                .threshold(threshold_wire[i]),
                .spike_out(spike_out[i]),
                .membrane_potential(membrane_potential[i*DATA_WIDTH +: DATA_WIDTH])
            );
        end
    endgenerate

endmodule