# Game Design Document: GeoStacker

## 1. Game Title

**GeoStacker**

## 2. Objective

The player must stack a set of geometric shapes to reach a designated height line within the
5-second time limit. The tower of shapes must be stable and not collapse before the time is up.

**Win Condition:** The highest point of the stacked shapes is above the target height line when the
timer ends. **Loss Condition:** The tower collapses, or the highest point of the stacked shapes is
below the target height line when the timer ends.

## 3. Control Scheme

- **Input:** Mouse click/drag or Touch/drag.
- **Action:**
  - Click and drag a shape to move it.
  - Release the mouse button/touch to drop the shape.
  - A single tap or press of the 'R' key will rotate the current shape 90 degrees clockwise.

## 4. Gameplay Loop

1.  The game starts, and a random layout of 2-3 geometric shapes is presented to the player at the
    bottom of the screen.
2.  A horizontal "target height" line is displayed on the screen.
3.  The player has 5 seconds to pick up the shapes and stack them on top of each other.
4.  If the player builds a stable tower that reaches the target height within the time limit, they
    win.
5.  If the tower collapses or doesn't reach the height, they lose.
6.  A simple win or lose animation is played at the end.

## 5. Visual Style

- **Style:** "Digital Marker Chaos"
- **Description:** A minimalist and vibrant 2D art style. The shapes are filled with bright, solid
  colors, and have a slightly imperfect, hand-drawn outline, resembling a marker drawing. The
  background is a solid, contrasting color that changes with each new game. The UI elements (timer,
  height line) are clean and unobtrusive.

## 6. Required Assets

### Sprites:

- `square.png`: A simple square shape.
- `rectangle.png`: A rectangle shape.
- `triangle.png`: An equilateral triangle shape.
- `trapezoid.png`: A trapezoid shape.
- `target_line.png`: A simple dashed or solid line.
- `win_effect.png`: A particle sprite for the win animation (e.g., a star or confetti).
- `lose_effect.png`: A particle sprite for the lose animation (e.g., a dust cloud or crack).

### Sound Effects:

- `sfx_place.wav`: A soft "thud" sound when a shape is placed.
- `sfx_rotate.wav`: A "swoosh" sound for shape rotation.
- `sfx_win.wav`: A cheerful, short musical chord or chime.
- `sfx_lose.wav`: A short, descending musical tone or a crumbling sound. -g

## 7. Technical Requirements

- The main game scene script will extend `res://shared/scripts/microgame.gd`.
- The game will feature 8 pre-defined layouts with different combinations of shapes and target
  heights. A layout will be chosen randomly at the start of each game.
