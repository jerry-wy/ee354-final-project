// basic pipe generation for now

module pipe (Clk, Reset, div_clk, pause, GapY);

  input Clk, Reset, div_clk, pause;
  output reg [11:0] GapY;

  integer i;

  localparam
    GAP_INIT = 12'd210,
    GAP_0    = 12'd90,
    GAP_1    = 12'd130,
    GAP_2    = 12'd170,
    GAP_3    = 12'd210,
    GAP_4    = 12'd250,
    GAP_5    = 12'd290,
    GAP_6    = 12'd330,
    GAP_7    = 12'd370;

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
