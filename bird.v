module bird_physics (Reset, Clk, div_clk, flap, pause, Ypos, velocity, Qini, Qflap, Qrise, Qfall);

input Reset, Clk;
input div_clk, flap, pause;
output Qini, Qflap, Qrise, Qfall;
output reg [9:0] Ypos, velocity;

reg [3:0] state;

localparam
    INI  = 4'b0001,
    FLAP = 4'b0010,
    RISE = 4'b0100,
    FALL = 4'b1000;

localparam
    YINIT = 10'd200,
    VINIT = 10'd0,
    JUMP_SPEED = 10'd10,
    GRAVITY = 10'd1,
    MAX_FALL = 10'd8;

assign {Qfall, Qrise, Qflap, Qini} = state;

always @(posedge Clk or posedge Reset)
begin
    if (Reset)
    begin
        Ypos <= YINIT;
        velocity <= VINIT;
        state <= INI;
    end
    else if (div_clk && !pause)
    begin
        case (state)

            INI:
            begin
                if (flap)
                    state <= FLAP;
                else
                    state <= INI;

                Ypos <= YINIT;
                velocity <= GRAVITY;
            end

            FLAP:
            begin
                state <= RISE;

                if (Ypos > JUMP_SPEED)
                    Ypos <= Ypos - JUMP_SPEED;
                else
                    Ypos <= 10'd0;
                velocity <= JUMP_SPEED;
            end

            RISE:
            begin
                if (flap)
                    state <= FLAP;
                else if (velocity > GRAVITY)
                    state <= RISE;
                else
                    state <= FALL;

                if (velocity > GRAVITY && !flap)
                begin
                    if (Ypos > velocity)
                        Ypos <= Ypos - velocity;
                    else
                        Ypos <= 10'd0;
                    velocity <= velocity - GRAVITY;
                end
                else if (velocity <= GRAVITY && !flap)
                begin
                    if (Ypos > velocity)
                        Ypos <= Ypos - velocity;
                    else
                        Ypos <= 10'd0;
                    velocity <= GRAVITY;
                end
            end

            FALL:
            begin
                if (flap)
                    state <= FLAP;
                else
                    state <= FALL;

                if (!flap)
                begin
                    Ypos <= Ypos + velocity;
                    if (velocity < MAX_FALL)
                        velocity <= velocity + GRAVITY;
                    else
                        velocity <= MAX_FALL;
                end
            end

            default:
            begin
                state <= INI;
                Ypos <= YINIT;
                velocity <= VINIT;
            end
        endcase
    end
end

endmodule
