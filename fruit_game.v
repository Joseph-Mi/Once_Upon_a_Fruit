module fruit_game(
    input CLOCK_50,
    input [0:0] KEY, // Reset
    output [6:0] HEX0, HEX5, HEX4,
    output [9:0] LEDR, // Debug signals
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_BLANK_N,
    output VGA_SYNC_N,
    output VGA_CLK,
	 
	 // KEYBOARD //
	 inout PS2_CLK,
	 inout PS2_DAT,
	 
	 // AUDIO //
	 inout AUD_BCLK,        // Bidirectional audio clock
    inout AUD_ADCLRCK,     // Bidirectional ADC LR clock
    inout AUD_DACLRCK,     // Bidirectional DAC LR clock
    inout FPGA_I2C_SDAT,   // I2C data line
    input AUD_ADCDAT,      // Audio ADC data input
    output AUD_XCK,        // Audio system clock
    output AUD_DACDAT,     // Audio DAC data output
    output FPGA_I2C_SCLK   // I2C clock line

);

    // Parameters
    parameter X_RES = 8'd159;
    parameter Y_RES = 7'd119;

    // FSM States
    parameter DRAW_BACKGROUND = 3'b111;
    parameter DRAW_FRUIT_1 = 3'b001;
    parameter DRAW_FRUIT_2 = 3'b010;
    parameter DRAW_PLAYER = 3'b100;
    parameter UPDATE_POSITION_1 = 3'b110;
    parameter UPDATE_POSITION_2 = 3'b011;
    parameter UPDATE_PLAYER = 3'b101;

///////////////////////////////////////////////////////
/////////////////////// Signals ///////////////////////
///////////////////////////////////////////////////////
    reg [2:0] current_state, next_state;
    reg plot;                // Plot signal
    reg [7:0] bg_X;          // Background X coordinate
    reg [6:0] bg_Y;          // Background Y coordinate
    wire [2:0] bg_color;     // Background pixel color
//    wire timer_tick;         // Timer tick for state transitions
    reg [7:0] X_current, X_current_2; // Fruits' active X coordinates
    wire [7:0] X_rnd;        // Random X-coordinate
    reg [6:0] Y_current, Y_current_2; // Fruits' active Y coordinates
    reg [2:0] XC, YC, XC_2, YC_2;      // Fruits' pixel coordinates
    wire [2:0] fruit_color, fruit_color_2; // Fruits' pixel colors
    wire [2:0] VGA_COLOR;    // VGA final color signal
    reg [19:0] fall_timer_1, fall_timer_2, move_timer; // Fall sync timers
    wire fall_sync_1, fall_sync_2, move_sync;    // Fall synchronization signals
	
	 ///// KEYBOARD WIRES /////
	 wire right;
	 wire left;
	 wire idle;
	 wire escape;
	 
	 ////// POINTS //////
//	 wire collision1, collision2;
	 wire [6:0] score;
	 
	 ///// LATCHED COORDS FOR POINTS /////
//	 reg [7:0] latched_X_fruit1, latched_X_fruit2, latched_X_basket;
//	 reg [6:0] latched_Y_fruit1, latched_Y_fruit2, latched_Y_basket;

////////////////////////////////////////////////////////////////////
/////////////////////// ALL MEMORY RETRIEVAL ///////////////////////
////////////////////////////////////////////////////////////////////
    // Memory translator
    wire [14:0] addr;
    vga_address_translator addr_inst (bg_X, bg_Y, addr);
    defparam addr_inst.RESOLUTION = "160x120";

    // Instantiate the background ROM
    image_colour bg_ROM (addr, CLOCK_50, bg_color);

    // Instantiate fruit ROMs
    orange orange_ROM1 ({YC, XC}, CLOCK_50, fruit_color);
    orange2 orange_ROM2 ({YC_2, XC_2}, CLOCK_50, fruit_color_2);
//    orange3 orange_ROM3 ({YC_3, XC_3}, CLOCK_50, fruit_color_3);

//    wire [8:0] player;
//	 vga_address_translator player_inst (XP, YP, player);
//	 defparam player_inst.RESOLUTION = "160x120";
	 
	 wire [2:0] player_color; // Player (bucket) color
	 reg [3:0] XP, YP;        // Bucket (player) pixel coordinates
	 reg [7:0] X_player; // current bucket x
	 reg [6:0] Y_player; // current bucket y
	 bucket player_ROM ({YP, XP}, CLOCK_50, player_color);
