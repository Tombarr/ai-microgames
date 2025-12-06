extends Microgame

# Game state
enum MoleState { HIDDEN, RISING, VISIBLE, HIDING, HIT }

var game_ended: bool = false
var time_elapsed: float = 0.0
var moles_hit: int = 0
const MOLES_TO_WIN: int = 3  # Must hit 3 moles to win

# Color Palette (PICO-8 inspired with warmer grass)
var COLOR_PALETTE = {
	"grass_dark": Color("#5b9943"),    # Warmer darker green
	"grass_light": Color("#a7db8d"),   # Warmer lighter green
	"grass_mid": Color("#7fc75e"),     # Warmer mid green
	"brown": Color("#ab5236"),
	"brown_dark": Color("#5f574f"),
	"brown_light": Color("#c2c3c7"),
	"pink": Color("#ff77a8"),
	"white": Color("#fff1e8"),
	"black": Color("#1d2b53"),
	"hole_dark": Color("#1d2b53"),
	"hole_mid": Color("#5f574f"),
	"hole_light": Color("#ab5236"),
	"ui_bg": Color("#29adff"),
	"ui_border": Color("#1d2b53"),
	"ui_text": Color("#fff1e8"),
}

# Textures
var grass_texture: ImageTexture
var hole_texture: ImageTexture
var mole_texture: ImageTexture
var mole_hit_texture: ImageTexture

# Mole data
var moles: Array = []
const GRID_SIZE: int = 3
const HOLE_SPACING: float = 150.0
const GRID_OFFSET: Vector2 = Vector2(170, 200)

# Mole timing
var mole_spawn_timer: float = 0.0
var spawn_interval: float = 0.0

func _ready():
	instruction = "WHACK 3!"
	super._ready()

	# Initialize hit sound
	var sfx_hit = AudioStreamPlayer.new()
	sfx_hit.name = "sfx_hit"
	sfx_hit.stream = load("res://shared/assets/sfx_button_press.wav")
	add_child(sfx_hit)

	# Calculate spawn interval to ensure at least 5 moles spawn
	# Need to spawn 5 moles within time_limit
	# Each mole takes time to: rise (0.3s) + be visible (0.8-1.5s avg 1.15s) + hide (0.3s)
	# Average mole lifecycle: ~1.75 seconds
	# To guarantee 5 moles can be hit, we need good spacing
	# Spawn interval = (time_limit - buffer) / 5
	var buffer = 1.0  # Give player 1 second buffer at the end
	spawn_interval = max(0.8, (time_limit - buffer) / MOLES_TO_WIN)
	
	# Generate all textures
	_create_grass_texture()
	_create_hole_texture()
	_create_mole_texture()
	_create_mole_hit_texture()
	
	# Create background
	_create_background()
	
	# Create mole grid
	_create_mole_grid()

