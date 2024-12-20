module basketController (
    input Clock,           // System clock
    input Resetn,          // Active-low reset
    input key2,            // Left arrow key
    input key0,            // Right arrow key
    output reg [7:0] X_basket // X-coordinate of the basket
);

    parameter SCREEN_WIDTH = 160;  // Define screen width (adjust as necessary)
    parameter BASKET_WIDTH = 15;  // Width of the basket (adjust as necessary)

    // Initialize X_basket at reset
    always @(posedge Clock or negedge Resetn) begin
        if (!Resetn) begin
            X_basket <= 0; // Initialize the basket position to 0
        end else begin
            // Check for key presses and move the basket accordingly
            if (key2 && X_basket > 0) begin
                X_basket <= X_basket - 1; // Move basket left
            end else if (key0 && X_basket < SCREEN_WIDTH - BASKET_WIDTH) begin
                X_basket <= X_basket + 1; // Move basket right
            end
        end
    end

endmodule
