//module KeyboardModule(
//	// Inputs
//	CLOCK_50,
//	KEY,
//	
//	// Bidirectionals
//	PS2_CLK,
//	PS2_DAT,
//	
//	// visual output
//	LEDR[6:0],
//	
//	//to game logic 
//	right_command,
//	left_command,
//	end_game,
//	idle_game
//);
///*****************************************************************************
// *                           Parameter Declarations                          *
// *****************************************************************************/
//// Inputs
//input			CLOCK_50;
//input	[0:0] KEY;
//
//inout		 	PS2_CLK;
//inout 		PS2_DAT;
//
//output [6:0] LEDR;
//
//output		 right_command;
//output 		 left_command;
//output		 end_game;
//output		 idle_game;
//
///*****************************************************************************
// *                 Internal Wires and Registers Declarations                 *
// *****************************************************************************/
//
//// Internal Wires
//wire [7:0]	 ps2_key_data;
//wire			 ps2_key_pressed;
//wire 			 inSignal; // from SpeedUpCounter to control processing
//
//// State Machine Registers
//
///*****************************************************************************
// *                         Finite State Machine(s)                           *
// *****************************************************************************/
//reg [2:0] 	 current_state;
//reg [2:0] 	 next_state;
//
//parameter END_STATE = 3'b000;
//parameter IDLE_GAME_STATE = 3'b100;
//parameter MOVE_RIGHT = 3'b101;
//parameter MOVE_LEFT = 3'b110;
//
//// LEFT 6B
//// RIGHT 74
//// ENTER 5A
//// ESC 76 8'h76
//parameter SCAN_CODE_LEFT  = 8'h6B;  // LEFT
//parameter SCAN_CODE_RIGHT = 8'h74;  // RIGHT
//parameter SCAN_CODE_ENTER = 8'h5A;  // ENTER
//parameter SCAN_CODE_ESC   = 8'h76;  // ESC
// 
//always @(*) 
//begin 
//	if (KEY[0] == 1'b0)
//	begin
//		next_state <= END_STATE;
//	end
//		
//	else if (ps2_key_pressed) 
//	begin
//		case (current_state)
//		
//			END_STATE: begin
//				if (ps2_key_data == SCAN_CODE_ENTER) // start game
//					next_state <= IDLE_GAME_STATE;
//				else // stay in end
//					next_state <= END_STATE;
//			end
//			
//			
//			IDLE_GAME_STATE: begin
//				if (ps2_key_data == SCAN_CODE_ESC) // end game
//					next_state <= END_STATE;
//				else if (ps2_key_data == SCAN_CODE_RIGHT) //RIGHT
//					next_state <= MOVE_RIGHT;
//				else if (ps2_key_data == SCAN_CODE_LEFT) //LEFT
//					next_state <= MOVE_LEFT;
//				else
//					next_state <= IDLE_GAME_STATE;
//			end
//			
//			
//			MOVE_RIGHT: begin
//                if (ps2_key_data == SCAN_CODE_ESC)      // end game
//                    next_state <= END_STATE;
//                else if (ps2_key_data == SCAN_CODE_RIGHT)
//                    next_state <= MOVE_RIGHT;
//                else if (ps2_key_data == SCAN_CODE_LEFT)
//                    next_state <= MOVE_LEFT;
//                else
//                    next_state <= IDLE_GAME_STATE;
//            end
//            
//            MOVE_LEFT: begin
//                if (ps2_key_data == SCAN_CODE_ESC)      // end game
//                    next_state <= END_STATE;
//                else if (ps2_key_data == SCAN_CODE_RIGHT)
//                    next_state <= MOVE_RIGHT;
//                else if (ps2_key_data == SCAN_CODE_LEFT)
//                    next_state <= MOVE_LEFT;
//                else
//                    next_state <= IDLE_GAME_STATE;
//            end
//
//			
//			default: next_state <= END_STATE;
//
//		endcase
//	end			
//end
//
//// keep going to next state
//always @(posedge inSignal) 
//begin: keyboard_input_state
//	if (KEY[0] == 1'b0) 
//		current_state <= END_STATE;
//	else
//		current_state <= next_state;
//end
//
//assign LEDR[6] = inSignal;
//assign LEDR[5] = (ps2_key_data == SCAN_CODE_ENTER);  // Shows if the ENTER key is detected
//assign LEDR[4] = (current_state == IDLE_GAME_STATE); // Shows if the current state is IDLE_GAME_STATE
//assign LEDR[3] = (current_state == END_STATE);       // Shows if the current state is END_STATE
//
////always keep this for debugging
//assign LEDR[2:0] = current_state;
//
//// can also use always block here (try that if this doesnt work)
//assign right_command = (current_state == MOVE_RIGHT);
//assign left_command = (current_state == MOVE_LEFT);
//assign end_game = (current_state == END_STATE);
//assign idle_game = (current_state == IDLE_GAME_STATE);
//
//
///*****************************************************************************
// *                              Internal Modules                             *
// *****************************************************************************/
//
//PS2_Controller PS2 (
//	// Inputs
//	.CLOCK_50(CLOCK_50),
//	.reset(~KEY[0]),
//
//	// Bidirectionals
//	.PS2_CLK(PS2_CLK),
// 	.PS2_DAT(PS2_DAT),
//
//	// Outputs
//	.received_data(ps2_key_data),
//	.received_data_en(ps2_key_pressed)
//);
//
//SpeedUpCounter speedUpCounter(
//    .C50(CLOCK_50),  // 50 MHz clock
//    .outSignal(inSignal)
//);
//
//
//
//
//endmodule





