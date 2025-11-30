# Visual Style Guide: AI Microgames

## 1. Visual Identity: "Digital Marker Chaos"
We embrace a **"Digital Marker / Pop Art"** aesthetic (reminiscent of *WarioWare DIY* or *Scribblenauts*).
*   **Why?** The thick outlines and flat colors effectively hide AI "hallucinations." If a line is wobbly, it looks like a stylistic choice (a doodle) rather than a glitch.
*   **Vibe:** High energy, irreverent, and readable on mobile.

## 2. Prompt Strategy (For AI Generator)
Append these tokens to **every** generation request to force consistency:

> **"vector art style, thick distinct black outlines, flat vibrant colors, no gradients, white background, sticker art, minimal details, 2D game asset"**

**Negative Prompt (if available):**
> "photorealistic, 3d render, shading, shadows, gradients, blur, noise, text, watermark"

## 3. UI Overlay
The UI must float above the chaotic game world. We will use a **"Sticker"** aesthetic.
*   **Font**: Heavy/Black weight (e.g., Impact, Anton).
*   **Style**: White text with a **heavy 4px Black Stroke**.
*   **Colors**:
    *   **Action Pink (#FF0055)**: Urgent elements (Timer).
    *   **Electric Cyan (#00F0FF)**: Positive feedback (Score).
    *   **Tape Yellow (#FFEB3B)**: Background strips for instructions (e.g., "DODGE!").

## 4. Pipeline Requirement
*   **Post-Process**: All AI output must go through a **Background Removal** step (e.g., `rembg`) to turn the "white background" into transparency before being used as a sprite.
