extends Microgame

# Grid configuration
const GRID_SIZE = 4
const VIEWPORT_SIZE = 640  # 640x640 viewport
const PADDING = 20  # Outer padding from viewport edge
const BORDER_WIDTH = 2  # Thin border between tiles

# Calculate tile size to fill viewport
# Total available space = VIEWPORT_SIZE - (2 * PADDING) - (BORDER_WIDTH * (GRID_SIZE - 1))
# TILE_SIZE = available_space / GRID_SIZE
const AVAILABLE_SPACE = VIEWPORT_SIZE - (2 * PADDING) - (BORDER_WIDTH * (GRID_SIZE - 1))
const TILE_SIZE = AVAILABLE_SPACE / float(GRID_SIZE)  # Each tile fills its square
const GRID_OFFSET = Vector2(PADDING, PADDING)  # Start from padding edge

# Pipe type definitions with connection points
enum PipeType { BLANK, STRAIGHT, L_BEND, T_JUNCTION, CROSS, TERMINAL }
enum Direction { NORTH, EAST, SOUTH, WEST }

# Pipe connection data: which sides have openings (matching sprite assets)
const PIPE_CONNECTIONS = {
	PipeType.BLANK: [],  # No connections
	PipeType.STRAIGHT: [Direction.EAST, Direction.WEST],  # Horizontal ═ by default (sprite is horizontal)
	PipeType.L_BEND: [Direction.SOUTH, Direction.EAST],  # Bottom-right corner ╔ by default (sprite has S,E)
	PipeType.T_JUNCTION: [Direction.NORTH, Direction.EAST, Direction.WEST],  # ╩ Missing south (sprite has N,E,W)
	PipeType.CROSS: [Direction.NORTH, Direction.EAST, Direction.SOUTH, Direction.WEST],
	PipeType.TERMINAL: [Direction.NORTH]  # Single opening pointing up
}

# Sprite paths
const PIPE_SPRITES = {
	PipeType.STRAIGHT: "res://games/loop_connect/assets/pipe_straight.png",
	PipeType.L_BEND: "res://games/loop_connect/assets/pipe_l_bend.png",
	PipeType.T_JUNCTION: "res://games/loop_connect/assets/pipe_t_junction.png",
	PipeType.CROSS: "res://games/loop_connect/assets/pipe_cross.png",
	PipeType.TERMINAL: "res://games/loop_connect/assets/pipe_terminal.png"
}

# Puzzle definitions using text notation
# Format: Each line is a row, each character pair is (type)(rotation)
# Types: . = blank, - = straight, L = L-bend, T = T-junction, + = cross, O = terminal
#
# ROTATION REFERENCE (base connections rotate clockwise):
# ═══════════════════════════════════════════════════════
# STRAIGHT (-): Base has E,W connections (horizontal ═)
#   -0 = ═ (E,W)    -1 = ║ (N,S)    -2 = ═ (E,W)*   -3 = ║ (N,S)*
#   * Note: 0/2 and 1/3 are identical - normalized internally
#
# L_BEND (L): Base has S,E connections (╔ top-left corner, opens down and right)
#   L0 = ╔ (S,E)    L1 = ╗ (S,W)    L2 = ╝ (N,W)    L3 = ╚ (N,E)
#
# T_JUNCTION (T): Base has N,E,W connections (╩ opens up, left, right)
#   T0 = ╩ (N,E,W)  T1 = ╠ (N,E,S)  T2 = ╦ (E,S,W)  T3 = ╣ (N,S,W)
#
# CROSS (+): All 4 connections, rotation doesn't matter visually
#   +0 = ╬ (N,E,S,W)
#
# TERMINAL (O): Base has N connection only
#   O0 = ↑ (N)      O1 = → (E)      O2 = ↓ (S)      O3 = ← (W)
# ═══════════════════════════════════════════════════════

# L_BEND rotation: L0=╔(S,E) → L1=╗(S,W) → L2=╝(N,W) → L3=╚(N,E) → L0
# STRAIGHT rotation: -0=═(E,W) → -1=║(N,S) → -0=═(E,W)...

