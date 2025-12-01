extends Microgame

# Grid configuration
const GRID_SIZE = 5
const VIEWPORT_SIZE = 640
const PADDING = 40  # Padding from viewport edges
const TILE_SPACING = 6  # Gap between tiles

# Calculate tile size to fill viewport
# Available space = VIEWPORT_SIZE - (2 * PADDING) - (TILE_SPACING * (GRID_SIZE - 1))
# TILE_SIZE = available_space / GRID_SIZE
const AVAILABLE_SPACE = VIEWPORT_SIZE - (2 * PADDING) - (TILE_SPACING * (GRID_SIZE - 1))
const TILE_SIZE = AVAILABLE_SPACE / GRID_SIZE  # ~108px per tile

# Center the grid in the viewport
const GRID_OFFSET = Vector2(PADDING, PADDING)

# Tile states
enum TileState { UNREVEALED, REVEALED, BOMB, GOAL }

# Color palette
const COLOR_BG = Color("#1a1a1a")
const COLOR_TILE_UNREVEALED = Color("#3a3a3a")
const COLOR_TILE_REVEALED = Color("#2a2a2a")
const COLOR_TILE_HOVER = Color("#4a4a4a")
const COLOR_GOAL = Color("#ffd700")
const COLOR_BOMB = Color("#ff4444")
const COLOR_NUMBERS = {
	1: Color("#4a9eff"),
	2: Color("#5ec269"),
	3: Color("#ff6b6b"),
	4: Color("#9b59b6"),
	5: Color("#e67e22"),
	6: Color("#e67e22"),
	7: Color("#e67e22"),
	8: Color("#e67e22")
}

# Map data structure: [bomb_positions, goal_positions]
# Positions are [row, col] pairs
const MAPS = [
	{
		"name": "Corner Safe Zone",
		"bombs": [[0,4], [1,3], [2,2], [3,1], [4,0]],
		"goals": [[0,0]],
		"instruction": "FIND STAR!"
	},
	{
		"name": "Two Islands",
		"bombs": [[0,0], [0,4], [1,2], [2,1], [2,3], [4,0]],
		"goals": [[3,2], [4,4]],
		"instruction": "FIND STARS!"
	},
	{
		"name": "Center Goal",
		"bombs": [[0,0], [0,1], [0,3], [0,4], [1,0], [1,4], [3,0], [3,4], [4,0], [4,1], [4,3], [4,4]],
		"goals": [[2,2]],
		"instruction": "FIND STAR!"
	},
	{
		"name": "Edge Path",
		"bombs": [[0,2], [1,0], [2,2], [2,3], [3,4], [4,2]],
		"goals": [[0,4], [4,0]],
		"instruction": "FIND STARS!"
	}
]

# Game state
var grid: Array = []  # 5x5 array of tile data
var tiles: Array = []  # Visual tile nodes
var current_map: Dictionary
var goals_found: int = 0
var first_click: bool = true
var game_ended: bool = false
var time_elapsed: float = 0.0
const GAME_DURATION: float = 5.0

# Sound effects
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")

func _ready():
	# Select random map
	current_map = MAPS.pick_random()
	instruction = current_map["instruction"]
	super._ready()
	
	_setup_grid()
	_create_tiles()

func _setup_grid():
	"""Initialize the 5x5 grid with bomb and goal data."""
	# Initialize empty grid
	for row in range(GRID_SIZE):
		var row_data = []
		for col in range(GRID_SIZE):
			row_data.append({
				"state": TileState.UNREVEALED,
				"is_bomb": false,
				"is_goal": false,
				"adjacent_bombs": 0,
				"revealed": false
			})
		grid.append(row_data)
	
	# Place bombs
	for pos in current_map["bombs"]:
		var row = pos[0]
		var col = pos[1]
		grid[row][col]["is_bomb"] = true
	
	# Place goals
	for pos in current_map["goals"]:
		var row = pos[0]
		var col = pos[1]
		grid[row][col]["is_goal"] = true
	
	# Calculate adjacent bomb counts
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if not grid[row][col]["is_bomb"]:
				grid[row][col]["adjacent_bombs"] = _count_adjacent_bombs(row, col)

