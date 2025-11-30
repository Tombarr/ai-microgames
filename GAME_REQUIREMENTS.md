# Game Requirements

## Format Constraints

| Property | Requirement |
|----------|-------------|
| **Folder Structure** | Each game in own folder: `games/[game_name]/` |
| **Instruction** | One word, ALL CAPS (e.g., "DODGE!", "CATCH!", "PUSH!") |
| **Resolution** | 640x640 pixels (square canvas) |
| **Duration** | 5 seconds |
| **Outcome** | Binary pass/fail only |
| **Speed Multiplier** | 1.0x to 5.0x (progressive difficulty) |

## File Structure

```
games/
└── [game_name]/
    ├── main.gd          # Game logic (extends Microgame)
    ├── main.tscn        # Scene file
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
- Call `win()` when objective complete
- Call `lose()` when player fails
- If timeout (5s) with no call: defaults to LOSE

### Instruction
- Must be set in `_ready()`
- Single action verb in ALL CAPS
- Max 12 characters
- Examples: "DODGE!", "CATCH!", "PUSH!", "TAP!", "AVOID!"

## Example Template

```gdscript
extends Microgame

func _ready():
    instruction = "TAP!"
    super._ready()

    # Setup game
    _spawn_target()

func _process(delta):
    # Apply speed_multiplier to all movement
    enemy_speed = BASE_SPEED * speed_multiplier * delta

    # Check win/lose conditions
    if objective_complete:
        win()
    elif failed:
        lose()

func _input(event):
    # Handle player input
    pass
```

## Checklist

- [ ] Game folder: `games/[game_name]/`
- [ ] One-word instruction set
- [ ] 640x640 resolution compatible
- [ ] 5-second duration
- [ ] `speed_multiplier` applied to all speeds
- [ ] `win()` or `lose()` called explicitly
- [ ] Pass/fail outcome only
