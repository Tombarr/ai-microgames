# Godot Microgames Platform

An AI-generated microgaming platform built with Godot 4.

## 🎮 Available Games

### [Cyber Cleanup](games/micro_sokoban/README.md)

_Contain the radioactive core before the meltdown begins!_

- **Genre:** Puzzle / Sokoban
- **Status:** Playable
- **Controls:** Arrow Keys

## 🚀 How to Play

### In Godot Editor

1. Open this project in Godot 4.5+.
2. Press **F5** (Play) to start the default game (Cyber Cleanup).

### Web Export (HTML5)

This project is pre-configured for Web export.

1. Ensure you have **Export Templates** installed for Godot 4.5.1.
   - Go to `Editor > Manage Export Templates` to install them.
2. Click `Project > Export...`.
3. Select the **Web** preset.
4. Click **Export Project** and save to `builds/web/index.html`.
5. Run the generated HTML file in a local web server (e.g., `python3 -m http.server` in the build
   directory).

## ⚙️ Project Configuration

- **Renderer:** Compatibility (OpenGL ES 3.0 / WebGL 2.0) for maximum web compatibility.
- **Resolution:** 640x640 (Viewport Stretch) optimized for pixel art.
- **Main Scene:** `games/micro_sokoban/main.tscn`
