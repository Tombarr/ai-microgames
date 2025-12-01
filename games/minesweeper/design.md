# Minesweeper Microgame - Design Document

## Overview

A fast-paced Minesweeper variant on a 5x5 grid where players must find and click 1-2 specific goal
squares in 5 seconds without hitting bombs.

## Core Mechanics

### Grid

- **Size**: 5x5 (25 squares total)
- **Tile Size**: 100px (fills 640x640 viewport with margins)
- **Spacing**: 8px between tiles

### Win Condition

- Click 1-2 specific "goal squares" marked with a subtle star/sparkle indicator
- Goal squares are always safe (never bombs)
- Clicking all required goal squares = WIN

### Lose Condition

- Click any bomb square = LOSE (instant)
- Timeout (5 seconds) = LOSE

### Square Types

1. **Unrevealed** - Gray tile, clickable
2. **Goal** - Has subtle sparkle animation (player must find these)
3. **Number** - Shows count of adjacent bombs (0-8)
4. **Empty** - Revealed safe square with 0 adjacent bombs
5. **Bomb** - Red explosion icon (only shown on loss)

### Revealing Behavior

- Click unrevealed square → reveal ONLY that square
- NO auto-reveal/flood-fill (keeps game fast and simple)
- Numbers show immediately on click
- First click is ALWAYS safe (classic Minesweeper rule)

## Visual Design

### Color Palette (Minimalist)

- Background: `#1a1a1a` (dark gray)
- Unrevealed tile: `#3a3a3a` (medium gray)
- Revealed tile: `#2a2a2a` (darker gray)
- Goal sparkle: `#ffd700` (gold)
- Numbers: Color-coded by value
  - 1: `#4a9eff` (blue)
  - 2: `#5ec269` (green)
  - 3: `#ff6b6b` (red)
  - 4: `#9b59b6` (purple)
  - 5+: `#e67e22` (orange)
- Bomb: `#ff4444` (bright red)

### Tile States

- **Unrevealed**: Raised 3D effect, subtle gradient
- **Revealed**: Flat, slightly darker
- **Goal indicator**: Animated gold sparkle in corner
- **Hover**: Slight brightness increase

## Four Map Configurations

### Map 1: Corner Safe Zone (1 click to win)

```
G . . . B
. . . B .
. . B . .
. B . . .
B . . . .
```

- 5 bombs in diagonal pattern
- 1 goal square (top-left corner)
- Large safe zone in bottom-right

### Map 2: Two Islands (2 clicks to win)

```
B . . . B
. . B . .
. B . B .
. . G . .
B . . . G
```

- 6 bombs scattered
- 2 goal squares (bottom area)
- Two safe "islands" to find

### Map 3: Center Goal (1 click to win)

```
B B . B B
B . . . B
. . G . .
B . . . B
B B . B B
```

- 12 bombs in diamond pattern
- 1 goal in center
- High risk, single target

### Map 4: Edge Path (2 clicks to win)

```
. . B . G
B . . . .
. . B B .
. . . . B
G . B . .
```

- 7 bombs scattered
- 2 goal squares on opposite corners
- Safe path along edges

## Controls

- **Mouse/Touch**: Click tiles to reveal
- **Keyboard**: Arrow keys to move cursor, Space/Enter to reveal (optional)

## Audio

- **sfx_reveal.wav** - Soft click when revealing safe square
- **sfx_goal.wav** - Success chime when clicking goal square
- **sfx_explode.wav** - Explosion sound on bomb click
- Uses shared: `sfx_win.wav`, `sfx_lose.wav`

## Instruction Text

**"FIND THE STAR!"** (or "STARS!" for 2-goal maps)

## Speed Multiplier Scaling

- Tile reveal animations speed up
- Goal sparkle animation speeds up
- NO change to grid layout or bomb count (keep maps consistent)

## Implementation Notes

- Use programmatic tile generation (no sprite sheets needed)
- Draw numbers with Label nodes (easier than sprite fonts)
- Bomb icon: Simple circle with "X" or "💣" emoji
- Goal sparkle: Rotating star polygon or animated opacity pulse
- First click safety: If first click is bomb, silently move it to random safe square
