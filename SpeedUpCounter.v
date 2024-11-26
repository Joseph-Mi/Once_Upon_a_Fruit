module SpeedUpCounter(
    C50,
    outSignal    
);

// Input
input C50;

// Outputs 
output reg outSignal;

// Internal registers
reg [25:0] cycleTime;
reg [25:0] count;

// Parameters
parameter INITIAL_CYCLE_TIME = 26'd100000000;  // Initial 2 seconds at 50MHz
parameter MAX_CYCLE_TIME = 26'd200000000;      // Maximum cycle time (4 seconds at 50MHz)
parameter MIN_CYCLE_TIME = 26'd5000000;        // Minimum cycle time (0.1 second at 50MHz)
parameter CYCLE_TIME_DECREMENT = 26'd50000;    // Amount to decrease cycle time

// Initialize registers
initial begin
    outSignal = 1'b0;
    cycleTime = INITIAL_CYCLE_TIME > MAX_CYCLE_TIME ? MAX_CYCLE_TIME : INITIAL_CYCLE_TIME; // Start at a valid initial cycle time
    count = 26'b0;
end

always @(posedge C50) 
begin
    if (count == cycleTime) 
    begin
        outSignal <= ~outSignal;  // Toggle output signal
        count <= 26'b0;           // Reset count

        // Decrease cycle time to speed up, but enforce limits
        if (cycleTime > MIN_CYCLE_TIME) 
        begin
            cycleTime <= cycleTime - CYCLE_TIME_DECREMENT;
            // Ensure cycle time does not go below minimum
            if (cycleTime < MIN_CYCLE_TIME) 
                cycleTime <= MIN_CYCLE_TIME;
        end
    end
    else 
    begin
        count <= count + 1'b1;  // Increment count
    end
end        
endmodule







///// 4 bit
//module SpeedUpCounter(
//    input C50,               // Clock signal
//    output reg outSignal     // Output signal
//);
//
//// Internal registers
//reg [3:0] count;             // 4-bit counter for simulation
//reg [3:0] cycleTime;         // Reduced cycle time for simulation
//
//// Parameters for simulation
//parameter INITIAL_CYCLE_TIME = 4'd8;  // Initial cycle time (adjust for faster simulation)
//parameter MAX_CYCLE_TIME = 4'd15;     // Maximum cycle time (4-bit maximum)
//parameter MIN_CYCLE_TIME = 4'd2;      // Minimum cycle time
//parameter CYCLE_TIME_DECREMENT = 4'd1; // Amount to decrease cycle time per toggle
//
//// Initialize registers
//initial begin
//    outSignal = 1'b0;
//    cycleTime = INITIAL_CYCLE_TIME; // Start at the initial cycle time
//    count = 4'b0;
//end
//
//always @(posedge C50) begin
//    if (count == cycleTime) begin
//        outSignal <= ~outSignal;  // Toggle output signal
//        count <= 4'b0;            // Reset count
//
//        // Decrease cycle time to speed up, but enforce limits
//        if (cycleTime > MIN_CYCLE_TIME) begin
//            cycleTime <= cycleTime - CYCLE_TIME_DECREMENT;
//        end
//    end else begin
//        count <= count + 1'b1;  // Increment count
//    end
//end
//
//endmodule


