#!/usr/bin/env python3
"""
Generate individual HTML pages for each game with OpenGraph and Twitter meta tags.

This script creates subdirectories for each game in the build output, each containing
an index.html with game-specific meta tags for social sharing. All pages load the
same Godot WASM bundle but pre-set the ?game= parameter.

Usage:
    python3 scripts/generate_game_pages.py [--base-url URL] [--games-dir DIR] [--build-dir DIR]

Environment variables:
    BASE_URL: Base URL for the deployed site (default: https://tombarr.github.io/ai-microgames)
    BUILD_DIR: Build output directory (default: builds/web)
    GAMES_DIR: Directory containing games (default: games)
    SITE_NAME: Site name for meta tags (default: Microgames)
"""

import argparse
import html
import json
import os
import re
import shutil
from pathlib import Path


# Default configuration - can be overridden by environment variables or CLI args
DEFAULT_BASE_URL = os.environ.get("BASE_URL", "https://tombarr.github.io/ai-microgames")
DEFAULT_GAMES_DIR = os.environ.get("GAMES_DIR", "games")
DEFAULT_BUILD_DIR = os.environ.get("BUILD_DIR", "builds/web")
DEFAULT_SITE_NAME = os.environ.get("SITE_NAME", "Microgames")

# Default metadata for games without metadata.json
DEFAULT_META = {
    "title": "Microgame",
    "description": "A fast-paced 5-second microgame challenge! Test your reflexes and skills.",
    "og_image": None,
    "tags": ["microgame", "arcade", "quick"]
}


def get_game_metadata(games_dir: Path, game_id: str) -> dict:
    """Load metadata.json for a game, falling back to defaults."""
    meta_path = games_dir / game_id / "metadata.json"
    meta = DEFAULT_META.copy()
    
    if meta_path.exists():
        try:
            with open(meta_path, encoding="utf-8") as f:
                loaded = json.load(f)
                meta.update(loaded)
        except (json.JSONDecodeError, IOError) as e:
            print(f"  Warning: Could not load {meta_path}: {e}")
    else:
        # Generate default title from game_id
        meta["title"] = game_id.replace("_", " ").title()
    
    return meta


def escape_meta_content(text: str) -> str:
    """Escape text for use in HTML meta tag content attributes."""
    return html.escape(text, quote=True)


def generate_meta_tags(game_id: str, meta: dict, base_url: str, site_name: str) -> str:
    """Generate OpenGraph and Twitter meta tags for a game."""
    game_url = f"{base_url}/{game_id}/"
    
    # Determine OG image URL
    if meta.get("og_image"):
        og_image_url = f"{base_url}/{game_id}/og_image.png"
    else:
        og_image_url = f"{base_url}/og_image.png"
    
    title = escape_meta_content(meta["title"])
    description = escape_meta_content(meta["description"])
    full_title = f"{title} - {site_name}"
    
    return f'''
    <!-- Primary Meta Tags -->
    <title>{full_title}</title>
    <meta name="title" content="{full_title}">
    <meta name="description" content="{description}">

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{game_url}">
    <meta property="og:title" content="{title}">
    <meta property="og:description" content="{description}">
    <meta property="og:image" content="{og_image_url}">
    <meta property="og:site_name" content="{site_name}">

    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:url" content="{game_url}">
    <meta name="twitter:title" content="{title}">
    <meta name="twitter:description" content="{description}">
    <meta name="twitter:image" content="{og_image_url}">
'''


def generate_game_script(game_id: str) -> str:
    """Generate JavaScript to set the game parameter before Godot loads."""
    return f'''
    <script type="text/javascript">
        // Pre-set game parameter for this permalink
        (function() {{
            if (!window.location.search.includes('game=')) {{
                var url = new URL(window.location);
                url.searchParams.set('game', '{game_id}');
                window.history.replaceState({{}}, '', url);
            }}
        }})();
    </script>
'''


def generate_game_page(game_id: str, base_html: str, games_dir: Path, 
                       base_url: str, site_name: str) -> str:
    """Generate a complete HTML page for a specific game."""
    meta = get_game_metadata(games_dir, game_id)
    meta_tags = generate_meta_tags(game_id, meta, base_url, site_name)
    game_script = generate_game_script(game_id)
    
    # Insert meta tags after <head>
    modified_html = base_html.replace("<head>", f"<head>{meta_tags}", 1)
    
    # Insert game script before </head>
    modified_html = modified_html.replace("</head>", f"{game_script}</head>", 1)
    
    return modified_html


