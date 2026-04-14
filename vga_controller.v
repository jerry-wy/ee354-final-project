// VGA Controller — 640x480 @ 60 Hz
// Expects a 25 MHz pixel clock on `clk` (generated in flappy_top.v)

module vga_controller(
    input  wire clk,       // 25 MHz pixel clock
    input  wire rst,
    output reg  hsync,
    output reg  vsync,
    output wire video_on,  // high when pixel is in the visible area
    output wire [9:0] x,   // current pixel column (0–639 when video_on)
    output wire [9:0] y    // current pixel row    (0–479 when video_on)
);

    // ---------- Horizontal timing (pixels) ----------
    localparam H_VISIBLE     = 640;
    localparam H_FRONT_PORCH = 16;
    localparam H_SYNC        = 96;
    localparam H_BACK_PORCH  = 48;
    localparam H_TOTAL       = H_VISIBLE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH; // 800

    // ---------- Vertical timing (lines) ----------
    localparam V_VISIBLE     = 480;
    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC        = 2;
    localparam V_BACK_PORCH  = 33;
    localparam V_TOTAL       = V_VISIBLE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH; // 525

    // ---------- Counters ----------
    reg [9:0] h_count = 0;  // 0 – 799
    reg [9:0] v_count = 0;  // 0 – 524

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // ---------- Sync pulses (active-low) ----------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hsync <= 1;
            vsync <= 1;
        end else begin
            hsync <= ~(h_count >= H_VISIBLE + H_FRONT_PORCH &&
                       h_count <  H_VISIBLE + H_FRONT_PORCH + H_SYNC);
            vsync <= ~(v_count >= V_VISIBLE + V_FRONT_PORCH &&
                       v_count <  V_VISIBLE + V_FRONT_PORCH + V_SYNC);
        end
    end

    // ---------- Visible area and pixel coordinates ----------
    wire h_visible = (h_count < H_VISIBLE);
    wire v_visible = (v_count < V_VISIBLE);

    assign video_on = h_visible & v_visible;
    assign x = h_count;   // renderer checks video_on before using x/y
    assign y = v_count;

endmodule
