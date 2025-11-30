extends Microgame

# Grid configuration - sized to fill 640x640 viewport with progress bar at bottom
const GRID_WIDTH = 14
const GRID_HEIGHT = 13
const TILE_SIZE = 45
const BORDER_SIZE = 4  # Thick black border between squares
const GRID_OFFSET = Vector2(5, 5)  # Small margin from edges
const PROGRESS_BAR_HEIGHT = 20

# High contrast color palette (5 colors)
const COLORS = [
	Color("#E63946"),  # Bright Red
	Color("#2A9D8F"),  # Deep Teal
	Color("#F4A261"),  # Orange
	Color("#457B9D"),  # Steel Blue
	Color("#9B5DE5")   # Vivid Purple
]

# Tetromino shapes defined as arrays of Vector2 offsets from origin
const SHAPES = {
	"SQUARE": [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)],
	"LINE": [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0)],
	"L": [Vector2(0, 0), Vector2(0, 1), Vector2(0, 2), Vector2(1, 2)],
	"J": [Vector2(1, 0), Vector2(1, 1), Vector2(1, 2), Vector2(0, 2)],
	"T": [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(1, 1)]
}

# 4 different starting floor configurations using textual representation
# X = filled tile, . = empty space
# Each config is an array of strings, bottom row first
const FLOOR_CONFIGS = [
	# Config 1: Pyramid gap in center
	[
		"XXXXX..XXXXX..",
		"XXXX....XXXX..",
		"XXX......XXX..",
		"XX........XX.."
	],
	# Config 2: Alternating pillars
	[
		"XX..XX..XX..XX",
		"XX..XX..XX..XX",
		"....XX..XX....",
		"....XX..XX...."
	],
	# Config 3: Steps from left
	[
		"XXXXXXXXXXXX..",
		"XXXXXXXXXX....",
		"XXXXXXXX......",
		"XXXXXX........"
	],
	# Config 4: Scattered holes
	[
		"XXX.XXXXXX.XXX",
		"XX.XXXXXXXX.XX",
		"X.XXXXXXXXXX.X",
		".XXXXXXXXXXXX."
	]
]

const GAME_DURATION = 10.0  # 10 second timer

var grid = []  # 2D array to track placed tiles
var current_piece = null  # Dictionary with shape data
var current_piece_tiles = []  # Array of ColorRect nodes for current piece
var placed_tiles = []  # 2D array of ColorRect nodes for placed tiles
var lines_cleared = 0
var game_active = true
var drop_timer = 0.0
var drop_interval = 0.5  # Faster drops for 10 second game
var time_remaining = GAME_DURATION
var progress_bar_fill = null
var result_label = null

func _ready():
	instruction = "STACK!"
	super._ready()

	_initialize_sounds()
	_initialize_grid()
	_draw_grid_background()
	_create_progress_bar()
	_place_starting_pieces()
	_spawn_new_piece()

func _initialize_grid():
	# Initialize empty grid
	grid = []
	placed_tiles = []
	for x in range(GRID_WIDTH):
		var col = []
		var tile_col = []
		for y in range(GRID_HEIGHT):
			col.append(false)
			tile_col.append(null)
		grid.append(col)
		placed_tiles.append(tile_col)

func _draw_grid_background():
	# Draw solid black background for the grid (serves as borders)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.position = GRID_OFFSET
	bg.size = Vector2(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)
	add_child(bg)

func _create_progress_bar():
	# Progress bar background (gray)
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.2, 0.2, 0.2)
	bar_bg.position = Vector2(5, 640 - PROGRESS_BAR_HEIGHT - 5)
	bar_bg.size = Vector2(630, PROGRESS_BAR_HEIGHT)
	add_child(bar_bg)
	
	# Progress bar fill (green to red gradient effect via color change)
	progress_bar_fill = ColorRect.new()
	progress_bar_fill.color = Color(0.2, 0.8, 0.2)  # Start green
	progress_bar_fill.position = Vector2(5, 640 - PROGRESS_BAR_HEIGHT - 5)
	progress_bar_fill.size = Vector2(630, PROGRESS_BAR_HEIGHT)
	add_child(progress_bar_fill)

func _place_starting_pieces():
	# Pick a random floor configuration
	var config = FLOOR_CONFIGS[randi() % FLOOR_CONFIGS.size()]
	
	# Parse the config and place tiles (config is bottom-up)
	for row_idx in range(config.size()):
		var row_str = config[row_idx]
		var grid_y = GRID_HEIGHT - 1 - row_idx  # Convert to grid coordinates (bottom = highest y)
		
		for x in range(min(row_str.length(), GRID_WIDTH)):
			if row_str[x] == "X":
				_place_single_tile(x, grid_y, COLORS[randi() % COLORS.size()])

