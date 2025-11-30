# Loop Connect - Game Design Document

## Game Title

**Loop Connect**

_Alternative titles considered: Circuit Snap, Pipe Zen, Quick Loop, Flow Fix_

## Overview

A minimalist 4x4 grid puzzle where players rotate pipe segments to complete closed loops within 5
seconds. Inspired by Loops of Zen, this microgame distills the meditative satisfaction of connection
puzzles into a rapid-fire challenge.

## Core Objective

**WIN CONDITION**: All pipe segments must form complete, closed loops with zero dead ends or
disconnected segments.

**LOSE CONDITION**: 5-second timer expires before all loops are completed.

## Game Mechanics

### Grid System

- 4x4 grid (16 tiles total)
- Each tile contains one pipe segment
- Tiles can be rotated in 90° increments (4 possible orientations)
- Fixed grid layout - no tile movement, only rotation

### Pipe Types (5 Types)

1. **Straight Pipe** (`═` or `║`)
   - 2 connection points (opposite sides)
   - Orientations: horizontal or vertical

2. **L-Bend Pipe** (`╚` `╔` `╗` `╝`)
   - 2 connection points (adjacent sides)
   - 4 possible orientations (corners)

3. **T-Junction Pipe** (`╩` `╠` `╦` `╣`)
   - 3 connection points
   - 4 possible orientations

4. **Cross Pipe** (`╬`)
   - 4 connection points (all sides)
   - Rotation has no visual effect (symmetrical)

5. **Terminal Circle** (`●` with pipe stub)
   - 1 connection point (loop endpoint/starting point)
   - 4 possible orientations
   - **Note**: In a valid solution, terminals should connect to form closed loops

### Connection Rules

- Two adjacent pipes connect if both have openings facing each other
- A completed loop has all segments connected with no open ends
- Multiple separate loops are allowed (and encouraged for 4x4 grid)
- All pipes must be part of a completed loop (no isolated segments)

### Speed Multiplier Integration

Since this is a turn-based puzzle:

- **Visual feedback speed** scales with `speed_multiplier` (rotation animation, highlight pulse)
- **Timer countdown visual** could pulse faster at higher speeds
- Core gameplay remains unchanged (rotation is instant, puzzle difficulty is fixed)

## Control Scheme

### Mouse/Touch Controls (Primary)

- **Click/Tap tile**: Rotate that tile 90° clockwise
- **Visual feedback**: Tile flashes or animates rotation

### Keyboard Controls (Secondary)

- **Arrow Keys / WASD**: Move selection highlight (yellow border)
- **Enter / Space**: Rotate currently selected tile 90° clockwise
- **Initial state**: Center tile (position 1,1) selected by default

### Input Mapping

```
action_rotate: Mouse Button 1, Enter, Space
action_up: Up Arrow, W
action_down: Down Arrow, S
action_left: Left Arrow, A
action_right: Right Arrow, D
```

## Preset Puzzle Configurations

Each puzzle is designed to be solvable with **1-2 rotations** at 1x speed, scaling to near-instant
reflexes at 5x speed.

### Puzzle Notation

- Grid positions: `[row][col]` where `0,0` is top-left
- Pipe orientation: `N/E/S/W` = connection directions (North/East/South/West)
- `rotation_needed`: Number of 90° clockwise rotations from starting state

---

### Puzzle 1: "The Simple Gap"

**Difficulty**: Easy (1 rotation)  
**Pattern**: Single large loop with one break

