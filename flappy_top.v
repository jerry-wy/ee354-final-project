module flappy_top(
    input  wire clk,     // 100 MHz
    input  wire rst,
    output wire hsync,
    output wire vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);

    wire pixel_clk;
    wire video_on;
    wire [9:0] x, y;
    wire [11:0] rgb;

    // -------------------------
    // Clock divider (100MHz → 25MHz)
    // -------------------------
    reg [1:0] clk_div = 0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    assign pixel_clk = clk_div[1];

    // -------------------------
    // VGA controller
    // -------------------------
    vga_controller vga_inst (
        .clk(pixel_clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .x(x),
        .y(y)
    );

    // -------------------------
    // Renderer
    // -------------------------
    renderer renderer_inst (
        .video_on(video_on),
        .x(x),
        .y(y),
        .rgb(rgb)
    );

    // -------------------------
    // Output to VGA
    // -------------------------
    assign vga_r = rgb[11:8];
    assign vga_g = rgb[7:4];
    assign vga_b = rgb[3:0];

endmodule