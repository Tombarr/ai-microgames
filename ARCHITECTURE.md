# AI Microgames Platform: Technical Architecture

## Executive Summary

This document describes the technical architecture of the **AI Microgames Platform**, a WarioWare-style infinite arcade where 5-second microgames provide rapid-fire gameplay with progressive difficulty scaling.

**Technology Stack**:
- **Client**: Godot 4.5.1 (GDScript 2.0)
- **Backend**: Supabase (PostgreSQL + REST API)
- **Deployment**: Web (HTML5/WASM)

**Evolution Roadmap**:
```
v1.0 (Current)          v2.0 (Future)           v3.0 (Future)
Manual Game Creation → DLC System             → AI Generation Pipeline
11 hand-crafted games   Downloadable packs      Automated game creation
Static library          Dynamic content         Player feedback-driven QA
```

**Companion Documentation**:
- [GAME_REQUIREMENTS.md](GAME_REQUIREMENTS.md) - Game creation specifications
- [GAME_CATEGORIES.md](GAME_CATEGORIES.md) - All games organized by style/genre
- [VISUAL_STYLE_GUIDE.md](VISUAL_STYLE_GUIDE.md) - Art direction
- [STYLE_GUIDE_GRID_PUZZLE.md](STYLE_GUIDE_GRID_PUZZLE.md) - Grid-based puzzle game patterns
- [STYLE_GUIDE_PLATFORMER.md](STYLE_GUIDE_PLATFORMER.md) - Platformer & runner game patterns
- [CLAUDE.md](CLAUDE.md) - Developer workflow guide
- [README.md](README.md) - Project overview

---

## Version 1.0: Current Production Architecture

### System Overview

The current platform is built around a **Director pattern** where a central orchestrator manages the game loop, and individual microgames are self-contained scenes that follow a strict interface contract.

**Architecture Diagram**:
```
┌─────────────────────────────────────────────────────┐
│              Godot Client (Web/WASM)                │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  Director (main.tscn)                         │ │
│  │  - Game discovery (static GAME_LIST)          │ │
│  │  - Lifecycle orchestration                    │ │
│  │  - Lives/Score/Speed progression              │ │
│  │  - UI management                              │ │
│  │  - Audio playback                             │ │
│  └───────────────────────────────────────────────┘ │
│                       ↓                             │
│  ┌───────────────────────────────────────────────┐ │
│  │  Microgame Instances                          │ │
│  │  (games/*/main.tscn)                          │ │
│  │  - Extends Microgame base class               │ │
│  │  - Implements game logic                      │ │
│  │  - Emits game_over(score) signal              │ │
│  └───────────────────────────────────────────────┘ │
│                       ↓                             │
│  ┌───────────────────────────────────────────────┐ │
│  │  Shared Framework                             │ │
│  │  - Microgame base class                       │ │
│  │  - LeaderboardManager (autoload)              │ │
│  │  - GameDebugger (F3 panel)                    │ │
│  │  - Shared SFX library                         │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
                       ↓ (HTTPS)
        ┌──────────────────────────────┐
        │    Supabase Backend          │
        │    - REST API                │
        │    - PostgreSQL (leaderboard)│
        │    - CORS-enabled            │
        └──────────────────────────────┘
```

---

### Core Components

#### 1. Microgame Base Class

**File**: [`shared/scripts/microgame.gd`](shared/scripts/microgame.gd) (23 lines)

All games extend this base class, which defines the contract between individual games and the Director.

**Properties**:
```gdscript
var current_score: int = 0           # Win indicator (>0 = pass, 0 = fail)
var speed_multiplier: float = 1.0    # Difficulty scaling (1.0-5.0x)
var instruction: String = ""         # One-word command (e.g., "DODGE!")
var time_limit: float = 5.0          # Set by Director (5-10 seconds)
var game_name: String = ""           # Display name (set by Director)
```

**Methods**:
```gdscript
func add_score(points: int)  # Increment score
func end_game()              # Signal completion to Director
```

**Signals**:
```gdscript
signal game_over(score: int)      # Emitted when game ends (score determines pass/fail)
signal score_updated(score: int)  # Optional real-time updates
```

**Contract Rules**:
- Games MUST set `instruction` in `_ready()` before calling `super._ready()`
- Games MUST call `end_game()` when objective is complete or timeout occurs
- Games MUST stop all logic after calling `end_game()` (set `game_ended = true` flag)
- **Win**: Call `add_score(positive_value)` then `end_game()` → score > 0
- **Lose**: Call `end_game()` with score still at 0 → score = 0
- Director interprets: `score > 0` = PASS, `score == 0` = FAIL

**Example Implementation**:
```gdscript
extends Microgame

var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

func _ready():
    instruction = "TAP!"  # Required: One word, ALL CAPS
    super._ready()
    _setup_game()

func _process(delta):
    time_elapsed += delta

    # Always let full 5 seconds run for Director timing
    if time_elapsed >= GAME_DURATION:
        if not game_ended:
            end_game()  # Timeout = fail (score still 0)
            game_ended = true
        return

    # Stop game logic after win/lose
    if game_ended:
        return

    # Apply speed_multiplier to movement (CRITICAL ORDER)
    object.position += velocity * speed_multiplier * delta

    # Check win condition
    if objective_complete:
        add_score(100)  # Any positive value
        end_game()
        game_ended = true
```

**Critical Pattern - Speed Multiplier Application**:
```gdscript
# CORRECT: Multiply speed, then delta
velocity * speed_multiplier * delta

# WRONG: Don't multiply delta first
velocity * delta * speed_multiplier
```

Apply `speed_multiplier` to: velocities, spawn rates, timers
Never apply to: collision shapes, visual sizes, `delta` itself

---

#### 2. Director

**File**: [`shared/scripts/director.gd`](shared/scripts/director.gd) (940 lines)

The Director is the central orchestrator that manages the entire game loop.

**Responsibilities**:

