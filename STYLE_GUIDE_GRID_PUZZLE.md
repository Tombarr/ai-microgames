# Style Guide: Grid-Based Puzzle Games

## Overview

This style guide captures the patterns from **box_pusher** (Sokoban-style puzzle game) for creating grid-based puzzle microgames.

**Best for**: Puzzles, turn-based strategy, tile-based movement, tactical games

**Reference Implementation**: [`games/box_pusher/main.gd`](games/box_pusher/main.gd)

---

## Visual Style

### Perspective & Layout
- **View**: Top-down 2D orthographic
- **Grid-based**: All elements snap to grid tiles
- **Tile Size**: 64x64 pixels (scales automatically to viewport)
- **Grid Dimensions**: 8x8 recommended (adjustable)

### Art Direction
- **Style**: Pixel art, industrial/sci-fi theme
- **Palette**: High contrast (neon accents on dark backgrounds)
- **Sprites**: Pre-loaded PNG textures
- **Examples**:
  - Player: Hazmat Bot, Robot, Character
  - Objects: Crates, Cores, Blocks
  - Targets: Marked zones with hazard stripes
  - Walls: Metal plating, pipes, barriers
  - Floor: Grated metal, concrete

### Color Scheme
```
Neon Green:    #00FF88  (Radioactive, Tech)
Dark Grey:     #2A2A2A  (Walls, Shadows)
Yellow:        #FFD700  (Hazard Stripes, Targets)
Cyan:          #00FFFF  (UI Highlights)
```

---

## Code Structure

### Asset Organization

```gdscript
# Preload textures at top of file
const TEX_PLAYER = preload("res://games/[game_name]/assets/player.png")
const TEX_BOX = preload("res://games/[game_name]/assets/box.png")
const TEX_TARGET = preload("res://games/[game_name]/assets/target.png")
const TEX_WALL = preload("res://games/[game_name]/assets/wall.png")
const TEX_FLOOR = preload("res://games/[game_name]/assets/floor.png")

# Preload sounds
const SFX_MOVE = preload("res://games/[game_name]/assets/sfx_move.wav")
const SFX_PUSH = preload("res://games/[game_name]/assets/sfx_push.wav")
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
```

### Grid Configuration

```gdscript
# Grid constants
const TILE_SIZE = 64
const GRID_W = 8
const GRID_H = 8

# Tile types
enum TileType { FLOOR, WALL, TARGET }

# Grid data structure
var grid = []  # 2D array [y][x] storing TileType
```

### Level Design Patterns

**Multiple Pre-made Levels**:
```gdscript
const PREMADE_LEVELS = [
    [
        "########",
        "#    ###",
        "# P B T#",
        "#      #",
        "#      #",
        "#  ##  #",
        "#      #",
        "########"
    ],
    [
        "########",
        "#   T###",
        "#   B ##",
        "#   P  #",
        "#      #",
        "##     #",
        "###    #",
        "########"
    ]
]
```

**Level Legend**:
- `#` = Wall
- `P` = Player spawn
- `B` = Box/Object
- `T` = Target/Goal
- ` ` = Empty floor

### Level Loading & Parsing

```gdscript
func _load_random_level():
    var rng = RandomNumberGenerator.new()
    rng.randomize()
    var layout_idx = rng.randi() % PREMADE_LEVELS.size()
    var layout = PREMADE_LEVELS[layout_idx]

    grid = []

    for y in range(GRID_H):
        var row_data = []
        var line = layout[y]
        for x in range(GRID_W):
            var line_char = line[x]
            var type = TileType.FLOOR

            if line_char == '#':
                type = TileType.WALL
            elif line_char == 'T':
                type = TileType.TARGET
                target_pos = Vector2i(x, y)
            elif line_char == 'B':
                box_pos = Vector2i(x, y)
            elif line_char == 'P':
                player_pos = Vector2i(x, y)

            row_data.append(type)
        grid.append(row_data)
```

### Rendering System

**Viewport Scaling** (auto-fits 640x640):
```gdscript
func _render_level():
    # Clear previous children
    for child in level_root.get_children():
        child.queue_free()

    # Calculate scale to fit viewport
    var viewport_size = get_viewport().get_visible_rect().size
    if viewport_size == Vector2.ZERO:
        viewport_size = Vector2(640, 640)

    var grid_px_w = GRID_W * TILE_SIZE
    var grid_px_h = GRID_H * TILE_SIZE

    var scale_x = viewport_size.x / float(grid_px_w)
    var scale_y = viewport_size.y / float(grid_px_h)
    var final_scale = min(scale_x, scale_y)

    # Apply scale to level container
    level_root.scale = Vector2(final_scale, final_scale)

    # Center level
    var scaled_size = Vector2(grid_px_w, grid_px_h) * final_scale
    level_root.position = (viewport_size - scaled_size) / 2.0

    # Render tiles...
```

