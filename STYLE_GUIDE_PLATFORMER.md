# Style Guide: Platformer & Runner Games

## Overview

This style guide captures the patterns from **infinite_jump2** (Mario-style infinite runner) for creating physics-based platformer and auto-runner microgames.

**Best for**: Platformers, endless runners, obstacle courses, jumping challenges, timing-based games

**Reference Implementation**: [`games/infinite_jump2/main.gd`](games/infinite_jump2/main.gd)

---

## Visual Style

### Perspective & Layout
- **View**: 2D side-scrolling (horizontal or vertical)
- **Physics**: Real-time continuous movement
- **Layers**: Background → Ground → Player → Obstacles → UI

### Art Direction
- **Style**: Clean geometric shapes or pixel art sprites
- **Animation**: Visual feedback scripts (`_draw()` methods)
- **Dynamic**: Obstacles spawn off-screen and scroll
- **Examples**:
  - Player: Mario-style character with jump animation
  - Obstacles: Pipes, goombas, spikes, gaps
  - Ground: Scrolling platform with repeating texture

### Color Scheme
```
Sky Blue:      #87CEEB  (Background)
Ground Brown:  #8B4513  (Platform)
Character Red: #FF0000  (Player)
Enemy Brown:   #654321  (Goombas/Obstacles)
Pipe Green:    #228B22  (Pipes)
```

---

## Code Structure

### Physics Constants

**CRITICAL**: Document all physics values with comments

```gdscript
# ========================================
# PHYSICS CONFIGURATION
# ========================================
# Define exact collision boundaries
const FLOOR_Y: float = 580.0  # Ground collision Y coordinate

# Player dimensions (must match CollisionShape2D)
const PLAYER_HEIGHT: float = 40.0
const PLAYER_WIDTH: float = 32.0

# Gravity system (higher = faster fall, snappier feel)
const GRAVITY: float = 1800.0  # Pixels per second squared

# Jump mechanics (tune for desired jump height)
const JUMP_VELOCITY: float = -650.0  # Negative = upward

# Scrolling speed (affected by speed_multiplier)
const BASE_SCROLL_SPEED: float = 350.0  # Pixels per second

# Calculate max jump height (for obstacle sizing)
var max_jump_height: float = 0.0
```

### Scene Structure

```
Node2D (main.gd)
├── Player (CharacterBody2D)
│   ├── CollisionShape2D
│   └── Visual (Node2D with _draw() script)
├── Ground (StaticBody2D)
│   ├── CollisionShape2D
│   └── Visual (Node2D with _draw() script)
├── ObstacleContainer (Node2D)
│   └── [Dynamic obstacles added at runtime]
├── SpawnTimer (Timer)
├── sfx_jump (AudioStreamPlayer)
├── sfx_win (AudioStreamPlayer)
└── sfx_lose (AudioStreamPlayer)
```

### Asset Organization

```gdscript
# Preload sounds
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
const SFX_JUMP = preload("res://games/[game_name]/assets/sfx_jump.wav")

# Preload obstacle scenes
var pipe_scene = preload("res://games/[game_name]/pipe.tscn")
var goomba_scene = preload("res://games/[game_name]/goomba.tscn")

# Node references (@onready)
@onready var player = $Player
@onready var obstacle_container = $ObstacleContainer
@onready var spawn_timer = $SpawnTimer
@onready var ground_visual = $Ground/Visual
```

---

## Physics System

### Gravity & Jump

```gdscript
func _ready():
    instruction = "DODGE!"
    super._ready()

    # Calculate max jump height for obstacle clamping
    # Formula: h = v^2 / (2 * g)
    max_jump_height = (JUMP_VELOCITY * JUMP_VELOCITY) / (2.0 * GRAVITY)
    print("Max Jump Height: ", max_jump_height, " pixels")

    # Setup audio
    var sfx_jump = AudioStreamPlayer.new()
    sfx_jump.name = "sfx_jump"
    sfx_jump.stream = SFX_JUMP
    add_child(sfx_jump)

    # Start obstacle spawning
    spawn_timer.start()

func _physics_process(delta):
    if game_ended:
        return

    # Apply gravity when airborne
    if not player.is_on_floor():
        player.velocity.y += GRAVITY * delta

    # Use Godot's built-in physics
    player.move_and_slide()
```

