# Changelog

All notable changes to AI Microgames are documented in this file.

---

## [1.1.0] - 2025-12-05

### Visual Overhaul
- **Upgraded graphics for 5 games** to match the quality standard set by Infinite Jump 2:
  - **Balloon Popper**: New 3D-shaded balloons with highlights, knots, and curved strings. Added sky gradient background with decorative clouds.
  - **Don't Touch**: Added warning triangle danger signs, yellow/black hazard stripe borders, improved button styling with 3D depth effects.
  - **Flappy Bird**: Redesigned bird with expressive eye, animated wing, and orange beak. New pipe visuals with highlight/shadow strips. Added ground with grass texture and background clouds.
  - **Money Grabber**: New detailed hand with fingers and highlights. Faceted gem visuals with sparkle effects and value indicators. Dark cave background with treasure chest.
  - **Space Invaders**: Redesigned player ship with cockpit, hull highlights, and engine glow. New octopus-style aliens with eyes, eyebrows, tentacles, and fangs. Laser bolts with glow effects. Starfield background.

### Bug Fixes
- **Fixed leaderboard not working on web builds (itch.io)**
  - Root cause: Godot web exports can't decompress gzip-compressed responses (Supabase/Cloudflare ignores `Accept-Encoding: identity` header)
  - Solution: Implemented JavaScript fetch API bridge for web builds - browser handles gzip decompression natively
  - Native builds continue using Godot's HTTPRequest for compatibility

### Quality of Life
- **Pause functionality**: Press Tab to pause game and view leaderboard mid-session
- **Resume works correctly**: Leaderboard displays during pause, game resumes properly

---

## [1.0.0] - 2025-11-30

### Initial Release
- **11 hand-crafted microgames**:
  - Balloon Popper
  - Box Pusher
  - Dodge Bullets
  - Don't Touch
  - Flappy Bird
  - Infinite Jump 2
  - Micro Sokoban
  - Money Grabber
  - Sample AI Game
  - Space Invaders
  - Whack-a-Mole

### Core Features
- **WarioWare-style gameplay**: 5-second microgames with pass/fail outcomes
- **Progressive difficulty**: Speed multiplier increases from 1.0x to 5.0x
- **Lives system**: Start with 3 lives, lose one per failed game
- **Director orchestration**: Automatic game discovery, random selection, smooth transitions

### Online Features
- **Global leaderboard**: Top 10 scores stored in Supabase
- **Score submission**: Enter 3-character name for high scores
- **URL sharing**: Share direct links to specific games via `?game=` parameter
- **Web Share API**: Native share dialog on supported devices

### Technical
- **Platform**: Godot 4.5.1 (GDScript 2.0)
- **Resolution**: 640x640 pixels
- **Deployment**: Web (HTML5/WASM) on itch.io
- **Backend**: Supabase (PostgreSQL + REST API)

---

## Version History Summary

| Version | Date       | Highlights                                      |
|---------|------------|-------------------------------------------------|
| 1.1.0   | 2025-12-05 | Visual overhaul, web leaderboard fix, Tab pause |
| 1.0.0   | 2025-11-30 | Initial release with 11 games                   |
