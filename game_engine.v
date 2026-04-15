module game_engine(
    input Clk,
    input Reset,

    output [9:0] bird_y,
    output reg [9:0] pipe_x,
    output reg [9:0] pipe_gap_y,
    output reg [7:0] scroll_x,
    output reg [15:0] best_score,

    input [9:0] hCount,
    input [9:0] vCount
);

parameter SPEED = 2; // 2 x 100, roughly 200 pixels per second

initial begin
    bird_y     = 10'd263;
    pipe_x     = 640;
    scroll_x   = 0;
    best_score = 0;
end

wire frame_tick = (hCount == 0 && vCount == 0);
always @(posedge clk) begin
    if (frame_tick) begin

        if (pipe_x <= SPEED)
            pipe_x <= 640;
        else
            pipe_x <= pipe_x - SPEED;

        // ground scroll
        scroll_x <= scroll_x + SPEED;
    end
end

bird_physics bp(.Reset(Reset), .Clk(Clk), .div_clk(frame_tick), .flap(flap), .pause(1'b0), .Ypos(bird_y),
                .velocity(bird_velocity), .Qini(Qini), .Qflap(Qflap), .Qrise(Qrise), .Qfall(Qfall));

always @(posedge Clk or posedge Reset)
begin
    if (Reset)
      begin
        pipe_x <= 640;
        pipe_gap_y <= 200;
        scroll_x <= 8'd0;
        score <= 16'd0;
        best_score <= 16'd0;
      end

    else if (frame_tick)
    begin
        if (pipe_x <= SPEED)
            pipe_x <= 640;
        else
            pipe_x <= pipe_x - SPEED;
        scroll_x <= scroll_x + SPEED[7:0];
    end
end

endmodule
