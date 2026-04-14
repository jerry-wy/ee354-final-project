# Converts an image to a Verilog Block RAM ROM (12-bit color: RRRRGGGGBBBB)
# Uses Pillow (PIL) instead of the removed scipy.misc.imread
#
# Usage:
#   generate("bird.png")                     -> full image, no masking
#   generate("bird.png", mask_x=0, mask_y=0) -> pixel (0,0) treated as transparent (outputs 0)
#
# Install dependency:  pip install Pillow

from PIL import Image
import math
import os

def get_color_bits(px):
    """Return 12-bit color string 'RRRRGGGGBBBB' for an RGB pixel tuple."""
    r = format(px[0], '08b')[0:4]
    g = format(px[1], '08b')[0:4]
    b = format(px[2], '08b')[0:4]
    return r + g + b

def rom_12_bit(name, im, mask_x=-1, mask_y=-1):
    """
    Write a Verilog ROM module inferred as Xilinx Block RAM.

    Parameters
    ----------
    name   : original image filename (used to derive module / output name)
    im     : PIL Image object (mode 'RGB')
    mask_x : column of the pixel whose color is treated as transparent (→ 000000000000)
    mask_y : row    of the pixel whose color is treated as transparent
    """
    pixels   = im.load()
    x_max, y_max = im.size          # PIL: width, height
    # use only the bare filename stem (no path separators) for the module name
    stem     = os.path.splitext(os.path.basename(name))[0]
    out_file = os.path.join(os.path.dirname(name), stem + "_12_bit_rom.v")

    row_width = max(1, math.ceil(math.log2(y_max)))
    col_width = max(1, math.ceil(math.log2(x_max)))
    addr_width = row_width + col_width

    # color to mask out (background / transparent color)
    mask_color = get_color_bits(pixels[mask_x, mask_y]) if (mask_x >= 0 and mask_y >= 0) else None

    with open(out_file, 'w') as f:
        # --- module header ---
        f.write(f"module {stem}_rom\n(\n")
        f.write(f"    input  wire clk,\n")
        f.write(f"    input  wire [{row_width-1}:0] row,\n")
        f.write(f"    input  wire [{col_width-1}:0] col,\n")
        f.write(f"    output reg  [11:0] color_data\n")
        f.write(f");\n\n")
        f.write(f"    (* rom_style = \"block\" *)\n\n")
        f.write(f"    reg [{row_width-1}:0] row_reg;\n")
        f.write(f"    reg [{col_width-1}:0] col_reg;\n\n")
        f.write(f"    always @(posedge clk) begin\n")
        f.write(f"        row_reg <= row;\n")
        f.write(f"        col_reg <= col;\n")
        f.write(f"    end\n\n")
        f.write(f"    always @* begin\n")
        f.write(f"        case ({{row_reg, col_reg}})\n")

        # --- pixel data ---
        for y in range(y_max):
            for x in range(x_max):
                px     = pixels[x, y]          # PIL: pixels[col, row]
                bits   = get_color_bits(px)
                addr   = format(y, 'b').zfill(row_width) + format(x, 'b').zfill(col_width)
                color  = "000000000000" if (mask_color and bits == mask_color) else bits
                f.write(f"            {addr_width}'b{addr}: color_data = 12'b{color};\n")

        # --- end of module ---
        f.write(f"            default: color_data = 12'b000000000000;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n\n")
        f.write(f"endmodule\n")

    print(f"Written: {out_file}  ({x_max}x{y_max} px, {addr_width}-bit address)")

def generate(filename, mask_x=-1, mask_y=-1, resize=None):
    """
    Convert an image file to a Verilog ROM.

    Parameters
    ----------
    filename : path to image (.png / .bmp / .jpg …)
    mask_x   : column of the background pixel to treat as transparent (-1 = no mask)
    mask_y   : row    of the background pixel to treat as transparent (-1 = no mask)
    resize   : (width, height) tuple to scale image before converting, e.g. (34, 24)
               Keep sprites small — each pixel costs 12 bits of BRAM.
               Nexys A7 has ~1.8 Mbit BRAM total.
    """
    im = Image.open(filename).convert('RGB')
    if resize:
        # NEAREST for sprites (preserves exact colors so mask works correctly at edges).
        # LANCZOS for backgrounds (no masking, smooth downscale looks better).
        interp = Image.NEAREST if (mask_x >= 0 and mask_y >= 0) else Image.LANCZOS
        im = im.resize(resize, interp)
    print(f"Loaded: {filename}  size={im.size[0]}x{im.size[1]}")
    rom_12_bit(filename, im, mask_x, mask_y)


# Bird sprite: resize to 34x24 (standard Flappy Bird proportions)
# Pixel (0,0) is the background color → output 0 (transparent)
# generate("figures/bird.png", mask_x=0, mask_y=0, resize=(34, 24))

# # Pipe cap texture: resize to 52x20 (matches PIPE_W=52)
# generate("figures/pipe.png", resize=(52, 20))

# Pipe cap texture: resize to 52x20 (matches PIPE_W=52)
generate("figures/bird.png", mask_x=0, mask_y=0, resize=(34, 24))
generate("figures/background.png", resize=(160, 120))
generate("figures/moving_bar.png", resize=(256, 30))