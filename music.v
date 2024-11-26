module music (
    // Inputs
    clk,                // Clock input
    reset,              // Reset signal (active low)

    // Audio CODEC interface
    AUD_ADCDAT,
    AUD_BCLK,
    AUD_ADCLRCK,
    AUD_DACLRCK,
    FPGA_I2C_SDAT,

    // Outputs to Audio CODEC
    AUD_XCK,
    AUD_DACDAT,
    FPGA_I2C_SCLK
);

    /*****************************************************************************
     *                             Port Declarations                             *
     *****************************************************************************/
    // Inputs
    input               clk;            // 50 MHz clock
    input               reset;          // Active low reset

    // Audio CODEC Inputs and Bidirectionals
    input               AUD_ADCDAT;     // Audio ADC data input
    inout               AUD_BCLK;       // Bidirectional audio clock
    inout               AUD_ADCLRCK;    // Bidirectional ADC LR clock
    inout               AUD_DACLRCK;    // Bidirectional DAC LR clock
    inout               FPGA_I2C_SDAT;  // I2C data line

    // Outputs to Audio CODEC
    output              AUD_XCK;        // Audio system clock
    output              AUD_DACDAT;     // Audio DAC data output
    output              FPGA_I2C_SCLK;  // I2C clock line

    /*****************************************************************************
     *                             Parameters and Notes                          *
     *****************************************************************************/
    localparam NOTE_C4 = 262;  // Frequency in Hz
    localparam NOTE_D4 = 294;
    localparam NOTE_E4 = 330;
    localparam NOTE_F4 = 349;
    localparam NOTE_G4 = 392;
    localparam NOTE_A4 = 440;
    localparam SILENCE = 1;

    // Define the tune (happy melody)
    reg [15:0] tune [0:15];
    initial begin
        tune[0]  = NOTE_C4;
        tune[1]  = NOTE_E4;
        tune[2]  = NOTE_G4;
        tune[3]  = NOTE_A4;
        tune[4]  = NOTE_G4;
        tune[5]  = NOTE_E4;
        tune[6]  = NOTE_F4;
        tune[7]  = NOTE_C4;
        tune[8]  = SILENCE;
        tune[9]  = NOTE_C4;
        tune[10] = NOTE_E4;
        tune[11] = NOTE_G4;
        tune[12] = NOTE_F4;
        tune[13] = NOTE_E4;
        tune[14] = NOTE_D4;
        tune[15] = SILENCE;
    end

    /*****************************************************************************
     *                             Internal Signals                              *
     *****************************************************************************/
    reg [25:0] note_timer;
    reg [3:0] note_index;
    wire [15:0] note_freq;
    assign note_freq = tune[note_index];

    reg [18:0] square_wave_counter;
    reg square_wave_output;

    /*****************************************************************************
     *                         Finite State Machine Logic                        *
     *****************************************************************************/
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            note_index <= 0;
            note_timer <= 0;
        end else begin
            if (note_timer == 26'd50_000_000) begin // Adjust timing for note duration
                note_timer <= 0;
                note_index <= (note_index == 15) ? 0 : note_index + 1;
            end else begin
                note_timer <= note_timer + 1;
            end
        end
    end

    /*****************************************************************************
     *                           Square Wave Generator                           *
     *****************************************************************************/
    always @(posedge clk) begin
        if (note_freq == SILENCE) begin
            square_wave_counter <= 0;
            square_wave_output <= 0;
        end else if (square_wave_counter >= (50_000_000 / (note_freq * 2))) begin
            square_wave_counter <= 0;
            square_wave_output <= ~square_wave_output;
        end else begin
            square_wave_counter <= square_wave_counter + 1;
        end
    end

    wire [31:0] audio_out = square_wave_output ? 32'd5000000 : -32'd5000000;

    /*****************************************************************************
     *                          Audio Controller Integration                     *
     *****************************************************************************/
    wire audio_in_available;
    wire audio_out_allowed;
    wire [31:0] left_channel_audio_out;
    wire [31:0] right_channel_audio_out;
    wire write_audio_out;

    assign left_channel_audio_out = audio_out;
    assign right_channel_audio_out = audio_out;
    assign write_audio_out = audio_out_allowed;

    Audio_Controller Audio_Controller (
        // Inputs
        .CLOCK_50(clk),
        .reset(~reset),

        .clear_audio_in_memory(1'b0),
        .read_audio_in(1'b0),
        
        .clear_audio_out_memory(1'b0),
        .left_channel_audio_out(left_channel_audio_out),
        .right_channel_audio_out(right_channel_audio_out),
        .write_audio_out(write_audio_out),

        .AUD_ADCDAT(AUD_ADCDAT),

        // Bidirectionals
        .AUD_BCLK(AUD_BCLK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_DACLRCK(AUD_DACLRCK),

        // Outputs
        .left_channel_audio_in(),
        .right_channel_audio_in(),
        .audio_in_available(audio_in_available),
        .audio_out_allowed(audio_out_allowed),

        .AUD_XCK(AUD_XCK),
        .AUD_DACDAT(AUD_DACDAT)
    );

    /*****************************************************************************
     *                          Audio Configuration Module                       *
     *****************************************************************************/
	avconf #(.USE_MIC_INPUT(1)) avc (
		.CLOCK_50(clk),
		.reset(~reset),
		.FPGA_I2C_SCLK(FPGA_I2C_SCLK),
		.FPGA_I2C_SDAT(FPGA_I2C_SDAT)
	);


endmodule