module KeyboardModule(
    // Inputs from top module
    input clk,          // Clock input
    input resetn,       // Active-low reset
    inout ps2_clk,      // PS2 Clock
    inout ps2_dat,      // PS2 Data

    // Outputs to top module
    output right_command,
    output left_command,
    output end_game,
    output idle_game
);

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/

// Internal Wires
wire [7:0] ps2_key_data;
wire       ps2_key_pressed;
wire       inSignal; // From SpeedUpCounter to control processing

// State Machine Registers
reg [2:0] current_state, next_state;

parameter END_STATE = 3'b000;
parameter IDLE_GAME_STATE = 3'b100;
parameter MOVE_RIGHT = 3'b101;
parameter MOVE_LEFT = 3'b110;

// Key Scan Codes
parameter SCAN_CODE_LEFT  = 8'h6B;  // LEFT
parameter SCAN_CODE_RIGHT = 8'h74;  // RIGHT
parameter SCAN_CODE_ENTER = 8'h5A;  // ENTER
parameter SCAN_CODE_ESC   = 8'h76;  // ESC

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/
always @(*) 
begin
    if (!resetn) begin
        next_state <= END_STATE;
    end else if (ps2_key_pressed) begin
        case (current_state)
            END_STATE: begin
                if (ps2_key_data == SCAN_CODE_ENTER)
                    next_state <= IDLE_GAME_STATE;
                else
                    next_state <= END_STATE;
            end

            IDLE_GAME_STATE: begin
                if (ps2_key_data == SCAN_CODE_ESC)
                    next_state <= END_STATE;
                else if (ps2_key_data == SCAN_CODE_RIGHT)
                    next_state <= MOVE_RIGHT;
                else if (ps2_key_data == SCAN_CODE_LEFT)
                    next_state <= MOVE_LEFT;
                else
                    next_state <= IDLE_GAME_STATE;
            end

            MOVE_RIGHT: begin
                if (ps2_key_data == SCAN_CODE_ESC)
                    next_state <= END_STATE;
                else if (ps2_key_data == SCAN_CODE_LEFT)
                    next_state <= MOVE_LEFT;
                else
                    next_state <= IDLE_GAME_STATE;
            end

            MOVE_LEFT: begin
                if (ps2_key_data == SCAN_CODE_ESC)
                    next_state <= END_STATE;
                else if (ps2_key_data == SCAN_CODE_RIGHT)
                    next_state <= MOVE_RIGHT;
                else
                    next_state <= IDLE_GAME_STATE;
            end

            default: next_state <= END_STATE;
        endcase
    end
end

// Update the current state
always @(posedge clk or negedge resetn) 
begin: keyboard_input_state
    if (!resetn)
        current_state <= IDLE_GAME_STATE;
    else
        current_state <= next_state;
end

// Outputs
assign right_command = (current_state == MOVE_RIGHT);
assign left_command = (current_state == MOVE_LEFT);
assign end_game = (current_state == END_STATE);
assign idle_game = (current_state == IDLE_GAME_STATE);

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

PS2_Controller PS2 (
	 //input	
    .CLOCK_50(clk),
    .reset(~resetn),
	 
	 // bidirectional
    .PS2_CLK(ps2_clk),
    .PS2_DAT(ps2_dat),
	 
	 // output
    .received_data(ps2_key_data),
    .received_data_en(ps2_key_pressed)
);

SpeedUpCounter speedUpCounter(
    .C50(clk),  // 50 MHz clock
    .outSignal(inSignal)
);

endmodule

