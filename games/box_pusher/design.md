# Game Design Document: Cyber Cleanup

## 1. Overview

**Title:** Cyber Cleanup **Internal Name:** `micro_sokoban` **Theme:** Sci-Fi / Cyberpunk
**Duration:** 5-10 seconds **Tagline:** Contain the Core!

## 2. Objective

Push the unstable **Radioactive Core** (Box) into the **Containment Zone** (Target) before the time
runs out.

## 3. Controls

- **D-Pad / Arrow Keys:** Move Hazmat Bot.
- **Movement:** Grid-based movement. pushing the box moves it one tile if the space behind is empty.

## 4. Visual Style

- **Perspective:** Top-down 2D pixel art.
- **Palette:** Neon green, dark grey, industrial yellow.
- **Vibe:** Urgent, industrial, hazardous.

## 5. Assets Required

### Sprites

- `player.png`: Hazmat Bot (Idle/Move animations optional, static ok for prototype).
- `box.png`: Radioactive Core (Glowing green pulsing effect).
- `target.png`: Containment Zone (Floor marking with hazard stripes).
- `wall.png`: Metal plating / dark pipes.
- `floor.png`: Grated metal floor.

### Audio

- `sfx_move.wav`: Robotic servo step.
- `sfx_push.wav`: Heavy metallic scrape.
- `sfx_win.wav`: Airlock sealing sound + positive chime.
- `sfx_lose.wav`: Alarm / Power down.

## 6. Level Design

**Grid Size:** 5x5 **Moves to Solve:** 5

**Layout:**

```text
#####
#T  #
# B #
#  P#
#####
```

**Legend:**

- `#`: Wall
- `T`: Target (Containment Zone)
- `B`: Box (Radioactive Core)
- `P`: Player (Hazmat Bot)
- ` `: Empty Floor

**Solution:**

1. Move **Left**
2. Push **Up**
3. Move **Right**
4. Move **Up**
5. Push **Left** -> **WIN**
