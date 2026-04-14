module game_engine(
    input clk,
    input button,
    output reg [9:0] bird_y,
    output reg [15:0] best_score
);

initial begin
    bird_y    = 10'd263;  // (35 + 514 - 24) / 2 = vertically centered
    best_score = 16'd0;
end

endmodule