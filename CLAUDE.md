# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WarioWare-style microgame platform. Each game is 5 seconds, pass/fail outcome, with progressive difficulty via speed multiplier (1x-5x).

**Stack**: Godot 4.5.1 (GDScript 2.0)

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

Apply to: velocities, spawn rates, timers
Never apply to: collision shapes, sizes, delta itself

### Game Lifecycle
```gdscript
extends Microgame

var time_elapsed: float = 0.0
const GAME_DURATION: float = 5.0

func _ready():
    instruction = "CATCH!"  # Required, one word, ALL CAPS
    super._ready()

    # Initialize game objects
    _setup_game()

func _process(delta):
    time_elapsed += delta

    # Check timeout
    if time_elapsed >= GAME_DURATION:
        end_game()  # Score already set, emit game_over signal
        return

    # Apply speed_multiplier to movement
    object.position += velocity * speed_multiplier * delta

    # Check win condition
    if objective_complete:
        add_score(100)  # Or any positive value
        end_game()  # Emits game_over(current_score)
```

### Win/Lose Logic
- **Pass**: Call `add_score(positive_value)` then `end_game()`
- **Fail**: Call `end_game()` with score still at 0
- Director checks: `score > 0` = PASS, `score == 0` = FAIL
- Always call `end_game()` before timeout or at timeout

### Common Mistakes
1. Not setting `instruction` in `_ready()`
2. Forgetting to call `super._ready()`
3. Wrong speed_multiplier order (multiplying delta first)
4. Not calling `end_game()` when objective complete
5. Scaling collision shapes with speed_multiplier
6. Not checking for timeout

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

### Testing
Director auto-discovers games with `main.tscn` in `games/` folder. Just run the project.

## Examples

Reference implementations:
- `games/micro_sokoban/` - Grid-based puzzle with scene nodes
- `games/money_grabber/` - Collection game with programmatic spawning
- `games/sample_ai_game/` - Minimal tap-target template

## Documentation

- **GAME_REQUIREMENTS.md** - Succinct game spec for AI agents
- **ARCHITECTURE.md** - System design and generation pipeline
- **VISUAL_STYLE_GUIDE.md** - Art direction
- **README.md** - Project overview
