module bird_physics_imp1 (Reset, Clk, div_clk, flap, pause, Ypos, velocity, Qini, Qflap, Qrise, Qfall);

input Reset, Clk;
input div_clk, flap, pause;
output Qini, Qflap, Qrise, Qfall;
output reg [11:0] Ypos, velocity;

reg [3:0] state;

localparam
INI   = 4'b0001,
FLAP  = 4'b0010,
RISE  = 4'b0100,
FALL  = 4'b1000,
UNKN  = 4'bxxxx;

localparam
YINIT      = 12'd200,
VINIT      = 12'd0,
JUMP_SPEED = 12'd6,
GRAVITY    = 12'd1;

assign {Qfall, Qrise, Qflap, Qini} = state;

always @(posedge Clk, posedge Reset)
begin
    if (Reset)
    begin
        Ypos     <= YINIT;
        velocity <= VINIT;
        state    <= INI;
    end
    else
    begin
        if (div_clk && !pause)
        begin
            case (state)

                INI:
                begin
                    // state transitions
                    if (flap)
                        state <= FLAP;
                    else
                        state <= INI;

                    // RTL
                    Ypos     <= YINIT;
                    velocity <= VINIT;
                end

                FLAP:
                begin
                    // state transitions
                    if (JUMP_SPEED > GRAVITY)
                        state <= RISE;
                    else
                        state <= FALL;

                    // RTL
                    Ypos <= Ypos + JUMP_SPEED;
                    velocity <= JUMP_SPEED;
                end

                RISE:
                begin
                    // state transitions
                    if (flap)
                        state <= FLAP;
                    else if (velocity > GRAVITY)
                        state <= RISE;
                    else
                        state <= FALL;

                    // RTL
                    if (flap)
                    begin
                        Ypos <= Ypos + JUMP_SPEED;
                        velocity <= JUMP_SPEED;
                    end
                    else if (velocity > GRAVITY)
                    begin
                        Ypos <= Ypos + velocity;
                        velocity <= velocity - GRAVITY;
                    end
                    else
                    begin
                        velocity <= 12'd0;
                    end
                end

                FALL:
                begin
                    // state transitions
                    if (flap)
                        state <= FLAP;
                    else
                        state <= FALL;

                    // RTL
                    if (flap)
                    begin
                        Ypos <= Ypos + JUMP_SPEED;
                        velocity <= JUMP_SPEED;
                    end
                    else
                    begin
                        Ypos <= Ypos - velocity;
                        velocity <= velocity + GRAVITY;
                    end
                end

                default:
                begin
                    state <= UNKN;
                end

            endcase
        end
    end
end
endmodule
