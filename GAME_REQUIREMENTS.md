# Game Requirements

## Format Constraints

| Property | Requirement |
|----------|-------------|
| **Folder Structure** | Each game in own folder: `games/[game_name]/` |
| **Instruction** | One word, ALL CAPS (e.g., "DODGE!", "CATCH!", "PUSH!") |
| **Resolution** | 640x640 pixels (square canvas) |
| **Duration** | 5 seconds |
| **Outcome** | Binary pass/fail (score > 0 = pass, score = 0 = fail) |
| **Speed Multiplier** | 1.0x to 5.0x (progressive difficulty) |

## File Structure

```
games/
└── [game_name]/
    ├── main.gd          # Game logic (extends Microgame)
    ├── main.tscn        # Scene file (root node with main.gd attached)
    └── assets/          # Game-specific assets (optional)
```

## Core Rules

### Speed Multiplier
- Games MUST scale difficulty with `speed_multiplier` property (1.0 to 5.0)
- Apply to: velocities, spawn rates, timers
- DO NOT scale: collision shapes, visual sizes, delta time

```gdscript
# CORRECT
velocity * speed_multiplier * delta

# WRONG
velocity * delta * speed_multiplier
```

### Win/Lose System
- **Pass**: Call `add_score(positive_value)` then `end_game()`
- **Fail**: Call `end_game()` with score still at 0
- Director interprets: score > 0 = PASS, score == 0 = FAIL
- Must call `end_game()` within 5 seconds (track with timer)

### Instruction
- Must be set in `_ready()`
- Single action verb in ALL CAPS
- Max 12 characters
- Examples: "DODGE!", "CATCH!", "PUSH!", "TAP!", "AVOID!"

## Example Template

```gdscript
extends Microgame

var time_elapsed: float = 0.0
const GAME_DURATION: float = 5.0

func _ready():
    instruction = "TAP!"
    super._ready()

    # Setup game objects
    _spawn_target()

func _process(delta):
    time_elapsed += delta

    # Check timeout
    if time_elapsed >= GAME_DURATION:
        end_game()  # Timeout = fail (score still 0)
        return

    # Apply speed_multiplier to all movement
    enemy.position += BASE_SPEED * speed_multiplier * delta

    # Check win condition
    if objective_complete:
        add_score(100)  # Any positive value
        end_game()

func _input(event):
    # Handle player input
    if event is InputEventMouseButton and event.pressed:
        _check_click(event.position)
```

## Checklist

- [ ] Game folder: `games/[game_name]/`
- [ ] `main.gd` extends `Microgame`
- [ ] `main.tscn` with root node and script attached
- [ ] One-word `instruction` set in `_ready()`
- [ ] Call `super._ready()`
- [ ] 640x640 resolution compatible
- [ ] 5-second timer with timeout check
- [ ] `speed_multiplier` applied to all speeds
- [ ] `add_score()` for positive outcome
- [ ] `end_game()` called explicitly
- [ ] Pass/fail outcome only (score > 0 or score = 0)