//	 reg bucket_done;

	 // Random X Generator
    rand_fruit_x RNG (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY[0:0]),
        .rnd(X_rnd)
    );

    // HEX Display for Random X
    hex7seg H1 (X_rnd[7:4], HEX3);
    hex7seg H0 (X_rnd[3:0], HEX2);

/////////////////////////////////////////
///////////// SPEED CONTROL /////////////
/////////////////////////////////////////

	reg [19:0] time_1 = 20'd790_000;
	reg [19:0] time_2 = 20'd690_000;
	reg [19:0] move_r8 = 20'd490_000;

	always @(posedge CLOCK_50 or negedge KEY[0]) begin
		 if (!KEY[0]) begin
			  // Reset all timers to 0 on reset
			  fall_timer_1 <= 20'd0;
			  fall_timer_2 <= 20'd0;
//			  fall_timer_3 <= 20'd0;
			  move_timer <= 20'd0;
			  
			  time_1 = 20'd790_000;
			  time_2 = 20'd690_000;
			  move_r8 = 20'd490_000;
		 end else begin
			  // Timer for fruit 1
			  if (fall_timer_1 == time_1) begin// Slightly slower
					fall_timer_1 <= 20'd0;
					time_1 <= time_1 - 20'd5;
			  end
			  else
					fall_timer_1 <= fall_timer_1 + 1'b1;

			  // Timer for fruit 2
			  if (fall_timer_2 == time_2) begin// Faster
					fall_timer_2 <= 20'd0;
					time_2 <= time_2 - 20'd5;
			  end
			  else
					fall_timer_2 <= fall_timer_2 + 1'b1;
			  
			  // Timer for move
			  if (move_timer == move_r8) begin
					move_timer <= 20'd0;
					move_r8 <= move_r8 - 20'd5;
			  end
			  else 
					move_timer <= move_timer + 1'b1;

			  // Timer for fruit 3
