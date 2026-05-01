module bird_physics (Reset, round_reset, Clk, div_clk, flap, pause, Ypos, velocity, Qini, Qflap, Qrise, Qfall);

input Reset, round_reset, Clk;
input div_clk, flap, pause;
output Qini, Qflap, Qrise, Qfall;
output [9:0] Ypos, velocity;

reg [3:0] state;
reg [10:0] rise_count;

reg [13:0] Ypos_fp;
reg [13:0] velocity_fp;

localparam
    INI  = 4'b0001,
    FLAP = 4'b0010,
    RISE = 4'b0100,
    FALL = 4'b1000;

localparam
    YINIT_FP = 14'd3200,
    VINIT_FP = 14'd0,

    JUMP_SPEED_FP = 14'd100,
    GRAVITY_FP = 14'd6,
    MAX_FALL_FP = 14'd160,

    FLOOR_Y_FP = 14'd6720,
    TOP_Y_FP = 14'd0,

    RISE_TICKS = 10'd20;

assign {Qfall, Qrise, Qflap, Qini} = state;

assign Ypos = Ypos_fp[13:4];
assign velocity = velocity_fp[13:4];

wire [13:0] fall_velocity_next;
wire [13:0] rise_velocity_next;

assign fall_velocity_next = ((velocity_fp + GRAVITY_FP) < MAX_FALL_FP) ? (velocity_fp + GRAVITY_FP) : MAX_FALL_FP;
assign rise_velocity_next = (velocity_fp > GRAVITY_FP) ? (velocity_fp - GRAVITY_FP) : 14'd0;

always @(posedge Clk or posedge Reset)
begin
    if (Reset || round_reset)
    begin
        Ypos_fp <= YINIT_FP;
        velocity_fp <= VINIT_FP;
        rise_count <= 0;
        state <= INI;
    end

    else if (div_clk && !pause)
    begin
        case (state)

            INI:
            begin
                Ypos_fp <= YINIT_FP;
                velocity_fp <= VINIT_FP;
                rise_count <= 0;

                if (flap)
                    state <= FLAP;
                else
                    state <= INI;
            end

            FLAP:
            begin
                state <= RISE;
                rise_count <= RISE_TICKS;

                if (Ypos_fp > JUMP_SPEED_FP)
                    Ypos_fp <= Ypos_fp - JUMP_SPEED_FP;
                else
                    Ypos_fp <= TOP_Y_FP;

                velocity_fp <= JUMP_SPEED_FP - GRAVITY_FP;
            end

            RISE:
            begin
                if (flap)
                begin
                    state <= FLAP;
                end

                else if ((rise_count > 0) && (velocity_fp > 0))
                begin
                    state <= RISE;

                    if (Ypos_fp > velocity_fp)
                        Ypos_fp <= Ypos_fp - velocity_fp;
                    else
                        Ypos_fp <= TOP_Y_FP;

                    velocity_fp <= rise_velocity_next;
                    rise_count <= rise_count - 1;
                end

                else
                begin
                    state <= FALL;
                    velocity_fp <= GRAVITY_FP;
                    rise_count <= 0;
                end
            end

            FALL:
            begin
                if (flap)
                begin
                    state <= FLAP;
                end

                else
                begin
                    state <= FALL;
                    if ((Ypos_fp + fall_velocity_next) < FLOOR_Y_FP)
                        Ypos_fp <= Ypos_fp + fall_velocity_next;
                    else
                        Ypos_fp <= FLOOR_Y_FP;

                    if (Ypos_fp < FLOOR_Y_FP)
                        velocity_fp <= fall_velocity_next;
                    else
                        velocity_fp <= VINIT_FP;
                end
            end

            default:
            begin
                state <= INI;
                Ypos_fp <= YINIT_FP;
                velocity_fp <= VINIT_FP;
                rise_count <= 0;
            end

        endcase
    end
end

endmodule
