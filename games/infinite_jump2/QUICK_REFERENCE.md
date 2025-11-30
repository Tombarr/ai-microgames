# Quick Reference - Fixed Values

## Critical Constants (main.gd)

```gdscript
# Floor alignment
const FLOOR_Y: float = 580.0

# Physics (FAST & SNAPPY)
const GRAVITY: float = 1800.0
const JUMP_VELOCITY: float = -650.0
const BASE_SCROLL_SPEED: float = 350.0

# Player dimensions
const PLAYER_HEIGHT: float = 40.0
const PLAYER_WIDTH: float = 32.0
```

## Spawn Formula

```gdscript
# Pipes
var pipe_height = 160.0
var max_allowed = max_jump_height * 0.7  # 70% safety
pipe_height = min(pipe_height, max_allowed)
var pipe_y = FLOOR_Y - pipe_height
obstacle.position = Vector2(700, pipe_y)

# Goombas
var goomba_height = 32.0
var goomba_y = FLOOR_Y - goomba_height
obstacle.position = Vector2(700, goomba_y)
```

## Collision Positions

- **Player:** y=560, collision offset (0, -20), bottom at 580
- **Pipe:** collision size 40x160, spawns so bottom = 580
- **Goomba:** collision size 24x24, spawns so bottom = 580

## Speed Scaling

```gdscript
scroll_speed = 350 * speed_multiplier
spawn_interval = randf_range(1.2, 2.0) / speed_multiplier
```
