module rand_fruit_x (
    input CLOCK_50,           // 50 MHz clock
    input [0:0] KEY,          // Reset signal
    output reg [7:0] rnd      // Random number output (range 10-150)
);

    // LFSR for pseudo-random number generation
    reg [7:0] lfsr = 8'hA5;   // 8-bit LFSR initialized with non-zero seed
    wire feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]; // XOR taps

    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if (!KEY[0]) begin
            lfsr <= 8'hA5;       // Reset LFSR
            rnd <= 8'd10;        // Reset random number
        end else begin
            // Update LFSR
            lfsr <= {lfsr[6:0], feedback};
            // Scale LFSR output to range [10, 150]
            rnd <= ((lfsr * 141) >> 8) + 10; // Scale without modulo bias
        end
    end

endmodule

