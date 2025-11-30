extends Microgame

# Grid configuration
const GRID_SIZE = 4
const TILE_SIZE = 80  # Visual size of each tile
const TILE_SPACING = 10  # Gap between tiles
const GRID_OFFSET = Vector2(85, 85)  # Center on 640x640 canvas

# Pipe type definitions with connection points
enum PipeType { STRAIGHT, L_BEND, T_JUNCTION, CROSS, TERMINAL }
enum Direction { NORTH, EAST, SOUTH, WEST }

# Pipe connection data: which sides have openings
const PIPE_CONNECTIONS = {
	PipeType.STRAIGHT: [Direction.NORTH, Direction.SOUTH],  # Vertical by default
	PipeType.L_BEND: [Direction.NORTH, Direction.EAST],  # Top-right corner by default
	PipeType.T_JUNCTION: [Direction.NORTH, Direction.EAST, Direction.WEST],  # Missing south
	PipeType.CROSS: [Direction.NORTH, Direction.EAST, Direction.SOUTH, Direction.WEST],
	PipeType.TERMINAL: [Direction.NORTH]  # Single opening
}

# Sprite paths
const PIPE_SPRITES = {
	PipeType.STRAIGHT: "res://games/loop_connect/assets/pipe_straight.png",
	PipeType.L_BEND: "res://games/loop_connect/assets/pipe_l_bend.png",
	PipeType.T_JUNCTION: "res://games/loop_connect/assets/pipe_t_junction.png",
	PipeType.CROSS: "res://games/loop_connect/assets/pipe_cross.png",
	PipeType.TERMINAL: "res://games/loop_connect/assets/pipe_terminal.png"
}

# Game state
var grid = []  # 2D array of tile data
var selected_tile = Vector2(1, 1)  # For keyboard control
var keyboard_mode = false  # Track if using keyboard
var time_elapsed = 0.0
var game_ended = false
const GAME_DURATION = 5.0
var rotating_tiles = []  # Track tiles currently animating

# Preset puzzles from GDD
var puzzles = []

func _ready():
	instruction = "CONNECT!"
	super._ready()
	
	_initialize_sounds()
	_initialize_puzzles()
	_setup_game()

func _initialize_sounds():
	var sfx_rotate = AudioStreamPlayer.new()
	sfx_rotate.name = "sfx_rotate"
	sfx_rotate.stream = load("res://games/loop_connect/assets/sfx_rotate.wav")
	add_child(sfx_rotate)
	
	var sfx_win = AudioStreamPlayer.new()
	sfx_win.name = "sfx_win"
	sfx_win.stream = load("res://games/loop_connect/assets/sfx_win.wav")
	add_child(sfx_win)
	
	var sfx_lose = AudioStreamPlayer.new()
	sfx_lose.name = "sfx_lose"
	sfx_lose.stream = load("res://games/loop_connect/assets/sfx_lose.wav")
	add_child(sfx_lose)

func _initialize_puzzles():
	# Puzzle 1: "The Simple Gap" - 1 rotation at [1,1]
	puzzles.append([
		[PipeType.L_BEND, 1, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.L_BEND, 2],  # Row 0
		[PipeType.STRAIGHT, 1, PipeType.STRAIGHT, 0, PipeType.L_BEND, 2, PipeType.STRAIGHT, 1],  # Row 1 - [1,1] needs rotation
		[PipeType.STRAIGHT, 1, PipeType.L_BEND, 1, PipeType.L_BEND, 3, PipeType.STRAIGHT, 0],  # Row 2
		[PipeType.L_BEND, 0, PipeType.L_BEND, 3, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0]   # Row 3
	])
	
	# Puzzle 2: "Double Loop" - 1 rotation at [1,3]
	puzzles.append([
		[PipeType.L_BEND, 1, PipeType.L_BEND, 2, PipeType.L_BEND, 1, PipeType.L_BEND, 2],  # Row 0
		[PipeType.L_BEND, 0, PipeType.L_BEND, 3, PipeType.L_BEND, 0, PipeType.L_BEND, 1],  # Row 1 - [1,3] needs rotation
		[PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0],  # Row 2
		[PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0]   # Row 3
	])
	
	# Puzzle 3: "T-Junction Twist" - 2 rotations at [2,2] and [3,2]
	puzzles.append([
		[PipeType.L_BEND, 1, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.L_BEND, 2],  # Row 0
		[PipeType.T_JUNCTION, 1, PipeType.L_BEND, 2, PipeType.L_BEND, 1, PipeType.T_JUNCTION, 3],  # Row 1
		[PipeType.L_BEND, 0, PipeType.L_BEND, 3, PipeType.STRAIGHT, 0, PipeType.L_BEND, 3],  # Row 2 - [2,2] needs rotation
		[PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.L_BEND, 0, PipeType.STRAIGHT, 0]   # Row 3 - [3,2] needs rotation
	])
	
	# Puzzle 4: "Cross Roads" - 2 rotations at [3,1] and [3,2]
	puzzles.append([
		[PipeType.STRAIGHT, 0, PipeType.L_BEND, 1, PipeType.L_BEND, 2, PipeType.STRAIGHT, 0],  # Row 0
		[PipeType.L_BEND, 1, PipeType.CROSS, 0, PipeType.CROSS, 0, PipeType.L_BEND, 2],  # Row 1
		[PipeType.L_BEND, 0, PipeType.CROSS, 0, PipeType.CROSS, 0, PipeType.L_BEND, 3],  # Row 2
		[PipeType.STRAIGHT, 0, PipeType.L_BEND, 0, PipeType.L_BEND, 3, PipeType.STRAIGHT, 0]   # Row 3 - [3,1] and [3,2] need rotation
	])
	
	# Puzzle 5: "Snake Path" - 2 rotations at [2,2] and [3,2]
	puzzles.append([
		[PipeType.L_BEND, 1, PipeType.STRAIGHT, 0, PipeType.STRAIGHT, 0, PipeType.L_BEND, 2],  # Row 0
		[PipeType.STRAIGHT, 1, PipeType.L_BEND, 1, PipeType.L_BEND, 2, PipeType.STRAIGHT, 1],  # Row 1
		[PipeType.STRAIGHT, 1, PipeType.L_BEND, 0, PipeType.STRAIGHT, 1, PipeType.STRAIGHT, 1],  # Row 2 - [2,2] needs rotation
		[PipeType.L_BEND, 0, PipeType.STRAIGHT, 0, PipeType.L_BEND, 3, PipeType.L_BEND, 3]   # Row 3 - [3,2] needs rotation
	])

