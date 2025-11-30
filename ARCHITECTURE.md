# Mobile Web Architecture: AI Microgame Platform

## Executive Summary

This document outlines the technical architecture for the **AI Microgame Platform**, a
"WarioWare-style" infinite arcade where 5-second microgames are generated on-demand by Artificial
Intelligence. The system leverages Godot 4.5.1 for the client-side runtime and a Serverless Backend
(Cloudflare Workers + AI Models) for the generation pipeline.

---

## 1. Generation Pipeline (Server-Side)

We implement a **Server-Side Generation Strategy** to ensure quality, security, and caching.

### Component: `GameGenerator` (Backend Service)

- **Trigger**: User prompt (e.g., "Dodge the falling asteroids") or automated daily challenge.
- **Orchestration**:
  1.  **Code Generation (LLM)**: **Google Gemini 1.5 Flash** (via AI Studio) generates a single
      GDScript file extending `res://shared/scripts/microgame_ai.gd`.
      - _Constraint_: The script must build its scene programmatically in `_ready()` using the
        `MicrogameAI` API.
  2.  **Asset Generation**:
      - **Visuals**: **Gemini 1.5 Flash** (Text-to-SVG) for instant vector graphics, or **Imagen 3**
        (via Vertex AI/Gemini API) for raster sprites.
      - **Audio**: Selection from a pre-defined SFX library to minimize generation latency.
  3.  **Validation**: Automated static analysis scans the generated GDScript for banned keywords
      (`OS`, `FileAccess`, `ProjectSettings`).
  4.  **Packaging**: Assets and scripts are bundled into a ZIP file or Godot PCK format.
  5.  **Storage**: The bundle is uploaded to **Cloudflare R2**.

## 2. Code Security Strategy

Running AI code carries risks. We implement a "Defense in Depth" approach:

- **Layer 1: Pre-Computation Filtering (Server)**: Regex/AST parser checks for banned keywords
  (`OS`, `FileAccess`, `DirAccess`, `GDExtension`).
- **Layer 2: Browser Sandbox (Client)**: Godot Web export runs inside the browser's WASM container.
- **Layer 3: Runtime Isolation (Godot)**: AI games are instantiated as child nodes. The
  `MicrogameAI` base class manages the lifecycle and can terminate misbehaving instances.

## 3. Frontend Architecture (Godot Client)

### 3.1 Project Structure

```
/microgame-web/
├── godot-project/
│   ├── scripts/
│   │   ├── microgame.gd        # Abstract base
│   │   ├── microgame_ai.gd     # AI-specific base (API surface)
│   │   ├── dynamic_loader.gd   # NEW: Handles ZIP/PCK loading
│   │   └── ...
│   └── scenes/
│       └── ...
```

### 3.2 Dynamic Loader

The client fetches generated bundles from the CDN.

1.  **Fetch**: HTTP Request to `https://api.microgamemania.com/games/{id}/bundle.zip`.
2.  **Extract**: Use `ZIPReader` to read contents in memory.
3.  **Load**: Create a generic `GDScript` instance, set `source_code`, and `reload()`.
4.  **Instantiate**: Add to the scene tree.

### 3.3 Director Pattern (Game Loop)

The `Director` is the central orchestrator node in the Godot client, managing the "WarioWare"
infinite loop flow.

- **Responsibility**:
  1.  **Pick Game**: Selects the next microgame from the queue (pre-fetched bundles).
  2.  **Transition**: Displays the "Instruction" screen (e.g., "DODGE!", "CATCH!").
  3.  **Run**: Instantiates the microgame and starts the 5-second timer.
      - _Speed Up_: As the score increases, the Director increases the global `Engine.time_scale`.
  4.  **Evaluate**: Listens for the `game_ended(win: bool)` signal from the microgame.
      - **Pass**: Play "Win" jingle, increment score, load next game.
      - **Fail**: Play "Lose" jingle, decrement life.
  5.  **Timeout**: If 5s elapses without a signal, treats as immediate Failure (or Success depending
      on game type, default is Fail).

## 4. Asset Pipeline (Visual Style)

- **Style**: "Digital Marker Chaos" / Pop Art.
- **Format**: 2D Sprites (PNG/WebP) or Vector (SVG).
- **Prompt Strategy**: "vector art style, thick distinct black outlines, flat vibrant colors, no
  gradients, white background, sticker art".

## 5. Deployment Strategy

- **Frontend**: Cloudflare Pages (Godot HTML5 export).
- **Backend**: Cloudflare Workers (API & Orchestrator).
- **Storage**: Cloudflare R2 (Generated Game Bundles & Assets).
- **Database**: Cloudflare KV (Metadata: Prompt -> Bundle URL).

## 6. Risk Assessment

- **Risk**: AI generates unplayable games.
  - _Mitigation_: "Monkey Tester" automated validation (fuzzing inputs) before serving to users.
    User voting system ("Fun" vs "Broken") to prune bad seeds.
- **Risk**: Generation latency.
  - _Mitigation_: "Forging" UI (loading screen) with entertaining text. Pre-generate a "Daily Mix"
    so users don't always have to wait.

### 3.3 Director Pattern (Game Loop)

The `Director` is the central orchestrator node in the Godot client, managing the "WarioWare"
infinite loop flow.

- **Responsibility**:
  1.  **Pick Game**: Selects the next microgame from the queue (pre-fetched bundles).
  2.  **Transition**: Displays the "Instruction" screen (e.g., "DODGE!", "CATCH!").
  3.  **Run**: Instantiates the microgame and starts the 5-second timer.
      - _Speed Up_: As the score increases, the Director increases the global `Engine.time_scale`
        and passes `speed_multiplier` to the microgame.
  4.  **Evaluate**: Listens for the `game_over(score)` signal from the microgame.
      - **Pass**: Play "Win" jingle, increment score, load next game.
      - **Fail**: Play "Lose" jingle, decrement life.
  5.  **Timeout**: If 5s elapses without a signal, treats as immediate Failure (or Success depending
      on game type, default is Fail).
