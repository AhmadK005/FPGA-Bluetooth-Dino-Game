//Version 5
module FinalProject (
    input        clk, //Clock
    input  [9:0] SW, //switches
    input  [1:0] KEY, // key
    input  BT_RX, // Bluetooth RX pin
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, //seven segment display
    output [3:0] VGA_R, VGA_G, VGA_B, //VGA
    output VGA_HS, VGA_VS,
    output [9:0] LEDR // LED
);
    // Pixel clock
    wire pixel_clk;
    pll pll_inst (.inclk0(clk), .c0(pixel_clk));

    //VGA controller from Lab 5
    wire [31:0] column;
    wire [31:0] row;
    wire disp_ena, h_sync, v_sync;

    vga_controller #(
        .h_pixels(640), .h_fp(16), .h_pulse(96), .h_bp(48), .h_pol(1'b0),
        .v_pixels(480), .v_fp(10), .v_pulse(2),  .v_bp(33), .v_pol(1'b0)
    ) timing (
        .pixel_clk(pixel_clk),
        .reset_n  (KEY[0]),
        .h_sync   (h_sync),
        .v_sync   (v_sync),
        .disp_ena (disp_ena),
        .column   (column),
        .row      (row)
    );

    // bluetooth modules instatiation
	 
	 //baud rate
    wire       baud_tick;									//signal tick rate
    localparam [15:0] BAUD_DIV_9600 = 16'd163;		//clock divisor for baudrate of 9600	

    BaudRate baud_gen (
        .Clk      (pixel_clk),		//pixel clock
        .Rst_n    (KEY[0]),			//reset key
        .Tick     (baud_tick),
        .BaudRate (BAUD_DIV_9600)	
    );
	 
	 //RX
    wire [7:0] bt_rx_data;		//8bit received data
    wire bt_rx_done;		//single bit feedback

    rx bt_uart (
        .Clk    (pixel_clk),	//pixel clock
        .Rst_n  (KEY[0]),		//reset key
        .RxEn   (1'b1),			//setting Bluetooth enable to always on
        .RxData (bt_rx_data),	
        .RxDone (bt_rx_done),
        .Rx     (BT_RX),
        .Tick   (baud_tick),
        .NBits  (4'b1000)
    );
	 
	 
    // Bluetooth jump pulse
    reg rx_done_sync0, rx_done_sync1; //syncing bluettoh data with pixel clock

    always @(posedge pixel_clk or negedge KEY[0]) begin //set to 0 on reset
        if (!KEY[0]) begin
            rx_done_sync0 <= 0;
            rx_done_sync1 <= 0;
        end else begin
            rx_done_sync0 <= bt_rx_done; //syncing clock
            rx_done_sync1 <= rx_done_sync0; //double flip flop sunc for stability
        end
    end

	 //detecting rising edge of rx done signal
    wire rx_done_rise = rx_done_sync0 & ~rx_done_sync1;
	 
	 // Generate a pulse for jumping action if data is received and not equal to zero
    wire bt_jump_pulse = rx_done_rise & (bt_rx_data != 8'd0);

    // Game engine
    wire [3:0] r, g, b; //VGA RGB 
    wire [6:0] core_hex1, core_hex2; //Score display
    wire game_alive;

    vga core (
        .clk        (pixel_clk), //pixel clock
        .reset_n    (KEY[0]), //reset key
        .key_n      (KEY[1]),	//on board jump key
        .jump_btn   (bt_jump_pulse),//blue tooth jump button
        .sw         (SW), //switches for colour change and high score
        .disp_ena   (disp_ena), //vga controller inputs
        .column     (column[9:0]),
        .row        (row[8:0]),
        .r          (r),
        .g          (g),
        .b          (b),
        .hex1       (core_hex1), //score display
        .hex2       (core_hex2),
        .game_alive (game_alive)	// Detecting if game running or end
    );

    // 1-second tick generator

    localparam integer SEC_DIV_MAX = 25_000_000 - 1;

    reg [24:0] sec_div_cnt;
    reg        one_sec_pulse;

    always @(posedge pixel_clk or negedge KEY[0]) begin //reset logic set everything to 0
        if (!KEY[0]) begin
            sec_div_cnt  <= 0;
            one_sec_pulse <= 0;
        end else if (game_alive) begin	//game running logic to count score absed of time
            if (sec_div_cnt == SEC_DIV_MAX) begin
                sec_div_cnt <= 0;
                one_sec_pulse <= 1;
            end else begin
                sec_div_cnt <= sec_div_cnt + 1;
                one_sec_pulse <= 0;
            end
        end else begin
            one_sec_pulse <= 0; //stop iterating score when game dead
        end
    end


    // Score
    reg [3:0] ones, tens, hundreds;

    always @(posedge pixel_clk or negedge KEY[0]) begin //set 0 on reset
        if (!KEY[0]) begin
            ones <= 0;
            tens <= 0;
            hundreds <= 0;
        end else if (game_alive && one_sec_pulse) begin  // setting up score for seven segment display
            if (ones == 9) begin
                ones <= 0;
                if (tens == 9) begin
                    tens <= 0;
                    if (hundreds != 9)
                        hundreds <= hundreds + 1;
                end else tens <= tens + 1;
            end else ones <= ones + 1;
        end
    end

  
    // HIGH SCORE tracking
    reg [3:0] high_ones, high_tens, high_hundreds; //registers to hold score

    always @(posedge pixel_clk) begin //once game ends update registers if last score higher than current highscore
        if (!game_alive) begin
            if ({hundreds,tens,ones} > {high_hundreds,high_tens,high_ones}) begin
                high_ones     <= ones;
                high_tens     <= tens;
                high_hundreds <= hundreds;
            end
        end
    end

    // Display highscore on switch 0
    wire [3:0] d0 = SW[0] ? high_ones     : ones;
    wire [3:0] d1 = SW[0] ? high_tens     : tens;
    wire [3:0] d2 = SW[0] ? high_hundreds : hundreds;


    // 7-seg decoder for Disaply
    function [6:0] seg7;
        input [3:0] digit;
        begin
            case (digit)
                0: seg7 = 7'b1000000;
                1: seg7 = 7'b1111001;
                2: seg7 = 7'b0100100;
                3: seg7 = 7'b0110000;
                4: seg7 = 7'b0011001;
                5: seg7 = 7'b0010010;
                6: seg7 = 7'b0000010;
                7: seg7 = 7'b1111000;
                8: seg7 = 7'b0000000;
                9: seg7 = 7'b0010000;
                default: seg7 = 7'b1111111;
            endcase
        end
    endfunction

    assign HEX0 = seg7(d0);
    assign HEX1 = seg7(d1);
    assign HEX2 = seg7(d2);
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;

    // VGA output
    assign VGA_R = r;
    assign VGA_G = g;
    assign VGA_B = b;
    assign VGA_HS = h_sync;
    assign VGA_VS = v_sync;

    // LED random pattern on death
    localparam integer LED_DIV_MAX = 5_000_000 - 1;  // ~5 Hz

    reg [22:0] led_div_cnt; //LED counter
    reg [9:0]  led_lfsr;	 //random number generator for randomness
    reg [9:0]  led_pattern; //pattern displayed on 9 leds

    always @(posedge pixel_clk or negedge KEY[0]) begin
        if (!KEY[0]) begin
            led_div_cnt <= 0;
            led_lfsr    <= 10'b1010110101; //starting lsfr bit
            led_pattern <= 0;
        end else begin
            if (game_alive) begin
                led_div_cnt <= 0;
                led_pattern <= 0;   // LEDsoffF while alive
            end else begin
                if (led_div_cnt == LED_DIV_MAX) begin
                    led_div_cnt <= 0;

                    // 10-bit LFSR
                    led_lfsr <= {led_lfsr[8:0], led_lfsr[9] ^ led_lfsr[6]};

                    // flashing pattern radomizes using XOR
                    led_pattern <= led_lfsr ^
                                    {led_lfsr[0], led_lfsr[1], led_lfsr[2],
                                     led_lfsr[3], led_lfsr[4], led_lfsr[5],
                                     led_lfsr[6], led_lfsr[7], led_lfsr[8],
                                     led_lfsr[9]};
                end else begin
                    led_div_cnt <= led_div_cnt + 1;
                end
            end
        end
    end

    assign LEDR = led_pattern;

endmodule


