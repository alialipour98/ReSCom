`timescale 1ns / 1ps
module signed_adder_tree #(
    parameter INPUT_WIDTH   = 16,
    parameter NUM_INPUTS    = 4,
    parameter SUM_WIDTH     = INPUT_WIDTH + $clog2(NUM_INPUTS),
    parameter NUM_STAGES    = $clog2(NUM_INPUTS)
) (
    input wire clk,
    input wire rst,
    input wire signed [INPUT_WIDTH * NUM_INPUTS-1:0] inputs,
    input wire [NUM_INPUTS-1:0] spike,
    output reg signed [SUM_WIDTH-1:0] sum
);
    
    // Declare stage registers with proper initialization
    reg signed [SUM_WIDTH-1:0] stage [0:NUM_STAGES][0:NUM_INPUTS-1];
    wire signed [INPUT_WIDTH-1:0] inputs_array [0:NUM_INPUTS-1];
    
    integer i, j;
    integer num_pairs;

    // Unpack input vector into array
    genvar w;
    generate
        for (w = 0; w < NUM_INPUTS; w = w + 1) begin : INPUT_UNPACK
            assign inputs_array[w] = inputs[INPUT_WIDTH * (w+1) - 1 : INPUT_WIDTH * w];
        end
    endgenerate
    
    // Combinational adder tree logic
    always @(*) begin
        // Initialize first stage with sign-extended inputs
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin
            stage[0][i] = spike[i] ? { {SUM_WIDTH-INPUT_WIDTH{inputs_array[i][INPUT_WIDTH-1]}}, 
                         inputs_array[i] } : 'b0;
        end
        
        // Build the adder tree stages
        for (i = 1; i <= NUM_STAGES; i = i + 1) begin
            // Calculate how many pairs we need to process in this stage
            num_pairs = (NUM_INPUTS + (1 << i) - 1) >> i;
            
            // Process pairs
            for (j = 0; j < num_pairs; j = j + 1) begin
                if ((2*j+1) < NUM_INPUTS) begin
                    stage[i][j] = stage[i-1][2*j] + stage[i-1][2*j+1];
                end else begin
                    // If odd number of elements, pass through the last one
                    stage[i][j] = stage[i-1][2*j];
                end
            end
            
            // Zero out unused elements in current stage
            for (j = num_pairs; j < NUM_INPUTS; j = j + 1) begin
                stage[i][j] = 0;
            end
        end
    end
    
    // Registered output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= 0;
        end else begin
            sum <= stage[NUM_STAGES][0];
        end
    end
endmodule