def update_asset_paths(html_content: str) -> str:
    """Update relative asset paths to point to parent directory.
    
    Since game pages are in subdirectories (e.g., /loop_connect/index.html),
    we need to update paths to the shared WASM/JS/PCK files.
    """
    # Patterns to update: src="index.js" -> src="../index.js"
    # Also handle: "index.wasm", "index.pck", "index.worker.js", etc.
    
    # Update script src attributes
    html_content = re.sub(
        r'src="(index\.[^"]+)"',
        r'src="../\1"',
        html_content
    )
    
    # Update any other index.* references (like in JavaScript strings)
    # Be careful not to double-replace
    html_content = re.sub(
        r'"(index\.(?:wasm|pck|worker\.js|audio\.worklet\.js))"',
        r'"../\1"',
        html_content
    )
    
    # Update favicon if present
    html_content = re.sub(
        r'href="(favicon[^"]*)"',
        r'href="../\1"',
        html_content
    )
    
    # Update icon.svg or icon.png
    html_content = re.sub(
        r'href="(icon\.[^"]+)"',
        r'href="../\1"',
        html_content
    )
    
    return html_content


def discover_games(games_dir: Path) -> list[str]:
    """Discover all games that have a main.tscn file."""
    games = []
    if not games_dir.exists():
        return games
    
    for item in games_dir.iterdir():
        if item.is_dir() and (item / "main.tscn").exists():
            games.append(item.name)
    
    return sorted(games)


def main():
    parser = argparse.ArgumentParser(
        description="Generate individual HTML pages for each game with OG/Twitter meta tags.",
        epilog="Environment variables BASE_URL, BUILD_DIR, GAMES_DIR, and SITE_NAME can also be used."
    )
    parser.add_argument(
        "--base-url",
        default=DEFAULT_BASE_URL,
        help=f"Base URL for the site (env: BASE_URL, default: {DEFAULT_BASE_URL})"
    )
    parser.add_argument(
        "--games-dir",
        default=DEFAULT_GAMES_DIR,
        help=f"Directory containing games (env: GAMES_DIR, default: {DEFAULT_GAMES_DIR})"
    )
    parser.add_argument(
        "--build-dir",
        default=DEFAULT_BUILD_DIR,
        help=f"Build output directory (env: BUILD_DIR, default: {DEFAULT_BUILD_DIR})"
    )
    parser.add_argument(
        "--site-name",
        default=DEFAULT_SITE_NAME,
        help=f"Site name for meta tags (env: SITE_NAME, default: {DEFAULT_SITE_NAME})"
    )
    args = parser.parse_args()
    
    games_dir = Path(args.games_dir)
    build_dir = Path(args.build_dir)
    base_url = args.base_url.rstrip("/")
    
    # Validate paths
    if not games_dir.exists():
        print(f"Error: Games directory not found: {games_dir}")
        return 1
    
    base_html_path = build_dir / "index.html"
    if not base_html_path.exists():
        print(f"Error: Base HTML not found: {base_html_path}")
        return 1
    
    # Read base HTML
    print(f"Reading base HTML from: {base_html_path}")
    with open(base_html_path, encoding="utf-8") as f:
        base_html = f.read()
    
    # Discover games
    games = discover_games(games_dir)
    if not games:
        print(f"Warning: No games found in {games_dir}")
        return 0
    
    print(f"Found {len(games)} games: {', '.join(games)}")
    print(f"Base URL: {base_url}")
    print()
    
    # Track missing images
    missing_images = []
    
    # Generate pages for each game
    for game_id in games:
        print(f"Generating page for: {game_id}")
        
        # Create game directory
        game_build_dir = build_dir / game_id
        game_build_dir.mkdir(exist_ok=True)
        
        # Generate HTML with updated paths
        game_html = generate_game_page(
            game_id, base_html, games_dir, base_url, args.site_name
        )
        game_html = update_asset_paths(game_html)
        
        # Write HTML
        html_path = game_build_dir / "index.html"
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(game_html)
        print(f"  Created: {html_path}")
        
        # Copy OG image if exists
        og_image_src = games_dir / game_id / "assets" / "og_image.png"
        if og_image_src.exists():
            og_image_dst = game_build_dir / "og_image.png"
            shutil.copy(og_image_src, og_image_dst)
            print(f"  Copied: og_image.png")
        else:
            missing_images.append(game_id)
            print(f"  Warning: No og_image.png found for {game_id}")
    
    print()
    print(f"Generated {len(games)} game pages")
    
    if missing_images:
        print()
        print("Missing og_image.png files:")
        for game_id in missing_images:
            print(f"  - games/{game_id}/assets/og_image.png")
        print()
        print("These games will use the default OG image.")
    
    return 0


if __name__ == "__main__":
    exit(main())