1. **Game Discovery**
   - Uses static `GAME_LIST` array for web compatibility (DirAccess doesn't work in browsers)
   - Current games:
     ```gdscript
     const GAME_LIST: Array[String] = [
         "balloon_popper", "box_pusher", "flappy_bird", "geo_stacker",
         "infinite_jump2", "loop_connect", "minesweeper", "money_grabber",
         "space_invaders", "whack_a_mole"
     ]
     ```
   - Loads scenes from `res://games/[game_id]/main.tscn`

2. **Lifecycle Management**
   - Load game scene
   - Set `speed_multiplier` property
   - Show 1-second title overlay
   - Start randomized timer (5-10 seconds)
   - Listen for `game_over(score)` signal
   - Handle timeout (score = 0 → fail)

3. **Progression System**
   - **Lives**: Start with 3, decrement on fail, game over at 0
   - **Score**: Cumulative across all games, incremented on pass
   - **Speed**: Starts at 1.0x, increases by 0.2 per win, caps at 5.0x

4. **UI Management**
   - Progress bar (green → yellow → red as time runs out)
   - Win/Lose overlay messages
   - Game Over screen with leaderboard entry
   - Lives display (hearts)
   - Score display

5. **Audio System**
   - Countdown SFX (pitch scales with speed: `pitch_scale = 1.0 + (speed - 1.0) * 0.15`)
   - Game Start SFX
   - Game Over SFX (3.5 seconds)

6. **Pause System**
   - Tab key pauses game and shows leaderboard
   - Resume button unpauses and hides overlay
   - Game tree paused, UI layer continues processing

**State Machine**:
```
[Start Game Loop]
        ↓
[Pick Random Game from GAME_LIST]
        ↓
[Load Scene: games/{id}/main.tscn]
        ↓
[Set speed_multiplier on instance]
        ↓
[Show 1-second title overlay]
        ↓
[Start 5-10 second timer]
        ↓
[Game Active - wait for game_over signal]
        ↓
[Receive game_over(score) OR timeout]
        ↓
[Evaluate: score > 0 = WIN, score == 0 = LOSE]
        ↓
    ┌───────┴───────┐
    ↓               ↓
  [WIN]          [LOSE]
  +score         -1 life
  +0.2 speed
    ↓               ↓
    └───────┬───────┘
            ↓
     [Lives > 0?]
            ↓
    ┌───────┴───────┐
    ↓               ↓
   [Yes]          [No]
   Next Game    Game Over Screen
    ↑               ↓
    │         [Show leaderboard]
    │         [Play Again button]
    └───────────────┘
```

**Key Code Patterns**:
```gdscript
# Scene loading
var scene_path = "res://games/" + game_id + "/main.tscn"
var game_instance = load(scene_path).instantiate() as Microgame
game_instance.speed_multiplier = current_speed_multiplier
game_instance.time_limit = current_time_limit
add_child(game_instance)

# Speed progression
func _on_game_win():
    score += current_game.current_score
    current_speed_multiplier = min(current_speed_multiplier + speed_increment, max_speed)

# Lives management
func _on_game_lose():
    lives -= 1
    if lives <= 0:
        _game_over()
```

---

#### 3. LeaderboardManager

**File**: [`shared/scripts/leaderboard_manager.gd`](shared/scripts/leaderboard_manager.gd) (163 lines)

**Type**: Autoload singleton (globally accessible as `LeaderboardManager`)

**Configuration**:
```gdscript
const SUPABASE_URL = "https://yyafrfrgayzgclwudkhp.supabase.co"
const SUPABASE_KEY = "[ANON_KEY]"
const TABLE_NAME = "leaderboard"
const MAX_ENTRIES = 10
```

**Features**:
- Fetch top 10 scores (sorted by score DESC)
- Submit new scores with player names
- Check if score qualifies for top 10
- Async operations with signals

**Signals**:
```gdscript
signal leaderboard_loaded(success: bool)
signal score_submitted(success: bool, rank: int)
```

**API Flow**:
```
Client                              Supabase
  │                                    │
  ├─ GET /rest/v1/leaderboard ────────>│
  │  ?select=*&order=score.desc&limit=10
  │  Headers:                          │
  │    - apikey: [KEY]                 │
  │    - Authorization: Bearer [KEY]   │
  │    - Accept-Encoding: identity     │ (Disable gzip for web builds)
  │                                    │
  │<─── 200 OK ─────────────────────────┤
  │    [{name, score, created_at}, ...]│
  │                                    │
  ├─ POST /rest/v1/leaderboard ───────>│ (if top 10)
  │  Body: {name, score, created_at}   │
  │  Headers: [same + Prefer: return=representation]
  │                                    │
  │<─── 201 Created ─────────────────────┤
  │    [{id, name, score, ...}]        │
  │                                    │
  ├─ GET /rest/v1/leaderboard ────────>│ (refresh)
  │                                    │
  │<─── 200 OK ─────────────────────────┤
```

**Key Methods**:
```gdscript
func _load_leaderboard() -> void
func add_entry(player_name: String, score: int) -> void
func is_top_10(score: int) -> bool
func get_leaderboard() -> Array[Dictionary]
func get_rank_suffix(rank: int) -> String  # "st", "nd", "rd", "th"
```

**Usage Example**:
```gdscript
# Check if score qualifies
if LeaderboardManager.is_top_10(final_score):
    # Show name entry UI
    _show_name_entry_dialog()

# Submit score
func _on_submit_name(player_name: String):
    LeaderboardManager.add_entry(player_name, final_score)
    await LeaderboardManager.score_submitted
    # Show updated leaderboard
```

---

#### 4. GameDebugger

**File**: [`shared/scripts/game_debugger.gd`](shared/scripts/game_debugger.gd) (130 lines)

**Purpose**: Development tool for quickly testing specific games

**Features**:
- Press F3 to toggle debug panel
- Lists all games from `GAME_LIST`
- Click any game to instantly load it
- Resets Director state (lives, score, speed)
- Layer 1000 (above all UI)

**Usage**: Press F3 during gameplay to open game selector

---

#### 5. Shared Assets

**Directory**: [`shared/assets/`](shared/assets/)

**Core Audio** (23 files total):
- `sfx_win.wav` - Success sound
- `sfx_lose.wav` - Failure sound
- `sfx_countdown.wav` - 1-second countdown beep (6 dB boosted)
- `sfx_game_start.wav` - Game start jingle
- `sfx_game_over.wav` - Game over fanfare (3.5 seconds)

**Common Game Sounds**:
- `sfx_button_press.wav`, `sfx_move.wav`, `sfx_push.wav`, `sfx_laser.wav`
- Alien sounds, laser shoot variations

**Usage**: Games can use shared SFX or bring custom assets in `games/[id]/assets/`

---

### Game Structure

**Standard Folder Layout**:
```
games/
└── [game_id]/
    ├── main.gd           # Extends Microgame
    ├── main.tscn         # Scene (root Node2D with main.gd attached)
    ├── metadata.json     # Optional: SEO/marketing data
    └── assets/           # Optional: Game-specific resources
```

**Metadata Format** (optional):
```json
{
  "title": "Display Name",
  "description": "Marketing copy for game browsers",
  "tags": ["genre", "style"],
  "difficulty": "Easy|Medium|Hard",
  "controls": "Tap / Click"
}
```

**Current Game Library** (11 games):
1. **balloon_popper** - Tap targets before they escape
2. **box_pusher** - Push box to goal (Sokoban-style)
3. **flappy_bird** - Navigate through pipes
4. **geo_stacker** - Stack Tetris-style shapes
5. **infinite_jump2** - Platforming challenge
6. **loop_connect** - Connect path puzzle
7. **minesweeper** - Classic minesweeper variant
8. **money_grabber** - Collect falling items (reach target score)
9. **space_invaders** - Shoot descending enemies
10. **whack_a_mole** - Tap appearing targets

**Reference Implementations**:
- **Grid-based puzzle**: [`games/box_pusher/main.gd`](games/box_pusher/main.gd)
  - Sokoban-style push puzzle
  - Grid layout with ASCII levels
  - Touch swipe controls
  - See [STYLE_GUIDE_GRID_PUZZLE.md](STYLE_GUIDE_GRID_PUZZLE.md)
- **Platformer/Runner**: [`games/infinite_jump2/main.gd`](games/infinite_jump2/main.gd)
  - Mario-style infinite runner
  - Physics-based jumping
  - Scrolling obstacles
  - See [STYLE_GUIDE_PLATFORMER.md](STYLE_GUIDE_PLATFORMER.md)
- **Programmatic creation**: [`games/money_grabber/main.gd`](games/money_grabber/main.gd)
  - Spawns nodes in code
  - Uses shared SFX library
  - Good example of speed_multiplier application
- **Minimal template**: See [GAME_REQUIREMENTS.md](GAME_REQUIREMENTS.md)

---

### Sharing & Discovery

#### URL Parameter Sharing

**Feature**: Share specific games via URL

**Format**: `https://game.com/?game=flappy_bird`

**Implementation** (director.gd:782-806):
```gdscript
# Read game parameter from URL
func _get_url_game_param() -> String:
    if OS.has_feature("web"):
        var result = JavaScriptBridge.eval("""
            (function() {
                var params = new URLSearchParams(window.location.search);
                return params.get('game') || '';
            })();
        """)
        return result if result is String else ""
    return ""

# Update URL without page reload
func _update_url_game_param(game_id: String) -> void:
    if OS.has_feature("web"):
        JavaScriptBridge.eval("""
            (function() {
                var url = new URL(window.location);
                url.searchParams.set('game', '%s');
                window.history.replaceState({}, '', url);
            })();
        """ % game_id)
```

**Flow**:
1. On page load: Director checks URL → loads specified game if valid
2. During play: URL updates to current game for sharing

#### Web Share API

**Feature**: Native share dialog or clipboard fallback

**Implementation**:
```gdscript
func _share_current_game() -> void:
    if not OS.has_feature("web"):
        return

    var js_code = """
        (function() {
            var shareData = {
                title: 'Play %s!',
                text: 'Try this microgame!',
                url: window.location.href
            };
            if (navigator.share) {
                navigator.share(shareData).catch(function(err) {
                    navigator.clipboard.writeText(window.location.href);
                    alert('Link copied to clipboard!');
                });
            } else {
                navigator.clipboard.writeText(window.location.href);
                alert('Link copied to clipboard!');
            }
        })();
    """ % _format_game_name(current_game_id)

    JavaScriptBridge.eval(js_code)
```

**Usage**: "Share" button on Game Over screen

---

### Build & Deployment

**Target Platform**: Web (HTML5/WASM)

**Export Settings**:
- Renderer: Compatibility (OpenGL ES 3.0 / WebGL 2.0)
- Resolution: 640x640 (fixed)
- Stretch Mode: Viewport
- Export templates: Godot 4.5.1 web templates

**Export Process**:
```bash
# Command-line export
/Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" builds/web/index.html

# Or use Godot editor: Project → Export → Web
```

**Exported Files**:
- `index.html` - Main page
- `index.js` - JavaScript bridge (~305 KB)
- `index.wasm` - WebAssembly binary (~38 MB)
- `index.pck` - Packed game resources (~4 MB)
- `index.png` - Game icon
- Audio worklet files (for sound processing)

**Git Workflow**:
- **Pre-commit hook**: Validates `GAME_LIST` sync
- Hook path: `.githooks/pre-commit`
- Setup: `git config core.hooksPath .githooks`
- Checks:
  - All games in `games/*/main.tscn` are in `GAME_LIST`
  - All `GAME_LIST` entries exist on disk

**Current Deployment**: GitHub Pages / itch.io (HTML5 upload)

---

### Development Workflow

**Quick Start**:
1. Create folder: `games/[game_name]/`
2. Create `main.gd` extending `Microgame`
3. Create `main.tscn` with root Node2D, attach main.gd script
4. In `_ready()`: Set `instruction`, call `super._ready()`, setup game
5. In `_process(delta)`: Apply `speed_multiplier` to all speeds, check timeout
6. Call `add_score()` and `end_game()` based on outcome
7. **Add game to `GAME_LIST`** in `shared/scripts/director.gd` (required for web export)
8. Test with `godot4 project.godot` or F3 debug panel

**Testing Speed Multiplier**:
- Start game, win multiple times
- Speed increases by 0.2x per win
- Test physics/spawns at 5.0x speed (max difficulty)

**Common Mistakes**:
1. Not setting `instruction` in `_ready()`
2. Forgetting to call `super._ready()`
3. Wrong speed_multiplier order (multiplying delta first)
4. Not calling `end_game()` when objective complete
5. Scaling collision shapes with speed_multiplier
6. Not checking for timeout
7. Allowing game logic to continue after `end_game()` is called
8. Adding replay/restart logic instead of letting Director handle transitions

**Documentation References**:
- **Game specs**: [GAME_REQUIREMENTS.md](GAME_REQUIREMENTS.md)
- **Art direction**: [VISUAL_STYLE_GUIDE.md](VISUAL_STYLE_GUIDE.md)
- **Developer guide**: [CLAUDE.md](CLAUDE.md)

---

## Version 2.0: DLC System Architecture (Future)

### Overview

**Goal**: Distribute game packs without rebuilding the entire client

**Approach**: Built-in DLC manager that fetches game packs from a server on-demand

**Benefits**:
- Rapid content updates (no client rebuild required)
- Monetization opportunities (premium packs)
- User choice (browse and install only desired packs)
- Bandwidth efficiency (download on-demand)

**Architecture Addition**:
```
┌─────────────────────────────────────────────────────┐
│         Godot Client (v2.0 - Enhanced)              │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  DLC Manager (new autoload)                   │ │
│  │  - Pack discovery (fetch catalog from API)    │ │
│  │  - Download & verify (HTTPRequest + SHA256)   │ │
│  │  - Local cache (user://dlc/)                  │ │
│  │  - Browse UI (pack browser scene)             │ │
│  │  - Ownership verification                     │ │
│  └───────────────────────────────────────────────┘ │
│                       ↓                             │
│  ┌───────────────────────────────────────────────┐ │
│  │  Director (enhanced)                          │ │
│  │  - Static GAME_LIST (core 10 games)           │ │
│  │  - + Dynamic DLC games (from installed packs) │ │
│  │  - Unified game queue                         │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
                       ↓ (HTTPS)
        ┌──────────────────────────────┐
        │    DLC Server                │
        │    - Pack Catalog API        │
        │    - Payment verification    │
        │    - CDN (R2/S3 storage)     │
        └──────────────────────────────┘
```

---

### Game Pack Structure

**File Format**: Godot PCK (native) or ZIP (fallback)

**Pack Structure**:
```
pack_id.pck
├── metadata.json         # Pack metadata
├── thumbnail.png         # 256x256 preview image
└── games/
    ├── game1/
    │   ├── main.gd
    │   ├── main.tscn
    │   └── assets/
    └── game2/
        ├── main.gd
        ├── main.tscn
        └── assets/
```

**Pack Metadata** (metadata.json):
```json
{
  "pack_id": "spooky_games_vol1",
  "version": "1.0.2",
  "title": "Spooky Games Vol. 1",
  "description": "5 Halloween-themed microgames",
  "author": "StudioName",
  "price": "free",
  "price_usd": 1.99,
  "release_date": "2025-10-01",
  "thumbnail_url": "https://cdn.example.com/packs/spooky_vol1/thumb.png",
  "game_count": 5,
  "games": [
    {
      "game_id": "ghost_chase",
      "instruction": "ESCAPE!",
      "difficulty": "medium"
    }
  ],
  "min_client_version": "2.0.0",
  "tags": ["halloween", "spooky", "seasonal"]
}
```

---

### Server-Side Components

#### Pack Catalog API

**Endpoints**:
```
GET  /api/packs                     # List all available packs
GET  /api/packs/{pack_id}           # Get pack details
GET  /api/packs/{pack_id}/download  # Get signed download URL
POST /api/packs/{pack_id}/purchase  # Initiate payment flow
POST /api/packs/{pack_id}/verify    # Verify user ownership
```

**Catalog Response**:
```json
{
  "packs": [
    {
      "pack_id": "spooky_games_vol1",
      "version": "1.0.2",
      "title": "Spooky Games Vol. 1",
      "thumbnail_url": "https://cdn.example.com/thumb.png",
      "price": "free",
      "game_count": 5,
      "size_mb": 12.3,
      "tags": ["halloween", "spooky"]
    }
  ],
  "total": 1,
  "featured": ["spooky_games_vol1"]
}
```

#### CDN Storage

**Technology**: Cloudflare R2 or AWS S3

**Structure**:
```
/packs/
  ├── spooky_games_vol1/
  │   ├── v1.0.2/
  │   │   ├── bundle.pck          # Game pack
  │   │   ├── metadata.json       # Pack metadata
  │   │   └── checksum.sha256     # Integrity verification
  │   └── thumbnail.png
```

**Versioning Strategy**:
- Immutable versions (never overwrite released bundles)
- Clients cache by version number
- Rollback capability if issues arise

#### Payment Integration

**Providers**: Stripe (web), in-app purchases (mobile future)

**Flow**:
```
[User clicks "Buy Pack" in browse UI]
        ↓
[Client: POST /api/packs/{id}/purchase]
        ↓
[Server: Create Stripe checkout session]
        ↓
[Client: Redirect to Stripe payment page]
        ↓
[User completes payment]
        ↓
[Stripe webhook → Server marks pack as owned]
        ↓
[Client: POST /api/packs/{id}/verify with receipt]
        ↓
[Server: Return ownership = true]
        ↓
[Client: Download and install pack]
```

**Free Packs**: Skip payment, direct to download

**Authentication**:
- Anonymous play: Store purchases in local storage (device-specific)
- User accounts (future): Sync purchases across devices via JWT tokens

---

### Client-Side Implementation

#### DLC Manager Component

**File**: `shared/scripts/dlc_manager.gd` (new)

**Type**: Autoload singleton

**Responsibilities**:
1. Fetch pack catalog on app start
2. Maintain local registry of installed packs
3. Download and install packs (HTTPRequest + extraction)
4. Verify pack ownership before allowing play
5. Check for updates and notify user
6. Provide data to browse UI

**State Management**:
```gdscript
enum PackState {
    AVAILABLE,           # In catalog, not downloaded
    DOWNLOADING,         # Download in progress
    INSTALLED,           # Downloaded and ready to play
    UPDATE_AVAILABLE,    # Newer version exists
    ERROR                # Download/install failed
}

var installed_packs: Dictionary = {
    "spooky_games_vol1": {
        "version": "1.0.2",
        "state": PackState.INSTALLED,
        "install_date": "2025-10-15",
        "games": ["ghost_chase", "pumpkin_panic", ...]
    }
}
```

#### Download System

**Implementation**:
```gdscript
func download_pack(pack_id: String) -> void:
    var url = await _get_download_url(pack_id)

    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_download_complete)

    var error = http.request(url)
    if error != OK:
        push_error("Download failed: " + str(error))
        pack_downloaded.emit(false, pack_id)

func _on_download_complete(result, response_code, headers, body):
    # Verify checksum
    var checksum = _calculate_sha256(body)
    if not _verify_checksum(pack_id, checksum):
        push_error("Checksum mismatch!")
        return

    # Extract to user://dlc/pack_id/
    _extract_pack(pack_id, body)

    # Update registry
    _register_pack(pack_id)

    pack_downloaded.emit(true, pack_id)
```

**Progress Tracking**:
```gdscript
func _process(delta):
    if is_downloading:
        var bytes_downloaded = http_request.get_downloaded_bytes()
        var total_bytes = http_request.get_body_size()
        var progress = float(bytes_downloaded) / float(total_bytes)
        download_progress.emit(current_pack_id, progress)
```

#### Dynamic Game Loading

**Challenge**: Godot web builds can't load PCK files at runtime

**Solutions**:

**Web Build Strategy** (v2.0):
- Pre-load all DLC packs in the export (embedded in WASM)
- DLC Manager checks ownership via API
- Show "BUY" button if not owned, "PLAY" if owned
- Unlock games locally after purchase verification

**Desktop Build Strategy** (future):
- True runtime PCK loading via `ProjectSettings.load_resource_pack()`
- Download on-demand
- Smaller initial download size

**Director Enhancement**:
```gdscript
func _scan_games() -> Array[String]:
    var games: Array[String] = []

    # Core games (always available)
    games.append_array(GAME_LIST)

    # DLC games (if installed and owned)
    for pack_id in DLCManager.get_installed_packs():
        if DLCManager.is_pack_owned(pack_id):
            games.append_array(DLCManager.get_pack_games(pack_id))

    return games
```

#### Browse UI

**File**: `shared/scenes/dlc_browser.tscn` (new)

**Layout**:
```
┌────────────────────────────────────────┐
│         DLC GAME PACKS                 │
├────────────────────────────────────────┤
│  [Featured Pack Carousel]              │
│  ┌──────────────────────────────────┐  │
│  │  [Large thumbnail]               │  │
│  │  Title: "Spooky Games Vol. 1"    │  │
│  │  5 games • FREE                  │  │
│  │  [INSTALL]                       │  │
│  └──────────────────────────────────┘  │
├────────────────────────────────────────┤
│  All Packs:                            │
│  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │[Thumb] │  │[Thumb] │  │[Thumb] │   │
│  │Pack 1  │  │Pack 2  │  │Pack 3  │   │
│  │5 games │  │3 games │  │7 games │   │
│  │[PLAY]  │  │[$1.99] │  │[UPDATE]│   │
│  └────────┘  └────────┘  └────────┘   │
│                                        │
│  [Sort: New | Popular | Free]          │
│  [Filter: All | Owned | Available]     │
└────────────────────────────────────────┘
```

**Features**:
- Browse all available packs
- Filter by free/paid/installed/owned
- Search by tags
- View pack details (game list, screenshots)
- Install/Buy/Update buttons
- Download progress indicators

**Access**: Main menu "DLC PACKS" button or from Game Over screen

---

### Security & Validation

**Code Security**:
- **Server-side validation**: Static analysis on all pack uploads
- **Banned keywords**: Scan for `OS`, `FileAccess`, `DirAccess`, `GDExtension`
- **Regex checks**: Parse GDScript source before approval

**Asset Validation**:
- Verify all games extend `Microgame`
- Check `main.tscn` exists and is valid
- File size limits (e.g., 50 MB per pack)
- No executable files allowed

**Sandboxing**:
- DLC games run in same sandbox as core games
- GDScript only (no native code)
- Web builds: WASM isolation

**Integrity**:
- SHA256 checksum verification on download
- Signature validation (future: code signing certificates)

---

### Monetization

**Revenue Models**:
1. Premium packs ($0.99 - $4.99 per pack)
2. Season pass (monthly subscription, all packs included)
3. Ad-supported free packs (future)

**Pricing Strategy**:
- Core 10 games: Always free
- DLC packs: 3-10 games per pack
- First DLC pack: Free (to onboard users)
- Themed packs: $1.99 (holiday, retro, puzzle)
- Large packs: $3.99-$4.99 (10+ games)

**Analytics Tracking**:
- Pack views and impressions
- Purchase conversion rate
- Play time per pack
- Refund rate
- A/B test pricing

---

### Implementation Roadmap

**Phase 1: Foundation (2 weeks)**
- [ ] Create DLC Manager singleton
- [ ] Implement pack catalog API (mock data)
- [ ] Build HTTP download system with progress tracking
- [ ] Local pack registry (save/load from user://dlc/registry.json)

**Phase 2: Integration (2 weeks)**
- [ ] Update Director for dynamic game discovery
- [ ] Build DLC browser UI (scene + GDScript)
- [ ] Install/uninstall flows
- [ ] Progress indicators and error handling

**Phase 3: Payment (1 week)**
- [ ] Integrate Stripe checkout
- [ ] Ownership verification API
- [ ] Purchase flow UI
- [ ] Receipt system and local storage

**Phase 4: Production (1 week)**
- [ ] Server-side validation pipeline
- [ ] CDN setup (Cloudflare R2)
- [ ] Create 2-3 launch packs
- [ ] QA testing (web + desktop)

**Total Timeline**: 6 weeks to v2.0 launch

---

## Version 3.0: AI Generation Pipeline (Future)

### Overview

**Goal**: AI generates playable microgames from text prompts using the same guidelines that human developers follow

**Approach**: Iterative generation with automated quality assurance and player feedback-driven debugging

**Quality Gate**: Winrate monitoring (0% winrate triggers automated debugging)

**Tools**:
- **Code Generation**: Claude Code (Sonnet 4.5) via Anthropic API
- **Asset Generation**: Gemini 2.5 Flash (text-to-image) via Google AI API
- **Testing**: Automated playtesting bots (monkey testing + heuristics)
- **Metrics**: Supabase (track winrate, play count, player ratings)
- **Debugging**: Claude Code with failure logs

**Philosophy**:
> AI uses the same documentation as human developers (GAME_REQUIREMENTS.md, VISUAL_STYLE_GUIDE.md, CLAUDE.md) and references shared components. No special AI syntax—just GDScript. Quality over quantity: only publish games that pass automated QA.

---

### Generation Workflow

#### Input Processing

**User Prompt**: `"Make a game where you dodge falling asteroids"`

**System Prompt Construction**:
```
You are creating a WarioWare-style microgame for Godot 4.5.1.

Read these guidelines carefully:
- GAME_REQUIREMENTS.md (constraints, template, checklist)
- VISUAL_STYLE_GUIDE.md (art direction)
- CLAUDE.md (development workflow)

Study these example implementations:
- games/flappy_bird/main.gd (programmatic sprite creation)
- games/money_grabber/main.gd (spawning pattern with speed_multiplier)
- games/box_pusher/main.gd (grid-based collision)

User request: "dodge falling asteroids"

Generate:
1. main.gd (extends Microgame, 100-300 lines)
2. main.tscn (root Node2D with script attached)
3. Asset generation plan (sprites needed, dimensions)

Requirements (CRITICAL):
- One-word instruction in ALL CAPS (e.g., "DODGE!")
- 5-second duration with timeout check
- Speed multiplier scaling: velocity * speed_multiplier * delta
- Binary win/lose: add_score(100) + end_game() OR end_game() with score=0
- Set game_ended flag after end_game() to stop logic
- Use shared SFX: res://shared/assets/sfx_win.wav, sfx_lose.wav

Constraints:
- No OS, FileAccess, DirAccess, or GDExtension calls
- Programmatic node creation (ColorRect for sprites is fine)
- Touch/click input only (InputEventMouseButton)
```

#### Code Generation

**Process**:
1. Claude Code API call with system prompt + guidelines
2. Generate `main.gd` (typically 100-300 lines)
3. Generate `main.tscn` (minimal scene tree, root Node2D)
4. AI self-review against GAME_REQUIREMENTS.md checklist
5. Static analysis: Check for banned keywords
6. Syntax validation: Parse GDScript AST

**Validation Pipeline**:
```python
# Pseudo-code
def validate_generated_game(main_gd, main_tscn):
    # 1. Security check
    banned = ["OS.", "FileAccess", "DirAccess", "GDExtension"]
    for keyword in banned:
        if keyword in main_gd:
            return Error(f"Security violation: {keyword}")

    # 2. Structure check
    if "extends Microgame" not in main_gd:
        return Error("Must extend Microgame")

    if 'instruction = "' not in main_gd:
        return Error("Missing instruction")

    if "super._ready()" not in main_gd:
        return Warning("Missing super._ready() call")

    # 3. Speed multiplier check (heuristic)
    if "speed_multiplier" not in main_gd:
        return Warning("Speed multiplier may not be applied")

    # 4. Scene validation
    scene = parse_tscn(main_tscn)
    if scene.root_type != "Node2D":
        return Error("Root must be Node2D")

    return Success()
```

#### Asset Generation

**Visuals**: Gemini 2.5 Flash (text-to-image)

**Prompt Strategy** (from VISUAL_STYLE_GUIDE.md):
```
"vector art style, thick distinct black outlines, flat vibrant colors,
 no gradients, white background, sticker art, minimal details, 2D game asset"

Subject: [asteroid sprite, player ship sprite]

Negative prompt: "photorealistic, 3d render, shading, shadows, gradients, blur, text, watermark"
```

**Post-Processing**:
1. Background removal (transparent PNG)
2. Resize to appropriate scale (e.g., 64x64 for small sprites)
3. Optimize file size

**Audio**:
- Select from shared SFX library (no generation in v3.0)
- Win: `sfx_win.wav`
- Lose: `sfx_lose.wav`
- Actions: Choose from `sfx_move.wav`, `sfx_button_press.wav`, etc.

**Asset Pipeline**:
```
[User prompt: "asteroid"] → Gemini 2.5 Flash
        ↓
[Raw PNG with white background]
        ↓
[Background removal tool (rembg)]
        ↓
[Transparent PNG]
        ↓
[Resize & optimize]
        ↓
[Save to games/asteroid_dodge/assets/asteroid.png]
```

#### Packaging

**Bundle Structure** (same as DLC v2.0):
```
ai_game_12345.pck
├── metadata.json
├── games/
    └── asteroid_dodge/
        ├── main.gd
        ├── main.tscn
        └── assets/
            ├── asteroid.png
            ├── player.png
            └── (sfx references shared/)
```

**Metadata**:
```json
{
  "pack_id": "ai_game_12345",
  "version": "1.0.0",
  "generated_at": "2025-10-15T14:30:00Z",
  "user_prompt": "dodge falling asteroids",
  "ai_models": {
    "code": "claude-sonnet-4-5",
    "art": "gemini-2.5-flash"
  },
  "qa_results": {
    "monkey_test_crashes": 0,
    "win_attempts": 15,
    "wins": 8,
    "initial_winrate": 0.53
  },
  "games": [
    {
      "game_id": "asteroid_dodge",
      "instruction": "DODGE!",
      "difficulty": "medium"
    }
  ]
}
```

---

### Quality Assurance System

#### Automated Testing

**1. Monkey Testing** (Random Input Bot):
```gdscript
# Test harness
class MonkeyTester:
    func test_game(game_scene: String, iterations: int = 100) -> Dictionary:
        var crashes = 0
        var timeouts = 0

        for i in range(iterations):
            var game = load(game_scene).instantiate()
            add_child(game)

            # Random clicks at random times
            for j in range(50):
                await get_tree().create_timer(randf() * 0.1).timeout
                var pos = Vector2(randf() * 640, randf() * 640)
                _simulate_click(game, pos)

            # Wait for game to end
            await game.game_over

            if game.current_score < 0:  # Crash indicator
                crashes += 1

            game.queue_free()

        return {"crashes": crashes, "success_rate": 1.0 - (crashes / float(iterations))}
```

**2. Win Validation** (Heuristic Bot):
```gdscript
class WinValidator:
    func attempt_to_win(game_scene: String, max_attempts: int = 50) -> float:
        var wins = 0

        for i in range(max_attempts):
            var game = load(game_scene).instantiate()
            add_child(game)

            # Strategy: Click on all visible moving objects
            while game.game_active:
                var targets = _find_moving_objects(game)
                for target in targets:
                    _simulate_click(game, target.global_position)
                await get_tree().create_timer(0.1).timeout

            await game.game_over

            if game.current_score > 0:
                wins += 1

            game.queue_free()

        return float(wins) / float(max_attempts)
```

**3. Performance Check**:
```gdscript
func measure_fps(game_scene: String, duration: float = 10.0) -> float:
    var game = load(game_scene).instantiate()
    add_child(game)

    var frame_count = 0
    var elapsed = 0.0

    while elapsed < duration:
        await get_tree().process_frame
        frame_count += 1
        elapsed += get_process_delta_time()

    game.queue_free()
    return frame_count / elapsed
```

**Pass Criteria**:
- **Monkey test**: 0 crashes in 100 runs
- **Win validation**: At least 1 win in 50 attempts (>2% winrate)
- **Performance**: Average 60 FPS at 1.0x speed, >30 FPS at 5.0x speed

#### Winrate Monitoring

**Database Schema** (Supabase):
```sql
CREATE TABLE game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id VARCHAR NOT NULL,
    game_version VARCHAR NOT NULL,
    player_id VARCHAR,  -- Anonymous or user ID
    outcome VARCHAR NOT NULL,  -- 'win' or 'lose'
    score INT NOT NULL,
    speed_multiplier FLOAT NOT NULL,
    duration_ms INT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_game_sessions_game_id ON game_sessions(game_id);
CREATE INDEX idx_game_sessions_created_at ON game_sessions(created_at);

-- Aggregate winrate view
CREATE VIEW game_winrates AS
SELECT
    game_id,
    game_version,
    COUNT(*) as total_plays,
    SUM(CASE WHEN outcome = 'win' THEN 1 ELSE 0 END) as wins,
    (SUM(CASE WHEN outcome = 'win' THEN 1 ELSE 0 END)::FLOAT / COUNT(*)) as winrate,
    AVG(score) as avg_score,
    AVG(duration_ms) as avg_duration_ms
FROM game_sessions
WHERE created_at > NOW() - INTERVAL '7 days'  -- Last 7 days
GROUP BY game_id, game_version;
```

**Tracking Implementation**:
```gdscript
# In Director, after game ends
func _on_game_over(final_score: int):
    var session_data = {
        "game_id": current_game_id,
        "game_version": current_game.get_meta("version", "1.0.0"),
        "outcome": "win" if final_score > 0 else "lose",
        "score": final_score,
        "speed_multiplier": current_speed_multiplier,
        "duration_ms": int(game_timer * 1000)
    }

    # Send to Supabase
    _submit_session_data(session_data)
```

**Winrate Thresholds**:
| Winrate | Status | Action |
|---------|--------|--------|
| 0% | Critical | Trigger automated debugging immediately |
| 1-10% | Low | Flag for manual review |
| 30-70% | Ideal | No action (balanced difficulty) |
| 90-100% | Too Easy | Consider difficulty adjustment |

#### Automated Debugging

**Trigger**: Winrate = 0% after 20 player attempts

**Process**:
1. **Collect failure data**:
   - Player input logs (click positions, timing)
   - Game state snapshots (object positions, velocities)
   - Error messages from console
   - Video recording (optional, web builds can use MediaRecorder API)

2. **Send to Claude Code** with debug prompt:
```
Game ID: asteroid_dodge
Winrate: 0% (20 attempts, 0 wins)

Original prompt: "dodge falling asteroids"

Generated code:
[main.gd content]

Failure analysis:
- All 20 attempts ended with score = 0
- Average game duration: 1.8 seconds (should be 5 seconds)
- Player click positions: [(120, 340), (450, 200), ...]

Failure patterns detected:
1. Asteroids spawn too fast (interval = 0.1s)
2. Player ship moves too slowly (base speed = 50, should be ~200)
3. Speed multiplier not applied to player movement (line 87)
4. Collision detection triggers immediately on spawn

Player feedback: "Can't move fast enough to dodge!"

Task: Fix the code to make this game winnable at 1.0x speed (target 30-70% winrate).
Ensure speed_multiplier is applied correctly: velocity * speed_multiplier * delta
```

3. **Generate fixed version**
4. **Re-test** with automated suite
5. **Deploy** if tests pass (winrate >2%)
6. **Monitor** new winrate

**Iteration Limit**: Maximum 3 re-generation attempts
If still broken after 3 tries → archive game and log for human review

---

### Integration with DLC System

**Distribution Model**: AI-generated games packaged as DLC packs

**Curation Strategies**:

1. **Instant Delivery** (v3.0 phase 1):
   - User enters prompt in-game
   - Generate game (30-60 seconds)
   - Play immediately (no pack creation)
   - Cached locally for replay

2. **Daily Pack** (v3.0 phase 2):
   - AI generates 10 games overnight (cron job)
   - Automated QA filters to 6-8 passing games
   - Human curator plays and picks best 5
   - Package as free DLC pack
   - Publish at 8am daily

3. **Themed Packs** (v3.0 phase 3):
   - Generate 20 games with theme prompt ("space games")
   - Automated QA filters to 12 passing games
   - Human curator picks best 5-7
   - Package as premium DLC ($1.99)
   - Publish weekly

**Versioning**:
- Track `game_id` + `version` in database
- Players always get latest version
- Old versions archived for rollback if needed
- Version increments on each regeneration

---

### Continuous Improvement Loop

**Feedback Sources**:
1. **Winrate** (primary metric)
2. **Player ratings** (thumbs up/down after each game)
3. **Completion rate** (did player finish 5 seconds?)
4. **Repeat play rate** (same game loaded again via URL share?)
5. **Skip rate** (Tab key pressed immediately?)

**Improvement Strategies**:
| Issue | Strategy |
|-------|----------|
| Low winrate (<10%) | Easier difficulty: slower enemies, bigger player hitbox |
| High skip rate | More engaging objective, better visual feedback |
| Low ratings | Regenerate with refined prompt |
| High repeat play | Successful game—add to curated pack |

**Metrics Dashboard**:
```
┌──────────────────────────────────────────────────┐
│   AI Game Generator Dashboard                    │
├──────────────────────────────────────────────────┤
│ Today (Oct 15, 2025):                            │
│   Generated: 15 games                            │
│   QA Passed: 12 (80%)                            │
│   Published: 8 (curator selected)                │
│   Player Sessions: 1,243                         │
├──────────────────────────────────────────────────┤
│ Top Performing (7-day):                          │
│   1. asteroid_dodge (v3)   - 65% winrate ⭐      │
│   2. coin_collector (v1)   - 58% winrate         │
│   3. ghost_escape (v4)     - 52% winrate         │
├──────────────────────────────────────────────────┤
│ Needs Attention:                                 │
│   - puzzle_match (v1)      - 0% winrate 🔴       │
│     → Automated debugging in progress...         │
│   - space_shooter (v2)     - 8% winrate ⚠️       │
│     → Flagged for review                         │
└──────────────────────────────────────────────────┘
```

**Model Fine-Tuning** (future):
- Collect successful games as training examples
- Fine-tune Claude Code on project-specific patterns
- Improve first-pass quality over time (target: 90% QA pass rate)

---

### Infrastructure

**Generation Server**:
- **Technology**: Node.js or Python backend
- **Hosting**: Cloudflare Workers (serverless) or DigitalOcean Droplet
- **Endpoints**:
  ```
  POST /api/generate          # Start generation job
  GET  /api/jobs/{id}         # Check job status
  GET  /api/jobs/{id}/download # Download completed game
  GET  /api/jobs              # List recent jobs
  ```
- **Queuing**: Redis for job queue (handle concurrency)
- **Concurrency**: 5-10 simultaneous generations
- **Timeout**: 5 minutes per generation

**Storage**:
- **Generated games**: Cloudflare R2 or AWS S3 (same as DLC packs)
- **Metrics**: Supabase PostgreSQL
- **Assets**: CDN (Cloudflare)
- **Logs**: Cloudflare Logs or Papertrail

**Monitoring**:
- Generation success rate (target: >80%)
- Average generation time (target: <60 seconds)
- QA pass rate (target: >60%)
- Player satisfaction (thumbs up %)

**Cost Estimates** (per 1,000 games):
| Service | Cost |
|---------|------|
| Claude Code API (200k tokens avg) | ~$50 |
| Gemini 2.5 Flash (5 images per game) | ~$10 |
| Compute (validation, packaging) | ~$5 |
| Storage (50MB per game) | ~$2 |
| **Total** | **~$67 per 1,000 games** |

At 10 games/day = $2/day = $60/month operating cost

---

### Implementation Roadmap

**Phase 1: Prototype (4 weeks)**
- [ ] Build generation prompt pipeline
- [ ] Integrate Claude Code API (test with 10 manual prompts)
- [ ] Create prompt template with guidelines injection
- [ ] Generate 10 test games manually
- [ ] Human QA: measure quality (target: 6/10 playable)

**Phase 2: Automation (4 weeks)**
- [ ] Automated test harness (monkey + win validators)
- [ ] Static analysis pipeline (security checks)
- [ ] Asset generation (Gemini integration)
- [ ] Packaging system (create PCK bundles)
- [ ] Generate 100 games automatically
- [ ] Measure QA pass rate (goal: 60%+)

**Phase 3: Metrics & Debugging (3 weeks)**
- [ ] Winrate tracking (Supabase schema)
- [ ] Session data collection (Director integration)
- [ ] Automated debugging pipeline (failure logs → Claude → regenerate)
- [ ] Dashboard for monitoring (web app)
- [ ] Test iteration: 10 games with 0% winrate → debug → verify improvement

**Phase 4: Production Integration (3 weeks)**
- [ ] Connect to DLC system (v2.0 dependency)
- [ ] Daily pack generation (cron job: 10 games overnight)
- [ ] Human curation workflow (curator dashboard)
- [ ] Public beta: 1 AI-generated pack per week
- [ ] Collect player feedback

**Phase 5: Scale & Optimize (ongoing)**
- [ ] Model fine-tuning (use successful games as examples)
- [ ] Prompt optimization (A/B test different templates)
- [ ] Cost reduction (caching, batch processing)
- [ ] User-submitted prompts (with moderation)
- [ ] Increase to 3 AI packs per week

**Total Timeline**: 14 weeks (3.5 months) to v3.0 launch

**Dependencies**: v2.0 DLC system must be complete first

---

## Appendices

### API Reference

**LeaderboardManager**:
```gdscript
# Singleton access
LeaderboardManager.add_entry(name: String, score: int)
LeaderboardManager.is_top_10(score: int) -> bool
LeaderboardManager.get_leaderboard() -> Array[Dictionary]

# Signals
LeaderboardManager.leaderboard_loaded.connect(func(success): ...)
LeaderboardManager.score_submitted.connect(func(success, rank): ...)
```

**DLCManager** (v2.0):
```gdscript
# Singleton access
DLCManager.get_catalog() -> Array[Dictionary]
DLCManager.download_pack(pack_id: String)
DLCManager.is_pack_owned(pack_id: String) -> bool
DLCManager.get_pack_games(pack_id: String) -> Array[String]

# Signals
DLCManager.catalog_loaded.connect(func(success): ...)
DLCManager.pack_downloaded.connect(func(success, pack_id): ...)
DLCManager.download_progress.connect(func(pack_id, progress): ...)
```

---

### File Structure Reference

```
ai-microgames/
├── main.tscn                          # Entry point (Director scene)
├── project.godot                      # Godot project config
├── export_presets.cfg                 # Export settings (web, desktop)
├── shared/
│   ├── scripts/
│   │   ├── microgame.gd               # Base class (23 lines)
│   │   ├── director.gd                # Game loop (940 lines)
│   │   ├── leaderboard_manager.gd     # Supabase integration (163 lines)
│   │   ├── game_debugger.gd           # F3 debug panel (130 lines)
│   │   ├── dlc_manager.gd             # v2.0: DLC system (future)
│   │   └── ai_generator.gd            # v3.0: AI pipeline (future)
│   ├── assets/
│   │   ├── sfx_win.wav
│   │   ├── sfx_lose.wav
│   │   ├── sfx_countdown.wav
│   │   ├── sfx_game_start.wav
│   │   ├── sfx_game_over.wav
│   │   └── ... (23 SFX total)
│   ├── scenes/
│   │   └── dlc_browser.tscn           # v2.0: DLC UI (future)
│   └── ui_components/                 # Empty (reserved)
├── games/
│   ├── balloon_popper/
│   ├── box_pusher/
│   ├── flappy_bird/
│   ├── geo_stacker/
│   ├── infinite_jump2/
│   ├── loop_connect/
│   ├── minesweeper/
│   ├── money_grabber/
│   ├── space_invaders/
│   └── whack_a_mole/
├── .githooks/
│   └── pre-commit                     # Validates GAME_LIST sync
├── ARCHITECTURE.md                    # This document
├── GAME_REQUIREMENTS.md               # Game creation spec
├── VISUAL_STYLE_GUIDE.md              # Art direction
├── CLAUDE.md                          # Developer guide
└── README.md                          # Project overview
```

---

### Glossary

| Term | Definition |
|------|------------|
| **Microgame** | 5-second mini-game with binary pass/fail outcome |
| **Director** | Central orchestrator that manages game loop and progression |
| **Speed Multiplier** | Difficulty scaling factor (1.0-5.0x) that increases per win |
| **Game Pack** | Collection of 3-10 microgames distributed as DLC |
| **Winrate** | Percentage of play sessions ending with score > 0 |
| **PCK** | Godot's native archive format for bundling game resources |
| **Autoload** | Godot singleton that persists across scene changes |
| **WASM** | WebAssembly binary format used for web builds |

---

### Change Log

**v1.0** (Current - 2025-12):
- Initial release with 11 hand-crafted games
- Supabase leaderboard integration
- URL parameter sharing
- Tab key pause/resume
- F3 debug panel

**v2.0** (Planned - 2026 Q1):
- DLC system with built-in pack manager
- Downloadable game packs from CDN
- Payment integration (Stripe)
- Pack browser UI
- Security validation pipeline

**v3.0** (Planned - 2026 Q2):
- AI generation pipeline (Claude Code + Gemini)
- Automated QA testing
- Winrate monitoring and debugging
- Daily AI-generated packs
- Player feedback integration

---

## Cross-References

For detailed information, refer to:
- **Game creation specs**: [GAME_REQUIREMENTS.md](GAME_REQUIREMENTS.md)
- **Art direction**: [VISUAL_STYLE_GUIDE.md](VISUAL_STYLE_GUIDE.md)
- **Grid puzzle style**: [STYLE_GUIDE_GRID_PUZZLE.md](STYLE_GUIDE_GRID_PUZZLE.md)
- **Platformer style**: [STYLE_GUIDE_PLATFORMER.md](STYLE_GUIDE_PLATFORMER.md)
- **Developer workflow**: [CLAUDE.md](CLAUDE.md)
- **Project overview**: [README.md](README.md)

Example code references:
- Speed multiplier pattern: [`games/money_grabber/main.gd:87`](games/money_grabber/main.gd#L87)
- Director game loading: [`shared/scripts/director.gd:550`](shared/scripts/director.gd#L550)
- Leaderboard submission: [`shared/scripts/leaderboard_manager.gd:135`](shared/scripts/leaderboard_manager.gd#L135)

---

**Document Version**: 2.0
**Last Updated**: December 2025
**Maintainer**: Development Team
