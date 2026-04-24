module pipe (
    input  wire        Clk,
    input  wire        Reset,
    input  wire        div_clk,  // one pulse per pipe-advance event
    input  wire        pause,
    output reg  [9:0]  pipe_gap_y
);

  // Gap center Y for each stage.
  // Valid range: PIPE_HALF_GAP (80) away from screen edge [0, 479].
  // Minimum: 0 + 80 = 80.  Maximum: 479 - 80 = 399.
  localparam [9:0]
    GAP_INIT = 10'd240,
    GAP_0    = 10'd170,
    GAP_1    = 10'd200,
    GAP_2    = 10'd240,
    GAP_3    = 10'd280,
    GAP_4    = 10'd320,
    GAP_5    = 10'd350,
    GAP_6    = 10'd200,
    GAP_7    = 10'd280;

  localparam N_GAPS = 3'd7; // last valid index (8 entries: 0-7)

  reg [2:0] idx;

  always @(posedge Clk or posedge Reset) begin
    if (Reset) begin
      pipe_gap_y <= GAP_INIT;
      idx        <= 3'd0;
    end else if (div_clk && !pause) begin
      case (idx)
        3'd0: pipe_gap_y <= GAP_0;
        3'd1: pipe_gap_y <= GAP_1;
        3'd2: pipe_gap_y <= GAP_2;
        3'd3: pipe_gap_y <= GAP_3;
        3'd4: pipe_gap_y <= GAP_4;
        3'd5: pipe_gap_y <= GAP_5;
        3'd6: pipe_gap_y <= GAP_6;
        3'd7: pipe_gap_y <= GAP_7;
      endcase
      idx <= (idx == N_GAPS) ? 3'd0 : idx + 3'd1;
    end
  end

endmodule
