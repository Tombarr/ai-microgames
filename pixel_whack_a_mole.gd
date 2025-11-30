extends Node2D

# Game state
enum MoleState { HIDDEN, RISING, VISIBLE, HIDING, HIT }

var score: int = 0
var missed: int = 0
var game_time: float = 60.0
var game_active: bool = true

# UI elements
var score_label: Label
var missed_label: Label
var timer_label: Label
var game_over_panel: Control
var final_score_label: Label
var retry_button: Button

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
const MOLE_SPAWN_INTERVAL: float = 1.5

func _ready():
	# Generate all textures
	_create_grass_texture()
	_create_hole_texture()
	_create_mole_texture()
	_create_mole_hit_texture()
	
	# Create background
	_create_background()
	
	# Create UI
	_create_ui()
	
	# Create mole grid
	_create_mole_grid()
	
	# Start the game
	_start_game()

func _create_grass_texture():
	var img = Image.create(640, 640, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.6, 0.2))  # Base grass green
	
	# Add some pixel variation for grass texture
	for y in range(640):
		for x in range(640):
			if (x + y) % 7 == 0:
				img.set_pixel(x, y, Color(0.18, 0.55, 0.18))
			elif (x * 2 + y) % 11 == 0:
				img.set_pixel(x, y, Color(0.22, 0.65, 0.22))
	
	grass_texture = ImageTexture.create_from_image(img)

