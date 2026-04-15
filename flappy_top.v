`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE354
// Engineer: Arda Caliskan
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name: 
// Module Name:    vga_top 
//
// Date: 11/11/2024
// Author: Arda Caliskan
// Description: Port from NEXYS4 to A7
//////////////////////////////////////////////////////////////////////////////////
module flappy_top(
	input  ClkPort,
	input  BtnC,
	input  BtnU,

	// VGA
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,

	//SSG signal
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,

	output QuadSpiFlashCS
);

	wire bright;
	wire [9:0] hc, vc;
	wire [9:0] bird_y;
	wire [15:0] score;
	wire [15:0] best_score;
	wire [6:0] ssdOut;
	wire [7:0] anode;
	wire [11:0] rgb;
    wire [9:0] pipe_x; 
	wire [9:0] pipe_gap_y;
    wire [7:0] scroll_x;

	display_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));
    game_engine ge(.clk(ClkPort), .button(BtnU), .bird_y(bird_y), .pipe_x(pipe_x), .pipe_gap_y(pipe_gap_y), .scroll_x(scroll_x), .best_score(best_score), .hCount(hc), .vCount(vc));
	vga_bitchange vbc(.clk(ClkPort), .bright(bright), .button(BtnU), .hCount(hc), .vCount(vc), .bird_y(bird_y), .pipe_x(pipe_x), .pipe_gap_y(pipe_gap_y), .scroll_x(scroll_x), .rgb(rgb), .score(score));
    counter cnt(.clk(ClkPort), .score(score), .best_score(best_score), .anode(anode), .ssdOut(ssdOut));

	assign vgaR = rgb[11:8];
	assign vgaG = rgb[7:4];
	assign vgaB = rgb[3:0];

	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = ssdOut[6:0];
	assign Dp = 1'b1;
	assign {An7, An6, An5, An4, An3, An2, An1, An0} = anode;

	assign QuadSpiFlashCS = 1'b1;

endmodule