```
Starting Grid (0 = North-up orientation):
┌─────┬─────┬─────┬─────┐
│ ╔═══╪═════╪═════╪═══╗ │
│ ║   │     │     │   ║ │
├─────┼─────┼─────┼─────┤
│ ║   │     │ ╔═══╪═══╝ │
│ ║   │     │ ║   │     │
├─────┼─────┼─────┼─────┤
│ ║   │ ╔═══╪═╝   │     │
│ ║   │ ║   │     │     │
├─────┼─────┼─────┼─────┤
│ ╚═══╪═╝   │     │     │
│     │     │     │     │
└─────┴─────┴─────┴─────┘

Grid Configuration:
[0,0]: L-bend (S,E) ✓
[0,1]: Straight (E,W) ✓
[0,2]: Straight (E,W) ✓
[0,3]: L-bend (S,W) ✓

[1,0]: Straight (N,S) ✓
[1,1]: Straight (E,W) ✗ NEEDS ROTATION → Change to (N,S)
[1,2]: L-bend (S,W) ✓
[1,3]: Straight (N,S) ✓

[2,0]: Straight (N,S) ✓
[2,1]: L-bend (S,E) ✓
[2,2]: L-bend (N,W) ✓
[2,3]: Straight (E,W) ✓

[3,0]: L-bend (N,E) ✓
[3,1]: L-bend (N,W) ✓
[3,2]: Straight (E,W) ✓
[3,3]: Straight (E,W) ✓

Solution: Rotate [1,1] once (horizontal → vertical)
```

---

### Puzzle 2: "Double Loop"

**Difficulty**: Easy (1 rotation)  
**Pattern**: Two separate loops sharing no edges

```
Starting Grid:
┌─────┬─────┬─────┬─────┐
│ ╔═══╪═══╗ │ ╔═══╪═══╗ │
│ ║   │   ║ │ ║   │   ║ │
├─────┼─────┼─────┼─────┤
│ ╚═══╪═══╝ │ ╚═══╪═══╝ │
│     │     │     │   X │ ← Wrong orientation
├─────┼─────┼─────┼─────┤
│     │     │     │     │
│     │     │     │     │
├─────┼─────┼─────┼─────┤
│     │     │     │     │
│     │     │     │     │
└─────┴─────┴─────┴─────┘

Grid Configuration:
[0,0]: L-bend (S,E)
[0,1]: L-bend (S,W)
[0,2]: L-bend (S,E)
[0,3]: L-bend (S,W)

[1,0]: L-bend (N,E)
[1,1]: L-bend (N,W)
[1,2]: L-bend (N,E)
[1,3]: L-bend (E,W) ✗ NEEDS ROTATION → Change to (N,W)

[2,0]: Straight (E,W)
[2,1]: Straight (E,W)
[2,2]: Straight (E,W)
[2,3]: Straight (E,W)

[3,0]: Straight (E,W)
[3,1]: Straight (E,W)
[3,2]: Straight (E,W)
[3,3]: Straight (E,W)

Solution: Rotate [1,3] once to complete top-right loop
```

---

### Puzzle 3: "T-Junction Twist"

**Difficulty**: Medium (2 rotations)  
**Pattern**: Loop with T-junction creating internal complexity

```
Starting Grid:
┌─────┬─────┬─────┬─────┐
│ ╔═══╪═════╪═════╪═══╗ │
│ ║   │     │     │   ║ │
├─────┼─────┼─────┼─────┤
│ ╠═══╪═══╗ │ ╔═══╪═══╣ │
│ ║   │   ║ │ ║   │   ║ │
├─────┼─────┼─────┼─────┤
│ ╚═══╪═══╝ │ ╚═══╪═══╝ │
│     │     │ X   │     │
├─────┼─────┼─────┼─────┤
│     │     │ X   │     │
│     │     │     │     │
└─────┴─────┴─────┴─────┘

Grid Configuration:
[0,0]: L-bend (S,E)
[0,1]: Straight (E,W)
[0,2]: Straight (E,W)
[0,3]: L-bend (S,W)

[1,0]: T-junction (N,E,S) - Left T
[1,1]: L-bend (S,W)
[1,2]: L-bend (S,E)
[1,3]: T-junction (N,W,S) - Right T

[2,0]: L-bend (N,E)
[2,1]: L-bend (N,W)
[2,2]: Straight (E,W) ✗ NEEDS ROTATION → to (N,S)
[2,3]: L-bend (N,W)

[3,0]: Straight (E,W)
[3,1]: Straight (E,W)
[3,2]: L-bend (E,W) ✗ NEEDS ROTATION → to (N,E)
[3,3]: Straight (E,W)

Solution:
1. Rotate [2,2] once (horizontal → vertical)
2. Rotate [3,2] twice (to create bottom-right corner)
```

