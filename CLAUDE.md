# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

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
    - Methods: win(), lose(), add_score()
    - Signals: game_over(score), score_updated(score)
```

### Director (shared/scripts/director.gd)
- Scans `games/` for valid games
- Loads random game each round
- Manages lives (3), score, speed multiplier
- Speed increases by 0.2 per win (max 5.0)

### Game Structure
Each game in `games/[name]/`:
- `main.gd` - Extends `Microgame`
- `main.tscn` - Scene file
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

### Win/Lose
```gdscript
func _ready():
    instruction = "CATCH!"  # Required
    super._ready()

func _process(delta):
    if objective_met:
        win()  # Ends game, player passes
    elif failed:
        lose()  # Ends game, player fails
    # Timeout (5s) without call = auto-lose
```

### Common Mistakes
1. Not setting `instruction` in `_ready()`
2. Forgetting to call `super._ready()`
3. Wrong speed_multiplier order
4. Not calling `win()` or `lose()`
5. Scaling collision shapes with speed_multiplier

## Game Requirements

- **Resolution**: 640x640 pixels
- **Duration**: 5 seconds
- **Instruction**: One word, ALL CAPS
- **Outcome**: Binary pass/fail
- **Speed**: Must scale with `speed_multiplier` (1.0-5.0)

See **GAME_REQUIREMENTS.md** for complete spec.

## Workflow

### Creating a Game
1. Create folder: `games/[name]/`
2. Add `main.gd` extending `Microgame`
3. Add `main.tscn` with root node script set to `main.gd`
4. Set `instruction` in `_ready()`
5. Apply `speed_multiplier` to all speeds
6. Call `win()` or `lose()` based on outcome

### Testing
Director auto-discovers games in `games/` folder. Just run the project.

## Examples

Reference implementations:
- `games/micro_sokoban/` - Grid-based puzzle
- `games/money_grabber/` - Collection game
- `games/sample_ai_game/` - Minimal template

## Documentation

- **GAME_REQUIREMENTS.md** - Succinct game spec for AI agents
- **ARCHITECTURE.md** - System design and generation pipeline
- **VISUAL_STYLE_GUIDE.md** - Art direction
- **README.md** - Project overview
