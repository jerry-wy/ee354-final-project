`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:15:38 12/14/2017 
// Design Name: 
// Module Name:    vgaBitChange 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Yue (Julien) Niu
// Description: Port from NEXYS3 to NEXYS4
//////////////////////////////////////////////////////////////////////////////////
module vga_bitchange(
	input clk,
	input bright,
	input button,
	input [9:0] hCount, vCount,
    input [9:0] bird_y,
    input [7:0] scroll_x,
	input [9:0] pipe_x,
	input [9:0] pipe_gap_y,
	output reg [11:0] rgb,
	output reg [15:0] score
   );

   	// ---- background ROM ------------------------------------------------
	// Scale the 160x120 ROM to fill the full 640x480 active area.
	// 640/160=4 and 480/120=4 — divide by 4 = right-shift 2 (no divider needed).
	wire [9:0] hActive = (hCount >= 10'd144) ? (hCount - 10'd144) : 10'd0;
	wire [9:0] vActive = (vCount >= 10'd35)  ? (vCount - 10'd35)  : 10'd0;
	wire [7:0] bg_col;
	wire [6:0] bg_row;
	wire [11:0] bg_color;
	assign bg_col = hActive[9:2];  // hActive / 4
	assign bg_row = vActive[9:2];  // vActive / 4

	background_rom u_bg (.clk(clk),.col(bg_col),.row(bg_row),.color_data(bg_color));

    reg [11:0] bg_color_d;

    always @(posedge clk) begin
        bg_color_d <= bg_color;
    end

    // ---- moving bar ROM -------------------------------------------------
	// 256x30 ground strip at the bottom 30 rows of the active area.
	// Scrolls left by incrementing scroll_x every ~10ms (≈95 px/s at 100MHz).
	localparam BAR_TOP = 10'd450;  // vActive row where bar starts (480-30=450)

	wire bar_in_y = (vActive >= BAR_TOP);
	wire [7:0] bar_col = hActive[7:0] + scroll_x;  // lower 8 bits = mod 256
	wire [4:0] bar_row = bar_in_y ? vActive - BAR_TOP : 5'd0;
	wire [11:0] bar_color;

	moving_bar_rom u_bar (.clk(clk), .col(bar_col), .row(bar_row), .color_data(bar_color));

	reg bar_on_d;
	reg [11:0] bar_color_d;

	always @(posedge clk) begin
		bar_on_d    <= bar_in_y;
		bar_color_d <= bar_color;
	end
	
	// ---- bird ROM -------------------------------------------------------
	parameter BIRD_W = 43;
    parameter BIRD_H = 30;
    parameter BIRD_X = 443;
    
    wire bird_in_x = (hCount >= BIRD_X) && (hCount < BIRD_X + BIRD_W);
    wire bird_in_y = (vCount >= bird_y) && (vCount < bird_y + BIRD_H);

	wire [5:0] bird_col;
    wire [4:0] bird_row;
    wire [11:0] bird_color;

    assign bird_col = bird_in_x ? (hCount - BIRD_X) : 6'd0;
    assign bird_row = bird_in_y ? (vCount - bird_y) : 5'd0;

	bird_rom u_bird (.clk(clk),.col(bird_col),.row(bird_row),.color_data(bird_color));

    reg bird_on_d;
    reg [11:0] bird_color_d;

    always @(posedge clk) begin
        bird_on_d    <= bird_in_x && bird_in_y;
        bird_color_d <= bird_color;
    end


	// ---- pipe ROM -------------------------------------------------------
    localparam PIPE_W     = 78;
	localparam PIPE_CAP_H = 36;
	localparam GAP_H      = 160;

	wire pipe_in_x = (hCount >= pipe_x) && (hCount < pipe_x + PIPE_W);

	wire top_cap  = pipe_in_x && (vCount >= pipe_gap_y - PIPE_CAP_H) && (vCount < pipe_gap_y);
	wire top_body = pipe_in_x && (vCount <  pipe_gap_y - PIPE_CAP_H);

	wire bot_cap  = pipe_in_x && (vCount >= pipe_gap_y + GAP_H) && (vCount < pipe_gap_y + GAP_H + PIPE_CAP_H);
	wire bot_body = pipe_in_x && (vCount >= pipe_gap_y + GAP_H + PIPE_CAP_H);

	wire pipe_active = top_cap || top_body || bot_cap || bot_body;

	wire [5:0] pipe_col = pipe_active ? (hCount - pipe_x) : 6'd0;

	// caps
	wire [5:0] pipe_row_cap_top =
		vCount - (pipe_gap_y - PIPE_CAP_H);

	wire [5:0] pipe_row_cap_bot =
		PIPE_CAP_H - 1 - (vCount - (pipe_gap_y + GAP_H));

	// safe offsets
	wire [9:0] top_offset =
		pipe_gap_y - PIPE_CAP_H - vCount + PIPE_CAP_H * 4;

	wire [9:0] bot_offset =
		vCount - (pipe_gap_y + GAP_H + PIPE_CAP_H);

	// body (continuous)
	wire [5:0] pipe_row_top_body =
		top_offset % PIPE_CAP_H;

	wire [5:0] pipe_row_bot_body =
		bot_offset % PIPE_CAP_H;

	// select
	wire [5:0] pipe_row =
		top_cap  ? pipe_row_cap_top  :
		bot_cap  ? pipe_row_cap_bot  :
		top_body ? pipe_row_top_body :
				pipe_row_bot_body;

	wire [11:0] pipe_color;
	pipe_rom u_pipe(.clk(clk), .col(pipe_col), .row(pipe_row), .color_data(pipe_color));

	reg pipe_on_d;
	reg [11:0] pipe_color_d;

	always @(posedge clk) begin
		pipe_on_d    <= pipe_active;
		pipe_color_d <= pipe_color;
	end

    always @(*) begin
		if (!bright)
			rgb = 0;
		else if (bird_on_d && bird_color_d != 0)
			rgb = bird_color_d;
		else if (pipe_on_d && pipe_color_d != 0)
			rgb = pipe_color_d;
		else if (bar_on_d)
			rgb = bar_color_d;
		else
			rgb = bg_color_d;
	end
endmodule
