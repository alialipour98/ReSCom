module array_multiplier_tb;
    parameter WIDTH = 4;
    
    reg signed [WIDTH-1:0] a, b;
    wire signed [2*WIDTH-1:0] product;
    
    // Instantiate signed multiplier
    array_multiplier #(.N(WIDTH)) dut (
        .a(a),
        .b(b),
        .p(product)
    );
    
    initial begin
        // Test positive * positive
        a = 3; b = 2;
        #10;
        $display("+%d * +%d = %d (Expected: +%d)", a, b, product, a*b);
        
        // Test positive * negative
        a = 3; b = -2;
        #10;
        $display("+%d * %d = %d (Expected: %d)", a, b, product, a*b);
        
        // Test negative * positive
        a = -3; b = 2;
        #10;
        $display("%d * +%d = %d (Expected: %d)", a, b, product, a*b);
        
        // Test negative * negative
        a = -3; b = -2;
        #10;
        $display("%d * %d = %d (Expected: +%d)", a, b, product, a*b);
        
        // Test edge cases
        a = {1'b1, {(WIDTH-1){1'b0}}}; // Most negative number
        b = 1;
        #10;
        $display("%d * +%d = %d (Expected: %d)", a, b, product, a*b);
        
        a = {1'b1, {(WIDTH-1){1'b0}}};
        b = -1;
        #10;
        $display("%d * %d = %d (Expected: %d)", a, b, product, a*b);
        
    end
    
    initial begin
        $monitor("Time=%0t: a=%b (%d), b=%b (%d), product=%b (%d)",
                $time, a, a, b, b, product, product);
    end
    
endmodule