### Jump Input

```gdscript
func _input(event):
    if game_ended:
        return

    # Touch/Click to jump (mobile + desktop)
    if event is InputEventScreenTouch and event.pressed:
        if player.is_on_floor():
            player.velocity.y = JUMP_VELOCITY
            $sfx_jump.play()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if player.is_on_floor():
            player.velocity.y = JUMP_VELOCITY
            $sfx_jump.play()
```

### Optional Mechanics

**Crouch/Duck**:
```gdscript
var is_crouching: bool = false

func handle_player_input():
    if Input.is_action_pressed("ui_down"):
        is_crouching = true
        player.scale.y = 0.6  # Squash vertically
    else:
        is_crouching = false
        player.scale.y = 1.0
```

**Double Jump** (optional):
```gdscript
var jumps_remaining: int = 2
const MAX_JUMPS: int = 2

func _input(event):
    if event is InputEventScreenTouch and event.pressed:
        if jumps_remaining > 0:
            player.velocity.y = JUMP_VELOCITY
            jumps_remaining -= 1
            $sfx_jump.play()

func _physics_process(delta):
    if player.is_on_floor():
        jumps_remaining = MAX_JUMPS  # Reset on landing
```

---

## Obstacle System

### Spawning Obstacles

**CRITICAL**: Y-axis alignment to ensure all obstacles spawn at same ground level

```gdscript
func _on_spawn_timer_timeout():
    if game_ended:
        return

    # ========================================
    # Y-AXIS ALIGNMENT (CRITICAL)
    # ========================================
    # All obstacles spawn with bottom edge at FLOOR_Y

    var obstacle
    var spawn_x = 700.0  # Off-screen right edge

    if randf() > 0.5:
        # Spawn pipe obstacle
        obstacle = pipe_scene.instantiate()

        var pipe_height = 160.0  # Default height
        # Clamp to max jump height (with safety margin)
        var max_allowed = max_jump_height * 0.7
        pipe_height = min(pipe_height, max_allowed)

        # Position so BOTTOM touches floor
        var pipe_y = FLOOR_Y - pipe_height
        obstacle.position = Vector2(spawn_x, pipe_y)

        print("Pipe spawned at Y:", pipe_y, " Height:", pipe_height)
    else:
        # Spawn goomba obstacle
        obstacle = goomba_scene.instantiate()

        var goomba_height = 32.0
        var goomba_y = FLOOR_Y - goomba_height
        obstacle.position = Vector2(spawn_x, goomba_y)

        print("Goomba spawned at Y:", goomba_y)

    obstacle_container.add_child(obstacle)

    # Dynamic spawn rate with speed_multiplier
    var spawn_interval = randf_range(0.6, 1.0) / speed_multiplier
    spawn_timer.wait_time = spawn_interval
    spawn_timer.start()
```

### Moving Obstacles

**Apply speed_multiplier to scroll speed**:

```gdscript
func move_obstacles(delta):
    # CORRECT: Multiply base speed by speed_multiplier
    var scroll_speed = BASE_SCROLL_SPEED * speed_multiplier

    for obstacle in obstacle_container.get_children():
        obstacle.position.x -= scroll_speed * delta

        # Remove off-screen obstacles (memory cleanup)
        if obstacle.position.x < -150:
            obstacle.queue_free()
```

### Collision Detection

**Using Area2D** (recommended):

```gdscript
func check_collisions():
    if game_ended:
        return

    for obstacle in obstacle_container.get_children():
        if obstacle is Area2D:
            var overlapping_bodies = obstacle.get_overlapping_bodies()
            for body in overlapping_bodies:
                if body == player:
                    # Collision = game over
                    $sfx_lose.play()
                    end_game()
                    game_ended = true
                    return
```

