# Style Guides Index

This document provides an overview of available style guides for creating microgames in different genres.

---

## Available Style Guides

### 1. [Grid-Based Puzzle Games](STYLE_GUIDE_GRID_PUZZLE.md)

**Best for**: Sokoban-style puzzles, turn-based strategy, tile-based movement, tactical games

**Reference Game**: [`box_pusher`](games/box_pusher/)

**Key Features**:
- Top-down grid layout (8x8 tiles)
- ASCII level design
- Touch swipe controls
- Static grid rendering
- Turn-based movement
- Push/pull mechanics

**Example Genres**:
- Sokoban puzzles
- Grid-based strategy
- Match-3 variants
- Tile puzzles
- Minesweeper-style

**Quick Start**:
```gdscript
const TILE_SIZE = 64
const GRID_W = 8
const GRID_H = 8
enum TileType { FLOOR, WALL, TARGET }
var grid = []  # 2D array
```

---

### 2. [Platformer & Runner Games](STYLE_GUIDE_PLATFORMER.md)

**Best for**: Infinite runners, platformers, obstacle courses, jumping challenges, timing-based games

**Reference Game**: [`infinite_jump2`](games/infinite_jump2/)

**Key Features**:
- Side-scrolling physics
- Gravity + jump mechanics
- Scrolling obstacles
- Collision detection (Area2D)
- Touch/click to jump
- Speed multiplier scaling

**Example Genres**:
- Infinite runners (Mario-style)
- Flappy Bird clones
- Platformers
- Obstacle courses
- Timing challenges

**Quick Start**:
```gdscript
const GRAVITY: float = 1800.0
const JUMP_VELOCITY: float = -650.0
const BASE_SCROLL_SPEED: float = 350.0

func _physics_process(delta):
    if not player.is_on_floor():
        player.velocity.y += GRAVITY * delta
    player.move_and_slide()
```

---

## Style Comparison Table

| Feature | Grid Puzzle | Platformer |
|---------|-------------|------------|
| **Perspective** | Top-down | Side-scrolling |
| **Movement** | Turn-based | Real-time physics |
| **Input** | Swipe/click direction | Tap to jump |
| **Speed Multiplier** | Optional | Required |
| **Collision** | Grid-based | Area2D/Rect2 |
| **Visual Style** | Pixel art tiles | Geometric/sprites |
| **Complexity** | Grid logic | Physics tuning |

---

## Choosing the Right Style

### Use **Grid Puzzle** if your game has:
- ✅ Turn-based movement
- ✅ Grid-aligned objects
- ✅ Puzzles requiring thinking
- ✅ Static layouts
- ✅ Push/pull mechanics
- ✅ Limited movement options

### Use **Platformer** if your game has:
- ✅ Continuous movement
- ✅ Jumping/gravity
- ✅ Obstacles to avoid
- ✅ Timing challenges
- ✅ Scrolling levels
- ✅ Reflex-based gameplay

---

## Common Patterns Across Styles

### Both styles share:

**Microgame Base Class**:
```gdscript
extends Microgame

var game_active: bool = true
var game_ended: bool = false

func _ready():
    instruction = "VERB!"  # One word, ALL CAPS
    super._ready()
    _setup_game()

func _process(delta):
    if game_ended:
        return
    # Game logic...
```

**Win/Lose Logic**:
```gdscript
func _win():
    if not game_active:
        return
    game_active = false
    add_score(100)
    $sfx_win.play()
    end_game()
    game_ended = true

func _fail():
    if not game_active:
        return
    game_active = false
    $sfx_lose.play()
    end_game()
    game_ended = true
```

**Audio Setup**:
```gdscript
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")

@onready var sfx_win = $SFXWin
@onready var sfx_lose = $SFXLose

func _ready():
    sfx_win.stream = SFX_WIN
    sfx_lose.stream = SFX_LOSE
```

---

## Quick Reference

### Grid Puzzle Essential Files
```
games/[name]/
├── main.gd          # Grid logic, touch swipe input
├── main.tscn        # LevelRoot + Audio nodes
├── assets/
│   ├── player.png   (64x64)
│   ├── box.png      (64x64)
│   ├── target.png   (64x64)
│   ├── wall.png     (64x64)
│   ├── floor.png    (64x64)
│   ├── sfx_move.wav
│   └── sfx_push.wav
└── design.md        # Level layouts (ASCII)
```

### Platformer Essential Files
```
games/[name]/
├── main.gd          # Physics, jump input, scrolling
├── main.tscn        # Player (CharacterBody2D) + Ground + SpawnTimer
├── pipe.tscn        # Obstacle (Area2D + Visual)
├── goomba.tscn      # Obstacle (Area2D + Visual)
├── pipe_visual.gd   # _draw() method for pipe
├── goomba_visual.gd # _draw() method for goomba
├── assets/
│   └── sfx_jump.wav
└── README.md
```

---

## Creating a New Game

### Step 1: Choose Your Style
- Read the relevant style guide
- Study the reference game implementation
- Understand the key patterns

### Step 2: Plan Your Game
- Sketch the core mechanic
- Design levels (Grid) or obstacles (Platformer)
- Define win/lose conditions

### Step 3: Set Up Structure
- Create `games/[name]/` folder
- Copy scene structure from reference game
- Create asset placeholders

### Step 4: Implement Core Logic
- Follow the style guide patterns
- Copy-paste skeleton code
- Customize for your game

### Step 5: Test & Polish
- Test with F3 debug panel
- Verify speed multiplier scaling (Platformer)
- Add audio feedback
- Tune difficulty

### Step 6: Integrate
- Add to `GAME_LIST` in `director.gd`
- Test in full game loop
- Get feedback

---

## Tips for Success

### Grid Puzzles
- Start with simple 5x5 layouts
- Test levels manually first
- Use ASCII art for level design
- Add multiple levels for variety
- Consider deadlock detection

### Platformers
- Tune physics first (gravity + jump)
- Calculate max jump height early
- Align all obstacles to FLOOR_Y
- Test at 1.0x and 5.0x speed
- Use _draw() for visuals (faster than sprites)

---

## Additional Resources

- **GAME_CATEGORIES.md** - All games organized by style/genre
- **GAME_REQUIREMENTS.md** - Universal game requirements
- **ARCHITECTURE.md** - Platform architecture overview
- **VISUAL_STYLE_GUIDE.md** - Art direction principles
- **CLAUDE.md** - Developer workflow guide

---

## Examples by Style

### Grid Puzzle Games
- ✅ box_pusher (Sokoban)
- ✅ minesweeper (Grid reveal)
- ✅ geo_stacker (Tetris-style)
- ✅ loop_connect (Path puzzle)

### Platformer Games
- ✅ infinite_jump2 (Infinite runner)
- ✅ flappy_bird (Vertical scroller)
- ⚠️ space_invaders (Shooter variation)

### Hybrid/Other Styles
- money_grabber (Collection game)
- balloon_popper (Tap targets)
- whack_a_mole (Timing game)

---

**Last Updated**: December 2025
**Maintainer**: Development Team
