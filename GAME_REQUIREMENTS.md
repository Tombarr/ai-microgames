# Game Requirements

## Format Constraints

| Property             | Requirement                                            |
| -------------------- | ------------------------------------------------------ |
| **Folder Structure** | Each game in own folder: `games/[game_name]/`          |
| **Instruction**      | One word, ALL CAPS (e.g., "DODGE!", "CATCH!", "PUSH!") |
| **Resolution**       | 640x640 pixels (square canvas)                         |
| **Duration**         | 4 seconds (8 beats) normal, 8 seconds (16 beats) long  |
| **Outcome**          | Binary pass/fail (score > 0 = pass, score = 0 = fail)  |
| **Speed Multiplier** | 1.0x to 5.0x (progressive difficulty)                  |

## Beat-Based Timing System

All game timing is synchronized to **120 BPM** (beats per minute):

| Duration Type   | Beats    | Seconds  | Usage                                      |
| --------------- | -------- | -------- | ------------------------------------------ |
| **Normal Game** | 8 beats  | 4 seconds | Most microgames (default)                  |
| **Long Game**   | 16 beats | 8 seconds | Complex games (geo_stacker, space_invaders)|
| **Intermission**| 4 beats  | 2 seconds | Between-game transitions                   |
| **Countdown**   | 4 beats  | 2 seconds | Last 4 beats show 3, 2, 1, 0               |

### Timing Constants (in Director)

```gdscript
const BPM: float = 120.0
const BEAT_DURATION: float = 60.0 / BPM  # 0.5 seconds per beat
const NORMAL_GAME_BEATS: int = 8   # 4 seconds
const LONG_GAME_BEATS: int = 16    # 8 seconds
```

### Using Long Game Duration

For complex games that need more time, override `time_limit` in `_ready()`:

```gdscript
func _ready():
    instruction = "BUILD!"
    time_limit = 8.0  # 16 beats for longer gameplay
    super._ready()
```

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
- **After end_game()**: Stop all game logic, but let the full timer run out before Director transition
- **No replay**: Games should not restart or loop - once ended, wait for Director
- Director interprets: score > 0 = PASS, score == 0 = FAIL
- Must call `end_game()` within time_limit (default 4 seconds / 8 beats)

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

func _ready():
    instruction = "TAP!"
    # time_limit defaults to 4.0 (8 beats at 120 BPM)
    # For longer games: time_limit = 8.0 (16 beats)
    super._ready()

    # Setup game objects
    _spawn_target()

func _process(delta):
    time_elapsed += delta

    # Check timeout - always let full time run for Director
    if time_elapsed >= time_limit:
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
- [ ] Timeout check using `time_limit` (default 4s, or 8s for long games)
- [ ] `speed_multiplier` applied to all speeds
- [ ] `add_score()` for positive outcome
- [ ] `end_game()` called explicitly
- [ ] Pass/fail outcome only (score > 0 or score = 0)
- [ ] Game added to `GAME_LIST` in `shared/scripts/director.gd`
