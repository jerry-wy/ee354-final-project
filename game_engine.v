module game_engine(
    input clk,
    input reset,
    input flap,
    input pause,
    input frame_tick,

    output [9:0] bird_y,

    output [9:0] pipe_x0, pipe_x1, pipe_x2, pipe_x3, pipe_x4,
    output [9:0] pipe_gap_y0, pipe_gap_y1, pipe_gap_y2, pipe_gap_y3, pipe_gap_y4,

    output reg [7:0] scroll_x,
    output reg [15:0] score,
    output reg [15:0] best_score
);

  localparam PIPE_SPACING = 10'd160;

  localparam PX_INIT      = 10'd718;
  localparam P_SPEED      = 10'd1;

  localparam SCROLL_INIT  = 8'd0;
  localparam SCROLL_SPEED = 8'd1;
  localparam SCROLL_WRAP  = 8'd255;

  wire [9:0] bird_velocity;
  wire Qini, Qflap, Qrise, Qfall;

  reg [9:0]  base_x;
  reg [9:0]  pipe_x_arr  [0:4];
  reg [10:0] pipe_x_wide [0:4];   // 11-bit to detect overflow before truncation
  reg [9:0]  pipe_gap_y_arr [0:4];

  reg [9:0] lfsr;

  integer i;

  bird_physics bp(
      .Reset(reset),
      .Clk(clk),
      .div_clk(frame_tick),
      .flap(flap),
      .pause(pause),
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
          // bit 10 set means value > 1023 — pipe is far off-screen right;
          // clamp to 800 so the 10-bit truncation cannot wrap onto the display.
          pipe_x_arr[i] = pipe_x_wide[i][10] ? 10'd800 : pipe_x_wide[i][9:0];
      end
  end


    always @(posedge clk or posedge reset) begin
        if (reset)
            lfsr <= 10'b1010010110;   // any non-zero seed
        else
            lfsr <= {lfsr[8:0], lfsr[9] ^ lfsr[6]};  // taps
    end

  always @(posedge clk or posedge reset) begin
      if (reset) begin
          base_x <= PX_INIT;

          for (i = 0; i < 5; i = i + 1)
              pipe_gap_y_arr[i] <= 10'd200 + i * 30;

          scroll_x <= SCROLL_INIT;
          score <= 0;
          best_score <= 0;
      end

      else if (frame_tick && !pause) begin
          if (base_x < P_SPEED) begin
            base_x <= PIPE_SPACING;

            for (i = 0; i < 4; i = i + 1)
                pipe_gap_y_arr[i] <= pipe_gap_y_arr[i+1];

            pipe_gap_y_arr[4] <= 80 + (lfsr % 320);

            score <= score + 1;
            if (score + 1 > best_score)
                best_score <= score + 1;
          end
          
          else begin
              base_x <= base_x - P_SPEED;
          end

          if (scroll_x < SCROLL_WRAP)
              scroll_x <= scroll_x + SCROLL_SPEED;
          else
              scroll_x <= 0;
      end
  end

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