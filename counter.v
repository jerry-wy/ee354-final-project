`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    13:08:25 12/01/2017
// Design Name:
// Module Name:    counterVerilog
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
//////////////////////////////////////////////////////////////////////////////////
// 8-digit SSD driver.
// Left  4 digits (An7-An4): current score
// Right 4 digits (An3-An0): best score
module counter(
	input clk,
	input  [15:0] score,
	input  [15:0] best_score,
	output reg [7:0] anode,
	output reg [6:0] ssdOut
    );

	reg [20:0] refresh;
	reg [3:0] LEDNumber;
	wire [2:0] LEDCounter;

	always @ (posedge clk)
		refresh <= refresh + 21'd1;

	assign LEDCounter = refresh[20:18];  // 3-bit: 8 digits

	always @ (*) begin
		case (LEDCounter)
		// --- left 4: current score (An7-An4) ---
		3'b000: begin anode = 8'b01111111; LEDNumber = score / 1000;               end
		3'b001: begin anode = 8'b10111111; LEDNumber = (score % 1000) / 100;       end
		3'b010: begin anode = 8'b11011111; LEDNumber = (score % 100) / 10;         end
		3'b011: begin anode = 8'b11101111; LEDNumber = score % 10;                 end
		// --- right 4: best score (An3-An0) ---
		3'b100: begin anode = 8'b11110111; LEDNumber = best_score / 1000;          end
		3'b101: begin anode = 8'b11111011; LEDNumber = (best_score % 1000) / 100;  end
		3'b110: begin anode = 8'b11111101; LEDNumber = (best_score % 100) / 10;    end
		3'b111: begin anode = 8'b11111110; LEDNumber = best_score % 10;            end
		endcase
	end

	always @ (*) begin
		case (LEDNumber)
		4'b0000: ssdOut = 7'b0000001;
		4'b0001: ssdOut = 7'b1001111;
		4'b0010: ssdOut = 7'b0010010;
		4'b0011: ssdOut = 7'b0000110;
		4'b0100: ssdOut = 7'b1001100;
		4'b0101: ssdOut = 7'b0100100;
		4'b0110: ssdOut = 7'b0100000;
		4'b0111: ssdOut = 7'b0001111;
		4'b1000: ssdOut = 7'b0000000;
		4'b1001: ssdOut = 7'b0000100;
		default: ssdOut = 7'b0000001;
		endcase
	end
endmodule
