`timescale 1ns / 1ps

module snntorch_model #(
    parameter NEURON_ID         = 0,
    parameter DATA_WIDTH        = 16,    // Q1.15 membrane potential
    parameter WEIGHT_WIDTH      = 8,     // input weight width
    parameter THRESHOLD_WIDTH   = 16     // Q1.15 threshold
)(
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         enable,

    // Mode selector
    input  wire [1:0]                   mode,   // 00: IF, 10: Synaptic

    // Decay factors (Q1.15)
    input  wire [DATA_WIDTH-1:0]        beta,   // synaptic current decay
    input  wire [DATA_WIDTH-1:0]        alpha,  // membrane potential decay

    // Input spike & weight
    input  wire                         syn_valid,       // spike input
    input  wire [WEIGHT_WIDTH-1:0]      syn_weight,      // unsigned weight

    // Parameters
    input  wire [THRESHOLD_WIDTH-1:0]   threshold,

    // Outputs
    output reg                          spike_out,
    output wire [DATA_WIDTH-1:0]        membrane_potential
);

    wire [DATA_WIDTH-1:0] I_t_stream;
    wire [DATA_WIDTH-1:0] v_mem_stream;

    wire ready_I_t;
    wire ready_v_mem;

    // Internal registers
    reg [DATA_WIDTH-1:0] v_mem;   // membrane potential u[t]
    reg [DATA_WIDTH-1:0] I_t;     // synaptic current I[t] (only used in synaptic)
    
    // Internal intermediate wires for synaptic model
//    wire signed [2*DATA_WIDTH-1:0] I_decay_mult = I_t * beta;
      wire signed [DATA_WIDTH-1:0] I_decay_mult;
//    wire signed [DATA_WIDTH-1:0]   I_next = 
//                    I_decay_mult[2*DATA_WIDTH-1:2*DATA_WIDTH-DATA_WIDTH-1] +
//                    (syn_valid ? {{(DATA_WIDTH-WEIGHT_WIDTH){1'b0}}, syn_weight} : 0);
    wire signed [DATA_WIDTH-1:0]   I_next = 
                    I_decay_mult +
                    (syn_valid ? {{(DATA_WIDTH-WEIGHT_WIDTH){1'b0}}, syn_weight} : 0);

//    wire signed [2*DATA_WIDTH-1:0] V_decay_mult = v_mem * alpha;
//    wire signed [DATA_WIDTH-1:0]   V_next = V_decay_mult[2*DATA_WIDTH-1:2*DATA_WIDTH-DATA_WIDTH-1];
    wire signed [DATA_WIDTH-1:0]   V_decay_mult;
    wire signed [DATA_WIDTH-1:0]   V_next = V_decay_mult;

    wire signed [DATA_WIDTH:0]     v_mem_next_syn = syn_valid ? (V_next + I_next) : v_mem;

    // Internal intermediate wires for IF model
    wire signed [DATA_WIDTH:0]     v_mem_next_if = syn_valid ?
                $signed({1'b0, v_mem}) + {{(DATA_WIDTH-WEIGHT_WIDTH+1){1'b0}}, syn_weight} :
                $signed({1'b0, v_mem});

    // Internal intermediate wires for IF model
//    wire signed [2*DATA_WIDTH-1:0] V_leaky_mult = v_mem * alpha;
//    wire signed [DATA_WIDTH-1:0]   V_leaky_next = 
//                    V_leaky_mult[2*DATA_WIDTH-1:2*DATA_WIDTH-DATA_WIDTH-1];
    wire signed [DATA_WIDTH-1:0] V_leaky_next = V_decay_mult;

    wire signed [DATA_WIDTH:0] v_mem_next_lif = syn_valid ?
                $signed({1'b0, V_leaky_next}) + {{(DATA_WIDTH-WEIGHT_WIDTH+1){1'b0}}, syn_weight} :
                $signed({1'b0, V_leaky_next});

    assign membrane_potential = v_mem;

    shift_add_multiplier 
    #
    (
        .WIDTH(WEIGHT_WIDTH)
    )
        I_decay_mult_inst
    (
        .A(I_t),
        .B(beta),
        .P(I_decay_mult)
    );

    shift_add_multiplier 
    #
    (
        .WIDTH(WEIGHT_WIDTH)
    )
        v_mem_mult_inst
    (
        .A(v_mem),
        .B(alpha),
        .P(I_decay_mult)
    );

    // Main neuron logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_mem     <= 0;
            I_t       <= 0;
            spike_out <= 0;
        end
        else if (enable) begin
            case (mode)
                2'b00: begin    // IF neuron
                    if (v_mem_next_if[DATA_WIDTH]) begin
                        v_mem       <= 0;
                    end else if (|v_mem_next_if[DATA_WIDTH:DATA_WIDTH-1]) begin
                        v_mem       <= threshold;  // saturation protection
                    end else begin
                        v_mem       <= v_mem_next_if[DATA_WIDTH-1:0];
                    end

                    if (v_mem >= threshold) begin
                        spike_out   <= 1;
                        v_mem       <= 0;
                    end else begin
                        spike_out   <= 0;
                    end
                end

                2'b01: begin    // LIF neuron
                    if (v_mem_next_lif[DATA_WIDTH]) begin
                        v_mem       <= 0;
                    end else if (|v_mem_next_lif[DATA_WIDTH:DATA_WIDTH-1]) begin
                        v_mem       <= threshold;  // saturation protection
                    end else begin
                        v_mem       <= v_mem_next_lif[DATA_WIDTH-1:0];
                    end

                    if (v_mem >= threshold) begin
                        spike_out   <= 1;
                        v_mem       <= 0;
                    end else begin
                        spike_out   <= 0;
                    end
                end
                2'b10: begin    // Synaptic neuron
                    I_t <= I_next;

                    if (v_mem_next_syn[DATA_WIDTH]) begin
                        v_mem       <= 0;
                    end else if (|v_mem_next_syn[DATA_WIDTH:DATA_WIDTH-1]) begin
                        v_mem       <= threshold;
                    end else begin
                        v_mem       <= v_mem_next_syn[DATA_WIDTH-1:0];
                    end

                    if (v_mem >= threshold) begin
                        spike_out   <= 1;
                        v_mem       <= 0;
                    end else begin
                        spike_out <= 0;
                    end
                end

                default: begin
                    v_mem       <= v_mem;
                    spike_out   <= 0;
                end
            endcase
        end
    end

endmodule