func _create_hole_texture():
	var img = Image.create(80, 60, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent
	
	# Draw an oval hole (dark brown/black)
	for y in range(60):
		for x in range(80):
			var dx = (x - 40.0) / 40.0
			var dy = (y - 30.0) / 30.0
			var dist = dx * dx + dy * dy
			
			if dist < 1.0:
				# Create depth effect
				if dist < 0.85:
					img.set_pixel(x, y, Color(0.15, 0.1, 0.05))
				else:
					img.set_pixel(x, y, Color(0.25, 0.2, 0.15))
	
	hole_texture = ImageTexture.create_from_image(img)

func _create_mole_texture():
	var img = Image.create(60, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent
	
	# Define mole pixel art (brown mole with features)
	var brown = Color(0.4, 0.25, 0.15)
	var dark_brown = Color(0.3, 0.2, 0.1)
	var pink = Color(0.9, 0.4, 0.5)
	var white = Color(1, 1, 1)
	var black = Color(0, 0, 0)
	
	# Body (oval shape)
	for y in range(25, 75):
		for x in range(10, 50):
			var dx = (x - 30.0) / 20.0
			var dy = (y - 50.0) / 25.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	# Head (round)
	for y in range(10, 40):
		for x in range(15, 45):
			var dx = (x - 30.0) / 15.0
			var dy = (y - 25.0) / 15.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	# Eyes (white with black pupils)
	for y in range(18, 24):
		for x in range(20, 26):
			img.set_pixel(x, y, white)
	for y in range(18, 24):
		for x in range(34, 40):
			img.set_pixel(x, y, white)
	
	# Pupils
	for y in range(20, 23):
		for x in range(22, 25):
			img.set_pixel(x, y, black)
	for y in range(20, 23):
		for x in range(36, 39):
			img.set_pixel(x, y, black)
	
	# Nose (pink)
	for y in range(26, 30):
		for x in range(27, 33):
			img.set_pixel(x, y, pink)
	
	# Mouth
	for x in range(25, 35):
		img.set_pixel(x, 31, dark_brown)
	
	# Hands (small ovals on sides)
	for y in range(45, 55):
		for x in range(5, 12):
			var dx = (x - 8.5) / 3.5
			var dy = (y - 50.0) / 5.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	for y in range(45, 55):
		for x in range(48, 55):
			var dx = (x - 51.5) / 3.5
			var dy = (y - 50.0) / 5.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	mole_texture = ImageTexture.create_from_image(img)

func _create_mole_hit_texture():
	var img = Image.create(60, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent
	
	# Similar to normal mole but with X eyes and dizzy expression
	var brown = Color(0.4, 0.25, 0.15)
	var dark_brown = Color(0.3, 0.2, 0.1)
	var pink = Color(0.9, 0.4, 0.5)
	var black = Color(0, 0, 0)
	
	# Body
	for y in range(25, 75):
		for x in range(10, 50):
			var dx = (x - 30.0) / 20.0
			var dy = (y - 50.0) / 25.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	# Head
	for y in range(10, 40):
		for x in range(15, 45):
			var dx = (x - 30.0) / 15.0
			var dy = (y - 25.0) / 15.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	# X eyes
	for i in range(6):
		img.set_pixel(20 + i, 18 + i, black)
		img.set_pixel(20 + i, 23 - i, black)
		img.set_pixel(34 + i, 18 + i, black)
		img.set_pixel(34 + i, 23 - i, black)
	
	# Nose
	for y in range(26, 30):
		for x in range(27, 33):
			img.set_pixel(x, y, pink)
	
	# Dizzy mouth (wavy)
	img.set_pixel(25, 32, dark_brown)
	img.set_pixel(26, 31, dark_brown)
	img.set_pixel(27, 32, dark_brown)
	img.set_pixel(28, 33, dark_brown)
	img.set_pixel(29, 32, dark_brown)
	img.set_pixel(30, 31, dark_brown)
	img.set_pixel(31, 32, dark_brown)
	img.set_pixel(32, 33, dark_brown)
	img.set_pixel(33, 32, dark_brown)
	img.set_pixel(34, 31, dark_brown)
	
	# Hands
	for y in range(45, 55):
		for x in range(5, 12):
			var dx = (x - 8.5) / 3.5
			var dy = (y - 50.0) / 5.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	for y in range(45, 55):
		for x in range(48, 55):
			var dx = (x - 51.5) / 3.5
			var dy = (y - 50.0) / 5.0
			if dx * dx + dy * dy < 1.0:
				img.set_pixel(x, y, brown)
	
	mole_hit_texture = ImageTexture.create_from_image(img)

func _create_background():
	var bg_sprite = Sprite2D.new()
	bg_sprite.texture = grass_texture
	bg_sprite.centered = false
	bg_sprite.z_index = -1
	add_child(bg_sprite)

func _create_ui():
	# Score label
	score_label = Label.new()
	score_label.position = Vector2(20, 20)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.text = "Score: 0"
	add_child(score_label)
	
	# Missed label
	missed_label = Label.new()
	missed_label.position = Vector2(20, 50)
	missed_label.add_theme_font_size_override("font_size", 24)
	missed_label.text = "Missed: 0"
	add_child(missed_label)
	
	# Timer label
	timer_label = Label.new()
	timer_label.position = Vector2(520, 20)
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.text = "Time: 60"
	add_child(timer_label)
	
	# Game over panel (hidden initially)
	game_over_panel = Control.new()
	game_over_panel.position = Vector2(170, 200)
	game_over_panel.visible = false
	add_child(game_over_panel)
	
	# Background for game over
	var panel_bg = ColorRect.new()
	panel_bg.size = Vector2(300, 200)
	panel_bg.color = Color(0, 0, 0, 0.8)
	game_over_panel.add_child(panel_bg)
	
	# Game over text
	var game_over_label = Label.new()
	game_over_label.position = Vector2(80, 30)
	game_over_label.add_theme_font_size_override("font_size", 32)
	game_over_label.text = "GAME OVER"
	game_over_panel.add_child(game_over_label)
	
	# Final score
	final_score_label = Label.new()
	final_score_label.position = Vector2(80, 80)
	final_score_label.add_theme_font_size_override("font_size", 24)
	final_score_label.text = "Score: 0"
	game_over_panel.add_child(final_score_label)
	
	# Retry button
	retry_button = Button.new()
	retry_button.position = Vector2(100, 130)
	retry_button.size = Vector2(100, 40)
	retry_button.text = "Retry"
	retry_button.pressed.connect(_on_retry_pressed)
	game_over_panel.add_child(retry_button)

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
			
			# Create mole sprite
			var mole_sprite = Sprite2D.new()
			mole_sprite.texture = mole_texture
			mole_sprite.position = mole_data.position + Vector2(0, 40)  # Start underground
			mole_sprite.visible = false
			add_child(mole_sprite)
			mole_data.mole_sprite = mole_sprite
			
			moles.append(mole_data)

func _start_game():
	score = 0
	missed = 0
	game_time = 60.0
	game_active = true
	mole_spawn_timer = 0.0
	
	# Reset all moles
	for mole in moles:
		mole.state = MoleState.HIDDEN
		mole.timer = 0.0
		mole.visible_time = 0.0
		mole.was_hit = false
		mole.mole_sprite.visible = false
		mole.mole_sprite.texture = mole_texture
		mole.y_offset = 0.0
	
	game_over_panel.visible = false
	_update_ui()

func _process(delta):
	if not game_active:
		return
	
	# Update timer
	game_time -= delta
	if game_time <= 0:
		game_time = 0
		_end_game()
		return
	
	# Update mole spawn timer
	mole_spawn_timer += delta
	if mole_spawn_timer >= MOLE_SPAWN_INTERVAL:
		mole_spawn_timer = 0.0
		_spawn_random_mole()
	
	# Update all moles
	for mole in moles:
		_update_mole(mole, delta)
	
	_update_ui()

func _update_mole(mole: Dictionary, delta: float):
	match mole.state:
		MoleState.HIDDEN:
			mole.mole_sprite.visible = false
		
		MoleState.RISING:
			mole.timer += delta
			var rise_duration = 0.3
			var progress = min(mole.timer / rise_duration, 1.0)
			mole.y_offset = -40.0 * progress
			mole.mole_sprite.position = mole.position + Vector2(0, 40 + mole.y_offset)
			mole.mole_sprite.visible = true
			
			if progress >= 1.0:
				mole.state = MoleState.VISIBLE
				mole.timer = 0.0
				mole.visible_time = randf_range(1.0, 2.5)
		
		MoleState.VISIBLE:
			mole.timer += delta
			if mole.timer >= mole.visible_time:
				mole.state = MoleState.HIDING
				mole.timer = 0.0
		
		MoleState.HIDING:
			mole.timer += delta
			var hide_duration = 0.3
			var progress = min(mole.timer / hide_duration, 1.0)
			mole.y_offset = -40.0 * (1.0 - progress)
			mole.mole_sprite.position = mole.position + Vector2(0, 40 + mole.y_offset)
			
			if progress >= 1.0:
				mole.state = MoleState.HIDDEN
				mole.timer = 0.0
				mole.y_offset = 0.0
				
				# Check if mole was missed
				if not mole.was_hit:
					missed += 1
					if missed >= 3:
						_end_game()
				
				mole.was_hit = false
				mole.mole_sprite.texture = mole_texture
		
		MoleState.HIT:
			mole.timer += delta
			var hit_duration = 0.5
			
			if mole.timer >= hit_duration:
				mole.state = MoleState.HIDING
				mole.timer = 0.0

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
		random_mole.was_hit = false

func _unhandled_input(event):
	if not game_active:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = event.position
			
			# Check if any visible mole was clicked
			for mole in moles:
				if mole.state == MoleState.VISIBLE:
					var mole_rect = Rect2(
						mole.mole_sprite.position - Vector2(30, 40),
						Vector2(60, 80)
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
		score += 10

func _update_ui():
	score_label.text = "Score: " + str(score)
	missed_label.text = "Missed: " + str(missed)
	timer_label.text = "Time: " + str(int(game_time))

func _end_game():
	game_active = false
	final_score_label.text = "Final Score: " + str(score)
	game_over_panel.visible = true

func _on_retry_pressed():
	_start_game()
