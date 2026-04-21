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

def rom_12_bit_rgba(name, im, get_color):
    import math, os

    pixels = im.load()
    x_max, y_max = im.size

    stem     = os.path.splitext(os.path.basename(name))[0]
    out_file = os.path.join(os.path.dirname(name), stem + "_12_bit_rom.v")

    row_width = max(1, math.ceil(math.log2(y_max)))
    col_width = max(1, math.ceil(math.log2(x_max)))
    addr_width = row_width + col_width

    with open(out_file, 'w') as f:
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

        for y in range(y_max):
            for x in range(x_max):
                px = pixels[x, y]
                color = get_color(px)

                addr = format(y, 'b').zfill(row_width) + format(x, 'b').zfill(col_width)
                f.write(f"            {addr_width}'b{addr}: color_data = 12'b{color};\n")

        f.write(f"            default: color_data = 12'b000000000000;\n")
        f.write(f"        endcase\n")
        f.write(f"    end\n\nendmodule\n")

    print(f"Written: {out_file}")

def generate(filename, resize=None):
    im = Image.open(filename).convert('RGBA') 

    if resize:
        interp = Image.NEAREST
        im = im.resize(resize, interp)

    print(f"Loaded: {filename}  size={im.size[0]}x{im.size[1]}")

    pixels = im.load()
    x_max, y_max = im.size

    def get_color(px):
        # px = (R, G, B, A)
        if px[3] < 128: 
            return "000000000000"
        else:
            r = format(px[0], '08b')[0:4]
            g = format(px[1], '08b')[0:4]
            b = format(px[2], '08b')[0:4]
            return r + g + b

    rom_12_bit_rgba(filename, im, get_color)


# Bird sprite: resize to 34x24 (standard Flappy Bird proportions)
# Pixel (0,0) is the background color → output 0 (transparent)
# generate("figures/bird.png", mask_x=0, mask_y=0, resize=(34, 24))

# # Pipe cap texture: resize to 52x20 (matches PIPE_W=52)
# generate("figures/pipe.png", resize=(52, 20))

# Pipe cap texture: resize to 52x20 (matches PIPE_W=52)
# generate("figures/bird.png", resize=(43, 30))
# generate("figures/background.png", resize=(160, 120))
# generate("figures/moving_bar.png", resize=(256, 30))
generate("figures/pipe.png", resize=(78, 36))