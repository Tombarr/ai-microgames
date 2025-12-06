# Game Categories

This document organizes all microgames by style and gameplay type for easy reference.

---

## Category 1: Grid-Based Puzzles 🧩

**Style Guide**: [STYLE_GUIDE_GRID_PUZZLE.md](STYLE_GUIDE_GRID_PUZZLE.md)

**Characteristics**:
- Turn-based movement
- Grid-aligned objects
- Strategic thinking
- No time pressure (Director handles timeout)
- Touch swipe or click controls

### Games in This Category:

#### 1. **box_pusher** - Sokoban Puzzle
- **Path**: `games/box_pusher/`
- **Instruction**: "PUSH!"
- **Mechanic**: Push box to target
- **Grid**: 8x8, ASCII level design
- **Features**: Multiple levels, deadlock detection
- **Reference**: Primary example for grid puzzle style

#### 2. **geo_stacker** - Tetris-Style
- **Path**: `games/geo_stacker/`
- **Instruction**: "STACK!"
- **Mechanic**: Stack falling shapes
- **Grid**: Tetris grid
- **Features**: Shape rotation, line clearing

#### 3. **loop_connect** - Path Puzzle
- **Path**: `games/loop_connect/`
- **Instruction**: "CONNECT!"
- **Mechanic**: Connect path segments
- **Grid**: Grid-based path tiles
- **Features**: Puzzle logic

#### 4. **minesweeper** - Classic Minesweeper
- **Path**: `games/minesweeper/`
- **Instruction**: "SWEEP!"
- **Mechanic**: Reveal safe tiles
- **Grid**: Classic minesweeper grid
- **Features**: Number hints, mine detection

---

## Category 2: Platformers & Runners 🏃

**Style Guide**: [STYLE_GUIDE_PLATFORMER.md](STYLE_GUIDE_PLATFORMER.md)

**Characteristics**:
- Real-time physics
- Gravity + jumping
- Scrolling obstacles
- Reflex-based
- Tap/click to jump
- Speed multiplier scaling required

### Games in This Category:

#### 1. **infinite_jump** - Mario-Style Runner
- **Path**: `games/infinite_jump/`
- **Instruction**: "DODGE!"
- **Mechanic**: Jump over obstacles
- **Physics**: Gravity 1800, Jump -650
- **Features**: Pipes, goombas, Y-axis alignment
- **Reference**: Primary example for platformer style

#### 2. **flappy_bird** - Vertical Scroller
- **Path**: `games/flappy_bird/`
- **Instruction**: "TAP!"
- **Mechanic**: Tap to flap through gaps
- **Physics**: Gravity 980, Jump -350
- **Features**: Pipe obstacles, pass scoring

---

## Category 3: Action & Timing Games 🎯

**Characteristics**:
- Tap/click targets
- Real-time action
- Hand-eye coordination
- Falling/moving objects
- Speed multiplier affects spawn rate
- No specific style guide (hybrid patterns)

### Games in This Category:

#### 1. **balloon_popper** - Target Tapping
- **Path**: `games/balloon_popper/`
- **Instruction**: "POP!"
- **Mechanic**: Tap moving balloon
- **Style**: Single target, predictable movement
- **Features**: Balloon escapes if not tapped

#### 2. **money_grabber** - Collection Game
- **Path**: `games/money_grabber/`
- **Instruction**: "GRAB 30!"
- **Mechanic**: Catch falling rubies
- **Style**: Multiple spawning objects
- **Features**: Different ruby values, progressive spawn rate
- **Note**: Good example of spawn system with speed_multiplier

#### 3. **whack_a_mole** - Timing Game
- **Path**: `games/whack_a_mole/`
- **Instruction**: "WHACK!"
- **Mechanic**: Tap appearing targets
- **Style**: Grid of spawn points, pop-up timing
- **Features**: Random target appearances

#### 4. **space_invaders** - Shooter
- **Path**: `games/space_invaders/`
- **Instruction**: "SHOOT!"
- **Mechanic**: Shoot descending enemies
- **Style**: Player controlled, projectile mechanics
- **Features**: Enemy waves, bullet collision
- **Note**: Variation of platformer style (horizontal movement instead of jumping)