**Tile Rendering**:
```gdscript
for y in range(GRID_H):
    for x in range(GRID_W):
        var pos = Vector2(x * TILE_SIZE + TILE_SIZE/2.0, y * TILE_SIZE + TILE_SIZE/2.0)
        var type = grid[y][x]

        # Floor background (always render)
        var floor_spr = Sprite2D.new()
        floor_spr.texture = TEX_FLOOR
        floor_spr.centered = true
        floor_spr.position = pos
        level_root.add_child(floor_spr)

        # Walls
        if type == TileType.WALL:
            var wall = Sprite2D.new()
            wall.texture = TEX_WALL
            wall.centered = true
            wall.position = pos
            level_root.add_child(wall)

        # Targets
        elif type == TileType.TARGET:
            var target = Sprite2D.new()
            target.texture = TEX_TARGET
            target.centered = true
            target.position = pos
            level_root.add_child(target)
```

**Dynamic Sprites** (player, movable objects):
```gdscript
# Create player sprite
player_sprite = Sprite2D.new()
player_sprite.texture = TEX_PLAYER
player_sprite.centered = true
player_sprite.z_index = 2  # Above other tiles
# Scale to fit tile
var player_scale = (TILE_SIZE / float(TEX_PLAYER.get_width())) * 0.9
player_sprite.scale = Vector2(player_scale, player_scale)
level_root.add_child(player_sprite)
_update_sprite_pos(player_sprite, player_pos)

# Helper to update sprite position
func _update_sprite_pos(sprite, grid_pos):
    sprite.position = Vector2(
        grid_pos.x * TILE_SIZE + TILE_SIZE/2.0,
        grid_pos.y * TILE_SIZE + TILE_SIZE/2.0
    )
```

---

## Input Handling

### Touch/Swipe Controls

```gdscript
# Touch state
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_active: bool = false
const SWIPE_THRESHOLD: float = 30.0

func _unhandled_input(event):
    if not game_active:
        return

    var dir = Vector2i.ZERO

    # Touch swipe gesture
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_active = true
            touch_start_pos = event.position
        else:
            if touch_active:
                touch_active = false
                var swipe_vector = event.position - touch_start_pos

                # Check if swipe is long enough
                if swipe_vector.length() >= SWIPE_THRESHOLD:
                    # Determine primary direction
                    if abs(swipe_vector.x) > abs(swipe_vector.y):
                        dir = Vector2i.RIGHT if swipe_vector.x > 0 else Vector2i.LEFT
                    else:
                        dir = Vector2i.DOWN if swipe_vector.y > 0 else Vector2i.UP

    # Mouse click (desktop testing)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var click_pos = event.position
        var player_screen_pos = level_root.position + (Vector2(player_pos) * TILE_SIZE + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)) * level_root.scale
        var to_click = click_pos - player_screen_pos

        # Determine direction based on click location
        if abs(to_click.x) > abs(to_click.y):
            dir = Vector2i.RIGHT if to_click.x > 0 else Vector2i.LEFT
        else:
            dir = Vector2i.DOWN if to_click.y > 0 else Vector2i.UP

    if dir != Vector2i.ZERO:
        _try_move(dir)
```

---

## Movement & Game Logic

### Grid-Based Movement

```gdscript
func _try_move(dir: Vector2i):
    var next_pos = player_pos + dir

    # Check wall collision
    if _is_wall(next_pos):
        return  # Blocked

    # Check if pushing object
    if next_pos == box_pos:
        var box_next = box_pos + dir
        if _is_wall(box_next):
            return  # Box blocked

        # Push box
        box_pos = box_next
        _update_sprite_pos(box_sprite, box_pos)
        player_pos = next_pos
        _update_sprite_pos(player_sprite, player_pos)
        sfx_push.play()

        # Check win condition
        if box_pos == target_pos:
            _win()
        else:
            _check_stuck()  # Deadlock detection
    else:
        # Just walking
        player_pos = next_pos
        _update_sprite_pos(player_sprite, player_pos)
        sfx_move.play()

func _is_wall(pos: Vector2i) -> bool:
    if pos.x < 0 or pos.x >= GRID_W or pos.y < 0 or pos.y >= GRID_H:
        return true
    return grid[pos.y][pos.x] == TileType.WALL
```

### Deadlock Detection (Optional)

```gdscript
func _check_stuck():
    # Detect if box is in corner (unwinnable)
    var blocked_h = _is_wall(box_pos + Vector2i.LEFT) or _is_wall(box_pos + Vector2i.RIGHT)
    var blocked_v = _is_wall(box_pos + Vector2i.UP) or _is_wall(box_pos + Vector2i.DOWN)

    if blocked_h and blocked_v:
        print("Box stuck in corner - Game Over")
        _fail()
```

---

## Win/Lose Conditions

```gdscript
func _win():
    if not game_active:
        return
    game_active = false
    sfx_win.play()
    add_score(1)  # Or points based on moves/time
    end_game()
    print("Puzzle Solved!")

func _fail():
    if not game_active:
        return
    game_active = false
    sfx_lose.play()
    end_game()
    print("Puzzle Failed!")
```