//			  if (fall_timer_3 == 20'd1_040_000) // Moderate speed
//					fall_timer_3 <= 20'd0;
//			  else
//					fall_timer_3 <= fall_timer_3 + 1'b1;
		 end
	end

	// Staggered fall sync signals
	assign fall_sync_1 = (fall_timer_1 == time_1 - 20'd10_000); // Sync for fruit 1
	assign fall_sync_2 = (fall_timer_2 == time_2 - 20'd20_000);  // Sync for fruit 2
//	assign fall_sync_3 = (fall_timer_3 == 20'd1_035_000); // Sync for fruit 3
	assign move_sync = (move_timer == move_r8 - 20'd20_000);


///////////////////////////////////////////////////
/////////////////////// FSM ///////////////////////
///////////////////////////////////////////////////
    // FSM Transitions
    always @(*) begin
        case (current_state)
            DRAW_BACKGROUND: begin
                plot = 1'b1;
                next_state = DRAW_FRUIT_1;
            end
            DRAW_FRUIT_1: begin
                plot = (fruit_color != 3'b111);
                next_state = DRAW_FRUIT_2;
            end
            DRAW_FRUIT_2: begin
                plot = (fruit_color_2 != 3'b111);
                next_state = DRAW_PLAYER;
            end
            DRAW_PLAYER: begin
                plot = (player_color != 3'b111);
					 next_state = UPDATE_POSITION_1;
            end
            UPDATE_POSITION_1: begin
                plot = 1'b0;
                next_state = UPDATE_POSITION_2;
            end
            UPDATE_POSITION_2: begin
                plot = 1'b0;
                next_state = UPDATE_PLAYER;
            end
            UPDATE_PLAYER: begin
                plot = 1'b0;
                next_state = DRAW_BACKGROUND;
            end
            default: begin
                plot = 1'b0;
                next_state = DRAW_BACKGROUND;
            end
        endcase
    end

    // FSM Current State
    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if (!KEY[0])
            current_state <= DRAW_BACKGROUND;
        else if (CLOCK_50)
            current_state <= next_state;
    end

    // Background Counters
    always @(posedge CLOCK_50 or negedge KEY[0]) begin
        if (!KEY[0]) begin
            bg_X <= 8'd0;
            bg_Y <= 7'd0;
        end else if (current_state == DRAW_BACKGROUND) begin
            if (bg_X == X_RES) begin
                bg_X <= 8'd0;
                if (bg_Y == Y_RES)
                    bg_Y <= 7'd0;
                else
                    bg_Y <= bg_Y + 1'b1;
            end else begin
                bg_X <= bg_X + 1'b1;
            end
        end
    end
	 
	 // Fruit Counters for DRAW_FRUIT States
	always @(posedge CLOCK_50 or negedge KEY[0]) begin
		 if (!KEY[0]) begin
			  // Reset all coordinates for all fruits
			  XC <= 3'b000;
			  YC <= 3'b000;
			  XC_2 <= 3'b000;
			  YC_2 <= 3'b000;
//			  XC_3 <= 3'b000;
//			  YC_3 <= 3'b000;

			  YP = 4'b0000;
			  XP = 4'b0000;
		 end else begin
			  // Logic for DRAW_FRUIT_1
			  if (current_state == DRAW_FRUIT_1) begin
					if (XC == 3'b111) begin
						 XC <= 3'b000;
						 if (YC == 3'b111)
							  YC <= 3'b000; // Done drawing fruit 1
						 else
							  YC <= YC + 1'b1; // Increment row within fruit
					end else begin
						 XC <= XC + 1'b1; // Increment column within fruit
					end
			  end

			  // Logic for DRAW_FRUIT_2
			  if (current_state == DRAW_FRUIT_2) begin
					if (XC_2 == 3'b111) begin
						 XC_2 <= 3'b000;
						 if (YC_2 == 3'b111)
							  YC_2 <= 3'b000; // Done drawing fruit 2
						 else
							  YC_2 <= YC_2 + 1'b1; // Increment row within fruit
					end else begin
						 XC_2 <= XC_2 + 1'b1; // Increment column within fruit
					end
			  end
			  
			  if (current_state == DRAW_PLAYER) begin
					if (XP == 4'b1111) begin
						 XP <= 3'b000;
						 if (YP == 4'b1111)
							  YP <= 4'b0000; // Done drawing fruit 2
						 else
							  YP <= YP + 1'b1; // Increment row within fruit
					end else begin
						 XP <= XP + 1'b1; // Increment column within fruit
					end
			  end
			  // Logic for DRAW_FRUIT_3
//			  if (current_state == DRAW_FRUIT_3) begin
//					if (XC_3 == 3'b111) begin
//						 XC_3 <= 3'b000;
//						 if (YC_3 == 3'b111)
//							  YC_3 <= 3'b000; // Done drawing fruit 3
//						 else
//							  YC_3 <= YC_3 + 1'b1; // Increment row within fruit
//					end else begin
//						 XC_3 <= XC_3 + 1'b1; // Increment column within fruit
//					end
//			  end
		 end
	end


	always @(posedge CLOCK_50 or negedge KEY[0]) begin
		 if (!KEY[0]) begin
			  // Initialize fruits at random non-zero positions
			  Y_current <= 7'b0; // Start at the top
			  X_current <= (X_rnd > 8'd10) ? X_rnd : (X_rnd + 8'd10); // Random non-zero X position for fruit 1

			  Y_current_2 <= 7'b0; // Start at the top
			  X_current_2 <= ((X_rnd + 8'd10) > 8'd10) ? (X_rnd + 8'd10) : (X_rnd + 8'd13); // Offset for fruit 2

//			  Y_current_3 <= 7'b0; // Start at the top
//			  X_current_3 <= ((X_rnd) > 8'd10) ? (X_rnd + 8'd1) : (X_rnd + 8'd12); // Offset for fruit 3
			  Y_player <= 7'd80;
			  X_player <= 8'd72;
		 end else begin
			  // Update fruit positions during their respective update states
			  if (current_state == UPDATE_POSITION_1 && fall_sync_1) begin
					if (Y_current >= Y_RES || collision1) begin
						 if (Y_current >= Y_RES) lives <= lives - 1'b1;
						 
						 Y_current <= 7'b1; // Reset Y position
						 X_current <= (X_rnd > 8'd10) ? X_rnd : (X_rnd + 8'd10); // Re-randomize X position for fruit 1
					end else begin
						 Y_current <= Y_current + 1'b1; // Increment Y position
					end
			  end

			  if (current_state == UPDATE_POSITION_2 && fall_sync_2) begin
					if (Y_current_2 >= Y_RES || collision2) begin
						 if (Y_current_2 >= Y_RES) lives <= lives - 1'b1;
						 Y_current_2 <= 7'd3; // Reset Y position
						 X_current_2 <= ((X_rnd + 8'd10) > 8'd10) ? (X_rnd + 8'd10) : (X_rnd + 8'd12); // Re-randomize X position for fruit 2
					end else begin
						 Y_current_2 <= Y_current_2 + 1'b1; // Increment Y position
					end
			  end
			  
			  if (current_state == UPDATE_PLAYER && move_sync) begin 
					if (X_player <= (X_RES - 5'd16) && right) 
						X_player <= X_player + 1'b1;
					else if (X_player > 1'b0 && left) 
						X_player <= X_player - 1'b1;
					else if (idle) 
						X_player <= X_player;
			  end

//			  if (current_state == UPDATE_POSITION_3 && fall_sync_3) begin
//					if (Y_current_3 >= Y_RES) begin
//						 Y_current_3 <= 7'b0; // Reset Y position
//						 X_current_3 <= ((X_rnd) > 8'd10) ? (X_rnd + 8'd2) : (X_rnd + 8'd13); // Re-randomize X position for fruit 3
//					end else begin
//						 Y_current_3 <= Y_current_3 + 1'b1; // Increment Y position
//					end
//			  end
		 end
	end

	 
//	 assign LEDR[9:7] = current_state; // Display FSM state on LEDs
//	 assign LEDR[0] = plot; // Debug: Plot signal status

//////////////////////////////////////////////////////////////////////
/////////////////////// KEYBOARD INSTANTIATION ///////////////////////
//////////////////////////////////////////////////////////////////////
	KeyboardModule move (
		.clk(CLOCK_50),          // Clock input
		.resetn(KEY[0]),       // Active-low reset
		.ps2_clk(PS2_CLK),      // PS2 Clock
		.ps2_dat(PS2_DAT),      // PS2 Data

		 // Outputs to top module
		 .right_command(right),
		 .left_command(left),
		 .end_game(escape),
		 .idle_game(idle)
	);

/////////////////////////////////////////////////////////
/////////////////////// Collision ///////////////////////
/////////////////////////////////////////////////////////
	wire x_match1, y_match1, x_match2, y_match2;

	collisionDetect collision_unit1 (
		  .X_fruit(X_current),
		  .Y_fruit(Y_current),
		  .X_basket(X_player),
		  .Y_basket(Y_player),
		  .collision(collision1),
		  .x_match(x_match1),  // New debug signal
		  .y_match(y_match1)   // New debug signal
	);

	collisionDetect collision_unit2 (
		  .X_fruit(X_current_2),
		  .Y_fruit(Y_current_2),
		  .X_basket(X_player),
		  .Y_basket(Y_player),
		  .collision(collision2),
		  .x_match(x_match2),  // New debug signal
		  .y_match(y_match2)   // New debug signal
	);

// Optionally, output these to LEDRs for debugging
//	assign LEDR[0] = x_match1;
//	assign LEDR[1] = y_match1;
//	assign LEDR[2] = collision1;
//	assign LEDR[3] = x_match2;
//	assign LEDR[4] = y_match2;
//	assign LEDR[5] = collision2;
//	assign LEDR[0] = collision1;
//	assign LEDR[1] = collision2;
//	assign LEDR[3:0] = X_current_2[7:4]; // Display lower 4 bits of x (1)
//	assign LEDR[7:4] = Y_current_2[6:3]; // display lower 4 bits of y (1)
	
//	assign LEDR[3:0] = X_player[7:4]; // Display lower 4 bits of x (1)
//	assign LEDR[7:4] = Y_player[6:3]; // display lower 4 bits of y (1)

/////////////////////////////////////////////////////////
/////////////////////// Point System ////////////////////
/////////////////////////////////////////////////////////
	assign LEDR[0] = collision1;
	assign LEDR[1] = collision2;

	pointsystem point_unit (
		 .Clock(fall_sync_1 ^ fall_sync_2 ^ move_sync),
		 .Resetn(KEY[0]),
		 .collision1(collision1),
		 .collision2(collision2),
		 .score(score)
	);
//	assign LEDR[9:3] = score;

/////////////////////////////////////////////////////////
/////////////////// Score Display ///////////////////////
/////////////////////////////////////////////////////////
	scoreDisplayWithHex display_unit (
		 .score(score),
		 .display_tens(HEX5),
		 .display_units(HEX4)
	);
	
//////////////////////////////////////////////////////
/////////////////// Lose Lives ///////////////////////
//////////////////////////////////////////////////////
	
	reg [1:0] lives = 2'b11; // Lives remaining

/////////////////////////////////////////////////////////
/////////////////// Display Lives ///////////////////////
/////////////////////////////////////////////////////////
	displayLives lives_display_module (
		 .lives(lives),
		 .display(HEX0)
	);

/////////////////////////////////////////////////
/////////////////// music ///////////////////////
/////////////////////////////////////////////////
	music bg_music (
		 .clk(CLOCK_50),
		 .reset(KEY[0]),
		 .AUD_ADCDAT(AUD_ADCDAT),
		 .AUD_BCLK(AUD_BCLK),
		 .AUD_ADCLRCK(AUD_ADCLRCK),
		 .AUD_DACLRCK(AUD_DACLRCK),
		 .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
		 .AUD_XCK(AUD_XCK),
		 .AUD_DACDAT(AUD_DACDAT),
		 .FPGA_I2C_SCLK(FPGA_I2C_SCLK)
	);

///////////////////////////////////////////////////////////
/////////////////////// VGA Adapter ///////////////////////
///////////////////////////////////////////////////////////
    vga_adapter VGA (
        .resetn(KEY[0]),
        .clock(CLOCK_50),
        .colour((current_state == DRAW_BACKGROUND) ? bg_color :
                (current_state == DRAW_FRUIT_1) ? fruit_color :
                (current_state == DRAW_FRUIT_2) ? fruit_color_2 :
                (current_state == DRAW_PLAYER) ? player_color :
                bg_color), // Select appropriate color
        .x((current_state == DRAW_BACKGROUND) ? bg_X :
           (current_state == DRAW_FRUIT_1) ? (X_current + XC) :
           (current_state == DRAW_FRUIT_2) ? (X_current_2 + XC_2) :
           (current_state == DRAW_PLAYER) ? (X_player + XP) :
           bg_X), // Select appropriate X coordinate
        .y((current_state == DRAW_BACKGROUND) ? bg_Y :
           (current_state == DRAW_FRUIT_1) ? (Y_current + YC) :
           (current_state == DRAW_FRUIT_2) ? (Y_current_2 + YC_2) :
           (current_state == DRAW_PLAYER) ? (Y_player + YP) :
           bg_Y), // Select appropriate Y coordinate
        .plot(plot),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK)
    );

    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
endmodule


module regn(R, Resetn, E, Clock, Q);
    parameter n = 8;
    input [n-1:0] R;
    input Resetn, E, Clock;
    output reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule

module countFruit(Clock, Resetn, E, Q);
    parameter n = 8;
    input Clock, Resetn, E;
    output reg [n-1:0] Q;

    always @ (posedge Clock)
        if (Resetn == 0)
            Q <= 0;
        else if (E)
                Q <= Q + 1;
endmodule

module hex7seg (hex, display);
    input [3:0] hex;
    output [6:0] display;

    reg [6:0] display;

    /*
     *       0  
     *      ---  
     *     |   |
     *    5|   |1
     *     | 6 |
     *      ---  
     *     |   |
     *    4|   |2
     *     |   |
     *      ---  
     *       3  
     */
    always @ (hex)
        case (hex)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0011000;
            4'hA: display = 7'b0001000;
            4'hB: display = 7'b0000011;
            4'hC: display = 7'b1000110;
            4'hD: display = 7'b0100001;
            4'hE: display = 7'b0000110;
            4'hF: display = 7'b0001110;
        endcase
endmodule