# Helper function to create image from ASCII art
func _create_image_from_ascii(art: Array, color_map: Dictionary, scale: int = 4) -> Image:
	var height = art.size()
	var width = art[0].length() if height > 0 else 0
	var img = Image.create(width * scale, height * scale, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background
	
	for y in range(height):
		for x in range(width):
			var char = art[y][x]
			if char in color_map:
				var color = color_map[char]
				# Draw scaled pixel
				for sy in range(scale):
					for sx in range(scale):
						img.set_pixel(x * scale + sx, y * scale + sy, color)
	
	return img

func _create_grass_texture():
	var img = Image.create(640, 640, false, Image.FORMAT_RGBA8)
	img.fill(COLOR_PALETTE.grass_dark)
	
	# Add varied grass texture using pattern
	for y in range(640):
		for x in range(640):
			var noise = (x * 7 + y * 13) % 17
			if noise < 3:
				img.set_pixel(x, y, COLOR_PALETTE.grass_light)
			elif noise < 6:
				img.set_pixel(x, y, COLOR_PALETTE.grass_mid)
	
	grass_texture = ImageTexture.create_from_image(img)

func _create_hole_texture():
	# Isometric hole with depth - 20x15 pixel art
	var hole_art = [
		"                    ",
		"      ########      ",
		"    ##LLLLLLLL##    ",
		"   #LLMMMMMMMMLL#   ",
		"  #LLMMDDDDDDDMLL#  ",
		"  #LMMDDDDDDDDMML#  ",
		" #LMMDDDDDDDDDDMML# ",
		" #LMMDDDDDDDDDDDML# ",
		" #LMMDDDDDDDDDDDML# ",
		"  #LMMDDDDDDDDMML#  ",
		"  #LLMMDDDDDDDMLL#  ",
		"   #LLMMMMMMMMLL#   ",
		"    ##LLLLLLLL##    ",
		"      ########      ",
		"                    ",
	]
	
	var hole_colors = {
		"#": COLOR_PALETTE.brown_dark,
		"L": COLOR_PALETTE.hole_light,
		"M": COLOR_PALETTE.hole_mid,
		"D": COLOR_PALETTE.hole_dark,
	}
	
	var img = _create_image_from_ascii(hole_art, hole_colors, 4)
	hole_texture = ImageTexture.create_from_image(img)

func _create_mole_texture():
	# Compact kawaii mole with dot eyes and pill mouth - 14x16 pixel art
	var mole_art = [
		"              ",
		"    ######    ",
		"   ########   ",
		"  ##########  ",
		"  ##########  ",
		"  #..##..###  ",
		"  ##########  ",
		"  ##PPPP####  ",
		"  #P####P###  ",
		"  ##MMMM####  ",
		"   ########   ",
		"   ########   ",
		"  ##    ##    ",
		"  ##    ##    ",
		"  ####  ####  ",
		"              ",
	]
	
	var mole_colors = {
		"#": COLOR_PALETTE.brown,
		".": COLOR_PALETTE.black,       # Simple black dot eyes
		"P": COLOR_PALETTE.pink,
		"M": COLOR_PALETTE.brown_dark,  # Pill-shaped mouth
	}
	
	var img = _create_image_from_ascii(mole_art, mole_colors, 4)
	mole_texture = ImageTexture.create_from_image(img)

func _create_mole_hit_texture():
	# Whacked mole with X eyes - 14x16 pixel art
	var mole_hit_art = [
		"              ",
		"    ######    ",
		"   ########   ",
		"  ##########  ",
		"  ##########  ",
		"  #XX##XX###  ",
		"  ##########  ",
		"  ##PPPP####  ",
		"  #P####P###  ",
		"  ##~##~####  ",
		"   ########   ",
		"   ########   ",
		"  ##    ##    ",
		"  ##    ##    ",
		"  ####  ####  ",
		"              ",
	]
	
	var mole_hit_colors = {
		"#": COLOR_PALETTE.brown,
		"X": COLOR_PALETTE.black,       # X eyes for hit state
		"P": COLOR_PALETTE.pink,
		"~": COLOR_PALETTE.brown_dark,  # Dazed mouth
	}
	
	var img = _create_image_from_ascii(mole_hit_art, mole_hit_colors, 4)
	mole_hit_texture = ImageTexture.create_from_image(img)

func _create_background():
	var bg_sprite = Sprite2D.new()
	bg_sprite.texture = grass_texture
	bg_sprite.centered = false
	bg_sprite.z_index = -1
	add_child(bg_sprite)

func _create_mole_grid():
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var mole_data = {
				"state": MoleState.HIDDEN,
				"position": GRID_OFFSET + Vector2(col * HOLE_SPACING, row * HOLE_SPACING),
				"timer": 0.0,
				"visible_time": 0.0,
				"was_hit": false,
				"hole_sprite": null,
				"mole_sprite": null,
				"y_offset": 0.0
			}
			
			# Create hole sprite
			var hole_sprite = Sprite2D.new()
			hole_sprite.texture = hole_texture
			hole_sprite.position = mole_data.position
			add_child(hole_sprite)
			mole_data.hole_sprite = hole_sprite
			
			# Create mole sprite (smaller size: 14x16 * 4 = 56x64)
			var mole_sprite = Sprite2D.new()
			mole_sprite.texture = mole_texture
			mole_sprite.position = mole_data.position + Vector2(0, 56)  # Start underground (smaller mole)
			mole_sprite.visible = false
			add_child(mole_sprite)
			mole_data.mole_sprite = mole_sprite
			
			moles.append(mole_data)

func _process(delta):
	time_elapsed += delta * speed_multiplier

	# Check for timeout (Director handles this, but we track for safety)
	if time_elapsed >= time_limit:
		if not game_ended:
			# If player didn't hit 5 moles before time ran out, they lose
			if moles_hit < MOLES_TO_WIN:
				current_score = 0  # Reset score so Director sees this as a loss
			# Otherwise score stays positive and player wins
			
			end_game()
			game_ended = true
		return
	
	# Stop processing after game ends
	if game_ended:
		return
	
	# Update mole spawn timer (scale with speed so more moles spawn at higher speeds)
	mole_spawn_timer += delta * speed_multiplier
	if mole_spawn_timer >= spawn_interval:
		mole_spawn_timer = 0.0
		_spawn_random_mole()
	
	# Update all moles
	for mole in moles:
		_update_mole(mole, delta)

func _update_mole(mole: Dictionary, delta: float):
	match mole.state:
		MoleState.HIDDEN:
			mole.mole_sprite.visible = false
		
		MoleState.RISING:
			mole.timer += delta * speed_multiplier
			var rise_duration = 0.3
			var progress = min(mole.timer / rise_duration, 1.0)
			mole.y_offset = -56.0 * progress  # Smaller mole: 14x16 * 4 = 56x64
			mole.mole_sprite.position = mole.position + Vector2(0, 56 + mole.y_offset)
			mole.mole_sprite.visible = true
			
			if progress >= 1.0:
				mole.state = MoleState.VISIBLE
				mole.timer = 0.0
				# Keep moles visible long enough to be hittable
				# At higher speeds, make them visible a bit longer
				mole.visible_time = randf_range(0.8, 1.5)
		
		MoleState.VISIBLE:
			mole.timer += delta
			# Add bobbing animation
			var bob = sin(mole.timer * 8.0) * 2.0
			mole.mole_sprite.position = mole.position + Vector2(0, mole.y_offset + bob)
			
			# Check if mole timed out AND wasn't hit
			if mole.timer >= mole.visible_time and not mole.was_hit:
				mole.state = MoleState.HIDING
				mole.timer = 0.0
				# was_hit is already false from spawn
		
		MoleState.HIDING:
			mole.timer += delta * speed_multiplier
			var hide_duration = 0.3
			var progress = min(mole.timer / hide_duration, 1.0)
			mole.y_offset = -56.0 * (1.0 - progress)  # Smaller mole
			mole.mole_sprite.position = mole.position + Vector2(0, 56 + mole.y_offset)
			
			if progress >= 1.0:
				# Reset mole state (no need to track misses anymore)
				mole.state = MoleState.HIDDEN
				mole.timer = 0.0
				mole.y_offset = 0.0
				mole.was_hit = false
				mole.mole_sprite.texture = mole_texture
		
		MoleState.HIT:
			mole.timer += delta * speed_multiplier
			var hit_duration = 0.3
			
			# Shake effect when hit
			var shake = Vector2(randf_range(-2, 2), randf_range(-2, 2))
			mole.mole_sprite.position = mole.position + Vector2(0, mole.y_offset) + shake
			
			if mole.timer >= hit_duration:
				mole.state = MoleState.HIDING
				mole.timer = 0.0
				# Keep was_hit = true so HIDING state knows this mole was hit

func _spawn_random_mole():
	# Find hidden moles
	var hidden_moles = []
	for mole in moles:
		if mole.state == MoleState.HIDDEN:
			hidden_moles.append(mole)
	
	if hidden_moles.size() > 0:
		var random_mole = hidden_moles[randi() % hidden_moles.size()]
		random_mole.state = MoleState.RISING
		random_mole.timer = 0.0
		random_mole.was_hit = false  # New mole starts as not hit

func _unhandled_input(event):
	if game_ended:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.position
			
			# Check if any visible mole was clicked (smaller mole: 56x64)
			for mole in moles:
				if mole.state == MoleState.VISIBLE:
					var mole_rect = Rect2(
						mole.mole_sprite.position - Vector2(28, 32),  # Center adjusted for smaller mole
						Vector2(56, 64)  # Smaller sprite size: 14x16 * 4
					)
					
					if mole_rect.has_point(mouse_pos):
						_hit_mole(mole)
						break

func _hit_mole(mole: Dictionary):
	if mole.state == MoleState.VISIBLE:
		mole.state = MoleState.HIT
		mole.timer = 0.0
		mole.was_hit = true
		mole.mole_sprite.texture = mole_hit_texture
		$sfx_hit.play()  # Play hit sound
		add_score(10)  # Use Microgame's add_score method
		moles_hit += 1
		
		# Check if player has hit enough moles to win
		if moles_hit >= MOLES_TO_WIN:
			if not game_ended:
				# Win! End game with positive score
				end_game()
				game_ended = true
