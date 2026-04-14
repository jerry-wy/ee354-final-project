module renderer(
    input  wire video_on,
    input  wire [9:0] x,
    input  wire [9:0] y,
    output reg  [11:0] rgb
);

    // Bird parameters
    localparam BIRD_X = 200;
    localparam BIRD_Y = 200;
    localparam RADIUS = 10;

    // Pipe parameters
    localparam PIPE_X = 300;
    localparam PIPE_W = 40;
    localparam GAP_TOP = 150;
    localparam GAP_BOTTOM = 250;

    wire signed [10:0] dx = $signed({1'b0, x}) - BIRD_X;
    wire signed [10:0] dy = $signed({1'b0, y}) - BIRD_Y;

    wire inside_circle;
    assign inside_circle = (dx*dx + dy*dy <= RADIUS*RADIUS);

    wire inside_pipe;
    assign inside_pipe =
        (x >= PIPE_X && x < PIPE_X + PIPE_W) &&
        (y < GAP_TOP || y > GAP_BOTTOM);

    always @(*) begin
        if (!video_on) begin
            rgb = 12'h000;
        end
        else begin
            // sky
            rgb = 12'h3CF;

            // ground
            if (y >= 400)
                rgb = 12'h6C3;

            // pipe
            if (inside_pipe)
                rgb = 12'h0F0;

            // bird
            if (inside_circle)
                rgb = 12'hFF0;
        end
    end

endmodule