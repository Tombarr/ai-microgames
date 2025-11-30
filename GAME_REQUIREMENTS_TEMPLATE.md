# Game Requirements Document (GRD) Format

## Overview
This document defines the **mandatory specification format** for all AI-generated microgames in the platform. Each game MUST conform to these technical constraints and structural requirements.

---

## 1. Project Structure

### 1.1 File Organization
**MANDATORY**: Each game MUST reside in its own isolated folder under `res://games/`.

```
/games/
  ├── [game_name]/
  │   ├── script.gd           # REQUIRED: Main game logic (extends MicrogameAI)
  │   ├── script.gd.uid       # REQUIRED: Godot UID file (auto-generated)
  │   └── assets/             # OPTIONAL: Game-specific textures/sounds
  │       ├── player.png
  │       ├── enemy.png
  │       └── ...
```

**Naming Convention**:
- Folder name: `snake_case` (e.g., `money_grabber`, `dodge_asteroids`)
- Script name: **MUST** be `script.gd` (Director scans for this exact filename)

---

## 2. Technical Constraints

### 2.1 Resolution
- **Canvas Size**: `640x640` pixels (square viewport)
- **Coordinate System**: Origin (0,0) at top-left, (640, 640) at bottom-right
- **Responsive Strategy**: Use `get_viewport_rect().size` for dynamic queries, but design assuming 640x640

### 2.2 Time Constraints
- **Duration**: Exactly `5.0` seconds per round
- **Default**: Set in `MicrogameAI.game_duration = 5.0`
- **Timeout Behavior**: If time expires without calling `win()` or `lose()`, the game **defaults to LOSS**
  - *AI Note*: Call `win()` explicitly when success condition is met BEFORE timeout

### 2.3 Win/Lose System
**MANDATORY**: Every game MUST implement a **binary pass/fail outcome**.

- **Win**: Call `win()` when the player achieves the objective
  - Emits `game_over(current_score)` with score > 0
  - Director interprets this as "PASSED"
- **Lose**: Call `lose()` when the player fails
  - Emits `game_over(0)`
  - Director interprets this as "FAILED"

**Explicit Rule**: No "partial success" or "almost won" states. It's WIN or LOSE.

---

## 3. Gameplay Parameters

### 3.1 Speed Multiplier
**CRITICAL**: Games MUST respect the `speed_multiplier` property to enable WarioWare-style difficulty progression.

- **Property**: `speed_multiplier: float` (inherited from `Microgame`)
- **Range**: Starts at `1.0`, increases by `0.2` per successful round, caps at `5.0`
- **Application Rules**:
  - Multiply ALL time-dependent speeds (enemy velocity, spawn rates, player movement)
  - Do NOT multiply `delta` directly (breaks physics)
  - Do NOT multiply collision radii or visual sizes

**Example**:
```gdscript
func _on_game_update(delta: float) -> void:
    # CORRECT: Multiply the speed constant
    enemy.position.y += enemy.base_speed * speed_multiplier * delta
    
    # WRONG: Multiplying delta breaks physics calculations
    # enemy.position.y += enemy.base_speed * delta * speed_multiplier
```

### 3.2 Instruction Text
**MANDATORY**: Every game MUST set a ONE-WORD instruction before gameplay starts.

- **Property**: `instruction: String` (inherited from `Microgame`)
- **Format**: Single verb in ALL CAPS (e.g., "DODGE!", "CATCH!", "TAP!", "COLLECT!")
- **Display**: Director shows this for 1.5s before gameplay
- **Character Limit**: Max 12 characters (enforced by UI layout)

**Example**:
```gdscript
func _on_game_start() -> void:
    instruction = "CATCH!"  # Concise and action-oriented
```

---

## 4. Code Architecture

### 4.1 Base Class Extension
**MANDATORY**: All game scripts MUST extend `MicrogameAI`.

```gdscript
extends MicrogameAI

# Game implementation here
```

### 4.2 Lifecycle Hooks
**AI Implementation Points**: Override these methods (do NOT override `_ready()`, `_process()`, or `_input()` directly):

```gdscript
func _on_game_start() -> void:
    # Called once when game begins
    # Initialize: Set instruction, spawn initial objects, configure difficulty

func _on_game_update(delta: float) -> void:
    # Called every frame while game is active
    # Update: Move entities, check collisions, update logic

func _on_input_event(pos: Vector2) -> void:
    # Called on mouse click or touch
    # Handle: Player input at screen position
```

### 4.3 Spawning API
Use the `MicrogameAI` helper functions for object creation:

```gdscript
# Spawn a visual sprite
var sprite = spawn_sprite("player", Vector2(320, 320))

# Spawn a clickable/collision area (auto-includes Sprite2D + CircleShape2D)
var enemy = spawn_area("enemy", Vector2(100, 100), 40.0) # 40px radius
```

**Asset Resolution**:
- Textures loaded from `res://games/[game_name]/assets/`
- If asset missing, returns `PlaceholderTexture2D` (pink square)

---

## 5. Security Constraints