---

### Puzzle 4: "Cross Roads"

**Difficulty**: Medium (2 rotations)  
**Pattern**: Uses 4-way junction in center

```
Starting Grid:
┌─────┬─────┬─────┬─────┐
│     │ ╔═══╪═══╗ │     │
│     │ ║   │   ║ │     │
├─────┼─────┼─────┼─────┤
│ ╔═══╪═╬═══╪═══╬═══╗   │
│ ║   │ ║   │   ║   ║   │
├─────┼─────┼─────┼─────┤
│ ╚═══╪═╬═══╪═══╬═══╝   │
│     │ ║ X │ X ║   │   │
├─────┼─────┼─────┼─────┤
│     │ ╚═══╪═══╝ │     │
│     │     │     │     │
└─────┴─────┴─────┴─────┘

Grid Configuration:
[0,0]: Straight (E,W)
[0,1]: L-bend (S,E)
[0,2]: L-bend (S,W)
[0,3]: Straight (E,W)

[1,0]: L-bend (S,E)
[1,1]: Cross (N,E,S,W)
[1,2]: Cross (N,E,S,W)
[1,3]: L-bend (S,W)

[2,0]: L-bend (N,E)
[2,1]: Cross (N,E,S,W)
[2,2]: Cross (N,E,S,W)
[2,3]: L-bend (N,W)

[3,0]: Straight (E,W)
[3,1]: L-bend (N,E) ✗ NEEDS ROTATION → to Straight (E,W)
[3,2]: L-bend (N,W) ✗ NEEDS ROTATION → to Straight (E,W)
[3,3]: Straight (E,W)

Solution:
1. Rotate [3,1] three times (corner → horizontal straight)
2. Rotate [3,2] once (corner → horizontal straight)
```

---

### Puzzle 5: "Snake Path"

**Difficulty**: Hard (2 rotations, requires spatial reasoning)  
**Pattern**: Winding single loop that fills the grid

```
Starting Grid:
┌─────┬─────┬─────┬─────┐
│ ╔═══╪═════╪═════╪═══╗ │
│ ║   │     │     │   ║ │
├─────┼─────┼─────┼─────┤
│ ║   │ ╔═══╪═══╗ │   ║ │
│ ║   │ ║   │ X ║ │   ║ │
├─────┼─────┼─────┼─────┤
│ ║   │ ╚═══╪═╗ ║ │   ║ │
│ ║   │     │ ║ ║ │   ║ │
├─────┼─────┼─────┼─────┤
│ ╚═══╪═════╪═╝ ╚═══╩═╝ │
│     │     │ X │     │ │
└─────┴─────┴─────┴─────┘

Grid Configuration:
[0,0]: L-bend (S,E)
[0,1]: Straight (E,W)
[0,2]: Straight (E,W)
[0,3]: L-bend (S,W)

[1,0]: Straight (N,S)
[1,1]: L-bend (S,E)
[1,2]: L-bend (S,W)
[1,3]: Straight (N,S)

[2,0]: Straight (N,S)
[2,1]: L-bend (N,E)
[2,2]: Straight (N,S) ✗ NEEDS ROTATION → to L-bend (S,E)
[2,3]: Straight (N,S)

[3,0]: L-bend (N,E)
[3,1]: Straight (E,W)
[3,2]: L-bend (N,W) ✗ NEEDS ROTATION → to L-bend (N,E)
[3,3]: L-bend (N,W)

Solution:
1. Rotate [2,2] once (vertical straight → bottom-left corner)
2. Rotate [3,2] twice (top-right corner → bottom-left corner)
```

---

## Visual Style

### Color Palette

- **Background**: Pure white (`#FFFFFF`)
- **Pipes**: Pure black (`#000000`, 8px line width)
- **Grid lines**: Light gray (`#E0E0E0`, 1px)
- **Selection highlight**: Yellow border (`#FFD700`, 3px, subtle glow)
- **Solved flash**: Bright green (`#00FF00`, brief flash on all tiles)
- **Timer bar**: Gradient from green → yellow → red

### Pipe Rendering