**Using Rect2 (alternative)**:

```gdscript
func check_collisions():
    var player_rect = Rect2(
        player.position.x - PLAYER_WIDTH/2,
        player.position.y - PLAYER_HEIGHT/2,
        PLAYER_WIDTH,
        PLAYER_HEIGHT
    )

    for obstacle in obstacle_container.get_children():
        var obs_rect = _get_obstacle_rect(obstacle)
        if player_rect.intersects(obs_rect):
            _fail()
            return
```

---

## Scoring System

### Survival Score

```gdscript
var obstacles_dodged: int = 0

func _process(delta):
    if game_ended:
        return

    # Count obstacles that passed player
    for obstacle in obstacle_container.get_children():
        if obstacle.position.x < player.position.x - 50:
            if not obstacle.has_meta("counted"):
                obstacle.set_meta("counted", true)
                obstacles_dodged += 1
```

### Timeout Victory

```gdscript
func _process(delta):
    time_elapsed += delta

    if time_elapsed >= GAME_DURATION:
        if not game_ended:
            # Win if survived
            if obstacles_dodged > 0:
                add_score(obstacles_dodged * 10)
                $sfx_win.play()
            else:
                $sfx_lose.play()
            end_game()
            game_ended = true
        return
```

---

## Visual Feedback

### Programmatic Drawing (Pipes)

Create `pipe_visual.gd`:

```gdscript
extends Node2D

func _draw():
    # Pipe stem (green rectangle)
    draw_rect(Rect2(0, 0, 60, 160), Color(0.13, 0.55, 0.13))

    # Pipe top (darker green cap)
    draw_rect(Rect2(-10, -20, 80, 20), Color(0.1, 0.4, 0.1))

    # Outline
    draw_rect(Rect2(0, 0, 60, 160), Color.BLACK, false, 2.0)
    draw_rect(Rect2(-10, -20, 80, 20), Color.BLACK, false, 2.0)
```

### Programmatic Drawing (Goomba)

Create `goomba_visual.gd`:

```gdscript
extends Node2D

func _draw():
    # Body (brown semi-circle)
    draw_circle(Vector2(16, 16), 16, Color(0.4, 0.25, 0.1))

    # Eyes (white ovals)
    draw_circle(Vector2(10, 12), 4, Color.WHITE)
    draw_circle(Vector2(22, 12), 4, Color.WHITE)

    # Pupils (black)
    draw_circle(Vector2(10, 12), 2, Color.BLACK)
    draw_circle(Vector2(22, 12), 2, Color.BLACK)

    # Outline
    draw_arc(Vector2(16, 16), 16, 0, PI, 32, Color.BLACK, 2.0)
```

### Animated Ground

Create `ground_visual.gd`:

```gdscript
extends Node2D

var scroll_offset: float = 0.0
const TILE_WIDTH: float = 64.0

func _process(delta):
    var speed = 350.0 * get_parent().get_parent().speed_multiplier
    scroll_offset += speed * delta

    if scroll_offset > TILE_WIDTH:
        scroll_offset -= TILE_WIDTH

    queue_redraw()

func _draw():
    # Scrolling tile pattern
    var num_tiles = ceil(640.0 / TILE_WIDTH) + 1

    for i in range(num_tiles):
        var x = i * TILE_WIDTH - scroll_offset
        draw_rect(Rect2(x, 0, TILE_WIDTH, 60), Color(0.55, 0.27, 0.07))
        draw_line(Vector2(x, 0), Vector2(x, 60), Color.BLACK, 2.0)
```

---

## Obstacle Scenes

### Pipe.tscn Structure

```
Area2D (pipe.gd)
├── CollisionShape2D (RectangleShape2D: 60x160)
└── Visual (Node2D with pipe_visual.gd)
```

