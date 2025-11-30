extends "res://shared/scripts/microgame.gd"

# Assets
const TEX_PLAYER = preload("res://games/box_pusher/assets/player.png")
const TEX_BOX = preload("res://games/box_pusher/assets/box.png")
const TEX_TARGET = preload("res://games/box_pusher/assets/target.png")
const TEX_WALL = preload("res://games/box_pusher/assets/wall.png")
const TEX_FLOOR = preload("res://games/box_pusher/assets/floor.png")

const SFX_MOVE = preload("res://games/box_pusher/assets/sfx_move.wav")
const SFX_PUSH = preload("res://games/box_pusher/assets/sfx_push.wav")
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")

# Grid
const TILE_SIZE = 64
const GRID_W = 8 # Increased grid size
const GRID_H = 8 # Increased grid size

const PREMADE_LEVELS = [
	[
		"########",
		"#    ###",
		"# P B T#",
		"#      #",
		"#      #",
		"#  ##  #",
		"#      #",
		"########"
	],
	[
		"########",
		"#   T###",
		"#   B ##",
		"#   P  #",
		"#      #",
		"##     #",
		"###    #",
		"########"
	],
	[
		"########",
		"#      #",
		"#  P   #",
		"# #B#  #",
		"#  T   #",
		"#      #",
		"#      #",
		"########"
	],
	[
		"########",
		"#      #",
		"# T B P#",
		"#  #   #",
		"#  ##  #",
		"#   #  #",
		"#      #",
		"########"
	],
	[
		"########",
		"#T   ###",
		"##B    #",
		"#  P####",
		"#     ##",
		"#      #",
		"#      #",
		"########"
	],
	[
		"########",
		"#     T#",
		"#  ##B #",
		"#   P  #",
		"#  #####",
		"#   ####",
		"#     ##",
		"########"
	],
	[
		"########",
		"####   #",
		"#  P   #",
		"# B    #",
		"#T ##  #",
		"#  ##  #",
		"#####  #",
		"########"
	],
	[
		"########",
		"###    #",
		"#   P  #",
		"#    B##",
		"#     T#",
		"#    ###",
		"#      #",
		"########"
	]
]

enum TileType { FLOOR, WALL, TARGET }

var grid = [] # 2D array [y][x] storing TileType
var player_pos: Vector2i
var box_pos: Vector2i
var target_pos: Vector2i
var game_active = true

# Nodes
@onready var level_root = $LevelRoot
@onready var sfx_move = $SFXMove
@onready var sfx_push = $SFXPush
@onready var sfx_win = $SFXWin
@onready var sfx_lose = $SFXLose

# Visuals
var player_sprite: Sprite2D
var box_sprite: Sprite2D

func _ready():
	instruction = "PUSH!"
	super._ready()
	
	# Initialize Audio Streams
	sfx_move.stream = SFX_MOVE
	sfx_push.stream = SFX_PUSH
	sfx_win.stream = SFX_WIN
	sfx_lose.stream = SFX_LOSE
	
	_load_random_level()
	_render_level()

func _load_random_level():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var layout_idx = rng.randi() % PREMADE_LEVELS.size()
	var layout = PREMADE_LEVELS[layout_idx]
	
	grid = []
	
	for y in range(GRID_H):
		var row_data = []
		var line = layout[y]
		for x in range(GRID_W):
			var line_char = line[x]
			var type = TileType.FLOOR
			
			if line_char == '#':
				type = TileType.WALL
			elif line_char == 'T':
				type = TileType.TARGET
				target_pos = Vector2i(x, y)
			elif line_char == 'B':
				box_pos = Vector2i(x, y)
			elif line_char == 'P':
				player_pos = Vector2i(x, y)
			
			row_data.append(type)
		grid.append(row_data)

