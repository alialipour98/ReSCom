`timescale 1ns / 1ps

module SNN_ML_BRAM_tb();

    localparam DATA_WIDTH        = 16;
    localparam WEIGHT_WIDTH      = 16;
    localparam THRESHOLD_WIDTH   = 16;
    localparam SAMPLE_NUM        = 2;
    localparam INPUT_NUM_L1      = 4;
    localparam NEURON_NUM_L1     = 4;
    localparam INPUT_NUM_L2      = 4;
    localparam NEURON_NUM_L2     = 10;
    localparam DELAY             = 25;
    localparam CLK_PERIOD        = 10;

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
    reg  ld_seed;
    reg  [WEIGHT_WIDTH + $clog2(NEURON_NUM_L2)-1: 0]                seed;
    reg  [WEIGHT_WIDTH + $clog2(NEURON_NUM_L2)-1: 0]                poly;
    reg  [WEIGHT_WIDTH-1:0]                 alpha;
    reg  [WEIGHT_WIDTH-1:0]                 beta;
    reg  [WEIGHT_WIDTH-1:0]                 threshold;
    reg  [INPUT_NUM_L1-1:0]                 spike;
    wire [NEURON_NUM_L2-1:0]                spike_out;
    wire [INPUT_NUM_L2 * WEIGHT_WIDTH -1:0] membrane_potential;


    // Test Parameter
    integer spike_count [0:NEURON_NUM_L2-1];
    integer                     test_num        = 0;
    integer                     cycle_count     = 0;
    integer                     error_count     = 0;
    integer                     i = 0, j = 0, k = 0;

    integer                     file_alpha      = 0;
    integer                     file_beta       = 0;
    integer                     file_threshold  = 0;
    integer                     file_weight     = 0;

    real                        spike_frequency[0:NEURON_NUM_L2-1];

    // Test logging
    reg [255:0] test_name = 0;

    ///////////////////////////////////////////////////////////////////////////////////////
    reg [INPUT_NUM_L1-1:0] xinput [0:SAMPLE_NUM-1];  // 100 elements, each 256 bits
    integer file;
    reg bit_value;
    reg [INPUT_NUM_L1-1:0] temp;
    
    initial begin
        file = $fopen("rand_input.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open file");
            $finish;
        end
        
        for (i = 0; i < SAMPLE_NUM; i = i + 1) begin
            temp = 'd0;  // Initialize temporary storage
            
            for (j = INPUT_NUM_L1-1; j >= 0; j = j - 1) begin
                if ($feof(file)) begin
                    $display("Error: Unexpected end of file at element %d, bit %d", i, j);
                    $fclose(file);
                    $finish;
                end
                
                // Read one bit from the file
                $fscanf(file, "%b\n", bit_value);
                
                // Store the bit in the correct position
                temp[j] = bit_value;
            end
            
            // Assign the completed 256-bit value to the array
            xinput[i] = temp;
        end
        
        $fclose(file);
        
//      Verification
        $display("First element: xinput[0] = %h", xinput[0]);
        $display("Last element: xinput[%d] = %h", SAMPLE_NUM, xinput[SAMPLE_NUM]);
    end
    ///////////////////////////////////////////////////////////////////////////////////////
    
    typedef enum reg [1:0] {
        IF,
        LIF,
        SYNAPTIC
    } MODEL;
    MODEL current_model;

    SNN_ML_BRAM
    #
    (
        .ADDR_WIDTH(),
        .WEIGHT_NUM_L1(INPUT_NUM_L1),
        .WEIGHT_NUM_L2(INPUT_NUM_L2),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .NEURON_NUM_L1(NEURON_NUM_L1),
        .NEURON_NUM_L2(NEURON_NUM_L2),
        .DELAY(DELAY)
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
        .ld_seed(ld_seed),
        .ready_gen(ready_gen),
        .seed(seed),
        .poly(poly),
        .mode(mode),
        .alpha(alpha),
        .beta(beta),
        .threshold(threshold),
        .spike(spike),
        .spike_out(spike_out),
        .membrane_potential(membrane_potential)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Initialize test
    task init_test(input [255:0] name);
        begin
            for (i = 0; i < NEURON_NUM_L2; i = i + 1) begin
                spike_count[i] = 0;
            end
            test_name       = name;
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
    task apply_synapse(input [INPUT_NUM_L1-1:0] inputs);
        begin
            @(posedge clk);
            spike         = inputs;
        end
    endtask

    always@(posedge clk)
    begin
        for (i = 0; i < NEURON_NUM_L2; i = i + 1)
        begin
            if (spike_out[i])
                spike_count[i] <= spike_count[i] + 1;
        end
    end

    initial
    begin
        clk                 <= 0;
        rst                 <= 1;
        enable              <= 0;
        mode                <= 0;
        init                <= 0;
        beta                <= 0;
        alpha               <= 0;
        spike               <= 0;
        threshold           <= 0;
        start_param         <= 0;
        start_gen           <= 0;
        ld_gen              <= 0;
        ready_gen           <= 0;
        ld_seed             <= 0;
        current_model       <= IF;

        start        = 0;
        seed         = $random($time);
        poly         = {WEIGHT_WIDTH{1'b1}};

        #10
        rst = 0;

        for (i = 0; i < NEURON_NUM_L2; i = i + 1)
        begin
                spike_count[i] = 0;
        end
        
        // Re-enable
        enable = 1'b1;

        for (k = 0; k < SAMPLE_NUM; k = k + 1) 
        begin
            apply_synapse(xinput[k]);
            #4000;
            start       <=  1;
            start_param <=  1;
            ld_seed     <=  1;
            #10
            start       <=  0;
            start_param <=  0;
            ld_seed     <=  0;
        end

        for (i = 0; i < NEURON_NUM_L2; i = i + 1) begin
            spike_count[i] = 0;
        end
    end

endmodule
