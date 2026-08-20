`timescale 1ns / 1ps

module snntorch_model_tb();

    // Parameters
    localparam DATA_WIDTH      = 16;
    localparam WEIGHT_WIDTH    = 16;
    localparam THRESHOLD_WIDTH = 16;
    localparam CLK_PERIOD      = 10;

    // DUT Inputs
    reg clk;
    reg rst;
    reg enable;
    reg syn_valid;
    reg [WEIGHT_WIDTH-1:0] syn_weight;
    reg [THRESHOLD_WIDTH-1:0] threshold;
    reg reset_potential_en;

    reg [1:0] mode;

    // DUT Outputs
    wire spike_out;
    wire [DATA_WIDTH-1:0] membrane_potential;

    // Test Parameter
    integer                     test_num;
    integer                     spike_count;
    integer                     cycle_count;
    integer                     error_count;
    integer                     i, j;

    real                        spike_frequency;

    // Test logging
    reg [255:0] test_name;

    reg [DATA_WIDTH-1:0] alpha;
    reg [DATA_WIDTH-1:0] beta;

    typedef enum reg [1:0] {
        IF,
        LIF,
        SYNAPTIC
    } MODEL;

    MODEL current_model;

    // Instantiate DUT
    snntorch_model
    #
    (
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .THRESHOLD_WIDTH(THRESHOLD_WIDTH)
    ) 
        dut
    (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .beta(beta),
        .alpha(alpha),
        .enable(enable),
        .syn_valid(syn_valid),
        .syn_weight(syn_weight),
        .threshold(threshold),
        .spike_out(spike_out),
        .membrane_potential(membrane_potential)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Initialize test
    task init_test(input [255:0] name);
        begin
            test_name       = name;
            spike_count     = 0;
            cycle_count     = 0;
            $display("\n========================================");
            $display("Test %0d: %0s", test_num, test_name);
            $display("========================================");
            test_num = test_num + 1;
        end
    endtask
    
    // Wait and monitor
    task wait_and_monitor(input integer cycles);
        integer k;
        begin
            for (k = 0; k < cycles; k = k + 1) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end
        end
    endtask
    
    // Check membrane potential
    task check_membrane(input [DATA_WIDTH-1:0] expected, input integer tolerance);
        begin
            if (membrane_potential < expected - tolerance || 
                membrane_potential > expected + tolerance) begin
                $display("ERROR: Membrane potential mismatch. Expected=%0d±%0d, Got=%0d", 
                         expected, tolerance, membrane_potential);
                error_count = error_count + 1;
            end else begin
                $display("PASS: Membrane potential correct: %0d", membrane_potential);
            end
        end
    endtask
    
    // Apply reset
    task apply_reset();
        begin
            @(posedge clk);
            rst = 1'b1;
            repeat(5) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
        end
    endtask
    
    // Apply single synaptic input
    task apply_synapse(input [WEIGHT_WIDTH-1:0] weight);
        begin
            @(posedge clk);
            syn_valid   = 1'b1;
            syn_weight  = weight;
            @(posedge clk);
            syn_valid   = 1'b1;
            syn_weight  = weight;
        end
    endtask
    
    // Apply burst of synaptic inputs
    task apply_synapse_burst(
        input [WEIGHT_WIDTH-1:0] weight, 
        input integer count
    );
        integer j;
        begin
            for (j = 0; j < count; j = j + 1) begin
                apply_synapse(weight);
            end
        end
    endtask

    always@(posedge clk)
    begin
        if (spike_out)
            spike_count <= spike_count + 1;
    end

    initial
    begin
        clk                 = 0;
        rst                 = 1;
        beta                = 'd19661;
        alpha               = 'd31785;
        enable              = 0;
        syn_valid           = 0;
        syn_weight          = 'd100;
        mode                = 'b01;
        threshold           = 'd2265;
        
        // Initial reset
        apply_reset();
        enable = 1'b1;
        wait_and_monitor(10);
                
        // Re-enable
        enable = 1'b1;
        
        //---------------------------------------------------------------------
        // Test 9: Spike Frequency Response
        //---------------------------------------------------------------------
        init_test("Spike Frequency Response");
        apply_reset();
        spike_count = 0;
        
        // Apply constant input for 1000 cycles
        for (j = 2; j < 3; j = j + 1)
        begin
            mode            = j;
            current_model = MODEL'(j);            
            for (i = 0; i < 1000; i = i + 1) 
            begin
                apply_synapse('d100);
                wait_and_monitor(1);
            end
        end
        
        spike_frequency = (spike_count * 1.0e9) / (i * CLK_PERIOD);
        $display("  Input weight=40, Spike count=%0d, Frequency=%.2f MHz", 
                 spike_count, spike_frequency);

    end
        
endmodule