func _count_adjacent_bombs(row: int, col: int) -> int:
	"""Count bombs in the 8 adjacent cells."""
	var count = 0
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			if dr == 0 and dc == 0:
				continue
			var nr = row + dr
			var nc = col + dc
			if nr >= 0 and nr < GRID_SIZE and nc >= 0 and nc < GRID_SIZE:
				if grid[nr][nc]["is_bomb"]:
					count += 1
	return count

func _create_tiles():
	"""Create visual tile nodes for the grid."""
	for row in range(GRID_SIZE):
		var row_tiles = []
		for col in range(GRID_SIZE):
			var tile = _create_tile(row, col)
			add_child(tile)
			row_tiles.append(tile)
		tiles.append(row_tiles)

func _create_tile(row: int, col: int) -> Control:
	"""Create a single tile button."""
	var tile = Button.new()
	var pos = GRID_OFFSET + Vector2(col * (TILE_SIZE + TILE_SPACING), row * (TILE_SIZE + TILE_SPACING))
	tile.position = pos
	tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	tile.size = Vector2(TILE_SIZE, TILE_SIZE)
	
	# Style unrevealed tile
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_TILE_UNREVEALED
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	style.border_color = Color("#2a2a2a")
	tile.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = COLOR_TILE_HOVER
	tile.add_theme_stylebox_override("hover", hover_style)
	
	# Add goal sparkle if this is a goal tile
	if grid[row][col]["is_goal"]:
		var sparkle = _create_sparkle()
		sparkle.position = Vector2(TILE_SIZE - 25, 15)
		tile.add_child(sparkle)
	
	# Connect click signal
	tile.pressed.connect(_on_tile_clicked.bind(row, col))
	
	return tile

func _create_sparkle() -> Node2D:
	"""Create a gold sparkle indicator for goal tiles."""
	var sparkle = Node2D.new()
	
	# Draw star polygon
	var star = Polygon2D.new()
	var points = PackedVector2Array()
	var outer_radius = 10.0
	var inner_radius = 5.0
	
	for i in range(10):
		var angle = (i * PI / 5.0) - PI / 2.0
		var radius = outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	star.polygon = points
	star.color = COLOR_GOAL
	sparkle.add_child(star)
	
	# Animate sparkle
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(star, "modulate:a", 0.5, 0.5)
	tween.tween_property(star, "modulate:a", 1.0, 0.5)
	
	return sparkle

func _on_tile_clicked(row: int, col: int):
	"""Handle tile click."""
	if game_ended:
		return
	
	var tile_data = grid[row][col]
	
	# Already revealed
	if tile_data["revealed"]:
		return
	
	# First click safety - move bomb if clicked
	if first_click and tile_data["is_bomb"]:
		_move_first_bomb(row, col)
		tile_data = grid[row][col]  # Refresh data
	
	first_click = false
	
	# Check for bomb BEFORE revealing
	if tile_data["is_bomb"]:
		tile_data["revealed"] = true
		_reveal_tile(row, col)
		_lose_game()
		return
	
	# Reveal tile and flood-fill contiguous safe tiles
	_flood_reveal(row, col)
	
	# Check win condition after flood reveal
	if goals_found >= current_map["goals"].size():
		_win_game()

func _flood_reveal(start_row: int, start_col: int):
	"""Flood-fill reveal all contiguous non-bomb tiles."""
	var queue = [[start_row, start_col]]
	
	while queue.size() > 0:
		var pos = queue.pop_front()
		var row = pos[0]
		var col = pos[1]
		
		# Skip if out of bounds
		if row < 0 or row >= GRID_SIZE or col < 0 or col >= GRID_SIZE:
			continue
		
		var tile_data = grid[row][col]
		
		# Skip if already revealed or is a bomb
		if tile_data["revealed"] or tile_data["is_bomb"]:
			continue
		
		# Reveal this tile
		tile_data["revealed"] = true
		_reveal_tile(row, col)
		
		# Check if this was a goal
		if tile_data["is_goal"]:
			goals_found += 1
			_play_goal_sound()
		
		# If this tile has no adjacent bombs, add neighbors to queue
		if tile_data["adjacent_bombs"] == 0:
			# Add all 8 neighbors
			for dr in range(-1, 2):
				for dc in range(-1, 2):
					if dr == 0 and dc == 0:
						continue
					queue.append([row + dr, col + dc])