func _place_single_tile(grid_x: int, grid_y: int, color: Color):
	if grid_x < 0 or grid_x >= GRID_WIDTH or grid_y < 0 or grid_y >= GRID_HEIGHT:
		return
	
	grid[grid_x][grid_y] = true
	
	var tile = ColorRect.new()
	# Tile size accounts for border - leaves black gap between tiles
	var inner_size = TILE_SIZE - BORDER_SIZE
	tile.size = Vector2(inner_size, inner_size)
	# Position with border offset
	var half_border = BORDER_SIZE / 2.0
	tile.position = GRID_OFFSET + Vector2(grid_x * TILE_SIZE + half_border, grid_y * TILE_SIZE + half_border)
	tile.color = color
	add_child(tile)
	placed_tiles[grid_x][grid_y] = tile

func _spawn_new_piece():
	if not game_active:
		return
	
	# Pick random shape and color
	var shape_names = SHAPES.keys()
	var shape_name = shape_names[randi() % shape_names.size()]
	var shape = SHAPES[shape_name].duplicate()
	var color = COLORS[randi() % COLORS.size()]
	
	# Starting position (top center)
	var start_x = GRID_WIDTH / 2 - 1
	var start_y = 0
	
	current_piece = {
		"shape": shape,
		"color": color,
		"grid_pos": Vector2(start_x, start_y),
		"rotation": 0
	}
	
	# Check if spawn position is valid
	if not _is_valid_position(current_piece.grid_pos, current_piece.shape):
		# Can't spawn - but don't end game, just wait for timer
		current_piece = null
		return
	
	_draw_current_piece()

func _draw_current_piece():
	# Clear old piece tiles
	for tile in current_piece_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	current_piece_tiles.clear()
	
	if current_piece == null:
		return
	
	# Draw new piece tiles
	for offset in current_piece.shape:
		var tile = ColorRect.new()
		var inner_size = TILE_SIZE - BORDER_SIZE
		tile.size = Vector2(inner_size, inner_size)
		var grid_x = current_piece.grid_pos.x + offset.x
		var grid_y = current_piece.grid_pos.y + offset.y
		var half_border = BORDER_SIZE / 2.0
		tile.position = GRID_OFFSET + Vector2(grid_x * TILE_SIZE + half_border, grid_y * TILE_SIZE + half_border)
		tile.color = current_piece.color
		add_child(tile)
		current_piece_tiles.append(tile)

func _is_valid_position(pos: Vector2, shape: Array) -> bool:
	for offset in shape:
		var x = int(pos.x + offset.x)
		var y = int(pos.y + offset.y)
		
		# Check bounds
		if x < 0 or x >= GRID_WIDTH or y < 0 or y >= GRID_HEIGHT:
			return false
		
		# Check collision with placed tiles
		if grid[x][y]:
			return false
	
	return true

func _rotate_shape(shape: Array) -> Array:
	# Rotate 90 degrees clockwise around center
	var rotated = []
	for offset in shape:
		rotated.append(Vector2(-offset.y, offset.x))
	
	# Normalize to keep positive coordinates
	var min_x = 0
	var min_y = 0
	for offset in rotated:
		min_x = min(min_x, offset.x)
		min_y = min(min_y, offset.y)
	
	var normalized = []
	for offset in rotated:
		normalized.append(Vector2(offset.x - min_x, offset.y - min_y))
	
	return normalized

func _process(delta):
	if not game_active:
		return
	
	# Update timer and progress bar
	time_remaining -= delta
	var progress = max(0, time_remaining / GAME_DURATION)
	
	if progress_bar_fill:
		progress_bar_fill.size.x = 630 * progress
		# Color transitions from green to yellow to red
		if progress > 0.5:
			progress_bar_fill.color = Color(0.2, 0.8, 0.2)  # Green
		elif progress > 0.25:
			progress_bar_fill.color = Color(0.9, 0.7, 0.1)  # Yellow
		else:
			progress_bar_fill.color = Color(0.9, 0.2, 0.2)  # Red
	
	# Check for time out (lose condition)
	if time_remaining <= 0:
		_end_game(false)
		return
	
	if current_piece == null:
		return
	
	# Auto-drop timer
	drop_timer += delta
	if drop_timer >= drop_interval:
		drop_timer = 0.0
		_move_piece(Vector2(0, 1))
	
	# Input handling
	if Input.is_action_just_pressed("ui_left"):
		_move_piece(Vector2(-1, 0))
	if Input.is_action_just_pressed("ui_right"):
		_move_piece(Vector2(1, 0))
	if Input.is_action_just_pressed("ui_down"):
		_move_piece(Vector2(0, 1))
	if Input.is_action_just_pressed("ui_up"):
		_rotate_piece()