- **Line style**: Rounded caps and joins
- **Terminal circles**: Filled black circle (radius: 8px) with pipe stub extending outward
- **Junction nodes**: Small filled circles at intersections for T and Cross types

### Animation

- **Rotation**: 0.1 second smooth rotation (scales with speed_multiplier)
- **Tile hover**: Subtle scale pulse (1.0 → 1.05)
- **Win state**: All tiles flash green, then zoom transition
- **Connection validation**: Brief highlight pulse on connected segments (optional visual feedback)

### UI Layout

```
┌─────────────────────────────────┐
│  [Timer: ████░░░░ 2.3s]         │ ← Top-center
│                                  │
│      ┌──────────────┐            │
│      │  CONNECT!    │            │ ← Instruction (1s, then fade)
│      └──────────────┘            │
│                                  │
│      ┌───┬───┬───┬───┐          │
│      │   │   │   │   │          │
│      ├───┼───┼───┼───┤          │
│      │   │ ▓ │   │   │          │ ← 4x4 grid (centered)
│      ├───┼───┼───┼───┤          │   ▓ = selected tile
│      │   │   │   │   │          │
│      ├───┼───┼───┼───┤          │
│      │   │   │   │   │          │
│      └───┴───┴───┴───┘          │
│                                  │
└─────────────────────────────────┘
```

## Asset List

### Sprites Required

1. **pipe_straight.png** (32x32px)
   - Black horizontal line, centered
   - Will be rotated programmatically for vertical orientation

2. **pipe_l_bend.png** (32x32px)
   - L-shaped pipe (bottom-left to top-right corner)
   - Will be rotated for all 4 corner variations

3. **pipe_t_junction.png** (32x32px)
   - T-shaped pipe (3 directions, missing bottom)
   - Small filled circle at junction point
   - Will be rotated for all 4 orientations

4. **pipe_cross.png** (32x32px)
   - 4-way cross/plus sign
   - Filled circle at center intersection
   - Rotation-invariant (symmetrical)

5. **pipe_terminal.png** (32x32px)
   - Filled circle with single pipe stub extending to one edge
   - Will be rotated for all 4 directions

6. **tile_bg.png** (32x32px) [Optional]
   - White square with subtle border
   - Used as tile background

7. **highlight_border.png** (32x32px)
   - Yellow/gold border overlay
   - Transparent center

### UI Elements

8. **grid_line.png** (1px texture)
   - Light gray, tiled for grid rendering

### Sound Effects

9. **sfx_rotate.wav**
   - Soft mechanical "click" or "snap" sound
   - Plays on each tile rotation
   - ~0.1-0.2s duration

10. **sfx_win.wav**
    - Satisfying "completion" chime
    - Bright, ascending tone
    - ~0.5s duration

11. **sfx_lose.wav**
    - Gentle "incomplete" buzz or descending tone
    - Not harsh (matches Zen theme)
    - ~0.3s duration

12. **sfx_select.wav** [Optional]
    - Subtle beep when moving keyboard selection
    - ~0.05s duration

### Font

- Use Godot default font (or include minimalist sans-serif)
- Instruction text: 48pt, bold, white with black outline

## Technical Implementation Notes

### Connection Validation Algorithm

```gdscript
# Pseudo-code for loop validation
func is_puzzle_solved() -> bool:
    # 1. Build adjacency graph of all tiles
    # 2. For each tile, check if connections match neighbors
    # 3. Ensure no tile has unconnected openings (dead ends)
    # 4. Verify all tiles are reachable (no isolated segments)
    # 5. Check that all paths form closed loops (DFS/BFS)

    for each tile in grid:
        for each direction in tile.connections:
            neighbor = get_neighbor(tile, direction)
            if not neighbor.connects_back(opposite(direction)):
                return false  # Mismatch or dead end

    # All tiles connected properly = solved
    return true
```

### Pipe Rotation System

```gdscript
# Each pipe type stores connections as array of Direction enums
enum Direction { NORTH, EAST, SOUTH, WEST }

class Pipe:
    var connections: Array[Direction]
    var rotation: int = 0  # 0-3 (0° to 270°)

    func rotate_clockwise():
        rotation = (rotation + 1) % 4
        # Rotate connection directions
        for i in connections.size():
            connections[i] = (connections[i] + 1) % 4

    func get_sprite_rotation() -> float:
        return rotation * 90.0
```