# PUZZLE 1: Single small loop - 1 rotation needed
# Target: ╔╗    L0=╔ L1=╗
#         ╚╝    L3=╚ L2=╝
# Start:  ╔╗
#         ╚╔    [1,1] is ╔ (L0), needs 1 rotation to become ╗ (L1)
const PUZZLE_1 = [
	"L0L1.0.0",  # ╔╗··
	"L3L0.0.0",  # ╚╔·· ← [1,1] needs 1 rotation
	".0.0.0.0",  # ····
	".0.0.0.0"   # ····
]

# PUZZLE 2: Horizontal line loop - 1 rotation needed
# Target: ╔══╗    L0 -0 -0 L1
#         ╚══╝    L3 -0 -0 L2
# Start:  ╔═╗╗    [0,3] is ╗ (L1), but should be... wait need different puzzle
#         ╚══╝
const PUZZLE_2 = [
	"L0-1-0L1",  # ╔║═╗ ← [0,1] is ║, needs 1 rotation to become ═
	"L3-0-0L2",  # ╚══╝
	".0.0.0.0",  # ····
	".0.0.0.0"   # ····
]

# PUZZLE 3: Simple square loop centered - 1 rotation needed
# Target: ·╔╗·
#         ·╚╝·
# Start:  ·╔╗·
#         ·╚╔·    [1,2] is ╔ (L0), needs 1 rotation to become ╗ (L1)
const PUZZLE_3 = [
	".0L0L1.0",  # ·╔╗·
	".0-1-1.0",  # ·║║· ← [1,2] needs 1 rotation
	".0L3L0.0",  # ·╚╔·
	".0.0.0.0"   # ····
]

# PUZZLE 4: Two separate small loops - 2 rotations needed  
# Target: ╔╗╔╗    L0 L1 L0 L1
#         ╚╝╚╝    L3 L2 L3 L2
# Start:  ╔╗╔╗    All correct except...
#         ╚╝╝╝    [1,2] is ╝ (L2), needs 1 rotation to become ╚ (L3)
#                 [1,3] is ╝ (L2), needs 0 rotations... wait need 2 wrong tiles
# REDESIGN:
# Start:  ╔╗╔╗
#         ╝╝╝╝    [1,0] needs 1 rot to ╚, [1,2] needs 1 rot to ╚
const PUZZLE_4 = [
	"L0L1L0L1",  # ╔╗╔╗
	"L2L2L2L2",  # ╝╝╝╝ ← [1,0] and [1,2] need 1 rotation each to become ╚
	".0.0.0.0",  # ····
	".0.0.0.0"   # ····
]

# PUZZLE 5: Vertical rectangle - 2 rotations needed
# Target: ╔╗··    L0 L1
#         ║║··    -1 -1
#         ╚╝··    L3 L2
# Start:  ╔╗··
#         ══··    [1,0] and [1,1] are ═ (-0), need 1 rotation each to become ║ (-1)
#         ╚╝··
const PUZZLE_5 = [
	"L0L1.0.0",  # ╔╗··
	"-0-0.0.0",  # ══·· ← [1,0] and [1,1] need 1 rotation each
	"L3L2.0.0",  # ╚╝··
	".0.0.0.0"   # ····
]

# PUZZLE 6: Horizontal line loop - 1 rotation needed
# Target: ╔╗
#         ╚╝
# Start:  ╔╗
#         ╝╝      [1,0] is ╝ (L2), needs 1 rotation to become ╚ (L3)
const PUZZLE_6 = [
	".0.0.0.0",  # ╔╗··
	".0L0L1.0",  # ╝╝·· ← [1,0] needs 1 rotation to become ╚
	".0L3L0.0",  # ····
	".0.0.0.0"   # ····
]

const PUZZLES = [PUZZLE_1, PUZZLE_2, PUZZLE_3, PUZZLE_4, PUZZLE_5, PUZZLE_6]

