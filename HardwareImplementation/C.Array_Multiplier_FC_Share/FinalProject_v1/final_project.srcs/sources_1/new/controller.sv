`timescale 1ns / 1ps

module controller
(
    clk,
    rst,
    ld,
    sht,
    start,
    co,
    init_cnt,
    inc_cnt
);

    input  clk;
    input  rst;
    input  start;
    input  co;
    
    output reg ld;
    output reg sht;
    output reg init_cnt;
    output reg inc_cnt;
    
    typedef enum reg [1:0] {
        INIT    = 2'b00,
        STRT    = 2'b01,
        CNTO    = 2'b10
    } state_t;

    state_t present_state;    
    state_t next_state;    


    always@(posedge clk, posedge rst)
    begin
        if (rst)
            present_state <= INIT;
        else
            present_state <= next_state;
    end

    always@(present_state, start, co)
    begin
        case(present_state)
            INIT : 
                if (start)
                    next_state <= STRT;
                else
                    next_state <= INIT;
            STRT : 
                if (start)
                    next_state <= STRT;
                else
                    next_state <= CNTO;
            CNTO :
                if (co)
                    next_state <= INIT;
                else
                    next_state <= CNTO;
            default : 
                next_state <= INIT;
        endcase
    end

    always@(present_state, co)
    begin
        {ld, sht, init_cnt, inc_cnt} = 0;        
        case(present_state)
            INIT :
                begin 
                    init_cnt    <= 'b1;
                    ld          <= 'b1;
                end
            CNTO :
                begin
                    sht         <= 'b1;
                    inc_cnt     <= 'b1;
                end
        endcase
    end

endmodule
