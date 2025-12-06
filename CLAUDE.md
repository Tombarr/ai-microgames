# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Project Overview

WarioWare-style microgame platform with beat-synced timing. Pass/fail outcome with progressive
difficulty via speed multiplier (1x-5x).

**Stack**: Godot 4.5.1 (GDScript 2.0)

## Beat-Based Timing System

All game timing is synced to **120 BPM** (beats per minute):

| Duration Type | Beats | Seconds | Usage |
|---------------|-------|---------|-------|
| **Normal Game** | 8 beats | 4 seconds | Most microgames |
| **Long Game** | 16 beats | 8 seconds | Complex games (geo_stacker, space_invaders) |
| **Intermission** | 4 beats | 2 seconds | Between-game transitions |
| **Countdown** | 4 beats | 2 seconds | Shows 3, 2, 1, 0 in last 4 beats |

**Key Constants** (in `director.gd`):
```gdscript
const BPM: float = 120.0
const BEAT_DURATION: float = 60.0 / BPM  # 0.5 seconds per beat
const NORMAL_GAME_BEATS: int = 8   # 4 seconds
const LONG_GAME_BEATS: int = 16    # 8 seconds
const INTERMISSION_BEATS: int = 4  # 2 seconds
```

**For longer games**, override `time_limit` in `_ready()`:
```gdscript
func _ready():
    instruction = "STACK!"
    super._ready()
    time_limit = 8.0  # 16 beats for complex games
```

## Commands

```bash
# Run game
godot4 project.godot

# Open editor
godot4 -e project.godot
```

## Architecture

### Class Hierarchy

```
Node2D
└── Microgame (shared/scripts/microgame.gd)
    - Properties: instruction, speed_multiplier, current_score
    - Methods: add_score(points), end_game()
    - Signals: game_over(score), score_updated(score)
```

### Director (shared/scripts/director.gd)

- Scans `games/` for folders with `main.tscn`
- Loads random game each round
- Manages lives (3), score, speed multiplier
- Speed increases by 0.2 per win (max 5.0)
- Sets `speed_multiplier` property before starting game
- Listens for `game_over(score)` signal
- Pass if score > 0, fail if score = 0

### Game Structure

Each game in `games/[name]/`:

- `main.gd` - Extends `Microgame`
- `main.tscn` - Scene file (root node attached to main.gd)
- `assets/` - Game-specific resources (optional)

## Critical Patterns

### Speed Multiplier

```gdscript
# CORRECT: Multiply speed, then delta
velocity * speed_multiplier * delta

# WRONG: Don't multiply delta
velocity * delta * speed_multiplier
```

Apply to: velocities, spawn rates, timers Never apply to: collision shapes, sizes, delta itself

### Game Lifecycle

```gdscript
extends Microgame

var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

func _ready():
    instruction = "CATCH!"  # Required, one word, ALL CAPS
    super._ready()

    # Initialize game objects
    _setup_game()

func _process(delta):
    time_elapsed += delta

    # Always let full 5 seconds run for Director timing
    if time_elapsed >= GAME_DURATION:
        if not game_ended:
            end_game()  # Timeout = fail
            game_ended = true
        return

    # Stop game logic after win/lose
    if game_ended:
        return

    # Apply speed_multiplier to movement
    object.position += velocity * speed_multiplier * delta

    # Check win condition
    if objective_complete:
        add_score(100)  # Or any positive value
        end_game()  # Game ends immediately
        game_ended = true  # Stop further logic
```

### Win/Lose Logic

- **Win**: Call `add_score(positive_value)` then `end_game()` - game logic stops immediately
- **Lose**: Call `end_game()` with score still at 0 - game logic stops immediately
- **After end_game()**: Set `game_ended = true` to stop processing, but let full 5-second timer run
- **No replay**: Games must not restart or loop - wait for Director transition
- Director checks: `score > 0` = PASS, `score == 0` = FAIL

### Common Mistakes

1. Not setting `instruction` in `_ready()`
2. Forgetting to call `super._ready()`
3. Wrong speed_multiplier order (multiplying delta first)
4. Not calling `end_game()` when objective complete
5. Scaling collision shapes with speed_multiplier
6. Not checking for timeout
7. **Allowing game logic to continue after `end_game()` is called**
8. **Adding replay/restart logic instead of letting Director handle transitions**

## Game Requirements

- **Resolution**: 640x640 pixels
- **Duration**: 5 seconds (track with timer)
- **Instruction**: One word, ALL CAPS (e.g., "DODGE!", "CATCH!", "PUSH!")
- **Outcome**: Binary pass/fail (score > 0 = pass)
- **Speed**: Must scale with `speed_multiplier` (1.0-5.0)

See **GAME_REQUIREMENTS.md** for complete spec.

## Workflow

### Creating a Game

1. Create folder: `games/[name]/`
2. Create `main.gd` extending `Microgame`
3. Create `main.tscn` with root Node2D, attach main.gd script
4. In `_ready()`: set `instruction`, call `super._ready()`, setup game
5. In `_process(delta)`: apply `speed_multiplier` to all speeds, check timeout
6. Call `add_score()` and `end_game()` based on outcome
7. **Add game to `GAME_LIST`** in `shared/scripts/director.gd` (required for web export)

### Git Hooks Setup

Run once after cloning to enable pre-commit validation:

```bash
git config core.hooksPath .githooks
```

The pre-commit hook verifies all games in `games/` are listed in `GAME_LIST`.

### Testing

Director auto-discovers games with `main.tscn` in `games/` folder. Just run the project.

## Examples

Reference implementations:

- `games/box_pusher/` - Grid-based Sokoban puzzle (**STYLE_GUIDE_GRID_PUZZLE.md**)
- `games/infinite_jump/` - Mario-style infinite runner (**STYLE_GUIDE_PLATFORMER.md**)
- `games/money_grabber/` - Collection game with programmatic spawning
- `games/sample_ai_game/` - Minimal tap-target template

## Documentation

- **GAME_REQUIREMENTS.md** - Succinct game spec for AI agents
- **GAME_CATEGORIES.md** - All games organized by style/genre
- **ARCHITECTURE.md** - System design and generation pipeline
- **VISUAL_STYLE_GUIDE.md** - Art direction
- **STYLE_GUIDE_GRID_PUZZLE.md** - Grid-based puzzle patterns (box_pusher style)
- **STYLE_GUIDE_PLATFORMER.md** - Platformer & runner patterns (infinite_jump style)
- **README.md** - Project overview