func _setup_game():
	# Draw background
	var bg = ColorRect.new()
	bg.color = Color.WHITE
	bg.position = Vector2.ZERO
	bg.size = Vector2(640, 640)
	bg.z_index = -2
	add_child(bg)
	
	# Draw grid lines
	_draw_grid_lines()
	
	# Load random puzzle
	var puzzle = puzzles[randi() % puzzles.size()]
	
	# Initialize grid with puzzle data
	grid = []
	for row in range(GRID_SIZE):
		var grid_row = []
		for col in range(GRID_SIZE):
			var idx = row * GRID_SIZE * 2 + col * 2
			var pipe_type = puzzle[row][idx]
			var rotation = puzzle[row][idx + 1]
			
			var tile_data = {
				"type": pipe_type,
				"rotation": rotation,
				"sprite": null,
				"highlight": null,
				"flash": null
			}
			
			# Create sprite
			var sprite = Sprite2D.new()
			sprite.texture = load(PIPE_SPRITES[pipe_type])
			sprite.position = _get_tile_position(col, row)
			sprite.rotation_degrees = rotation * 90
			add_child(sprite)
			tile_data.sprite = sprite
			
			# Create highlight border (hidden by default)
			var highlight = ColorRect.new()
			highlight.color = Color(1.0, 0.84, 0.0, 0.0)  # Yellow, transparent initially
			highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
			highlight.position = _get_tile_position(col, row) - Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
			highlight.z_index = -1
			add_child(highlight)
			tile_data.highlight = highlight
			
			grid_row.append(tile_data)
		grid.append(grid_row)
	
	# Show initial selection
	_update_highlight()

func _draw_grid_lines():
	# Draw light gray grid lines
	for i in range(GRID_SIZE + 1):
		# Vertical lines
		var v_line = ColorRect.new()
		v_line.color = Color(0.88, 0.88, 0.88)  # Light gray
		v_line.size = Vector2(1, GRID_SIZE * (TILE_SIZE + TILE_SPACING) - TILE_SPACING)
		v_line.position = GRID_OFFSET + Vector2(i * (TILE_SIZE + TILE_SPACING) - TILE_SPACING / 2, -TILE_SPACING / 2)
		v_line.z_index = -1
		add_child(v_line)
		
		# Horizontal lines
		var h_line = ColorRect.new()
		h_line.color = Color(0.88, 0.88, 0.88)
		h_line.size = Vector2(GRID_SIZE * (TILE_SIZE + TILE_SPACING) - TILE_SPACING, 1)
		h_line.position = GRID_OFFSET + Vector2(-TILE_SPACING / 2, i * (TILE_SIZE + TILE_SPACING) - TILE_SPACING / 2)
		h_line.z_index = -1
		add_child(h_line)

func _get_tile_position(col: int, row: int) -> Vector2:
	return GRID_OFFSET + Vector2(
		col * (TILE_SIZE + TILE_SPACING) + TILE_SIZE / 2,
		row * (TILE_SIZE + TILE_SPACING) + TILE_SIZE / 2
	)

func _process(delta):
	time_elapsed += delta
	
	# Check timeout
	if time_elapsed >= GAME_DURATION:
		if not game_ended:
			$sfx_lose.play()
			end_game()  # Timeout = fail
			game_ended = true
		return
	
	# Stop game logic after win/lose
	if game_ended:
		return

