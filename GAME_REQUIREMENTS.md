# Game Requirements

## Format Constraints

| Property             | Requirement                                            |
| -------------------- | ------------------------------------------------------ |
| **Folder Structure** | Each game in own folder: `games/[game_name]/`          |
| **Instruction**      | One word, ALL CAPS (e.g., "DODGE!", "CATCH!", "PUSH!") |
| **Resolution**       | 640x640 pixels (square canvas)                         |
| **Duration**         | 5 seconds                                              |
| **Outcome**          | Binary pass/fail (score > 0 = pass, score = 0 = fail)  |
| **Speed Multiplier** | 1.0x to 5.0x (progressive difficulty)                  |

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

- **Win**: Call `add_score(positive_value)` then `end_game()` - game ends immediately
- **Lose**: Call `end_game()` with score still at 0 - game ends immediately
- **After end_game()**: Stop all game logic, but let the full 5-second timer run out before Director
  transition
- **No replay**: Games should not restart or loop - once ended, wait for Director
- Director interprets: score > 0 = PASS, score == 0 = FAIL
- Must call `end_game()` within 5 seconds (track with timer)

### Instruction

- Must be set in `_ready()`
- Single action verb in ALL CAPS
- Max 12 characters
- Examples: "DODGE!", "CATCH!", "PUSH!", "TAP!", "AVOID!"

### Input Controls
- **Touch-first design**: Games are designed for mobile touch input
- **PC controls**: Mouse position and click events map to touch
- **Implementation**: Use `InputEventMouseButton` and `InputEventMouseMotion` for both platforms
- **Single-touch games**: Most games should use single-point interaction
- **Position-based**: Use `event.position` for tap/click location

```gdscript
func _input(event):
    if game_ended:
        return

    # Click/Tap detection
    if event is InputEventMouseButton and event.pressed:
        var click_pos = event.position
        _handle_tap(click_pos)

    # Drag/Move detection (optional)
    if event is InputEventMouseMotion:
        var mouse_pos = event.position
        _handle_drag(mouse_pos)
```

## Example Template

```gdscript
extends Microgame

var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

func _ready():
    instruction = "TAP!"
    super._ready()

    # Setup game objects
    _spawn_target()

func _process(delta):
    time_elapsed += delta

    # Check timeout - always let full 5 seconds run for Director
    if time_elapsed >= GAME_DURATION:
        if not game_ended:
            end_game()  # Timeout = fail (score still 0)
            game_ended = true
        return

    # Stop game logic after win/lose, but keep running until timeout
    if game_ended:
        return

    # Apply speed_multiplier to all movement
    enemy.position += BASE_SPEED * speed_multiplier * delta

    # Check win condition
    if objective_complete:
        add_score(100)  # Any positive value
        end_game()      # Game ends immediately
        game_ended = true  # Stop further game logic

func _input(event):
    # Ignore input after game ends
    if game_ended:
        return

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
