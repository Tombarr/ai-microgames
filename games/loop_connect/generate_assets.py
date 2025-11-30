#!/usr/bin/env python3
"""
Generate pipe sprites for Loop Connect microgame.
Creates 5 pipe types: straight, L-bend, T-junction, cross, and terminal.
"""

from PIL import Image, ImageDraw

# Configuration
SIZE = 32  # Canvas size (32x32px)
LINE_WIDTH = 8  # Pipe line width
COLOR_BLACK = (0, 0, 0, 255)  # Pure black, fully opaque
COLOR_TRANSPARENT = (0, 0, 0, 0)  # Transparent

JUNCTION_CIRCLE_RADIUS = 3  # 6px diameter = 3px radius
TERMINAL_CIRCLE_RADIUS = 8  # 16px diameter = 8px radius

CENTER = SIZE // 2  # 16px (center of 32x32 canvas)


def create_canvas():
    """Create a transparent canvas."""
    return Image.new('RGBA', (SIZE, SIZE), COLOR_TRANSPARENT)


def save_sprite(image, filename):
    """Save sprite to assets folder."""
    filepath = f"/Users/tbarrass/Documents/GitHub/ai-microgames/games/loop_connect/assets/{filename}"
    image.save(filepath, 'PNG')
    print(f"✓ Created {filename}")


# 1. STRAIGHT PIPE
# Horizontal black line, centered, rounded caps
def create_pipe_straight():
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    # Horizontal line from left edge to right edge
    # y-coordinate = CENTER (16), x from 0 to SIZE (32)
    draw.line(
        [(0, CENTER), (SIZE, CENTER)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    return img


# 2. L-BEND PIPE
# L-shaped connecting bottom-left to top-right
# This means: connections at SOUTH and EAST
def create_pipe_l_bend():
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    # Vertical line from center to bottom edge (SOUTH connection)
    draw.line(
        [(CENTER, CENTER), (CENTER, SIZE)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    # Horizontal line from center to right edge (EAST connection)
    draw.line(
        [(CENTER, CENTER), (SIZE, CENTER)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    # Add a small circle at the bend for smooth rounded join
    draw.ellipse(
        [CENTER - LINE_WIDTH//2, CENTER - LINE_WIDTH//2, 
         CENTER + LINE_WIDTH//2, CENTER + LINE_WIDTH//2],
        fill=COLOR_BLACK
    )
    
    return img


# 3. T-JUNCTION PIPE
# T-shaped with 3 directions: LEFT, TOP, RIGHT (missing SOUTH)
def create_pipe_t_junction():
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    # Horizontal line (LEFT to RIGHT)
    draw.line(
        [(0, CENTER), (SIZE, CENTER)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    # Vertical line from center to top edge (NORTH connection)
    draw.line(
        [(CENTER, 0), (CENTER, CENTER)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    # Filled circle at junction point
    draw.ellipse(
        [CENTER - JUNCTION_CIRCLE_RADIUS, CENTER - JUNCTION_CIRCLE_RADIUS,
         CENTER + JUNCTION_CIRCLE_RADIUS, CENTER + JUNCTION_CIRCLE_RADIUS],
        fill=COLOR_BLACK
    )
    
    return img


# 4. CROSS PIPE
# 4-way cross/plus sign with filled circle at center
def create_pipe_cross():
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    # Horizontal line (full width)
    draw.line(
        [(0, CENTER), (SIZE, CENTER)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    # Vertical line (full height)
    draw.line(
        [(CENTER, 0), (CENTER, SIZE)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    # Filled circle at center intersection
    draw.ellipse(
        [CENTER - JUNCTION_CIRCLE_RADIUS, CENTER - JUNCTION_CIRCLE_RADIUS,
         CENTER + JUNCTION_CIRCLE_RADIUS, CENTER + JUNCTION_CIRCLE_RADIUS],
        fill=COLOR_BLACK
    )
    
    return img


# 5. TERMINAL PIPE
# Filled circle (16px diameter) with single pipe stub extending to top edge
def create_pipe_terminal():
    img = create_canvas()
    draw = ImageDraw.Draw(img)
    
    # Pipe stub from center to top edge (NORTH connection)
    draw.line(
        [(CENTER, 0), (CENTER, CENTER)],
        fill=COLOR_BLACK,
        width=LINE_WIDTH,
        joint='curve'
    )
    
    # Large filled circle at center (16px diameter = 8px radius)
    draw.ellipse(
        [CENTER - TERMINAL_CIRCLE_RADIUS, CENTER - TERMINAL_CIRCLE_RADIUS,
         CENTER + TERMINAL_CIRCLE_RADIUS, CENTER + TERMINAL_CIRCLE_RADIUS],
        fill=COLOR_BLACK
    )
    
    return img


# Generate all sprites
if __name__ == "__main__":
    print("Generating Loop Connect pipe sprites...")
    print(f"Size: {SIZE}x{SIZE}px")
    print(f"Line width: {LINE_WIDTH}px")
    print(f"Color: Black (#000000)")
    print()
    
    save_sprite(create_pipe_straight(), "pipe_straight.png")
    save_sprite(create_pipe_l_bend(), "pipe_l_bend.png")
    save_sprite(create_pipe_t_junction(), "pipe_t_junction.png")
    save_sprite(create_pipe_cross(), "pipe_cross.png")
    save_sprite(create_pipe_terminal(), "pipe_terminal.png")
    
    print()
    print("✓ All pipe sprites generated successfully!")
    print("Location: games/loop_connect/assets/")
