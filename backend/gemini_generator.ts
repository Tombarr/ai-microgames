/**
 * Gemini Generator Client
 * Handles interaction with Google's Gemini API for both Code and Asset generation.
 * Designed for Cloudflare Workers (Edge Runtime).
 */

export interface GenerationRequest {
  prompt: string;
  type: 'code' | 'image';
  context?: string; // Optional context for the game
}

export interface GeneratedAsset {
  type: 'code' | 'image';
  data: string; // Source code or Base64 image/SVG
  contentType: string;
}

export class GeminiGenerator {
  private apiKey: string;
  private baseUrl: string = "https://generativelanguage.googleapis.com/v1beta";

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  /**
   * Orchestrates the generation based on request type
   */
  async generate(req: GenerationRequest): Promise<GeneratedAsset> {
    if (req.type === 'code') {
      return this.generateCode(req.prompt, req.context);
    } else {
      return this.generateImage(req.prompt);
    }
  }

  /**
   * Generates GDScript using Gemini 1.5 Flash (Optimized for speed/latency)
   */
  private async generateCode(prompt: string, context?: string): Promise<GeneratedAsset> {
    const model = "models/gemini-1.5-flash";
    const url = `${this.baseUrl}/${model}:generateContent?key=${this.apiKey}`;
    
    const systemInstruction = `
      You are an expert Godot 4.x Game Developer.
      Generate a single GDScript file for a microgame.
      The script must extend 'res://shared/scripts/microgame_ai.gd'.
      Do NOT use Markdown formatting. Output RAW code only.
      Implement the '_ready()' function to build the scene programmatically.
      Constraint: Game must end within 5 seconds using 'end_game(true/false)'.
      Constraint: Screen resolution is strictly 640x640. Use 'get_viewport_rect().size' but assume it's 640x640.
    `;

    const fullPrompt = `
      ${context ? `Context: ${context}\n` : ''}
      Task: Create a microgame script for: "${prompt}".
      Ensure all nodes are created via code (TextureRect, Area2D, etc.).
      Do not assume external assets exist; use placeholder ColorRects or generated textures.
    `;

    const payload = {
      contents: [{
        parts: [{ text: fullPrompt }]
      }],
      systemInstruction: {
        parts: [{ text: systemInstruction }]
      },
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 2000,
        responseMimeType: "text/plain"
      }
    };

    const response = await this.fetchGemini(url, payload);
    const code = response.candidates?.[0]?.content?.parts?.[0]?.text || "";

    // Basic cleanup if markdown is still present
    const cleanCode = code.replace(/\`\`\`gdscript/g, '').replace(/\`\`\`/g, '').trim();

    return {
      type: 'code',
      data: cleanCode,
      contentType: 'text/x-gdscript'
    };
  }

  /**
   * Generates Assets using Gemini 1.5 Flash (Text-to-SVG)
   * This is highly effective for "Digital Marker" style 2D games and very fast.
   */
  private async generateImage(prompt: string): Promise<GeneratedAsset> {
    const model = "models/gemini-1.5-flash";
    const url = `${this.baseUrl}/${model}:generateContent?key=${this.apiKey}`;
    
    const svgPrompt = `
      Generate a minimal SVG string for a game asset.
      Style: Digital Marker, thick black outlines, vibrant colors.
      Object: ${prompt}.
      Output ONLY the raw <svg>...</svg> string. No markdown.
    `;

    const payload = {
      contents: [{ parts: [{ text: svgPrompt }] }]
    };

    const response = await this.fetchGemini(url, payload);
    const svgData = response.candidates?.[0]?.content?.parts?.[0]?.text || "";
    
    // Extract SVG from response
    let cleanSvg = svgData;
    if (cleanSvg.includes('<svg')) {
      cleanSvg = cleanSvg.slice(cleanSvg.indexOf('<svg'), cleanSvg.lastIndexOf('</svg>') + 6);
    }

    return {
      type: 'image',
      data: cleanSvg,
      contentType: 'image/svg+xml'
    };
  }

  private async fetchGemini(url: string, payload: any): Promise<any> {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`Gemini API Error ${res.status}: ${errorText}`);
    }

    return await res.json();
  }
}
