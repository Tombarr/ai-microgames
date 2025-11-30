# Loop Connect

A minimalist 4x4 grid puzzle microgame where players rotate pipe segments to complete closed loops
within 5 seconds.

## Overview

**Instruction**: CONNECT!  
**Duration**: 5 seconds  
**Win Condition**: All pipes form complete, closed loops with no dead ends  
**Lose Condition**: Timer expires before completion

## How to Play

### Mouse/Touch Controls

- **Click tile**: Rotate 90° clockwise

### Keyboard Controls

- **Arrow Keys / WASD**: Move yellow highlight
- **Enter / Space**: Rotate selected tile

## Features

- **4x4 Grid**: 16 rotatable pipe tiles
- **5 Pipe Types**:
  - Straight pipe (2 connections)
  - L-bend pipe (2 connections)
  - T-junction pipe (3 connections)
  - Cross pipe (4 connections)
  - Terminal pipe (1 connection)
- **5 Preset Puzzles**: Randomly selected, each solvable in 1-2 rotations
- **Speed Scaling**: Rotation animation speeds up with difficulty multiplier (1x-5x)
- **Visual Feedback**:
  - Yellow highlight for keyboard selection
  - Green flash on puzzle completion
  - Light gray grid lines
  - Smooth rotation animations

## Game Mechanics

### Connection Rules

- Adjacent pipes connect when both have openings facing each other
- A valid solution has all pipes connected with no open ends
- Multiple separate loops are allowed
- All pipes must be part of a completed loop

### Speed Multiplier

- **Visual feedback** (rotation animation) scales with `speed_multiplier`
- Core gameplay remains turn-based and consistent
- At 5x speed, players must react instantly to pattern recognition

## Puzzle Difficulty

| Puzzle | Name             | Rotations Needed | Difficulty |
| ------ | ---------------- | ---------------- | ---------- |
| 1      | The Simple Gap   | 1                | Easy       |
| 2      | Double Loop      | 1                | Easy       |
| 3      | T-Junction Twist | 2                | Medium     |
| 4      | Cross Roads      | 2                | Medium     |
| 5      | Snake Path       | 2                | Hard       |

## Implementation Details

- **Grid**: 4x4 tiles at 80x80px each, with 10px spacing
- **Canvas**: Centered on 640x640 resolution
- **Assets**: Black pipes on white background (32x32px sprites)
- **Validation**: Graph-based connection checking with adjacency verification

## Technical Notes

### Connection Validation Algorithm

1. For each tile, check all connection points
2. Verify adjacent tiles have matching connections
3. Ensure no unconnected openings (dead ends)
4. Confirm all tiles form closed loops

### Pipe Rotation System

- Each pipe type has base connection array (N/E/S/W)
- Rotation updates both visual (sprite) and logical (connection array)
- Tiles store: type, rotation (0-3), sprite reference, highlight overlay

## Files

- `main.gd` - Game logic extending Microgame
- `main.tscn` - Scene file with root Node2D
- `assets/` - Pipe sprites and sound effects
  - `pipe_straight.png`
  - `pipe_l_bend.png`
  - `pipe_t_junction.png`
  - `pipe_cross.png`
  - `pipe_terminal.png`
  - `sfx_rotate.wav`
  - `sfx_win.wav`
  - `sfx_lose.wav`
- `design.md` - Full game design document

## Credits

- **Inspired by**: Loops of Zen, Pipe Dream/Pipe Mania
- **Game Format**: WarioWare-style microgame