# Game state
var grid = []  # 2D array of tile data
var selected_tile = Vector2(1, 1)  # For keyboard control
var keyboard_mode = false  # Track if using keyboard
var time_elapsed = 0.0
var game_ended = false
const GAME_DURATION = 5.0
var rotating_tiles = []  # Track tiles currently animating

func _ready():
	instruction = "CONNECT!"
	super._ready()
	
	_initialize_sounds()
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

func _parse_puzzle(puzzle_strings: Array) -> Array:
	"""Parse puzzle from text notation to tile data array."""
	var parsed_puzzle = []
	
	for row_str in puzzle_strings:
		var row_data = []
		# Parse pairs of characters (type, rotation)
		for i in range(0, row_str.length(), 2):
			var type_char = row_str[i]
			var rotation_char = row_str[i + 1]
			
			# Convert type character to PipeType enum
			var pipe_type = PipeType.BLANK
			match type_char:
				".": pipe_type = PipeType.BLANK
				"-": pipe_type = PipeType.STRAIGHT
				"L": pipe_type = PipeType.L_BEND
				"T": pipe_type = PipeType.T_JUNCTION
				"+": pipe_type = PipeType.CROSS
				"O": pipe_type = PipeType.TERMINAL
			
			# Convert rotation character to int
			var rotation_value = int(rotation_char)
			
			row_data.append(pipe_type)
			row_data.append(rotation_value)
		
		parsed_puzzle.append(row_data)
	
	return parsed_puzzle

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
	
	# Load random puzzle and parse it
	var puzzle_strings = PUZZLES[randi() % PUZZLES.size()]
	var puzzle = _parse_puzzle(puzzle_strings)
	
	# Initialize grid with puzzle data
	grid = []
	for row in range(GRID_SIZE):
		var grid_row = []
		for col in range(GRID_SIZE):
			var idx = col * 2
			var pipe_type = puzzle[row][idx]
			var pipe_rotation = puzzle[row][idx + 1]
			
			var tile_data = {
				"type": pipe_type,
				"rotation": pipe_rotation,
				"sprite": null,
				"highlight": null,
				"flash": null
			}
			
			# Create sprite (only for non-blank tiles)
			if pipe_type != PipeType.BLANK:
				var sprite = Sprite2D.new()
				sprite.texture = load(PIPE_SPRITES[pipe_type])
				sprite.position = _get_tile_position(col, row)
				# Normalize rotation for straight pipes (0,2 look the same; 1,3 look the same)
				var visual_rotation = pipe_rotation
				if pipe_type == PipeType.STRAIGHT:
					visual_rotation = pipe_rotation % 2
				sprite.rotation_degrees = visual_rotation * 90
				# Scale sprite to fill tile size
				var sprite_size = sprite.texture.get_size()
				sprite.scale = Vector2(TILE_SIZE / sprite_size.x, TILE_SIZE / sprite_size.y)
				add_child(sprite)
				tile_data.sprite = sprite
			
			# Create highlight border (hidden by default)
			var highlight = ColorRect.new()
			highlight.color = Color(1.0, 0.84, 0.0, 0.0)  # Yellow, transparent initially
			highlight.size = Vector2(TILE_SIZE, TILE_SIZE)
			highlight.position = _get_tile_position(col, row) - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
			highlight.z_index = -1
			add_child(highlight)
			tile_data.highlight = highlight
			
			grid_row.append(tile_data)
		grid.append(grid_row)
	
	# Show initial selection
	_update_highlight()

func _draw_grid_lines():
	# Draw borders between tiles (light gray)
	# Draw vertical borders (between columns)
	for i in range(1, GRID_SIZE):
		var v_line = ColorRect.new()
		v_line.color = Color(0.88, 0.88, 0.88)  # Light gray
		v_line.size = Vector2(BORDER_WIDTH, VIEWPORT_SIZE - 2 * PADDING)
		var x_pos = PADDING + i * TILE_SIZE + (i - 1) * BORDER_WIDTH
		v_line.position = Vector2(x_pos, PADDING)
		v_line.z_index = -1
		add_child(v_line)
	
	# Draw horizontal borders (between rows)
	for i in range(1, GRID_SIZE):
		var h_line = ColorRect.new()
		h_line.color = Color(0.88, 0.88, 0.88)
		h_line.size = Vector2(VIEWPORT_SIZE - 2 * PADDING, BORDER_WIDTH)
		var y_pos = PADDING + i * TILE_SIZE + (i - 1) * BORDER_WIDTH
		h_line.position = Vector2(PADDING, y_pos)
		h_line.z_index = -1
		add_child(h_line)

