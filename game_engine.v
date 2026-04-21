module game_engine(
    input clk,
    input reset,
    input flap, // user pressing the fap button --> SEND TO BP FOR BIRD JUMP
    input pause, // whether or not the game is paused
    input frame_tick,

    output [9:0] bird_y,
    output reg [9:0] pipe_x, // horizontal position of the pipe
    output [9:0] pipe_gap_y,// location of the pipe gap (center)
    output reg [7:0] scroll_x, //
    output reg [15:0] score,
    output reg [15:0] best_score
);

  wire [9:0] bird_velocity;
  wire Qini, Qflap, Qrise, Qfall;

  reg pipe_respawn;// flag to signal new incoming pipe

  localparam
    PX_INIT = 10'd639, // initial pipe x position, far right of screen
    P_SPEED = 10'd4,  // pipe speed # of pixels per frame
    P_WIDTH = 10'd78,  // pipe width
    SCROLL_INIT = 8'd0,
    SCROLL_SPEED = 8'd4, // scroll speed # of pixels per frame
    SCROLL_WRAP = 8'd255; // wrap around for scrolling

    bird_physics bp(.Reset(reset), .Clk(clk), .div_clk(frame_tick), .flap(flap), .pause(pause), .Ypos(bird_y), .velocity(bird_velocity), .Qini(Qini), .Qflap(Qflap),.Qrise(Qrise), .Qfall(Qfall));
    pipe p(.Clk(clk), .Reset(reset), .div_clk(pipe_respawn), .pause(pause), .GapY(pipe_gap_y));

  always @(posedge clk or posedge reset) begin
    if (reset)
    begin
        pipe_x <= PX_INIT;
        scroll_x <= SCROLL_INIT;
        score <= 0;
        best_score <= 0;
        pipe_respawn <= 0;
    end

    else
    begin
        pipe_respawn <= 0;
        if (frame_tick && !pause)
        begin
            if (pipe_x > P_SPEED)
                pipe_x <= pipe_x - P_SPEED;

            else
            begin
                pipe_x <= PX_INIT;
                pipe_respawn <= 1;
                score <= score + 1;

                if (score + 1 > best_score)
                    best_score <= score + 1;
            end

            if (scroll_x < SCROLL_WRAP)
                scroll_x <= scroll_x + SCROLL_SPEED;
            else
                scroll_x <= 0;

        end

    end
  end

endmodule
