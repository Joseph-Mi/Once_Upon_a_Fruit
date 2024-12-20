module speedCounter(
    input C50,               // Clock signal
    input Resetn,            // Active-low reset
    output reg outSignal,    // Output signal
    output reg [19:0] cycleTime // Current cycle time for external use
);

    // Internal registers
    reg [19:0] count;

    // Parameters
    parameter INITIAL_CYCLE_TIME = 20'd770_000;  // Initial cycle time
    parameter MIN_CYCLE_TIME = 20'd250_000;      // Minimum cycle time
    parameter CYCLE_TIME_DECREMENT = 20'd10;  // Decrease per toggle

    // Initialize registers
    initial begin
        outSignal = 1'b0;
        cycleTime = INITIAL_CYCLE_TIME; // Start at the initial cycle time
        count = 20'b0;
    end

    always @(posedge C50 or negedge Resetn) begin
        if (!Resetn) begin
            outSignal <= 1'b0;
            cycleTime <= INITIAL_CYCLE_TIME; // Reset cycle time
            count <= 20'b0;                  // Reset count
        end else if (count == cycleTime) begin
            outSignal <= ~outSignal;         // Toggle output signal
            count <= 20'b0;                  // Reset count

            // Gradually decrease cycle time to speed up
            if (cycleTime > MIN_CYCLE_TIME) begin
                cycleTime <= cycleTime - CYCLE_TIME_DECREMENT;
            end
        end else begin
            count <= count + 1'b1;           // Increment count
        end
    end
endmodule