#### 5. **dont_touch** - Avoidance Game
- **Path**: `games/dont_touch/`
- **Instruction**: "DODGE!"
- **Mechanic**: Avoid obstacles
- **Style**: Touch/mouse avoidance
- **Features**: Obstacle patterns

---

## Quick Category Reference

| Game | Category | Instruction | Difficulty | Style Guide |
|------|----------|-------------|-----------|-------------|
| box_pusher | Grid Puzzle | PUSH! | Medium | Grid Puzzle ✓ |
| geo_stacker | Grid Puzzle | STACK! | Medium | Grid Puzzle ✓ |
| loop_connect | Grid Puzzle | CONNECT! | Hard | Grid Puzzle ✓ |
| minesweeper | Grid Puzzle | SWEEP! | Medium | Grid Puzzle ✓ |
| infinite_jump | Platformer | DODGE! | Medium | Platformer ✓ |
| flappy_bird | Platformer | TAP! | Hard | Platformer ✓ |
| balloon_popper | Action | POP! | Easy | Hybrid |
| money_grabber | Action | GRAB 30! | Medium | Hybrid |
| whack_a_mole | Action | WHACK! | Easy | Hybrid |
| space_invaders | Action | SHOOT! | Medium | Hybrid |
| dont_touch | Action | DODGE! | Easy | Hybrid |

---

## Choosing a Reference Game for Development

### Want to make a puzzle game?
→ Study **box_pusher** → Follow **STYLE_GUIDE_GRID_PUZZLE.md**

### Want to make a platformer/runner?
→ Study **infinite_jump** → Follow **STYLE_GUIDE_PLATFORMER.md**

### Want to make an action/timing game?
→ Study **money_grabber** (spawning) or **balloon_popper** (single target)

---

## Game Count by Category

- **Grid Puzzles**: 4 games
- **Platformers**: 2 games
- **Action/Timing**: 5 games
- **Total**: 11 games

---

## Development Priorities by Category

### Grid Puzzles (4 games)
**Strengths**:
- Variety of puzzle types
- Good coverage of grid patterns
- box_pusher is excellent reference

**Opportunities**:
- Add more physics puzzles
- Add match-3 style games
- Add word/number puzzles

### Platformers (2 games)
**Strengths**:
- Two different scrolling styles (horizontal, vertical)
- infinite_jump is comprehensive reference

**Opportunities**:
- **NEEDS MORE GAMES** - Only 2 in this category
- Add more obstacle variety
- Add power-ups/collectibles
- Add different movement styles (wall jump, double jump)

### Action/Timing (5 games)
**Strengths**:
- Good variety of mechanics
- Different input patterns

**Opportunities**:
- Create dedicated style guide
- Standardize spawn patterns
- Add combo/scoring systems

---

## Recommended Development Order

For new games, prioritize these categories:

1. **Platformers** (only 2 games - need more variety)
   - Suggested: Wall-running game, Jetpack game, Grappling hook game

2. **Grid Puzzles** (4 games - good foundation, expand genres)
   - Suggested: Match-3, Pipe connection, Chess puzzle

3. **Action/Timing** (5 games - well represented)
   - Suggested: Rhythm game, Quick-time events, Combo challenges

---

## Pattern Summary by Category

### Grid Puzzle Pattern
```gdscript
const TILE_SIZE = 64
const GRID_W = 8
const GRID_H = 8
enum TileType { FLOOR, WALL, TARGET }
var grid = []  # 2D array

func _try_move(dir: Vector2i):
    # Grid-based collision
    # Push mechanics
    # Win condition
```

### Platformer Pattern
```gdscript
const GRAVITY: float = 1800.0
const JUMP_VELOCITY: float = -650.0
const BASE_SCROLL_SPEED: float = 350.0

func _physics_process(delta):
    if not player.is_on_floor():
        player.velocity.y += GRAVITY * delta
    player.move_and_slide()

func move_obstacles(delta):
    var scroll_speed = BASE_SCROLL_SPEED * speed_multiplier
    obstacle.position.x -= scroll_speed * delta
```

### Action/Timing Pattern
```gdscript
const SPAWN_RATE: float = 0.5
var targets: Array[Node2D] = []

func spawn_target():
    var target = create_target()
    target.position = random_position()
    add_child(target)

func _input(event):
    if event is InputEventScreenTouch and event.pressed:
        check_hit(event.position)
```

---

**Last Updated**: December 2025
**Maintainer**: Development Team
