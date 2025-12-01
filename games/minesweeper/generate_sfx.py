#!/usr/bin/env python3
"""Generate sound effects for Minesweeper game."""

import sys
import os

# Add parent directory to path to import shared generator
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../shared/asset_generators'))

from generate_sfx_hq import generate_game_sounds

def main():
    output_dir = os.path.join(os.path.dirname(__file__), 'assets')
    os.makedirs(output_dir, exist_ok=True)
    
    print("Generating Minesweeper sound effects...")
    
    # Generate sounds using the shared generator
    # Use the CLI interface to generate specific sounds
    import subprocess
    import sys
    
    gen_script = os.path.join(os.path.dirname(__file__), '../../shared/asset_generators/generate_sfx_hq.py')
    
    # Generate: button press (reveal), collect_mid (goal), explosion (bomb)
    subprocess.run([
        sys.executable, gen_script,
        '--game', 'minesweeper',
        '--sounds', 'button', 'collect_mid', 'explosion',
        '--output', output_dir
    ])
    
    # Rename to match our naming convention
    os.rename(os.path.join(output_dir, 'sfx_button.wav'), 
              os.path.join(output_dir, 'sfx_reveal.wav'))
    os.rename(os.path.join(output_dir, 'sfx_collect_mid.wav'),
              os.path.join(output_dir, 'sfx_goal.wav'))
    os.rename(os.path.join(output_dir, 'sfx_explosion.wav'),
              os.path.join(output_dir, 'sfx_explode.wav'))
    
    print("\nAll sound effects generated successfully!")
    print("Note: Game also uses shared sfx_win.wav and sfx_lose.wav")

if __name__ == '__main__':
    main()
