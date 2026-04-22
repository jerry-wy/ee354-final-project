module pipe (Clk, Reset, div_clk, pause, GapY);

  input Clk, Reset, div_clk, pause;
  output reg [9:0] GapY;

  integer i;

  // gap center values — valid range 108 to 371
  // (center ± 80 ± 28 must fit within active area 0-479)
  localparam
    GAP_INIT = 10'd240,
    GAP_0    = 10'd170,
    GAP_1    = 10'd200,
    GAP_2    = 10'd240,
    GAP_3    = 10'd280,
    GAP_4    = 10'd320,
    GAP_5    = 10'd350,
    GAP_6    = 10'd200,
    GAP_7    = 10'd280;

  always @(posedge Clk or posedge Reset)
    begin
      if (Reset)
        begin
          GapY <= GAP_INIT;
          i    <= 0;
        end

      else if (div_clk && !pause)
        begin
          case (i)
            0: GapY <= GAP_0;
            1: GapY <= GAP_1;
            2: GapY <= GAP_2;
            3: GapY <= GAP_3;
            4: GapY <= GAP_4;
            5: GapY <= GAP_5;
            6: GapY <= GAP_6;
            7: GapY <= GAP_7;
            default: GapY <= GAP_INIT;
          endcase

          if (i == 7)
            i <= 0;
          else
            i <= i + 1;
        end
    end

endmodule
