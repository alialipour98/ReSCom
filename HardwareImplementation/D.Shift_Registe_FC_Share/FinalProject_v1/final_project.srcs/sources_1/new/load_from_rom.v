`timescale 1ns / 1ps

module load_from_rom
#
(
    parameter ADDR_WIDTH      = 16,
    parameter WEIGHT_NUM      = 16,
    parameter WEIGHT_WIDTH    = 16,
    parameter NEURON_NUM      = 2,
    parameter DELAY           = 10
)
(
    input  clk,
    input  rst,
    input  init,
    input  enable,
    input  start,
    input  start_param,
    input  [1:0] mode,
    input  [WEIGHT_WIDTH-1:0] alpha,
    input  [WEIGHT_WIDTH-1:0] beta,
    input  [WEIGHT_WIDTH-1:0] threshold,
    input  [WEIGHT_NUM-1:0] spike,
    output end_process,
    output [NEURON_NUM-1:0] spike_out,
    output [NEURON_NUM * WEIGHT_WIDTH -1:0] membrane_potential
);

    wire [WEIGHT_WIDTH-1:0]                         BRAM_addr;
    wire [WEIGHT_WIDTH-1:0]                         BRAM_data;
    wire [WEIGHT_NUM * WEIGHT_WIDTH-1:0]            out_params;
    wire [WEIGHT_WIDTH + $clog2(WEIGHT_NUM)-1:0]    sum;
    wire                                            ld_completed;    

    wire ld_w;
    wire ld_valid;
    wire ld_weight;
        
    wire [WEIGHT_NUM-1:0] ld_weight_inst;
    
    wire process_completed;

    wire co_neuron;

    wire inc_weight_addr;

    wire [NEURON_NUM-1:0] syn_valid;
    wire [(WEIGHT_WIDTH + $clog2(WEIGHT_NUM) * NEURON_NUM) -1:0] input_neurons;
    genvar i;
    
    blk_mem_gen_0 BRAM_WEIGHT (
      .clka(clk),
      .ena('b1),
      .addra(BRAM_addr),
      .douta(BRAM_data)
    );

    assign end_process = process_completed;

    load_param
    #
    (
        .PARAM_WIDTH(WEIGHT_WIDTH),
        .INPUT_NUM(WEIGHT_NUM),
        .DELAY(DELAY)
    )
        weights
    (
        .clk(clk),
        .rst(rst),
        .start(start_param),
        .ld_w(ld_w),
        .ld_weight(ld_weight_inst),
        .ld_valid(ld_valid),
        .inc_weight_addr(inc_weight_addr),
        .co_neuron(co_neuron),
        .process_completed(process_completed),
        .params(BRAM_data),
        .ld_completed(ld_completed),
        .out_params(out_params)
    );

    signed_adder_tree #(
        .INPUT_WIDTH(WEIGHT_WIDTH),
        .NUM_INPUTS(WEIGHT_NUM)
    )
        fc_layer 
    (
        .clk(clk),
        .rst(rst),
        .inputs(out_params),
        .spike(spike),
        .sum(sum)
    );

    generate
        for (i = 0; i < NEURON_NUM; i = i + 1) begin
            snntorch_model 
            #
            (
                .NEURON_ID(i),
                .DATA_WIDTH(WEIGHT_WIDTH + $clog2(WEIGHT_NUM)),
                .WEIGHT_WIDTH(WEIGHT_WIDTH + $clog2(WEIGHT_NUM)),
                .THRESHOLD_WIDTH(WEIGHT_WIDTH + $clog2(WEIGHT_NUM))
            )
                snn_model_inst
            (
                .clk(clk),
                .rst(rst),
                .enable(enable),
                .mode(mode),
                .beta({ {(WEIGHT_WIDTH - $clog2(WEIGHT_NUM)){beta[WEIGHT_WIDTH-1]}}, beta}),
                .alpha({ {(WEIGHT_WIDTH - $clog2(WEIGHT_NUM)){alpha[WEIGHT_WIDTH-1]}}, alpha}),
                .syn_valid(syn_valid[i]),
                .syn_weight(sum),
                .threshold({ {(WEIGHT_WIDTH - $clog2(WEIGHT_NUM)){threshold[WEIGHT_WIDTH-1]}}, threshold}),
                .spike_out(spike_out[i]),
                .membrane_potential(membrane_potential[i*WEIGHT_WIDTH +: WEIGHT_WIDTH])
            );
        end
    endgenerate

    rom_controller
    #
    (
        .ADDR_WIDTH(ADDR_WIDTH),
        .INPUT_NUM(WEIGHT_NUM),
        .NEURON_NUM(NEURON_NUM)
    )
        rom_ctrl
    (
        .clk(clk),
        .rst(rst),
        .start(ld_weight_inst[0]),
        .process_completed(process_completed),
        .inc_weight_addr(inc_weight_addr),
        .ld_w(ld_w),
        .co_neuron(co_neuron),
        .ld_complete(ld_completed),
        .ld_weight(|ld_weight_inst),
        .ld_valid(ld_valid),
        .ld_w_neuron_out(syn_valid),
        .rom_adderss(BRAM_addr)
    );

endmodule
