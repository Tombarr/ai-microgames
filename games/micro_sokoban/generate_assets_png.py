import zlib
import struct
import os

def write_png(filename, width, height, data):
    # data is a list of (r, g, b, a) tuples
    # We'll use 8-bit depth, truecolor with alpha (color type 6)
    
    # Signature
    png_sig = b'\x89PNG\r\n\x1a\n'
    
    # IHDR
    # Length (4 bytes), Type (4 bytes), Data, CRC (4 bytes)
    ihdr_data = struct.pack('!IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr_chunk = struct.pack('!I', len(ihdr_data)) + b'IHDR' + ihdr_data
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    ihdr_chunk += struct.pack('!I', ihdr_crc)
    
    # IDAT
    # Scanlines: each scanline starts with a filter byte (0 = None)
    # followed by RGBA bytes
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00' # Filter type 0
        for x in range(width):
            pixel = data[y * width + x]
            raw_data += struct.pack('BBBB', pixel[0], pixel[1], pixel[2], pixel[3])
            
    compressed_data = zlib.compress(raw_data)
    idat_chunk = struct.pack('!I', len(compressed_data)) + b'IDAT' + compressed_data
    idat_crc = zlib.crc32(b'IDAT' + compressed_data) & 0xffffffff
    idat_chunk += struct.pack('!I', idat_crc)
    
    # IEND
    iend_chunk = struct.pack('!I', 0) + b'IEND' + struct.pack('!I', zlib.crc32(b'IEND') & 0xffffffff)
    
    with open(filename, 'wb') as f:
        f.write(png_sig)
        f.write(ihdr_chunk)
        f.write(idat_chunk)
        f.write(iend_chunk)

# Palette
# Neon green, dark grey, industrial yellow
PALETTE = {
    ' ': (0, 0, 0, 0),       # Transparent
    '.': (30, 30, 30, 255),  # Floor bg (Very Dark Grey)
    'G': (60, 60, 60, 255),  # Metal Grey
    'D': (40, 40, 40, 255),  # Darker Metal
    'K': (10, 10, 10, 255),  # Black/Outline
    'Y': (255, 200, 0, 255), # Industrial Yellow
    'N': (57, 255, 20, 255), # Neon Green
    'W': (220, 220, 220, 255)# White/Highlight
}

def parse_sprite(ascii_art, scale=4):
    lines = [l.replace(' ', '') for l in ascii_art.strip().split('\n') if l]
    h = len(lines)
    w = len(lines[0])
    
    pixels = []
    # Create original grid
    grid = []
    for line in lines:
        row = []
        for char in line:
            row.append(PALETTE.get(char, (255, 0, 255, 255))) # Magenta for error
        grid.append(row)
        
    # Scale up
    scaled_pixels = []
    for y in range(h * scale):
        for x in range(w * scale):
            orig_x = x // scale
            orig_y = y // scale
            scaled_pixels.append(grid[orig_y][orig_x])
            
    return w * scale, h * scale, scaled_pixels

# Assets Definitions (16x16 designs to be scaled to 64x64)

# Floor: Grated metal
# . = dark background
# G = grid lines
floor_art = """
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
K K K K K K K K K K K K K K K K
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
K K K K K K K K K K K K K K K K
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
K K K K K K K K K K K K K K K K
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
D D D K D D D K D D D K D D D K
K K K K K K K K K K K K K K K K
"""

# Wall: Metal plate with yellow hazard top
wall_art = """
K Y Y K Y Y K Y Y K Y Y K Y Y K
Y Y K Y Y K Y Y K Y Y K Y Y K Y
K K K K K K K K K K K K K K K K
G G G G G G K K G G G G G G G G
G G G G G G K K G G G G G G G G
G G G G G G G G G G G G G G G G
G K G G G G G G G G G G G K G G
G K G G G G G G G G G G G K G G
G G G G G G G G G G G G G G G G
G G G G G G G G G G G G G G G G
G G G G G G G G G G G G G G G G
G G G G G G G G G G G G G G G G
G K G G G G G G G G G G G K G G
G K G G G G G G G G G G G K G G
G G G G G G G G G G G G G G G G
K K K K K K K K K K K K K K K K
"""

# Target: Containment zone (dashed green outline on floor)
target_art = """
N N N N N N N N N N N N N N N N
N . . . . . . . . . . . . . . N
N . . . . . . . . . . . . . . N
N . . N N . . . . . . N N . . N
N . . N N . . . . . . N N . . N
N . . . . . . . . . . . . . . N
N . . . . . . . . . . . . . . N
N . . . . . . . . . . . . . . N
N . . . . . . . . . . . . . . N
N . . . . . . . . . . . . . . N
N . . . . . . . . . . . . . . N
N . . N N . . . . . . N N . . N
N . . N N . . . . . . N N . . N
N . . . . . . . . . . . . . . N
N . . . . . . . . . . . . . . N
N N N N N N N N N N N N N N N N
"""

# Box: Radioactive Core
# G = Frame, N = Glowing Core
box_art = """
K K K K K K K K K K K K K K K K
K G G G G G G G G G G G G G G K
K G N N N N N N N N N N N N G K
K G N W N N N N N N N N N N G K
K G N N N N K K K K N N N N G K
K G N N N K N N N N K N N N G K
K G N N N K N N N N K N N N G K
K G N N N K N N N N K N N N G K
K G N N N N K K K K N N N N G K
K G N N N K N N N N K N N N G K
K G N N N K N N N N K N N N G K
K G N N N K N N N N K N N N G K
K G N N N N K K K K N N N N G K
K G N N N N N N N N N N N N G K
K G G G G G G G G G G G G G G K
K K K K K K K K K K K K K K K K
"""

# Player: Hazmat Bot
# Y = Suit, B/K = Tracks/Visor
player_art = """
. . . . . K K K K K K . . . . .
. . . . K Y Y Y Y Y Y K . . . .
. . . . K Y Y Y Y Y Y K . . . .
. . . . K K K K K K K K . . . .
. . . . K N N N N N N K . . . .
. . . . K N N W W N N K . . . .
. . . . K K K K K K K K . . . .
. . K K K Y Y Y Y Y Y K K K . .
. . K Y Y Y Y Y Y Y Y Y Y K . .
. . K Y Y Y K K K K Y Y Y K . .
. . K Y Y Y K Y Y K Y Y Y K . .
. . K Y Y Y K Y Y K Y Y Y K . .
. . K K K K K Y Y K K K K K . .
. . K D D K K K K K K D D K . .
. . K D D K . . . . K D D K . .
. . K K K K . . . . K K K K . .
"""

assets = {
    'floor.png': floor_art,
    'wall.png': wall_art,
    'target.png': target_art,
    'box.png': box_art,
    'player.png': player_art
}

output_dir = "games/micro_sokoban/assets"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

for filename, art in assets.items():
    w, h, pixels = parse_sprite(art, scale=4) # 16x16 -> 64x64
    filepath = os.path.join(output_dir, filename)
    write_png(filepath, w, h, pixels)
    print(f"Generated {filepath}")
