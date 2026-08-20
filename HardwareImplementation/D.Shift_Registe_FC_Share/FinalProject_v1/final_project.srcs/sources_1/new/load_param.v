`timescale 1ns / 1ps

module load_param
#
(
    parameter PARAM_WIDTH  = 8,
    parameter INPUT_NUM    = 2,
    parameter DELAY        = 10
)
(
    input  clk,
    input  rst,
    input  start,
    input  process_completed,
    input  ld_w,
    input  [PARAM_WIDTH-1:0] params,
    input  co_neuron,
    output inc_weight_addr,
    output [INPUT_NUM-1:0] ld_weight,
    output ld_valid,
    output ld_completed,
    output [INPUT_NUM * PARAM_WIDTH-1:0] out_params
);

    wire [INPUT_NUM-1:0] ld_param;
//    wire ld [0:INPUT_NUM-1];
    wire init;

    assign ld_weight = ld_param;

    genvar i;
//    generate
//        for (i = 0; i < INPUT_NUM; i = i + 1)
//        begin
//            assign ld[i] = ld_param[i];
//        end
//    endgenerate
    
    load_ctrl
    #
    (
        .INPUT_NUM(INPUT_NUM),
        .DELAY(DELAY)
    )
        ctrl
    (
        .clk(clk),
        .rst(rst),
        .ld_w(ld_w),
        .ld_valid(ld_valid),
        .co_neuron(co_neuron),
        .inc_weight_addr(inc_weight_addr),
        .start(start),
        .process_completed(process_completed),
        .ld_completed(ld_completed),
        .init(init),
        .ld_param(ld_param)
    );

    generate
        for(i = 0; i < INPUT_NUM; i = i + 1)
        begin
            register_nBit
            #
            (
                .num_bit(PARAM_WIDTH)
            )
                reg_nBit
            (
                .clk(clk),
                .rst(rst),
                .init(init),
                .ld(ld_param[i]),
                .in_reg(params),
                .out_reg(out_params[i * PARAM_WIDTH +: PARAM_WIDTH])
            );
        end
    endgenerate

endmodule
