module game_engine(
    input clk,
    input reset,
    input flap,
    input ACK,
    input pause, // unused
    input frame_tick,
    input force_gameover,

    output [9:0] bird_y,
    output [9:0] pipe_x0, pipe_x1, pipe_x2, pipe_x3, pipe_x4,
    output [9:0] pipe_gap_y0, pipe_gap_y1, pipe_gap_y2, pipe_gap_y3, pipe_gap_y4,
    output reg [7:0] scroll_x,
    output reg [15:0] score,
    output reg [15:0] best_score,
    output reg [1:0]  game_state
);

  // game state codes
  localparam Q_TITLE = 2'd0;
  localparam Q_PLAY = 2'd1;
  localparam Q_OVER = 2'd2;

  localparam PIPE_SPACING = 10'd150;

  localparam PX_INIT = 10'd718;
  localparam P_SPEED = 10'd2;

  localparam SCROLL_INIT = 8'd0;
  localparam SCROLL_SPEED = 8'd2;
  localparam SCROLL_WRAP = 8'd255;

  localparam
    BIRD_X = 11'd205,
    BIRD_WIDTH = 11'd60,
    BIRD_HEIGHT = 11'd22,
    PIPE_WIDTH = 11'd34,
    PIPE_HGAP = 11'd70;

  wire [9:0] bird_velocity;

  wire bird_flap;
  reg flap_pending;
  wire Qini, Qflap, Qrise, Qfall;
  wire collision;
  wire round_reset;
  assign round_reset = (game_state == Q_OVER) && ACK;

  wire ground_col;
  assign ground_col = bird_y >= 10'd420;

  wire pipe_col;
  assign collision = ground_col || pipe_col;

  reg [9:0]  base_x;
  reg [9:0]  pipe_x_arr  [0:4];
  reg [10:0] pipe_x_wide [0:4];
  reg [9:0]  pipe_gap_y_arr [0:4];
  reg [9:0] lfsr; // linear feedback shift resgiter for random number generation
  reg pipe_col_reg;
  reg[10:0] birdl, birdr, birdtop, birdbottom;
  reg[10:0] pipel, piper, gaptop, gapbottom;

  integer i;
  integer j;

  // state machine
  always @(posedge clk or posedge reset) begin
      if (reset)
          game_state <= Q_TITLE;
      else case (game_state)
          Q_TITLE: if (flap) game_state <= Q_PLAY;
          Q_PLAY: if (force_gameover || collision) game_state <= Q_OVER;
          Q_OVER:
            begin
                game_state <= Q_OVER;
                if (ACK)
                    game_state <= Q_TITLE;
            end
          default: ;
      endcase
  end

  always @(posedge clk or posedge reset) begin
    if (reset)
        flap_pending <= 0;

    else if (game_state == Q_OVER)
        flap_pending <= 0;

    else if (flap)
        flap_pending <= 1;

    else if (frame_tick && game_state == Q_PLAY)
        flap_pending <= 0;

 end

 assign bird_flap = flap_pending;

  bird_physics bp(
      .Reset(reset),
      .round_reset(round_reset),
      .Clk(clk),
      .div_clk(frame_tick),
      .flap(bird_flap),
      .pause((game_state != Q_PLAY) || pause),
      .Ypos(bird_y),
      .velocity(bird_velocity),
      .Qini(Qini),
      .Qflap(Qflap),
      .Qrise(Qrise),
      .Qfall(Qfall)
  );

  always @(*) begin
      for (i = 0; i < 5; i = i + 1) begin
          pipe_x_wide[i] = base_x + i * PIPE_SPACING;
          pipe_x_arr[i] = pipe_x_wide[i][10] ? 10'd800 : pipe_x_wide[i][9:0];
      end
  end


    always @(posedge clk or posedge reset) begin
        if (reset)
            lfsr <= 10'b1010010110;
        else
            lfsr <= {lfsr[8:0], lfsr[9] ^ lfsr[6]};
    end

  always @(posedge clk or posedge reset) begin
      if (reset || round_reset) begin
          base_x <= PX_INIT; // reset pipe position to offscreen

          for (i = 0; i < 5; i = i + 1)
              pipe_gap_y_arr[i] <= 10'd200 + i * 20; // initial pipe values (hardcoded)

          scroll_x <= SCROLL_INIT;
          score <= 0;
          if (reset)
            best_score <= 0;
      end

      else if (frame_tick) begin
          // bar scrolls in START and PLAYING; freezes in GAMEOVER
          if (game_state != Q_OVER) begin
              if (scroll_x < SCROLL_WRAP)
                  scroll_x <= scroll_x + SCROLL_SPEED;
              else
                  scroll_x <= 0;
          end

          // pipes advance only while playing
          if (game_state == Q_PLAY && !pause) begin

              if (((pipe_x_arr[0] > 10'd200) && (pipe_x_arr[0] <= 10'd200 + P_SPEED)) ||
                 ((pipe_x_arr[1] > 10'd200) && (pipe_x_arr[1] <= 10'd200 + P_SPEED)) ||
                 ((pipe_x_arr[2] > 10'd200) && (pipe_x_arr[2] <= 10'd200 + P_SPEED)) ||
                 ((pipe_x_arr[3] > 10'd200) && (pipe_x_arr[3] <= 10'd200 + P_SPEED)) ||
                 ((pipe_x_arr[4] > 10'd200) && (pipe_x_arr[4] <= 10'd200 + P_SPEED)))
                 begin
                   score <= score + 1;
                   if (score + 1 > best_score)
                     best_score <= score + 1;
                  end
              if (base_x < P_SPEED) begin // recycle pipe
                  base_x <= PIPE_SPACING;

                  for (i = 0; i < 4; i = i + 1)
                      pipe_gap_y_arr[i] <= pipe_gap_y_arr[i+1];

                  pipe_gap_y_arr[4] <= 80 + (lfsr % 320);

              end else begin
                  base_x <= base_x - P_SPEED;
              end
          end
      end
  end

  always @(*) begin
    pipe_col_reg = 0;
    birdl = BIRD_X;
    birdr = BIRD_X + BIRD_WIDTH - 1;
    birdtop = {1'b0, bird_y};
    birdbottom = {1'b0, bird_y} + BIRD_HEIGHT - 1;
    for (j = 0; j < 5; j = j + 1) begin
          if ({1'b0, pipe_x_arr[j]}> PIPE_WIDTH)
            pipel  = {1'b0, pipe_x_arr[j]};
          else
            pipel = 0;

          piper = {1'b0, pipe_x_arr[j]};

          gaptop    = {1'b0, pipe_gap_y_arr[j]} - PIPE_HGAP;
          gapbottom = {1'b0, pipe_gap_y_arr[j]} + PIPE_HGAP;

          if ((birdr >= pipel) && (birdl <= piper) && ((birdtop < gaptop) || (birdbottom > gapbottom))) begin
              pipe_col_reg = 1'b1;
          end
      end
  end

  assign pipe_col = pipe_col_reg;


  assign pipe_x0 = pipe_x_arr[0];
  assign pipe_x1 = pipe_x_arr[1];
  assign pipe_x2 = pipe_x_arr[2];
  assign pipe_x3 = pipe_x_arr[3];
  assign pipe_x4 = pipe_x_arr[4];

  assign pipe_gap_y0 = pipe_gap_y_arr[0];
  assign pipe_gap_y1 = pipe_gap_y_arr[1];
  assign pipe_gap_y2 = pipe_gap_y_arr[2];
  assign pipe_gap_y3 = pipe_gap_y_arr[3];
  assign pipe_gap_y4 = pipe_gap_y_arr[4];

endmodule
