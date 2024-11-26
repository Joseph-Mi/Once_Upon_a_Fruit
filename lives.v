module displayLives (
    input [1:0] lives,         // Number of lives remaining (2 bits for 0-3 lives)
    output reg [6:0] display   // 7-segment display output for lives
);

    always @(*) begin
        case (lives)
            2'b00: display = 7'b1000000; // "0" on 7-segment
            2'b01: display = 7'b1111001; // "1" on 7-segment
            2'b10: display = 7'b0100100; // "2" on 7-segment
            2'b11: display = 7'b0110000; // "3" on 7-segment
            default: display = 7'b1111111; // Blank display (or all segments off)
        endcase
    end
endmodule