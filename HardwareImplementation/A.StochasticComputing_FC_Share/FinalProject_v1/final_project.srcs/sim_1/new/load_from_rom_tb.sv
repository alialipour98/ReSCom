`timescale 1ns / 1ps

module load_from_rom_tb();

    parameter ADDR_WIDTH = 16;
    parameter WEIGHT_NUM = 4;
    parameter WEIGHT_WIDTH = 16;
    parameter NEURON_NUM = 2;

    reg  clk;
    reg  rst;
    reg  init;
    reg  enable;
    reg  start;
    reg  start_param;
    reg  start_gen;
    reg  ld_gen;
    reg  ready_gen;
    reg  [1:0] mode;
    reg  [WEIGHT_NUM-1:0] alpha;
    reg  [WEIGHT_NUM-1:0] beta;
    reg  [WEIGHT_NUM-1:0] threshold;
    reg  [WEIGHT_WIDTH-1:0] lfsr_in;
    reg  [WEIGHT_NUM-1:0] spike;
    
    wire end_process;
    wire [NEURON_NUM-1:0] spike_out;
    wire [NEURON_NUM * WEIGHT_WIDTH -1:0] membrane_potential;

    load_from_rom
    #
    (
        .ADDR_WIDTH(ADDR_WIDTH),
        .WEIGHT_NUM(WEIGHT_NUM),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .NEURON_NUM(NEURON_NUM)
    )
        uut
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
        .end_process(end_process),
        .spike_out(spike_out),
        .membrane_potential(membrane_potential)
    );

    always #5 clk = ~clk;

    initial
    begin
        clk         <=  0;
        rst         <=  1;
        init        <=  0;
        enable      <=  0;
        start       <=  0;
        start_param <=  0;
        start_gen   <=  0;
        ld_gen      <=  0;
        ready_gen   <=  0;
        mode        <=  0;
        alpha       <=  0;
        beta        <=  0;
        threshold   <=  0;
        lfsr_in     <=  0;
        spike       <=  0;
        #10
        rst         <=  0;
        
        start       <=  1;
        start_param <=  1;
        #10
        start       <=  0;
        start_param <=  0;

    end

endmodule
