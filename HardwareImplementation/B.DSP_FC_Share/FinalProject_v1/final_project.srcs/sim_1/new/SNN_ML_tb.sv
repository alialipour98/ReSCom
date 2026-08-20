`timescale 1ns / 1ps

module SNN_ML_tb();

    localparam DATA_WIDTH        = 16;
    localparam WEIGHT_WIDTH      = 16;
    localparam THRESHOLD_WIDTH   = 16;
    localparam SAMPLE_NUM        = 100;
    localparam INPUT_NUM_L1      = 4;
    localparam NEURON_NUM_L1     = 4;
    localparam INPUT_NUM_L2      = 4;
    localparam NEURON_NUM_L2     = 10;
    localparam CLK_PERIOD        = 10;

    reg                       clk;
    reg                       rst;
    reg                       enable;
    reg                       ld_start;
    reg                       ldw_l1;
    reg                       ldw_l2;
    reg                       ldb_l1;
    reg                       ldb_l2;
    reg                       lda_l1;
    reg                       lda_l2;
    reg                       ldth_l1;
    reg                       ldth_l2;
    reg [1:0]                 mode;
    reg [DATA_WIDTH-1:0]      beta;
    reg [DATA_WIDTH-1:0]      alpha;
    reg [INPUT_NUM_L1-1:0]    input_spike;
    reg [NEURON_NUM_L1-1:0]   syn_valid_l1;
    reg [NEURON_NUM_L1-1:0]   syn_valid_l2;
    reg [THRESHOLD_WIDTH-1:0] threshold;
    reg [WEIGHT_WIDTH-1: 0]   weight = 0;

    reg                       start;
    reg [WEIGHT_WIDTH-1: 0]   seed;
    reg [WEIGHT_WIDTH-1: 0]   poly;
    
    wire                      ready;

    wire                      ld_completed_l1;
    wire                      ldb_completed_l1;
    wire                      lda_completed_l1;
    wire                      ldth_completed_l1;
    wire                      ld_completed_l2;
    wire                      ldb_completed_l2;
    wire                      lda_completed_l2;
    wire                      ldth_completed_l2;
    wire [NEURON_NUM_L2-1:0]  spike_out;

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

    SNN_ML
    #
    (
        .INPUT_NUM_L1(INPUT_NUM_L1),
        .NEURON_NUM_L1(NEURON_NUM_L1),
        .INPUT_NUM_L2(INPUT_NUM_L2),
        .NEURON_NUM_L2(NEURON_NUM_L2),
        .DATA_WIDTH(DATA_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .THRESHOLD_WIDTH(THRESHOLD_WIDTH)
    )
        dut
    (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .ld_start(ld_start),
        .start(start),
        .ldw_l1(ldw_l1),
        .ldw_l2(ldw_l2),
        .ldb_l1(ldb_l1),
        .ldb_l2(ldb_l2),
        .lda_l1(lda_l1),
        .lda_l2(lda_l2),
        .ldth_l1(ldth_l1),
        .ldth_l2(ldth_l2),
        .mode(mode),
        .beta(beta),
        .alpha(alpha),
        .input_weight(weight),
        .seed(seed),
        .poly(poly),
        .spike(input_spike),
        .syn_valid_l1(syn_valid_l1),
        .syn_valid_l2(syn_valid_l2),
        .threshold(threshold),
        .ld_completed_l1(ld_completed_l1),
        .ldb_completed_l1(ldb_completed_l1),
        .lda_completed_l1(lda_completed_l1),
        .ldth_completed_l1(ldth_completed_l1),
        .ld_completed_l2(ld_completed_l2),
        .ldb_completed_l2(ldb_completed_l2),
        .lda_completed_l2(lda_completed_l2),
        .ldth_completed_l2(ldth_completed_l2),
        .spike_out(spike_out)
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
            syn_valid_l1        = {INPUT_NUM_L1{1'b1}};
            syn_valid_l2        = {INPUT_NUM_L2{1'b1}};
            input_spike         = inputs;
            @(posedge clk); 
            syn_valid_l1        = {INPUT_NUM_L1{1'b1}};
            syn_valid_l2        = {INPUT_NUM_L2{1'b1}};
            input_spike         = 0;
        end
    endtask
    
    // Apply burst of synaptic inputs
//    task apply_synapse_burst(
//        input integer count
//    );
//        integer j;
//        begin
//            for (j = 0; j < count; j = j + 1) begin
//                apply_synapse();
//            end
//        end
//    endtask

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
        clk                 = 0;
        rst                 = 1;
        enable              = 0;
        ld_start            = 0;
        ldw_l1              = 0;
        ldw_l2              = 0;
        ldb_l1              = 0;
        ldb_l2              = 0;
        lda_l1              = 0;
        lda_l2              = 0;
        ldth_l1             = 0;
        ldth_l2             = 0;
        mode                = 0;
        beta                = 0;
        alpha               = 0;
        input_spike         = 0;
        syn_valid_l1        = 0;
        syn_valid_l2        = 0;
        threshold           = 0;
        current_model       = IF;

        start        = 0;
        seed         = $random($time);
        poly         = {WEIGHT_WIDTH{1'b1}};

        for (i = 0; i < NEURON_NUM_L2; i = i + 1)
        begin
                spike_count[i] = 0;
        end
        
        #20
        rst         = 0;
        ld_start    = 1;
        #10
        ld_start    = 0;
        #15

        file_alpha = $fopen("alpha.txt", "r");
                
        for (k = 0; k < NEURON_NUM_L1; k = k + 1)
        begin
            $fscanf(file_alpha, "%h\n", alpha);
            #10;
            lda_l1 = 1;
            #10;
            lda_l1 = 0;
            #20;
        end

        #10;

        file_beta = $fopen("beta.txt", "r");
                
        for (k = 0; k < NEURON_NUM_L1; k = k + 1)
        begin
            $fscanf(file_beta, "%h\n", beta);
            #10;
            ldb_l1 = 1;
            #10;
            ldb_l1 = 0;
            #20;
        end

        #10;  

        file_threshold = $fopen("threshold.txt", "r");
                
        for (k = 0; k < NEURON_NUM_L1; k = k + 1)
        begin
            $fscanf(file_threshold, "%h\n", threshold);
            #10;
            ldth_l1 = 1;
            #10;
            ldth_l1 = 0;
            #20;
        end

        #10;


        file_weight = $fopen("weights.txt", "r");
                
        for (k = 0; k < NEURON_NUM_L1; k = k + 1)
        begin
            for (j = 0; j < INPUT_NUM_L1; j = j + 1)
            begin
                #10;
                ldw_l1 = 1;
                #10;
                ldw_l1 = 0;
                $fscanf(file_weight, "%h\n", weight);
            end
            #20;
        end

        #10;

        for (k = 0; k < NEURON_NUM_L2; k = k + 1)
        begin
            $fscanf(file_alpha, "%h\n", alpha);
            #10;
            lda_l2 = 1;
            #10;
            lda_l2 = 0;
            #20;
        end
        
        $fclose(file_alpha);
        
        for (k = 0; k < NEURON_NUM_L2; k = k + 1)
        begin
            $fscanf(file_beta, "%h\n", beta);
            #10;
            ldb_l2 = 1;
            #10;
            ldb_l2 = 0;
            #20;
        end
        
        $fclose(file_beta);

        for (k = 0; k < NEURON_NUM_L2; k = k + 1)
        begin
            $fscanf(file_threshold, "%h\n", threshold);
            #10;
            ldth_l2 = 1;
            #10;
            ldth_l2 = 0;
            #20;
        end
        
        $fclose(file_threshold);

        for (k = 0; k < NEURON_NUM_L2; k = k + 1)
        begin
            for (j = 0; j < INPUT_NUM_L2; j = j + 1)
            begin
                #10;
                ldw_l2 = 1;
                #10;
                ldw_l2 = 0;
                $fscanf(file_weight, "%h\n", weight);
            end
            #20;
        end

        $fclose(file_weight);

        // Re-enable
        enable = 1'b1;

        for (k = 0; k < SAMPLE_NUM; k = k + 1) 
        begin
            apply_synapse(xinput[k]);
            wait_and_monitor(1);
        end

        // Apply constant input for 1000 cycles
//        for (j = 0; j < 3; j = j + 1)
//        begin
//            mode            = j;
//            current_model = MODEL'(j);            
//            for (k = 0; k < 100; k = k + 1) 
//            begin
//                apply_synapse();
//                wait_and_monitor(1);
//            end
//        end
        
        ldw_l1  = 0;
        ldw_l2  = 0;
        weight  = 0;

        for (i = 0; i < NEURON_NUM_L2; i = i + 1) begin
            spike_count[i] = 0;
        end
    end

endmodule
