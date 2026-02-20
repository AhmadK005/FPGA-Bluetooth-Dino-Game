module vga(
    input             clk, //Clock
    input             reset_n, // Key0 reset 0
    input             key_n, // Manual Jump 
    input             jump_btn, //Bluetooth jump pulse, active-high
    input      [9:0]  sw, // now using sw[1] sw[0] for color random
    input             disp_ena,
    input      [9:0]  column,
    input      [8:0]  row,
    output reg [3:0]  r, g, b,
    output      [6:0] hex1, hex2,
    output            game_alive // high when game is running
);

    // Screen / Dino / Obstacle constants (pixels)
    localparam SCREEN_W  = 10'd640;	//Screen Width
    localparam SCREEN_H  = 9'd480;	//Screen Height

    localparam GROUND_Y  = 9'd380;	//Screen ground

    localparam DINO_W    = 10'd32; //player width
    localparam DINO_H    = 9'd40;  //player height
    localparam DINO_X    = 10'd80;	//player start location
    localparam [8:0] DINO_GROUND_Y = GROUND_Y - DINO_H; // player ground is ground - dino height 380 - 40 = 340 

    localparam OBS_W     = 10'd20;	//obstacle width
    localparam OBS_H     = 9'd40;	//obstacle height
    localparam OBS_SPEED = 10'd4;   // obstacel speed

    //spacing in game 
    localparam [9:0] MIN_SPAWN_FIRST = 10'd200; // first obstacle after ~4+ s
    localparam [9:0] MIN_SPAWN_GAP   = 10'd100; // ~2.1 s
    localparam [9:0] MAX_SPAWN_GAP   = 10'd160; // ~3.3 s
    localparam [9:0] GAP_RANGE       = MAX_SPAWN_GAP - MIN_SPAWN_GAP; // 60

 
    reg [18:0] tick_cnt;
    wire game_tick = (tick_cnt == 19'd0);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) //set tick count to 0
            tick_cnt <= 19'd0;
        else
            tick_cnt <= tick_cnt + 19'd1; //increment tick counter for
    end
   // Jump physics 

    reg [9:0] dino_x;
    reg [8:0] dino_y;
    reg signed [7:0] vel_y;
    reg jumping;

    wire signed [9:0] dino_y_signed = {1'b0, dino_y};
    wire signed [9:0] dino_y_next   = dino_y_signed + vel_y;


    // Multiple obstacles (3 slots)
 
    reg [9:0] obs_x0, obs_x1, obs_x2;
    reg       obs_a0, obs_a1, obs_a2;  // active flags

    reg [9:0] spawn_cnt;
    reg [9:0] rand_val;
    reg [9:0] rand_gap;

    reg       game_over;

    // 12-bit LFSR for randomness
    reg [11:0] lfsr;
    wire       lfsr_fb = lfsr[11] ^ lfsr[10] ^ lfsr[9] ^ lfsr[3];

    wire       jump_pressed = (!key_n) | jump_btn;


    // Dino color randomization
    reg        sw1_d;
    reg [3:0]  dino_r_col, dino_g_col, dino_b_col;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            sw1_d       <= 1'b0;
            // default dino color = green
            dino_r_col  <= 4'h0;
            dino_g_col  <= 4'hF;
            dino_b_col  <= 4'h0;
        end else begin
            // detect toggle of SW1 
            sw1_d <= sw[1];

            if (sw1_d ^ sw[1]) begin
                // On each toggle, pick a new random color from LFSR
                {dino_r_col, dino_g_col, dino_b_col} <= {lfsr[11:8], lfsr[7:4], lfsr[3:0]};
                // avoid all-black 
                if ({lfsr[11:8], lfsr[7:4], lfsr[3:0]} == 12'h000) begin
                    dino_r_col <= 4'hF;
                    dino_g_col <= 4'hF;
                    dino_b_col <= 4'hF;
                end
            end
        end
    end


    // Main state update
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Dino
            dino_x     <= DINO_X;
            dino_y     <= DINO_GROUND_Y;
            vel_y      <= 8'sd0;
            jumping    <= 1'b0;

            // Obstacles
            obs_x0 <= SCREEN_W; obs_a0 <= 1'b0;
            obs_x1 <= SCREEN_W; obs_a1 <= 1'b0;
            obs_x2 <= SCREEN_W; obs_a2 <= 1'b0;

            spawn_cnt <= MIN_SPAWN_FIRST;  // long wait before first spawn

            game_over <= 1'b0;

            // RNG
            lfsr     <= 12'hA5A;
            rand_val <= 10'd0;
            rand_gap <= 10'd0;
        end else begin
            // LFSR advances on each game tick
            if (game_tick) begin
                lfsr <= {lfsr[10:0], lfsr_fb};
                // jump_pressed 
            end

            if (jump_pressed && !jumping && (dino_y == DINO_GROUND_Y) && !game_over) begin
                jumping <= 1'b1;
                vel_y   <= -8'sd15;     // jump velocity
            end


            // Jump update
            if (game_tick && jumping && !game_over) begin
                if (dino_y_next[8:0] >= DINO_GROUND_Y) begin
                    dino_y  <= DINO_GROUND_Y;
                    vel_y   <= 8'sd0;
                    jumping <= 1'b0;
                end else begin
                    dino_y <= dino_y_next[8:0];
                    vel_y  <= vel_y + 8'sd1;  // gravity
                end
            end

            // Move all active obstacles

            if (game_tick && !game_over) begin
                // slot 0
                if (obs_a0) begin
                    if (obs_x0 > OBS_SPEED)
                        obs_x0 <= obs_x0 - OBS_SPEED;
                    else begin
                        obs_x0 <= SCREEN_W;
                        obs_a0 <= 1'b0;
                    end
                end
                // slot 1
                if (obs_a1) begin
                    if (obs_x1 > OBS_SPEED)
                        obs_x1 <= obs_x1 - OBS_SPEED;
                    else begin
                        obs_x1 <= SCREEN_W;
                        obs_a1 <= 1'b0;
                    end
                end
                // slot 2
                if (obs_a2) begin
                    if (obs_x2 > OBS_SPEED)
                        obs_x2 <= obs_x2 - OBS_SPEED;
                    else begin
                        obs_x2 <= SCREEN_W;
                        obs_a2 <= 1'b0;
                    end
                end
                // Spawn new obstacles based on spawn_cnt
                if (spawn_cnt > 0) begin
                    spawn_cnt <= spawn_cnt - 10'd1;
                end else begin
                    // find first free slot (max 3)
                    if (!obs_a0) begin
                        obs_a0 <= 1'b1;
                        obs_x0 <= SCREEN_W;
                    end else if (!obs_a1) begin
                        obs_a1 <= 1'b1;
                        obs_x1 <= SCREEN_W;
                    end else if (!obs_a2) begin
                        obs_a2 <= 1'b1;
                        obs_x2 <= SCREEN_W;
                    end
                    // compute next random spawn_cnt in [MIN_SPAWN_GAP, MAX_SPAWN_GAP]
                    rand_val = {2'b00, lfsr[7:0]};             // 0 - 255
                    rand_gap = rand_val % (GAP_RANGE + 10'd1); // 0 - GAP_RANGE
                    spawn_cnt <= MIN_SPAWN_GAP + rand_gap;     // MIN - MAX
                end
            end


            // Collision detection with any obstacle
            if (game_tick && !game_over) begin
                // slot 0
                if (obs_a0 &&
                    (dino_x + DINO_W > obs_x0) &&
                    (dino_x < obs_x0 + OBS_W) &&
                    (dino_y + DINO_H > (GROUND_Y - OBS_H)) &&
                    (dino_y < GROUND_Y)) begin
                    game_over <= 1'b1;
                end
                // slot 1
                else if (obs_a1 &&
                    (dino_x + DINO_W > obs_x1) &&
                    (dino_x < obs_x1 + OBS_W) &&
                    (dino_y + DINO_H > (GROUND_Y - OBS_H)) &&
                    (dino_y < GROUND_Y)) begin
                    game_over <= 1'b1;
                end
                // slot 2
                else if (obs_a2 &&
                    (dino_x + DINO_W > obs_x2) &&
                    (dino_x < obs_x2 + OBS_W) &&
                    (dino_y + DINO_H > (GROUND_Y - OBS_H)) &&
                    (dino_y < GROUND_Y)) begin
                    game_over <= 1'b1;
                end
            end
        end
    end


    // VGA drawing
    wire in_dino =
        (column >= dino_x) && (column < dino_x + DINO_W) &&
        (row    >= dino_y) && (row    < dino_y + DINO_H);

    wire in_obs0 =
        obs_a0 &&
        (column >= obs_x0) && (column < obs_x0 + OBS_W) &&
        (row    >= (GROUND_Y - OBS_H)) && (row < GROUND_Y);

    wire in_obs1 =
        obs_a1 &&
        (column >= obs_x1) && (column < obs_x1 + OBS_W) &&
        (row    >= (GROUND_Y - OBS_H)) && (row < GROUND_Y);

    wire in_obs2 =
        obs_a2 &&
        (column >= obs_x2) && (column < obs_x2 + OBS_W) &&
        (row    >= (GROUND_Y - OBS_H)) && (row < GROUND_Y);

    wire in_obs    = in_obs0 | in_obs1 | in_obs2;
    wire on_ground = (row >= GROUND_Y);

    always @(*) begin
        if (!disp_ena) begin
            r = 4'h0; g = 4'h0; b = 4'h0;
        end else begin
            // Sky
            r = 4'h4; g = 4'h7; b = 4'hF;

            // Ground strip
            if (on_ground) begin
                r = 4'h3; g = 4'h2; b = 4'h0;
            end

            // Obstacles (red)
            if (in_obs) begin
                r = 4'hF; g = 4'h0; b = 4'h0;
            end

            // Dino (random color when alive, magenta when game over)
            if (in_dino) begin
                if (game_over)
                    {r,g,b} = {4'hF, 4'h0, 4'hF};  // magenta = dead
                else
                    {r,g,b} = {dino_r_col, dino_g_col, dino_b_col};
            end
        end
    end



    assign hex1 = 7'b1111111;
    assign hex2 = 7'b1111111;


    // Game alive flag
    assign game_alive = ~game_over;

endmodule