### Puzzle Selection

```gdscript
# In main.gd _ready()
var puzzles: Array[PuzzleConfig] = [puzzle1, puzzle2, puzzle3, puzzle4, puzzle5]
var selected_puzzle: PuzzleConfig = puzzles.pick_random()
load_puzzle(selected_puzzle)
```

### Speed Multiplier Application

```gdscript
# Rotation animation speed
var rotation_tween = create_tween()
rotation_tween.set_speed_scale(speed_multiplier)  # 1x-5x faster
rotation_tween.tween_property(tile, "rotation_degrees", target, 0.1)
```

## Win/Lose Conditions Summary

| Condition                          | Score            | Action                                          |
| ---------------------------------- | ---------------- | ----------------------------------------------- |
| All loops completed before timeout | `add_score(100)` | Call `end_game()` immediately, show green flash |
| Timer reaches 5.0 seconds          | Score remains 0  | Call `end_game()`, show incomplete grid         |
| Invalid state                      | Not possible     | Puzzle starts in valid (near-complete) state    |

**Binary Outcome**: Score > 0 = WIN (loops complete), Score = 0 = LOSE (timeout)

## Difficulty Scaling with Speed Multiplier

| Speed | Effective Time to Solve | Player Challenge             |
| ----- | ----------------------- | ---------------------------- |
| 1x    | 5.0 seconds             | Casual - learn the pattern   |
| 2x    | 2.5 seconds             | Moderate - quick recognition |
| 3x    | 1.67 seconds            | Hard - muscle memory         |
| 4x    | 1.25 seconds            | Expert - instant reaction    |
| 5x    | 1.0 seconds             | Master - pure reflex         |

Since puzzles require 1-2 rotations, players need to:

- Instantly recognize the error(s)
- Navigate/click the correct tile(s)
- Execute rotation(s)

At 5x speed, this becomes a pure pattern recognition + reflex challenge.

## Development Phases

### Phase 1: Core Grid System

- [ ] Create 4x4 grid layout (640x640 canvas)
- [ ] Implement Pipe class with 5 types
- [ ] Add rotation logic (click/keyboard input)
- [ ] Render pipes with rotation

### Phase 2: Puzzle System

- [ ] Define PuzzleConfig data structure
- [ ] Implement all 5 preset puzzles
- [ ] Add puzzle loading/initialization
- [ ] Create connection validation algorithm

### Phase 3: Game Loop Integration

- [ ] Extend Microgame base class
- [ ] Implement 5-second timer
- [ ] Add win/lose detection
- [ ] Integrate with Director score system

### Phase 4: Polish

- [ ] Generate/import all sprite assets
- [ ] Add rotation animation with speed scaling
- [ ] Implement selection highlight
- [ ] Add sound effects
- [ ] Create win state visual feedback (green flash)

### Phase 5: Testing

- [ ] Verify all 5 puzzles are solvable
- [ ] Test at all speed multipliers (1x-5x)
- [ ] Confirm keyboard and mouse controls work
- [ ] Validate with Director system

## Estimated Complexity

**Implementation Time**: ~4-6 hours for experienced Godot developer

**Key Challenges**:

1. Connection validation logic (graph traversal)
2. Ensuring puzzles are balanced for 1-2 rotations
3. Clean rotation animation that scales with speed
4. Accurate collision detection for 4x4 grid clicks

**Low Risk Elements**:

- Grid rendering (straightforward)
- Input handling (standard Godot patterns)
- Asset creation (simple geometric shapes)
- Microgame integration (well-documented API)

---

## Credits & Inspiration

- **Loops of Zen** - Original inspiration for meditative loop puzzles
- **Pipe Dream / Pipe Mania** - Classic pipe rotation gameplay
- **WarioWare Series** - Microgame format and pacing

## License

Assets and code are subject to repository license (see root LICENSE file).

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-30  
**Agent**: Game Designer (The Architect)  
**Status**: ✅ Ready for Implementation
