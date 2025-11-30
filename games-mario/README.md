# Microgames

This directory contains the individual microgames. Each game should be in its own folder.

## Creating a new Microgame

1. Create a new folder here (e.g. `my_cool_game`).
2. Create a main scene for your game inside that folder (e.g. `main.tscn`).
3. Create a script for your main scene that extends `Microgame` (found in `res://shared/scripts/microgame.gd`).

## Example Structure

```
games/
  my_cool_game/
    main.tscn
    game_logic.gd (extends Microgame)
    assets/
      sprite.png
```
