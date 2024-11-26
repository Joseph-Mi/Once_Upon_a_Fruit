//module collisionDetect(
//    input [7:0] X_fruit,
//    input [6:0] Y_fruit,
//    input [7:0] X_basket,
//    input [6:0] Y_basket,
//    output reg collision
//);
//    //we want to measure the collision between the center of the fruit and the width of the basket
//    //fruit is 8 by 8 
//
//    wire X_fruit_center = X_fruit + 8'd4;     //we note that the x,y coordinates saved are top left corner of the fruit
//    wire Y_fruit_center = Y_fruit + 7'd4;
//
//    //basket is 15 pixels in length and 11 pixels in height
//    //need to check that the fruit is within the basket
//
//    always @(*) begin
//        if ((X_fruit_center >= X_basket && X_fruit_center <= X_basket + 8'd15) && 
//			  (Y_fruit_center >= Y_basket - 7'd3 && Y_fruit_center <= Y_basket + 7'd15)) 
//		  begin
//            collision = 1'b1;
//        end else begin
//            collision = 1'b0;
//        end
//    end
//endmodule

module collisionDetect(
    input [7:0] X_fruit,
    input [6:0] Y_fruit,
    input [7:0] X_basket,
    input [6:0] Y_basket,
    output reg collision,
    // Debug outputs
    output reg x_match,
    output reg y_match
);
    wire [7:0] X_fruit_center = X_fruit + 8'd4;
    wire [6:0] Y_fruit_center = Y_fruit + 7'd4;

    always @(*) begin
        // Explicitly break down the conditions
        x_match = (X_fruit_center >= X_basket && X_fruit_center <= X_basket + 8'd15);
        y_match = (Y_fruit_center >= Y_basket && Y_fruit_center <= Y_basket + 7'd15);
        
        collision = x_match && y_match;
    end
endmodule

module pointsystem(
    input Clock,
    input Resetn,
    input collision1,
    input collision2,
    output reg [6:0] score // 7 bits to hold values up to 100
);

    reg collision1_prev; // To store the previous state of collision1
    reg collision2_prev; // To store the previous state of collision2
    reg increment_lock1; // Increment lock for collision1
    reg increment_lock2; // Increment lock for collision2

    always @(posedge Clock or negedge Resetn) begin
        if (!Resetn) begin
            score <= 7'd0;            // Reset score to 0
            collision1_prev <= 1'b0;  // Reset previous collision1 state
            collision2_prev <= 1'b0;  // Reset previous collision2 state
            increment_lock1 <= 1'b0;  // Reset increment lock for collision1
            increment_lock2 <= 1'b0;  // Reset increment lock for collision2
        end else begin
            // Handle collision1: Rising edge detection
            if (collision1 && !collision1_prev && score < 7'd100 && !increment_lock1) begin
                score <= score + 1'b1;
                increment_lock1 <= 1'b1; // Lock increment for collision1
            end

            // Handle collision2: Rising edge detection
            if (collision2 && !collision2_prev && score < 7'd100 && !increment_lock2) begin
                score <= score + 1'b1;
                increment_lock2 <= 1'b1; // Lock increment for collision2
            end

            // Unlock increment for collision1 when the collision ends
            if (!collision1) begin
                increment_lock1 <= 1'b0;
            end

            // Unlock increment for collision2 when the collision ends
            if (!collision2) begin
                increment_lock2 <= 1'b0;
            end

            // Update previous state of collisions
            collision1_prev <= collision1;
            collision2_prev <= collision2;
        end
    end
endmodule



module scoreDisplayWithHex (
    input [6:0] score,        // Binary score input (0 to 99 expected)
    output reg [6:0] display_tens, // Tens digit 7-segment display
    output reg [6:0] display_units // Units digit 7-segment display
);

    reg [3:0] tens;  // Tens digit
    reg [3:0] units; // Units digit
    reg [13:0] shift_reg; // Register for BCD conversion
    integer i;

    always @(*) begin
        if (score >= 7'd100) begin
            // Handle invalid scores gracefully (display blank)
            tens = 4'd0;  // Blank value for tens
            units = 4'd0; // Blank value for units
        end else begin
            // Perform binary to BCD conversion
            shift_reg = {7'b0, score}; // Initialize shift register with score
            for (i = 0; i < 7; i = i + 1) begin
                // Add 3 to BCD digits >= 5
                if (shift_reg[13:10] >= 5)
                    shift_reg[13:10] = shift_reg[13:10] + 3;
                if (shift_reg[9:6] >= 5)
                    shift_reg[9:6] = shift_reg[9:6] + 3;

                // Shift left by 1 bit
                shift_reg = shift_reg << 1;
            end

            // Extract tens and units digits
            tens = shift_reg[13:10];
            units = shift_reg[9:6];
        end
    end

    // 7-segment display encoding for tens digit
    always @(*) begin
        case (tens)
            4'd0: display_tens = 7'b1000000;
            4'd1: display_tens = 7'b1111001;
            4'd2: display_tens = 7'b0100100;
            4'd3: display_tens = 7'b0110000;
            4'd4: display_tens = 7'b0011001;
            4'd5: display_tens = 7'b0010010;
            4'd6: display_tens = 7'b0000010;
            4'd7: display_tens = 7'b1111000;
            4'd8: display_tens = 7'b0000000;
            4'd9: display_tens = 7'b0010000;
            default: display_tens = 7'b1111111; // Blank display
        endcase
    end

    // 7-segment display encoding for units digit
    always @(*) begin
        case (units)
            4'd0: display_units = 7'b1000000;
            4'd1: display_units = 7'b1111001;
            4'd2: display_units = 7'b0100100;
            4'd3: display_units = 7'b0110000;
            4'd4: display_units = 7'b0011001;
            4'd5: display_units = 7'b0010010;
            4'd6: display_units = 7'b0000010;
            4'd7: display_units = 7'b1111000;
            4'd8: display_units = 7'b0000000;
            4'd9: display_units = 7'b0010000;
            default: display_units = 7'b1111111; // Blank display
        endcase
    end
endmodule