func _get_tile_position(col: int, row: int) -> Vector2:
	# Calculate position: padding + (tiles before this one) + (borders before this one) + half tile size
	return Vector2(
		PADDING + col * TILE_SIZE + col * BORDER_WIDTH + TILE_SIZE / 2.0,
		PADDING + row * TILE_SIZE + row * BORDER_WIDTH + TILE_SIZE / 2.0
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
			var half_size = TILE_SIZE / 2.0
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
	
	var tile = grid[row][col]
	
	# Don't rotate blank tiles
	if tile.type == PipeType.BLANK:
		return
	
	# Don't rotate if already rotating
	if Vector2(col, row) in rotating_tiles:
		return
	
	rotating_tiles.append(Vector2(col, row))
	
	# Update rotation
	tile.rotation = (tile.rotation + 1) % 4
	
	# Play sound
	$sfx_rotate.play()
	
	# Calculate visual rotation
	# For straight pipes, only 2 visual states exist (0° horizontal, 90° vertical)
	# For other pipes, use full 4-state rotation
	var target_rotation: float
	if tile.type == PipeType.STRAIGHT:
		# Straight pipes alternate between 0° and 90°
		target_rotation = (tile.rotation % 2) * 90.0
		# Snap immediately to avoid weird backwards animation
		tile.sprite.rotation_degrees = target_rotation
	else:
		target_rotation = tile.rotation * 90.0
	
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
			
			# Skip blank tiles
			if tile.type == PipeType.BLANK:
				continue
			
			var connections = _get_rotated_connections(tile.type, tile.rotation)
			
			# Check each connection point
			for dir in connections:
				var neighbor_pos = _get_neighbor_position(col, row, dir)
				
				# If neighbor is out of bounds, this is a dead end
				if neighbor_pos.x < 0 or neighbor_pos.x >= GRID_SIZE or neighbor_pos.y < 0 or neighbor_pos.y >= GRID_SIZE:
					return false
				
				var neighbor = grid[int(neighbor_pos.y)][int(neighbor_pos.x)]
				
				# If neighbor is blank, this is a dead end
				if neighbor.type == PipeType.BLANK:
					return false
				
				var neighbor_connections = _get_rotated_connections(neighbor.type, neighbor.rotation)
				var opposite_dir = _get_opposite_direction(dir)
				
				# Neighbor must have matching connection
				if not opposite_dir in neighbor_connections:
					return false
	
	return true

func _get_rotated_connections(pipe_type: PipeType, pipe_rotation: int) -> Array:
	var base_connections = PIPE_CONNECTIONS[pipe_type].duplicate()
	var rotated = []
	
	# Normalize rotation for straight pipes (0,2 are identical; 1,3 are identical)
	var effective_rotation = pipe_rotation
	if pipe_type == PipeType.STRAIGHT:
		effective_rotation = pipe_rotation % 2
	
	for dir in base_connections:
		var new_dir = (dir + effective_rotation) % 4
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
	
	# Flash all non-blank tiles green
	for row in grid:
		for tile in row:
			# Skip blank tiles (no sprite)
			if tile.sprite == null:
				continue
			
			var flash = ColorRect.new()
			flash.color = Color(0.0, 1.0, 0.0, 0.5)  # Semi-transparent green
			flash.size = Vector2(TILE_SIZE, TILE_SIZE)
			flash.position = tile.sprite.position - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
			add_child(flash)
			
			var tween = create_tween()
			tween.tween_property(flash, "color", Color(0.0, 1.0, 0.0, 0.0), 0.5)
			tween.finished.connect(func(): flash.queue_free())
	
	# Win!
	add_score(100)
	end_game()