**No timeout tracking needed** - Puzzle games typically let player take their time, Director's timer handles game duration.

---

## Audio Integration

### Scene Setup (main.tscn)

```
Node2D (main.gd)
├── LevelRoot (Node2D) - Container for grid tiles
├── SFXMove (AudioStreamPlayer)
├── SFXPush (AudioStreamPlayer)
├── SFXWin (AudioStreamPlayer)
└── SFXLose (AudioStreamPlayer)
```

### Audio Assignment

```gdscript
@onready var sfx_move = $SFXMove
@onready var sfx_push = $SFXPush
@onready var sfx_win = $SFXWin
@onready var sfx_lose = $SFXLose

func _ready():
    instruction = "PUSH!"
    super._ready()

    # Assign audio streams
    sfx_move.stream = SFX_MOVE
    sfx_push.stream = SFX_PUSH
    sfx_win.stream = SFX_WIN
    sfx_lose.stream = SFX_LOSE

    _load_random_level()
    _render_level()
```

---

## Speed Multiplier (Not Applicable)

Grid-based puzzle games typically don't use speed multiplier since they're turn-based.

**Exception**: If adding timed pressure:
```gdscript
# Optional: Shrinking time limit
var time_per_move = 1.0 / speed_multiplier
```

---

## Asset Requirements

### Sprites (64x64 recommended)
- `player.png` - Main character (robot, person, etc.)
- `box.png` - Movable object
- `target.png` - Goal marker
- `wall.png` - Obstacle
- `floor.png` - Background tile

### Audio
- `sfx_move.wav` - Footstep/servo sound (~0.1s)
- `sfx_push.wav` - Heavy push sound (~0.3s)
- `sfx_win.wav` - Shared success sound
- `sfx_lose.wav` - Shared failure sound

### Optional
- `metadata.json` - SEO/marketing data
- `design.md` - Level design documentation
- `README.md` - Player-facing info

---

## Design Document Template

Create `design.md` with this structure:

```markdown
# Game Design Document: [Game Name]

## 1. Overview
**Title:** [Display Name]
**Internal Name:** [folder_name]
**Theme:** [Sci-Fi / Fantasy / Industrial]
**Duration:** 5-10 seconds
**Tagline:** [One sentence hook]

## 2. Objective
[What the player must do to win]

## 3. Controls
- **Touch/Mouse:** Swipe or click direction to move
- **Movement:** Grid-based, turn-based

## 4. Visual Style
- **Perspective:** Top-down 2D pixel art
- **Palette:** [Color scheme]
- **Vibe:** [Urgent, tactical, puzzle-focused]

## 5. Assets Required
### Sprites
- `player.png`: [Description]
- `box.png`: [Description]
- `target.png`: [Description]
- `wall.png`: [Description]
- `floor.png`: [Description]

### Audio
- `sfx_move.wav`: [Description]
- `sfx_push.wav`: [Description]

## 6. Level Design
**Grid Size:** 8x8
**Moves to Solve:** 5-10

**Layout:**
```
########
#    ###
# P B T#
#      #
########
```

**Legend:**
- `#`: Wall
- `T`: Target
- `B`: Box
- `P`: Player

**Solution:** [Step-by-step moves]
```

---

## Common Patterns

### Multi-Object Puzzles
```gdscript
var boxes: Array[Vector2i] = []  # Track multiple boxes
var targets: Array[Vector2i] = []

func _check_win() -> bool:
    # All boxes must be on targets
    for box in boxes:
        if box not in targets:
            return false
    return true
```

### Undo System (Optional)
```gdscript
var move_history: Array[Dictionary] = []

func _record_move(player_from, player_to, box_from, box_to):
    move_history.append({
        "player_from": player_from,
        "player_to": player_to,
        "box_from": box_from,
        "box_to": box_to
    })

func _undo_move():
    if move_history.is_empty():
        return
    var last_move = move_history.pop_back()
    player_pos = last_move.player_from
    box_pos = last_move.box_from
    _update_sprite_pos(player_sprite, player_pos)
    _update_sprite_pos(box_sprite, box_pos)
```

---

## Checklist

- [ ] Grid constants defined (TILE_SIZE, GRID_W, GRID_H)
- [ ] TileType enum for grid cells
- [ ] PREMADE_LEVELS array with ASCII layouts
- [ ] Level parsing function
- [ ] Viewport-scaled rendering
- [ ] Touch swipe input detection
- [ ] Grid-based movement with collision
- [ ] Win condition (object on target)
- [ ] Audio for move/push/win/lose
- [ ] Instruction set in _ready()
- [ ] Deadlock detection (optional)
- [ ] Multiple levels for variety

---

## Example Games Using This Style

- **box_pusher** - Sokoban-style puzzle (reference implementation)
- **minesweeper** - Grid-based reveal mechanic
- **geo_stacker** - Tetris-style grid placement

---

**Reference Implementation**: See [`games/box_pusher/main.gd`](games/box_pusher/main.gd) for complete working example.
