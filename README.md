# AI Microgames Platform

A WarioWare-style infinite arcade where 5-second microgames are generated and played in rapid succession.

## Core Specifications

| Constraint | Value | Rationale |
|------------|-------|-----------|
| **Resolution** | 640x640 px | Mobile-friendly square canvas |
| **Duration** | 5 seconds | Fast-paced WarioWare style |
| **Outcome** | Pass/Fail | Binary win/lose system |
| **Speed Multiplier** | 1.0 → 5.0x | Progressive difficulty scaling |
| **Instruction** | One word | Instant comprehension ("DODGE!", "CATCH!") |

## Quick Start

### Running the Game

```bash
# Open in Godot Editor
godot4 -e project.godot

# Run directly
godot4 project.godot
```

### Creating a New Game

1. **Create game folder**: `res://games/your_game_name/`
2. **Add script**: `script.gd` (must extend `MicrogameAI`)
3. **Implement hooks**:
   - `_on_game_start()` - Set instruction, spawn objects
   - `_on_game_update(delta)` - Game logic loop
   - `_on_input_event(pos)` - Handle clicks/taps
4. **Call outcome**: `win()` or `lose()` when appropriate

See **GAME_REQUIREMENTS_TEMPLATE.md** for complete specification.

## Project Structure

```
/ai-microgames/
├── games/                    # Game library
│   ├── money_grabber/       # Example: Collection game
│   └── sample_ai_game/      # Example: Template
├── shared/scripts/          # Core framework
│   ├── microgame.gd        # Base class
│   ├── microgame_ai.gd     # AI-specific API
│   └── director.gd         # Game loop orchestrator
├── backend/                 # Generation service
│   └── gemini_generator.ts # AI code generation
└── main.tscn               # Entry point
```

## Documentation

- **[GAME_REQUIREMENTS_TEMPLATE.md](./GAME_REQUIREMENTS_TEMPLATE.md)** - Complete specification for creating microgames
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture and technical design
- **[VISUAL_STYLE_GUIDE.md](./VISUAL_STYLE_GUIDE.md)** - Art direction and visual standards

## Development Workflow

1. **Design**: Define objective, instruction, mechanics
2. **Generate**: Use AI or write manually following template
3. **Test**: Director automatically picks up games in `/games/` folder
4. **Deploy**: Games are validated and bundled server-side

## Security

- No `OS`, `FileAccess`, `ProjectSettings` APIs
- Server-side validation of generated code
- Browser WASM sandbox (Web export)

## Technical Stack

- **Client**: Godot 4.5.1 (GDScript 2.0)
- **Backend**: Cloudflare Workers + Gemini 1.5 Flash
- **Storage**: Cloudflare R2
- **Deployment**: Cloudflare Pages
