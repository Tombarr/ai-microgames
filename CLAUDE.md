# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A WarioWare-style arcade platform where AI-generated 5-second microgames play in rapid succession. Built with Godot 4.5.1 (GDScript 2.0). Games are procedurally generated, validated server-side, and run in a browser WASM sandbox.

**Core Constraints:**
- 640x640px resolution (mobile-optimized square canvas)
- 5-second game duration
- Binary pass/fail outcome
- Speed multiplier: 1.0 → 5.0x (progressive difficulty)
- One-word instruction (e.g., "DODGE!", "CATCH!")

## Development Commands

### Running the Game
```bash
# Open project in Godot Editor
godot4 -e project.godot

# Run directly from command line
godot4 project.godot
```

### Testing
The Director automatically discovers and loads games from `res://games/` - no explicit test command needed. Add a new game folder and it will appear in rotation.

## Architecture

### Core Class Hierarchy
```
Node2D (Godot base)
└── Microgame (shared/scripts/microgame.gd)
    - Base class with score tracking, signals
    - Properties: current_score, speed_multiplier, instruction
    - Signals: game_over(score), score_updated(score)

    └── MicrogameAI (shared/scripts/microgame_ai.gd)
        - High-level API for AI-generated games
        - Lifecycle hooks: _on_game_start(), _on_game_update(delta), _on_input_event(pos)
        - Spawning API: spawn_sprite(), spawn_area()
        - Game control: win(), lose()
        - Auto-loads assets from script's assets/ folder
        - Defaults to LOSS on timeout if neither win()/lose() called
```

### Director Pattern (shared/scripts/director.gd)
Orchestrates the game loop:
1. Scans `res://games/` for folders containing `script.gd`
2. Randomly selects and loads a game script
3. Sets `speed_multiplier` (increases by 0.2 per round, max 5.0)
4. Displays instruction overlay (fades after 1.5s)
5. Connects to `game_over` signal
6. On pass: increments score, increases difficulty
7. On fail: decrements lives (3 total)
8. Shows transition UI (2s), then loads next game

### Game Creation Pattern

Every game MUST:
1. Extend `MicrogameAI` class
2. Be named `script.gd` in `res://games/[game_name]/` folder
3. Set `instruction` property in `_on_game_start()`
4. Apply `speed_multiplier` to ALL velocities/timers
5. Call `win()` or `lose()` explicitly

Critical: `speed_multiplier` scales difficulty. Apply it to:
- Velocities: `base_speed * speed_multiplier * delta`
- Spawn timers: `base_interval / speed_multiplier`
- NEVER apply to: collision radii, sprite scales, delta itself

### Asset Loading
Assets load from `res://games/[game_name]/assets/[texture_name].png`. The `spawn_area()` and `spawn_sprite()` methods automatically resolve paths based on the script location. Missing assets fallback to `PlaceholderTexture2D` (pink square).

### Security Sandbox
Banned APIs (validated server-side):
- `OS.*` - Operating system access
- `FileAccess.*` / `DirAccess.*` - File I/O (except Director)
- `ProjectSettings.*` - Global settings modification
- `GDExtension.*` - Native plugins
- `eval()` / `Expression.execute()` - Code execution

Exception: Director uses `DirAccess` and `FileAccess` for game scanning (allowed in trusted code).

## Common Pitfalls

1. **Wrong speed_multiplier application**
   ```gdscript
   # WRONG: Multiplies delta instead of speed
   velocity * delta * speed_multiplier

   # CORRECT: Multiply speed first
   velocity * speed_multiplier * delta
   ```

2. **Forgetting to call win()/lose()**
   - Games that reach 5s timeout without calling either will auto-lose
   - Always explicitly call `win()` when objective complete

3. **Not cleaning up nodes**
   - Off-screen objects should be removed with `queue_free()` immediately
   - Performance budget: 100 simultaneous nodes, 10 spawns/sec

4. **Scaling collision shapes**
   - Never multiply collision radii by speed_multiplier
   - Only scale velocities and spawn rates

## Documentation

- **README.md** - Project overview and quick start
- **GAME_REQUIREMENTS_TEMPLATE.md** - Complete specification for creating microgames (canonical reference)
- **ARCHITECTURE.md** - System architecture, generation pipeline, deployment
- **VISUAL_STYLE_GUIDE.md** - Art direction and visual standards

## Project Settings

Configured in `project.godot`:
- Resolution: 640x640 (non-resizable window)
- Engine: Godot 4.5 (Forward+ renderer)
- Main scene: `res://main.tscn`

## Backend (for reference)

Located in `backend/gemini_generator.ts`:
- AI generation: Gemini 1.5 Flash generates GDScript from prompts
- Validation: Server-side code scanning for banned APIs
- Deployment: Cloudflare Workers + R2 storage + Pages hosting

## Editing Guidelines

When modifying games:
1. Read the game's `script.gd` first to understand structure
2. Verify `speed_multiplier` is applied correctly to all speeds
3. Test at 1x, 2x, and 5x speeds to ensure proper scaling
4. Check that win/lose conditions trigger before timeout
5. Ensure assets exist in `assets/` folder or fallback works

When modifying framework:
- Changes to `Microgame` or `MicrogameAI` affect ALL games
- Director changes affect game loop timing and UI
- Test with multiple games in rotation after changes