func _move_first_bomb(row: int, col: int):
	"""Move bomb from first click to a random safe square."""
	# Remove bomb from clicked square
	grid[row][col]["is_bomb"] = false
	
	# Find all safe squares (not bomb, not goal, not clicked)
	var safe_squares = []
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if r == row and c == col:
				continue
			if not grid[r][c]["is_bomb"] and not grid[r][c]["is_goal"]:
				safe_squares.append([r, c])
	
	# Move bomb to random safe square
	if safe_squares.size() > 0:
		var new_pos = safe_squares.pick_random()
		grid[new_pos[0]][new_pos[1]]["is_bomb"] = true
	
	# Recalculate adjacent bomb counts
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			if not grid[r][c]["is_bomb"]:
				grid[r][c]["adjacent_bombs"] = _count_adjacent_bombs(r, c)

func _reveal_tile(row: int, col: int):
	"""Update tile visual to show revealed state."""
	var tile = tiles[row][col]
	var tile_data = grid[row][col]
	
	# Change background to revealed style
	var revealed_style = StyleBoxFlat.new()
	revealed_style.bg_color = COLOR_TILE_REVEALED
	revealed_style.set_corner_radius_all(6)
	tile.add_theme_stylebox_override("normal", revealed_style)
	tile.add_theme_stylebox_override("hover", revealed_style)
	tile.add_theme_stylebox_override("pressed", revealed_style)
	
	# Show number if adjacent bombs exist
	if tile_data["adjacent_bombs"] > 0:
		var label = Label.new()
		label.text = str(tile_data["adjacent_bombs"])
		label.add_theme_font_size_override("font_size", int(TILE_SIZE * 0.5))
		label.add_theme_color_override("font_color", COLOR_NUMBERS.get(tile_data["adjacent_bombs"], COLOR_NUMBERS[5]))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = Vector2(TILE_SIZE, TILE_SIZE)
		tile.add_child(label)

func _reveal_all_bombs():
	"""Show all bombs on the grid (called on loss)."""
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			if grid[row][col]["is_bomb"]:
				var tile = tiles[row][col]
				
				# Show bomb icon
				var bomb_visual = _create_bomb_icon()
				tile.add_child(bomb_visual)

func _create_bomb_icon() -> Control:
	"""Create a bomb visual (circle with emoji)."""
	var container = Control.new()
	container.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
	
	# Bomb circle background
	var circle = ColorRect.new()
	circle.color = COLOR_BOMB
	var circle_size = TILE_SIZE * 0.4
	circle.position = Vector2((TILE_SIZE - circle_size) / 2.0, (TILE_SIZE - circle_size) / 2.0)
	circle.size = Vector2(circle_size, circle_size)
	container.add_child(circle)
	
	# Bomb emoji
	var label = Label.new()
	label.text = "💣"
	label.add_theme_font_size_override("font_size", int(TILE_SIZE * 0.4))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(0, -5)
	label.size = Vector2(TILE_SIZE, TILE_SIZE)
	container.add_child(label)
	
	return container

func _play_goal_sound():
	"""Play success sound for finding a goal."""
	var sfx = AudioStreamPlayer.new()
	sfx.stream = preload("res://shared/assets/sfx_button_press.wav")
	sfx.volume_db = 0
	add_child(sfx)
	sfx.play()
	# Don't await - let sound play in background

func _win_game():
	"""Player found all goals."""
	if game_ended:
		return
	
	game_ended = true
	
	# Play win sound
	var sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_WIN
	add_child(sfx)
	sfx.play()
	
	# Add score and end game
	add_score(100)
	end_game()

func _lose_game():
	"""Player clicked a bomb."""
	if game_ended:
		return
	
	game_ended = true
	
	# Reveal all bombs
	_reveal_all_bombs()
	
	# Play lose sound
	var sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_LOSE
	add_child(sfx)
	sfx.play()
	
	# Wait a moment then end
	await get_tree().create_timer(1.0).timeout
	end_game()

func _process(delta):
	if game_ended:
		return
	
	time_elapsed += delta
	
	# Check timeout
	if time_elapsed >= GAME_DURATION:
		_lose_game()
