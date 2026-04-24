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
	input [9:0] pipe_x0, pipe_x1, pipe_x2, pipe_x3, pipe_x4,
	input [9:0] pipe_gap_y0, pipe_gap_y1, pipe_gap_y2, pipe_gap_y3, pipe_gap_y4,
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
	wire [9:0] pipe_x [0:4];
	wire [9:0] pipe_gap_y [0:4];

	assign pipe_x[0] = pipe_x0;
	assign pipe_x[1] = pipe_x1;
	assign pipe_x[2] = pipe_x2;
	assign pipe_x[3] = pipe_x3;
	assign pipe_x[4] = pipe_x4;

	assign pipe_gap_y[0] = pipe_gap_y0;
	assign pipe_gap_y[1] = pipe_gap_y1;
	assign pipe_gap_y[2] = pipe_gap_y2;
	assign pipe_gap_y[3] = pipe_gap_y3;
	assign pipe_gap_y[4] = pipe_gap_y4;

	localparam [9:0] PIPE_W           = 10'd34;
	localparam [6:0] PIPE_COL_OFS     = 7'd42;
	localparam [9:0] PIPE_HALF_GAP    = 10'd80;
	localparam [5:0] PIPE_CAP_BOT_ROW = 6'd31;
	localparam [5:0] PIPE_BODY_BOT_ROW= 6'd26;
	localparam       PIPE_CAP_H       = 5;
	localparam       PIPE_BODY_H      = 24;

	integer i;
	
	reg        pipe_hit;
	reg [6:0]  pipe_col_mux;
	reg [5:0]  pipe_row_mux;
	reg [9:0]  dist;

	always @(*) begin
		pipe_hit     = 0;
		pipe_col_mux = 0;
		pipe_row_mux = 0;

		for (i = 0; i < 5; i = i + 1) begin
			if (!pipe_hit) begin

				// ---- horizontal check ----
				if ((pipe_x[i] > 0) && (hActive < pipe_x[i]) && (hActive + PIPE_W >= pipe_x[i])) begin

					// ---- vertical check ----
					if ((vActive <  pipe_gap_y[i] - PIPE_HALF_GAP) || (vActive >= pipe_gap_y[i] + PIPE_HALF_GAP && vActive < BAR_TOP)) begin

						// ---- distance from gap ----
						if (vActive < pipe_gap_y[i])
							dist = (pipe_gap_y[i] - PIPE_HALF_GAP - 1) - vActive;
						else
							dist = vActive - (pipe_gap_y[i] + PIPE_HALF_GAP);

						// ---- row selection ----
						if (dist < PIPE_CAP_H)
							pipe_row_mux = PIPE_CAP_BOT_ROW - dist[2:0];
						else
							pipe_row_mux = PIPE_BODY_BOT_ROW -
										((dist - PIPE_CAP_H) % PIPE_BODY_H);

						// ---- column selection ----
						pipe_col_mux = PIPE_COL_OFS +
									(hActive - (pipe_x[i] - PIPE_W));

						pipe_hit = 1;
					end
				end
			end
		end
	end


	wire [11:0] pipe_color;
	pipe_rom u_pipe (.clk(clk),.row(pipe_row_mux),.col(pipe_col_mux),.color_data (pipe_color));

	reg [11:0] pipe_color_d;
	always @(posedge clk)
	    pipe_color_d <= pipe_color;

	// ---------------- rgb Rendering ----------------
	always @(*) begin
		if (!bright)
			rgb = 0;
		else if (bird_on_d && bird_color_d != 0)
			rgb = bird_color_d;
		else if (pipe_hit && pipe_color_d != 0)
			rgb = pipe_color_d;
		else if (bar_on_d)
			rgb = bar_color_d;
		else
			rgb = bg_color_d;
	end
endmodule