func _input(event):
	if game_ended:
		return
	
	# Mouse/touch input
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.position
		var tile_pos = _get_tile_from_position(mouse_pos)
		if tile_pos != Vector2(-1, -1):
			keyboard_mode = false
			_rotate_tile(int(tile_pos.x), int(tile_pos.y))
	
	# Keyboard input
	if event is InputEventKey and event.pressed:
		keyboard_mode = true
		
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			selected_tile.x = max(0, selected_tile.x - 1)
			_update_highlight()
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			selected_tile.x = min(GRID_SIZE - 1, selected_tile.x + 1)
			_update_highlight()
		elif event.keycode == KEY_UP or event.keycode == KEY_W:
			selected_tile.y = max(0, selected_tile.y - 1)
			_update_highlight()
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			selected_tile.y = min(GRID_SIZE - 1, selected_tile.y + 1)
			_update_highlight()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_rotate_tile(int(selected_tile.x), int(selected_tile.y))

func _get_tile_from_position(pos: Vector2) -> Vector2:
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var tile_pos = _get_tile_position(col, row)
			var half_size = TILE_SIZE / 2
			if pos.x >= tile_pos.x - half_size and pos.x <= tile_pos.x + half_size:
				if pos.y >= tile_pos.y - half_size and pos.y <= tile_pos.y + half_size:
					return Vector2(col, row)
	return Vector2(-1, -1)

func _update_highlight():
	# Hide all highlights
	for row in grid:
		for tile in row:
			tile.highlight.color = Color(1.0, 0.84, 0.0, 0.0)
	
	# Show highlight only in keyboard mode
	if keyboard_mode:
		var tile = grid[int(selected_tile.y)][int(selected_tile.x)]
		tile.highlight.color = Color(1.0, 0.84, 0.0, 0.5)  # Semi-transparent yellow

func _rotate_tile(col: int, row: int):
	if game_ended:
		return
	
	# Don't rotate if already rotating
	if Vector2(col, row) in rotating_tiles:
		return
	
	var tile = grid[row][col]
	rotating_tiles.append(Vector2(col, row))
	
	# Update rotation
	tile.rotation = (tile.rotation + 1) % 4
	
	# Play sound
	$sfx_rotate.play()
	
	# Animate rotation
	var target_rotation = tile.rotation * 90
	var tween = create_tween()
	tween.set_speed_scale(speed_multiplier)  # Scale animation with speed
	tween.tween_property(tile.sprite, "rotation_degrees", target_rotation, 0.1)
	tween.finished.connect(func():
		rotating_tiles.erase(Vector2(col, row))
		# Check win condition after rotation completes
		if _check_win():
			_win_game()
	)

func _check_win() -> bool:
	# Check if all pipes form closed loops with no dead ends
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var tile = grid[row][col]
			var connections = _get_rotated_connections(tile.type, tile.rotation)
			
			# Check each connection point
			for dir in connections:
				var neighbor_pos = _get_neighbor_position(col, row, dir)
				
				# If neighbor is out of bounds, this is a dead end
				if neighbor_pos.x < 0 or neighbor_pos.x >= GRID_SIZE or neighbor_pos.y < 0 or neighbor_pos.y >= GRID_SIZE:
					return false
				
				var neighbor = grid[int(neighbor_pos.y)][int(neighbor_pos.x)]
				var neighbor_connections = _get_rotated_connections(neighbor.type, neighbor.rotation)
				var opposite_dir = _get_opposite_direction(dir)
				
				# Neighbor must have matching connection
				if not opposite_dir in neighbor_connections:
					return false
	
	return true

func _get_rotated_connections(pipe_type: PipeType, rotation: int) -> Array:
	var base_connections = PIPE_CONNECTIONS[pipe_type].duplicate()
	var rotated = []
	
	for dir in base_connections:
		var new_dir = (dir + rotation) % 4
		rotated.append(new_dir)
	
	return rotated

func _get_neighbor_position(col: int, row: int, direction: Direction) -> Vector2:
	match direction:
		Direction.NORTH:
			return Vector2(col, row - 1)
		Direction.EAST:
			return Vector2(col + 1, row)
		Direction.SOUTH:
			return Vector2(col, row + 1)
		Direction.WEST:
			return Vector2(col - 1, row)
	return Vector2(-1, -1)

func _get_opposite_direction(direction: Direction) -> Direction:
	match direction:
		Direction.NORTH:
			return Direction.SOUTH
		Direction.EAST:
			return Direction.WEST
		Direction.SOUTH:
			return Direction.NORTH
		Direction.WEST:
			return Direction.EAST
	return Direction.NORTH

func _win_game():
	if game_ended:
		return
	
	game_ended = true
	$sfx_win.play()
	
	# Flash all tiles green
	for row in grid:
		for tile in row:
			var flash = ColorRect.new()
			flash.color = Color(0.0, 1.0, 0.0, 0.5)  # Semi-transparent green
			flash.size = Vector2(TILE_SIZE, TILE_SIZE)
			flash.position = tile.sprite.position - Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
			add_child(flash)
			
			var tween = create_tween()
			tween.tween_property(flash, "color", Color(0.0, 1.0, 0.0, 0.0), 0.5)
			tween.finished.connect(func(): flash.queue_free())
	
	# Win!
	add_score(100)
	end_game()