**pipe.gd**:
```gdscript
extends Area2D
# No logic needed - collision handled by main game
```

### Goomba.tscn Structure

```
Area2D (goomba.gd)
├── CollisionShape2D (RectangleShape2D: 32x32)
└── Visual (Node2D with goomba_visual.gd)
```

**goomba.gd**:
```gdscript
extends Area2D
# No logic needed - collision handled by main game
```

---

## Speed Multiplier Integration

**CRITICAL**: Apply to all movement speeds

```gdscript
# Obstacle scrolling
var scroll_speed = BASE_SCROLL_SPEED * speed_multiplier
obstacle.position.x -= scroll_speed * delta

# Spawn rate
var spawn_interval = randf_range(0.6, 1.0) / speed_multiplier
spawn_timer.wait_time = spawn_interval

# Ground animation
var ground_speed = BASE_SCROLL_SPEED * speed_multiplier
scroll_offset += ground_speed * delta
```

**Do NOT apply to**:
- Gravity (GRAVITY constant)
- Jump velocity (JUMP_VELOCITY constant)
- Collision shapes
- Player size

---

## Game State Management

```gdscript
# Game state
var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

func _process(delta):
    time_elapsed += delta

    # Timeout check
    if time_elapsed >= GAME_DURATION:
        if not game_ended:
            _handle_timeout()
            game_ended = true
        return

    # Stop logic after game ends
    if game_ended:
        return

    # Game logic here...
```

---

## Audio Integration

```gdscript
func _ready():
    instruction = "JUMP!"
    super._ready()

    # Setup audio nodes
    var sfx_win = AudioStreamPlayer.new()
    sfx_win.name = "sfx_win"
    sfx_win.stream = SFX_WIN
    add_child(sfx_win)

    var sfx_lose = AudioStreamPlayer.new()
    sfx_lose.name = "sfx_lose"
    sfx_lose.stream = SFX_LOSE
    add_child(sfx_lose)

    var sfx_jump = AudioStreamPlayer.new()
    sfx_jump.name = "sfx_jump"
    sfx_jump.stream = SFX_JUMP
    add_child(sfx_jump)
```

---

## Physics Tuning Guide

### Gravity Feel

```gdscript
# Floaty (like old platformers)
const GRAVITY: float = 980.0
const JUMP_VELOCITY: float = -450.0

# Snappy (modern, responsive)
const GRAVITY: float = 1800.0
const JUMP_VELOCITY: float = -650.0

# Super tight (hardcore platformer)
const GRAVITY: float = 2500.0
const JUMP_VELOCITY: float = -800.0
```

### Jump Height Calculation

**Formula**: `max_height = (jump_velocity^2) / (2 * gravity)`

**Example**:
- Jump: -650 px/s
- Gravity: 1800 px/s²
- Max height: (650²) / (2 × 1800) = **117 pixels**

Use this to clamp obstacle heights:
```gdscript
max_jump_height = (JUMP_VELOCITY * JUMP_VELOCITY) / (2.0 * GRAVITY)
var max_pipe_height = max_jump_height * 0.7  # 70% safety margin
```

### Scroll Speed Tuning

```gdscript
# Slow (easy)
const BASE_SCROLL_SPEED: float = 200.0

# Medium (balanced)
const BASE_SCROLL_SPEED: float = 350.0

# Fast (intense)
const BASE_SCROLL_SPEED: float = 500.0
```

---

## Common Patterns

### Vertical Scrolling (Flappy Bird Style)

```gdscript
const SCROLL_DIRECTION = Vector2.DOWN  # or Vector2.UP

func move_obstacles(delta):
    var scroll_speed = BASE_SCROLL_SPEED * speed_multiplier
    for obstacle in obstacle_container.get_children():
        obstacle.position += SCROLL_DIRECTION * scroll_speed * delta
```

### Gap Obstacles

