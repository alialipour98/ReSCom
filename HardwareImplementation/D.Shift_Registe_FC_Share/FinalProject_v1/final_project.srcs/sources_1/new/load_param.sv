`timescale 1ns / 1ps

module load_ctrl
#
(
    parameter INPUT_NUM = 256,
    parameter DELAY     = 10
)
(
    input clk,
    input rst,
    input start,
    input ld_w,
    input process_completed,
    input co_neuron,
    input inc_weight_addr,
    output reg ld_valid,
    output reg init,
    output reg ld_completed,
    output reg [INPUT_NUM-1:0] ld_param
);


    reg [$clog2(INPUT_NUM):0] cnt_int;
    reg init_cnt;
    reg inc_cnt;
    
    reg [$clog2(DELAY)+1:0] delay_cnt_int;
    reg delay_init_cnt;
    reg delay_inc_cnt;
    
    reg [INPUT_NUM-1:0] ld_w_reg;
    
    wire co;
    wire delay_co;

    wire [INPUT_NUM-1:0] shift_value;

    // Delay Registers
    wire [INPUT_NUM-1:0] ld_param_delay0;
    wire [INPUT_NUM-1:0] ld_param_delay1;

    assign shift_value[INPUT_NUM-1:1]   = 'b0;
    assign shift_value[0]               = 'b1;
    
    assign co               = (cnt_int       == INPUT_NUM+1) ? 'b1 : 'b0;
    assign delay_co         = (delay_cnt_int == DELAY)       ? 'b1 : 'b0;
    assign ld_param         = ld_valid ? ld_param_delay1 & {INPUT_NUM{ld_w}} : 'b0;
    assign inc_weight_addr  = |ld_w_reg;
    
    typedef enum logic [2:0] {
        IDLE,
        INIT,
        LDW,
        INC,
        LD_COMP,
        PROCESS_COMP
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
                        next_state <= LDW;
                end
            LDW:
                if (co | co_neuron)
                    next_state <= LD_COMP;
                else
                    next_state <= LDW;
            LD_COMP:
                if (delay_co)
                    next_state  <= PROCESS_COMP;
                else
                    next_state  <= LD_COMP;
            PROCESS_COMP:
                if (process_completed)
                    next_state <= IDLE;
                else
                    next_state <= LDW;
        endcase;    
    end

    always@(present_state, cnt_int)
    begin
        init_cnt        <= 'b0;
        inc_cnt         <= 'b0;
        init            <= 'b0;
        ld_valid        <= 'b0;
        ld_w_reg        <= 'b0;
        ld_completed    <= 'b0;
        delay_init_cnt  <= 'b0;
        delay_inc_cnt   <= 'b0;
        
        case(present_state)
            IDLE:
                begin
                    init_cnt        <= 'b1;
                    delay_init_cnt  <= 'b1;
                    init            <= 'b0;
                end                
            INIT:
                begin
                    init_cnt        <= 'b1;
                    delay_init_cnt  <= 'b1;
                    init            <= 'b1;
                end
            LDW:
                begin
                    ld_w_reg        <= shift_value << cnt_int;
                    ld_valid        <= 'b1;
                    inc_cnt         <= 'b1;
                end
            LD_COMP:
                begin
                    delay_inc_cnt   <= 'b1;
                end
            PROCESS_COMP:
                begin
                    ld_completed    <= 'b1;
                end
        endcase;    
    end

    counter_nBit #( .num_bit($clog2(INPUT_NUM)+2)) cnt
    (
        .clk(clk),
        .rst(rst),
        .inc(inc_cnt),
        .init(init_cnt | co),
        .cnt_out(cnt_int)
    );

    counter_nBit #( .num_bit($clog2(DELAY)+2)) delay_cnt
    (
        .clk(clk),
        .rst(rst),
        .inc(delay_inc_cnt),
        .init(delay_init_cnt | delay_co),
        .cnt_out(delay_cnt_int)
    );

    register_nBit
    #
    (
        .num_bit(INPUT_NUM)
    )
        Delay_0
    (
        .clk(clk),
        .rst(rst),
        .init('b0),
        .ld('b1),
        .in_reg(ld_w_reg),
        .out_reg(ld_param_delay0)
    );

    register_nBit
    #
    (
        .num_bit(INPUT_NUM)
    )
        Delay_1
    (
        .clk(clk),
        .rst(rst),
        .init('b0),
        .ld('b1),
        .in_reg(ld_param_delay0),
        .out_reg(ld_param_delay1)
    );


endmodule