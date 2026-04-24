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
	// input button,
	input [9:0] hCount, vCount,
    input [9:0] bird_y,
    input [7:0] scroll_x,
	input [9:0] pipe_x,
	input [9:0] pipe_gap_y,
	output reg [11:0] rgb
	// output reg [15:0] score
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

    wire bird_in_x = (hActive >= BIRD_X) && (hActive < BIRD_X + BIRD_W);
    wire bird_in_y = (vActive >= bird_y) && (vActive < bird_y + BIRD_H);

	wire [5:0] bird_col;
    wire [4:0] bird_row;
    wire [11:0] bird_color;

    assign bird_col = bird_in_x ? (hActive - BIRD_X) : 6'd0;
    assign bird_row = bird_in_y ? (vActive - bird_y) : 5'd0;

	bird_rom u_bird (.clk(clk),.col(bird_col),.row(bird_row),.color_data(bird_color));

    reg bird_on_d;
    reg [11:0] bird_color_d;

    always @(posedge clk) begin
        bird_on_d    <= bird_in_x && bird_in_y;
        bird_color_d <= bird_color;
    end

	// ---- pipe ROM -------------------------------------------------------
	localparam [9:0] PIPE_W           = 10'd34; // visual display width (cap width)
	localparam [6:0] PIPE_COL_OFS     = 7'd42;  // first non-transparent ROM column
	localparam [9:0] PIPE_HALF_GAP    = 10'd80; // half the Y gap between upper/lower pipe
	localparam [5:0] PIPE_CAP_BOT_ROW = 6'd31;  // gap-facing cap row (outermost)
	localparam [5:0] PIPE_BODY_BOT_ROW= 6'd26;  // body row adjacent to cap (innermost)
	localparam       PIPE_CAP_H       = 5;       // number of cap rows
	localparam       PIPE_BODY_H      = 24;      // number of body rows (tiled)

	// --- Horizontal ---
	wire        pipe_in_x = (pipe_x >= PIPE_W) &&
	                        (hActive >= pipe_x - PIPE_W) &&
	                        (hActive <  pipe_x);
	wire [9:0]  h_off     = hActive - (pipe_x - PIPE_W);   // 0..PIPE_W-1 when pipe_in_x
	wire [6:0]  pipe_col  = pipe_in_x ? (PIPE_COL_OFS + h_off[5:0]) : 7'd0;

	// --- Vertical ---
	wire        pipe_upper_in_y = (vActive < pipe_gap_y - PIPE_HALF_GAP);
	wire pipe_lower_in_y = (vActive >= pipe_gap_y + PIPE_HALF_GAP) && (vActive <  BAR_TOP);
	wire        pipe_in_y       = pipe_upper_in_y || pipe_lower_in_y;

	// Distance from the gap boundary (same interpretation for both pipes).
	wire [9:0]  dist_upper = (pipe_gap_y - PIPE_HALF_GAP - 10'd1) - vActive;
	wire [9:0]  dist_lower = vActive - (pipe_gap_y + PIPE_HALF_GAP);
	wire [9:0]  dist       = pipe_upper_in_y ? dist_upper : dist_lower;

	// --- ROM row ---
	wire        in_cap    = (dist < PIPE_CAP_H);
	wire [9:0]  body_off  = in_cap ? 10'd0 : (dist - PIPE_CAP_H); // safe unsigned
	wire [5:0]  body_idx  = body_off % PIPE_BODY_H;                // 0-23
	wire [5:0]  cap_row   = PIPE_CAP_BOT_ROW - {3'b0, dist[2:0]};  // 31..27
	wire [5:0]  body_row  = PIPE_BODY_BOT_ROW - body_idx;          // 26..3
	wire [5:0]  pipe_row  = (pipe_in_x && pipe_in_y)
	                            ? (in_cap ? cap_row : body_row)
	                            : 6'd0;

	wire [11:0] pipe_color;
	pipe_rom u_pipe (
	    .clk        (clk),
	    .row        (pipe_row),
	    .col        (pipe_col),
	    .color_data (pipe_color)
	);

	reg [11:0] pipe_color_d;
	always @(posedge clk)
	    pipe_color_d <= pipe_color;

	// ---------------- Rendering ----------------
    always @(*) begin
		if (!bright)
			rgb = 0;
		else if (bird_on_d && bird_color_d != 0)
			rgb = bird_color_d;
		else if (bird_on_d)
			rgb = bg_color_d;
		else if (pipe_color_d != 0)
			rgb = pipe_color_d;
		else if (bar_on_d)
			rgb = bar_color_d;
		else
			rgb = bg_color_d;
	end
endmodule