func _render_level():
	# Clear previous children if any
	for child in level_root.get_children():
		child.queue_free()
		
	# 1. Determine Viewport Size
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO: 
		viewport_size = Vector2(640, 640)

	# 2. Calculate Scale to fill viewport
	var grid_px_w = GRID_W * TILE_SIZE
	var grid_px_h = GRID_H * TILE_SIZE
	
	var scale_x = viewport_size.x / float(grid_px_w)
	var scale_y = viewport_size.y / float(grid_px_h)
	var final_scale = min(scale_x, scale_y)
	
	# Apply Scale to Root
	level_root.scale = Vector2(final_scale, final_scale)
	
	# 3. Center Level Root
	var scaled_size = Vector2(grid_px_w, grid_px_h) * final_scale
	level_root.position = (viewport_size - scaled_size) / 2.0
	
	for y in range(GRID_H):
		for x in range(GRID_W):
			var pos = Vector2(x * TILE_SIZE + TILE_SIZE/2.0, y * TILE_SIZE + TILE_SIZE/2.0)
			var type = grid[y][x]
			
			# Floor background for everything
			var floor_spr = Sprite2D.new()
			floor_spr.texture = TEX_FLOOR
			floor_spr.centered = true
			floor_spr.position = pos
			level_root.add_child(floor_spr)
			
			if type == TileType.WALL:
				var wall = Sprite2D.new()
				wall.texture = TEX_WALL
				wall.centered = true
				wall.position = pos
				level_root.add_child(wall)
			elif type == TileType.TARGET:
				var target = Sprite2D.new()
				target.texture = TEX_TARGET
				target.centered = true
				target.position = pos
				level_root.add_child(target)

	# Create dynamic sprites
	box_sprite = Sprite2D.new()
	box_sprite.texture = TEX_BOX
	box_sprite.centered = true
	box_sprite.z_index = 1
	# Force scale to fit tile
	var box_scale = (TILE_SIZE / float(TEX_BOX.get_width())) * 0.9
	box_sprite.scale = Vector2(box_scale, box_scale)
	level_root.add_child(box_sprite)
	_update_sprite_pos(box_sprite, box_pos)
	
	player_sprite = Sprite2D.new()
	player_sprite.texture = TEX_PLAYER
	player_sprite.centered = true
	player_sprite.z_index = 2
	# Force scale to fit tile
	var player_scale = (TILE_SIZE / float(TEX_PLAYER.get_width())) * 0.9
	player_sprite.scale = Vector2(player_scale, player_scale)
	level_root.add_child(player_sprite)
	_update_sprite_pos(player_sprite, player_pos)

func _update_sprite_pos(sprite, grid_pos):
	sprite.position = Vector2(grid_pos.x * TILE_SIZE + TILE_SIZE/2.0, grid_pos.y * TILE_SIZE + TILE_SIZE/2.0)

func _unhandled_input(event):
	if not game_active:
		return
	
	var dir = Vector2i.ZERO
	# Arrow keys
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		dir = Vector2i.UP
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		dir = Vector2i.DOWN
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		dir = Vector2i.LEFT
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		dir = Vector2i.RIGHT
		
	if dir != Vector2i.ZERO:
		_try_move(dir)

func _try_move(dir: Vector2i):
	var next_pos = player_pos + dir
	
	if _is_wall(next_pos):
		return # Blocked
		
	if next_pos == box_pos:
		# Pushing Box
		var box_next = box_pos + dir
		if _is_wall(box_next):
			return # Box blocked by wall
		
		# Push box
		box_pos = box_next
		_update_sprite_pos(box_sprite, box_pos)
		player_pos = next_pos
		_update_sprite_pos(player_sprite, player_pos)
		sfx_push.play()
		
		# Check Win
		if box_pos == target_pos:
			_win()
		else:
			_check_stuck()
	else:
		# Just walking
		player_pos = next_pos
		_update_sprite_pos(player_sprite, player_pos)
		sfx_move.play()

func _check_stuck():
	# Simple Deadlock Detection: Corner
	# If box is blocked horizontally AND vertically, and not on target -> Stuck
	
	var blocked_h = _is_wall(box_pos + Vector2i.LEFT) or _is_wall(box_pos + Vector2i.RIGHT)
	var blocked_v = _is_wall(box_pos + Vector2i.UP) or _is_wall(box_pos + Vector2i.DOWN)
	
	if blocked_h and blocked_v:
		print("Box Stuck! Game Over.")
		_fail()

func _is_wall(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= GRID_W or pos.y < 0 or pos.y >= GRID_H:
		return true
	return grid[pos.y][pos.x] == TileType.WALL

func _win():
	if not game_active:
		return
	game_active = false
	sfx_win.play()
	add_score(1)
	end_game()
	print("Game Won!")

func _fail():
	if not game_active:
		return
	game_active = false
	sfx_lose.play()
	end_game()
	print("Game Lost!")