```gdscript
func spawn_gap():
    var gap_y = randf_range(200, 400)
    var top_pipe = pipe_scene.instantiate()
    top_pipe.position = Vector2(700, gap_y - 200)
    obstacle_container.add_child(top_pipe)

    var bottom_pipe = pipe_scene.instantiate()
    bottom_pipe.position = Vector2(700, gap_y + 200)
    obstacle_container.add_child(bottom_pipe)
```

### Moving Platforms

```gdscript
var platform_scene = preload("res://games/[name]/platform.tscn")

func spawn_moving_platform():
    var platform = platform_scene.instantiate()
    platform.position = Vector2(700, randf_range(300, 500))
    # Platform moves vertically
    platform.set_meta("y_velocity", randf_range(-100, 100))
    obstacle_container.add_child(platform)

func move_obstacles(delta):
    for obstacle in obstacle_container.get_children():
        # Horizontal scroll
        obstacle.position.x -= BASE_SCROLL_SPEED * speed_multiplier * delta

        # Vertical movement (if platform)
        if obstacle.has_meta("y_velocity"):
            obstacle.position.y += obstacle.get_meta("y_velocity") * delta
```

---

## Asset Requirements

### Sprites (Optional - can use _draw())
- `player.png` - 32x40 character sprite
- `obstacle1.png` - Enemy/hazard sprite
- `obstacle2.png` - Another obstacle type
- `ground_tile.png` - 64x64 repeating tile

### Audio
- `sfx_jump.wav` - Jump sound (~0.2s, pitch varies)
- `sfx_win.wav` - Shared success sound
- `sfx_lose.wav` - Shared failure sound
- `sfx_collect.wav` - Optional collectible sound

### Scenes
- `main.tscn` - Main game scene
- `pipe.tscn` - Obstacle 1 (Area2D)
- `goomba.tscn` - Obstacle 2 (Area2D)

---

## Debugging Helpers

### Visualize Collision Boxes

```gdscript
func _draw():
    # Draw floor line
    draw_line(Vector2(0, FLOOR_Y), Vector2(640, FLOOR_Y), Color.RED, 2.0)

    # Draw player hitbox
    draw_rect(Rect2(
        player.position.x - PLAYER_WIDTH/2,
        player.position.y - PLAYER_HEIGHT/2,
        PLAYER_WIDTH,
        PLAYER_HEIGHT
    ), Color.GREEN, false, 2.0)
```

### Print Jump Stats

```gdscript
func _ready():
    max_jump_height = (JUMP_VELOCITY * JUMP_VELOCITY) / (2.0 * GRAVITY)
    var time_to_peak = abs(JUMP_VELOCITY / GRAVITY)
    var total_air_time = time_to_peak * 2.0

    print("=== Jump Physics ===")
    print("Max Height: ", max_jump_height, " px")
    print("Time to Peak: ", time_to_peak, " s")
    print("Total Air Time: ", total_air_time, " s")
```

---

## Checklist

- [ ] Physics constants documented (GRAVITY, JUMP_VELOCITY, etc.)
- [ ] FLOOR_Y defined for consistent spawning
- [ ] Max jump height calculated for obstacle clamping
- [ ] CharacterBody2D player with move_and_slide()
- [ ] Touch/click input for jumping
- [ ] Obstacle spawning with Y-axis alignment
- [ ] speed_multiplier applied to scroll speed
- [ ] speed_multiplier applied to spawn rate
- [ ] Collision detection (Area2D or Rect2)
- [ ] Survival scoring (obstacles dodged)
- [ ] Timeout victory condition
- [ ] Audio for jump/win/lose
- [ ] Visual feedback (_draw() scripts)
- [ ] Game state management (game_ended flag)

---

## Example Games Using This Style

- **infinite_jump2** - Mario-style infinite runner (reference implementation)
- **flappy_bird** - Vertical scrolling with gap obstacles
- **space_invaders** - Horizontal movement with projectiles (variation)

---

**Reference Implementation**: See [`games/infinite_jump2/main.gd`](games/infinite_jump2/main.gd) for complete working example with extensive comments.
