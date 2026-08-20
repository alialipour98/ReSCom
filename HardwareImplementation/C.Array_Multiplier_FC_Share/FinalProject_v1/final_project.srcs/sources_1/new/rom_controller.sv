`timescale 1ns / 1ps

module rom_controller
#
(
    parameter ADDR_WIDTH    = 16,
    parameter INPUT_NUM     = 8,
    parameter NEURON_NUM    = 8
)
(
    input clk,
    input rst,
    input start,
    input ld_valid,
    input ld_weight,
    input ld_complete,
    input inc_weight_addr,
    output co_neuron,
    output reg process_completed,
    output reg ld_w,
    output reg [NEURON_NUM-1:0] ld_w_neuron_out,
    output reg [ADDR_WIDTH-1:0] rom_adderss
);

    reg [ADDR_WIDTH/2-1:0] cnt_weight_int;
    reg [ADDR_WIDTH/2-1:0] cnt_neuron_int;
    
    reg init_weight_cnt;
    reg init_neuron_cnt;
    reg inc_weight_cnt;
    reg inc_neuron_cnt;
    
    reg ld_valid_int;
    
    wire co_reg;

    wire ld_complete_delay;

    reg [NEURON_NUM-1:0] ld_w_neuron;

    wire [INPUT_NUM-1:0] shift_value;

    assign ld_w = ld_valid;
    assign shift_value[INPUT_NUM-1:1]   = 'b0;
    assign shift_value[0]               = 'b1;

    assign ld_w_neuron_out = (ld_valid_int) ? ld_w_neuron & {NEURON_NUM{ld_complete}}: {NEURON_NUM{1'b0}};

    assign rom_adderss  = {cnt_neuron_int, cnt_weight_int};

    assign co_reg       = (cnt_weight_int == INPUT_NUM - 1)  ? 1'b1 : 1'b0;
    assign co_neuron    = (cnt_neuron_int == NEURON_NUM) ? 1'b1 : 1'b0;

    typedef enum logic [2:0] {
        IDLE,
        INIT,
        LD_REG,
        LD_NEURON,
        END_PROCESS
    } state;
    
    state present_state;
    state next_state;

    always@(posedge clk, posedge rst)
    begin
        if (rst)
            present_state <= IDLE;
        else
            present_state <= next_state;
    end

    always_comb
    begin
        case(present_state)
        IDLE:
            begin
                if (start)
                    next_state <= INIT;
                else
                    next_state <= IDLE;
            end
        INIT:
            begin
                if (start)
                    next_state <= INIT;
                else
                    next_state <= LD_REG;
            end
        LD_REG:
            begin
                if (co_neuron)
                    next_state <= END_PROCESS;
                else if (co_reg)
                    next_state <= LD_NEURON;
                else
                    next_state <= LD_REG;            
            end
        LD_NEURON:
            begin
                if (co_neuron)
                    next_state <= END_PROCESS;
                else
                    next_state <= LD_REG;
            end
        END_PROCESS:
            next_state <= IDLE;
        endcase;    
    end

    always@(present_state)
    begin
        init_weight_cnt     <= 0;
        init_neuron_cnt     <= 0;
//      ld_w                <= 0;
        inc_weight_cnt      <= 0;
        inc_neuron_cnt      <= 0;
        process_completed   <= 1;
        ld_valid_int        <= 1;
                
        case(present_state)
        IDLE:
            begin
                init_weight_cnt     <= 1'b0;
                init_neuron_cnt     <= 1'b1;
                ld_w_neuron         <= 0;
            end
        INIT:
            begin
                init_weight_cnt     <= 1'b1;
                init_neuron_cnt     <= 1'b1;
                ld_w_neuron         <= shift_value;
                process_completed   <= 1'b0;
            end
        LD_REG:
            begin
                ld_w_neuron         <= shift_value << cnt_neuron_int;
//                ld_w                <= 1'b1;
                inc_weight_cnt      <= 1'b1;
                process_completed   <= 1'b0;
            end
        LD_NEURON:
            begin
                ld_valid_int        <= 1'b0;
                init_weight_cnt     <= 1'b1;
                inc_neuron_cnt      <= 1'b1;
                process_completed   <= 1'b0;
            end
        END_PROCESS:
            begin
                init_neuron_cnt     <= 1'b1;
                init_weight_cnt     <= 1'b1;
                ld_w_neuron         <= 0;
            end
        endcase;    
    end

    counter_nBit #( .num_bit(ADDR_WIDTH/2)) cnt_weight
    (
        .clk(clk),
        .rst(rst ),
        .inc(inc_weight_addr),
        .init(init_weight_cnt),
        .cnt_out(cnt_weight_int)
    );

    counter_nBit #( .num_bit(ADDR_WIDTH/2)) cnt_neuron
    (
        .clk(clk),
        .rst(rst),
        .inc(ld_complete),
        .init(init_neuron_cnt),
        .cnt_out(cnt_neuron_int)
    );

    register_nBit
    #
    (
        .num_bit(1)
    )
        reg_nBit
    (
        .clk(clk),
        .rst(rst),
        .init('b0),
        .ld('b1),
        .in_reg(ld_complete),
        .out_reg(ld_complete_delay)
    );

endmodule