func _end_game(did_win: bool):
	game_active = false
	
	# Add a dark background behind text for readability (centered in 640x640 viewport)
	var label_bg = ColorRect.new()
	label_bg.color = Color(0, 0, 0, 0.7)
	label_bg.size = Vector2(300, 120)
	label_bg.position = Vector2((640 - label_bg.size.x) / 2, (640 - label_bg.size.y) / 2)
	add_child(label_bg)
	
	# Show result label (centered in viewport)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 72)
	result_label.size = Vector2(300, 120)
	result_label.position = Vector2((640 - result_label.size.x) / 2, (640 - result_label.size.y) / 2)
	
	if did_win:
		result_label.text = "WIN!"
		result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		$sfx_win.play()
	else:
		result_label.text = "LOSE"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		$sfx_lose.play()
	
	add_child(result_label)

	# Call end_game after a short delay to show the message
	if did_win:
		add_score(100)  # Win score
		await get_tree().create_timer(1.0).timeout
		end_game()
	else:
		await get_tree().create_timer(1.0).timeout
		end_game()  # Lose with score 0

func _move_piece(direction: Vector2):
	if current_piece == null:
		return
	
	var new_pos = current_piece.grid_pos + direction
	
	if _is_valid_position(new_pos, current_piece.shape):
		current_piece.grid_pos = new_pos
		_draw_current_piece()
	elif direction.y > 0:
		# Moving down but blocked - lock the piece
		_lock_piece()

func _rotate_piece():
	if current_piece == null:
		return
	
	var rotated_shape = _rotate_shape(current_piece.shape)
	
	# Try rotation at current position
	if _is_valid_position(current_piece.grid_pos, rotated_shape):
		current_piece.shape = rotated_shape
		$sfx_rotate.play()
		_draw_current_piece()
	else:
		# Try wall kicks (shift left or right)
		for kick in [Vector2(-1, 0), Vector2(1, 0), Vector2(-2, 0), Vector2(2, 0)]:
			if _is_valid_position(current_piece.grid_pos + kick, rotated_shape):
				current_piece.grid_pos += kick
				current_piece.shape = rotated_shape
				$sfx_rotate.play()
				_draw_current_piece()
				return

func _lock_piece():
	if current_piece == null:
		return
	
	$sfx_place.play()
	
	# Add piece tiles to grid
	for offset in current_piece.shape:
		var x = int(current_piece.grid_pos.x + offset.x)
		var y = int(current_piece.grid_pos.y + offset.y)
		_place_single_tile(x, y, current_piece.color)
	
	# Clear current piece visuals
	for tile in current_piece_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	current_piece_tiles.clear()
	current_piece = null
	
	# Check for completed lines
	_check_lines()
	
	# Spawn next piece
	_spawn_new_piece()

func _check_lines():
	var lines_to_clear = []
	
	# Check each row from bottom to top
	for y in range(GRID_HEIGHT - 1, -1, -1):
		var full = true
		for x in range(GRID_WIDTH):
			if not grid[x][y]:
				full = false
				break
		if full:
			lines_to_clear.append(y)
	
	if lines_to_clear.size() > 0:
		_clear_lines(lines_to_clear)
		lines_cleared += lines_to_clear.size()
		# Win immediately when a line is cleared
		_end_game(true)

func _clear_lines(lines: Array):
	# Remove tiles in cleared lines
	for y in lines:
		for x in range(GRID_WIDTH):
			if placed_tiles[x][y] != null:
				placed_tiles[x][y].queue_free()
				placed_tiles[x][y] = null
			grid[x][y] = false
	
	# Drop tiles above cleared lines
	lines.sort()  # Sort ascending
	for cleared_y in lines:
		# Move all rows above down by 1
		for y in range(cleared_y, 0, -1):
			for x in range(GRID_WIDTH):
				grid[x][y] = grid[x][y - 1]
				if placed_tiles[x][y - 1] != null:
					placed_tiles[x][y] = placed_tiles[x][y - 1]
					placed_tiles[x][y].position.y += TILE_SIZE
					placed_tiles[x][y - 1] = null
				else:
					placed_tiles[x][y] = null
		
		# Clear top row
		for x in range(GRID_WIDTH):
			grid[x][0] = false
			placed_tiles[x][0] = null

func _initialize_sounds():
	var sfx_place = AudioStreamPlayer.new()
	sfx_place.name = "sfx_place"
	sfx_place.stream = load("res://games/geo_stacker/assets/sfx_place.wav")
	add_child(sfx_place)
	
	var sfx_rotate = AudioStreamPlayer.new()
	sfx_rotate.name = "sfx_rotate"
	sfx_rotate.stream = load("res://games/geo_stacker/assets/sfx_rotate.wav")
	add_child(sfx_rotate)
	
	var sfx_win = AudioStreamPlayer.new()
	sfx_win.name = "sfx_win"
	sfx_win.stream = load("res://games/geo_stacker/assets/sfx_win.wav")
	add_child(sfx_win)
	
	var sfx_lose = AudioStreamPlayer.new()
	sfx_lose.name = "sfx_lose"
	sfx_lose.stream = load("res://games/geo_stacker/assets/sfx_lose.wav")
	add_child(sfx_lose)