### 5.1 Banned APIs
**FORBIDDEN**: The following Godot classes/functions are **strictly prohibited** in AI-generated code:

- `OS.*` (operating system access)
- `FileAccess.*` (file I/O)
- `DirAccess.*` (directory traversal)
- `ProjectSettings.*` (global config)
- `GDExtension.*` (native plugins)
- `eval()` / `Expression.execute()` (arbitrary code execution)

**Rationale**: These APIs bypass the sandbox and pose security risks.

### 5.2 Validation
- **Server-Side**: Regex/AST parser rejects scripts containing banned keywords
- **Runtime**: Sandboxed in browser WASM container (Web export)

---

## 6. Performance Budgets

### 6.1 Constraints
- **Max Objects**: 100 simultaneous entities (nodes) on screen
- **Max Spawns/sec**: 10 objects per second (to avoid memory thrashing)
- **Frame Budget**: Game logic MUST complete in <16ms per frame (60 FPS target)

### 6.2 Optimization Guidelines
- Use `queue_free()` to clean up off-screen entities immediately
- Avoid creating nodes in tight loops
- Use object pooling for frequently spawned items (advanced)

---

## 7. Example: Complete Minimal Game

**File**: `res://games/tap_circle/script.gd`

```gdscript
extends MicrogameAI

var target: Area2D
const TARGET_SIZE: float = 80.0

func _on_game_start() -> void:
    instruction = "TAP!"
    game_duration = 5.0
    
    # Spawn target at random position
    var viewport = get_viewport_rect().size
    var random_pos = Vector2(
        randf_range(100, viewport.x - 100),
        randf_range(100, viewport.y - 100)
    )
    
    target = spawn_area("target", random_pos, TARGET_SIZE / 2)

func _on_game_update(delta: float) -> void:
    # No continuous updates needed for this game
    pass

func _on_input_event(pos: Vector2) -> void:
    # Check if click/tap is inside target area
    var distance = pos.distance_to(target.position)
    if distance < TARGET_SIZE / 2:
        win()  # Player tapped the circle!
```

---

## 8. Validation Checklist

Before deploying a game, verify:

- [ ] Script is in `res://games/[game_name]/script.gd`
- [ ] Extends `MicrogameAI`
- [ ] Sets `instruction` to a ONE-WORD verb in `_on_game_start()`
- [ ] Respects `speed_multiplier` for all movement/spawn logic
- [ ] Calls `win()` or `lose()` based on objective completion
- [ ] No banned APIs (`OS`, `FileAccess`, etc.)
- [ ] Runs at 60 FPS with <100 entities
- [ ] 640x640 resolution compatible

---

## 9. AI Generation Prompt Template

**Use this template when instructing an LLM to generate a microgame:**

```
Generate a WarioWare-style microgame for Godot 4.5.1 with the following specs:

1. **Objective**: [Describe the goal, e.g., "Catch falling coins with a hand"]
2. **Instruction**: [ONE-WORD verb, e.g., "CATCH!"]
3. **Mechanics**: [Core interaction, e.g., "Move hand with mouse, collect items"]
4. **Win Condition**: [e.g., "Collect 30 points within 5 seconds"]
5. **Speed Scaling**: [How speed_multiplier affects difficulty, e.g., "Faster falling speed"]

**Technical Requirements**:
- Extend `MicrogameAI`
- 640x640 resolution
- 5-second duration
- Binary pass/fail outcome
- Respect `speed_multiplier` for all time-dependent values
- Use `spawn_area()` and `spawn_sprite()` for entities
- Call `win()` when objective met, `lose()` on failure
- No `OS`, `FileAccess`, or banned APIs

**Output**: A single GDScript file extending `MicrogameAI` with `_on_game_start()`, `_on_game_update()`, and `_on_input_event()` implemented.
```

---

## 10. Metadata Schema (Optional Extension)

For database/frontend integration, each game folder MAY include a `metadata.json`:

```json
{
  "name": "Money Grabber",
  "instruction": "COLLECT!",
  "description": "Catch falling gems with your hand",
  "difficulty_base": 3,
  "tags": ["arcade", "reflex", "collection"],
  "author": "ai-generated",
  "version": "1.0.0"
}
```

This is **optional** for the MVP but recommended for scalability.

---

## 11. ROI Analysis: Why These Constraints?

| Constraint | Benefit | Trade-Off |
|------------|---------|-----------|
| 5-second duration | Fast iteration, WarioWare feel | No complex narratives |
| 640x640 resolution | Uniform asset pipeline, mobile-friendly | No ultra-wide designs |
| Binary pass/fail | Clear feedback loop, easy scoring | No nuanced grading |
| Speed multiplier | Infinite replayability via difficulty curve | Requires careful balancing |
| One-word instruction | Instant comprehension, no localization | Limited context |

**Decision**: These constraints maximize **generation speed** and **player clarity** at the cost of gameplay complexity, which is acceptable for a microgame platform.

---

## 12. Version History

- **v1.0** (2025-11-30): Initial specification
  - Defined folder structure, technical constraints, and API surface
  - Established security and performance budgets

---

**End of Document**
