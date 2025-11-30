extends Microgame

# ========================================
# FIXED & BALANCED MARIO INFINITE RUNNER
# ========================================
# FIXES APPLIED:
# 1. Increased scroll speed for snappy gameplay
# 2. Y-axis alignment - all obstacles spawn on same ground level
# 3. Pipe height clamped to max jump height
# 4. Faster gravity and jump for responsive feel
# ========================================

# Node references
@onready var player = $Player
@onready var obstacle_container = $ObstacleContainer
@onready var spawn_timer = $SpawnTimer
@onready var ground_visual = $Ground/Visual

# Preload obstacle scenes
var pipe_scene = preload("res://games/infinite_jump2/pipe.tscn")
var goomba_scene = preload("res://games/infinite_jump2/goomba.tscn")

# Game state
var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

# ========================================
# PHASE 1: CRITICAL Y-AXIS ALIGNMENT
# ========================================
# Define exact floor Y-coordinate for consistent spawning
const FLOOR_Y: float = 580.0  # Ground collision is at y=580

# Player collision box dimensions (must match CollisionShape2D)
const PLAYER_HEIGHT: float = 40.0  # Height of player sprite
const PLAYER_WIDTH: float = 32.0

# ========================================
# PHASE 2: BALANCED PHYSICS (SNAPPY FEEL)
# ========================================
# FIX: Increased gravity for less "floaty" feel
const GRAVITY: float = 1800.0  # Was 980, now much faster fall

# FIX: Increased jump force to match higher gravity
const JUMP_VELOCITY: float = -650.0  # Was -450, now higher jump

# FIX: Increased scroll speed for fast-paced gameplay
const BASE_SCROLL_SPEED: float = 350.0  # Was 200, now 75% faster!

# ========================================
# PHASE 3: JUMP HEIGHT CALCULATION
# ========================================
# Calculate max jump height to clamp pipe generation
# Physics formula: max_height = (jump_velocity^2) / (2 * gravity)
var max_jump_height: float = 0.0

# Obstacle spawning
var obstacles_dodged: int = 0
var is_crouching: bool = false

func _ready():
	instruction = "DODGE!"
	super._ready()
	
	# Calculate maximum jump height based on physics
	# This ensures pipes never exceed what Mario can jump over
	max_jump_height = (JUMP_VELOCITY * JUMP_VELOCITY) / (2.0 * GRAVITY)
	print("Max Jump Height Calculated: ", max_jump_height, " pixels")
	
	# Trigger ground visual redraw
	if ground_visual:
		ground_visual.queue_redraw()
	
	# Start spawning obstacles
	spawn_timer.start()

func _physics_process(delta):
	if game_ended:
		return
	
	# Handle player input for ducking
	handle_player_input()
	
	# FIX: Apply faster gravity when not on floor
	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta
	
	# FIX: Jump input - ONLY when on floor (prevents double jump)
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up"):
		if player.is_on_floor():
			player.velocity.y = JUMP_VELOCITY
	
	# Move player using Godot's built-in physics engine
	player.move_and_slide()

func _process(delta):
	time_elapsed += delta
	
	# Check timeout - always let full 5 seconds run for Director
	if time_elapsed >= GAME_DURATION:
		if not game_ended:
			# Timeout = success if player survived
			if obstacles_dodged > 0:
				add_score(obstacles_dodged * 10)
			end_game()
			game_ended = true
		return
	
	# Stop game logic after win/lose
	if game_ended:
		return
	
	# Move obstacles at increased speed
	move_obstacles(delta)
	
	# Check collisions with proper hitbox alignment
	check_collisions()
	
	# Count obstacles that passed the player
	for obstacle in obstacle_container.get_children():
		if obstacle.position.x < player.position.x - 50 and not obstacle.has_meta("counted"):
			obstacle.set_meta("counted", true)
			obstacles_dodged += 1

func handle_player_input():
	if game_ended:
		return
	
	# Crouch/Duck mechanic (dodges low pipes)
	if Input.is_action_pressed("ui_down"):
		is_crouching = true
		player.scale.y = 0.6  # Squash player vertically
	else:
		is_crouching = false
		player.scale.y = 1.0  # Normal height

func move_obstacles(delta):
	# FIX: Increased scroll speed with speed_multiplier from Director
	var scroll_speed = BASE_SCROLL_SPEED * speed_multiplier
	
	for obstacle in obstacle_container.get_children():
		obstacle.position.x -= scroll_speed * delta
		
		# Remove off-screen obstacles to save memory
		if obstacle.position.x < -150:
			obstacle.queue_free()

func check_collisions():
	if game_ended:
		return
	
	# Use Area2D's built-in collision detection for accuracy
	for obstacle in obstacle_container.get_children():
		if obstacle is Area2D:
			var overlapping_bodies = obstacle.get_overlapping_bodies()
			for body in overlapping_bodies:
				if body == player:
					# Collision detected - game over
					end_game()
					game_ended = true
					return

func _on_spawn_timer_timeout():
	if game_ended:
		return
	
	# ========================================
	# FIX: Y-AXIS ALIGNMENT FOR ALL OBSTACLES
	# ========================================
	# All obstacles spawn with bottom edge touching FLOOR_Y
	
	var obstacle
	var spawn_x = 700.0  # Spawn off-screen right
	
	if randf() > 0.5:
		# ========================================
		# SPAWN PIPE (with height clamping)
		# ========================================
		obstacle = pipe_scene.instantiate()
		
		# Get pipe collision dimensions
		var pipe_height = 160.0  # Default pipe stem height
		
		# FIX: Clamp pipe height to 80% of max jump height
		# This ensures Mario can ALWAYS jump over pipes
		var max_allowed_pipe_height = max_jump_height * 0.7  # 70% safety margin
		pipe_height = min(pipe_height, max_allowed_pipe_height)
		
		# FIX: Calculate Y position so BOTTOM of pipe touches floor
		# pipe.position is at top-left of sprite, so we subtract height
		var pipe_y = FLOOR_Y - pipe_height
		
		obstacle.position = Vector2(spawn_x, pipe_y)
		
		print("Pipe spawned at Y: ", pipe_y, " (Height: ", pipe_height, ", Max allowed: ", max_allowed_pipe_height, ")")
	else:
		# ========================================
		# SPAWN GOOMBA (mushroom enemy)
		# ========================================
		obstacle = goomba_scene.instantiate()
		
		# Get goomba collision dimensions
		var goomba_height = 32.0  # Goomba sprite height
		
		# FIX: Calculate Y position so BOTTOM of goomba touches floor
		var goomba_y = FLOOR_Y - goomba_height
		
		obstacle.position = Vector2(spawn_x, goomba_y)
		
		print("Goomba spawned at Y: ", goomba_y, " (Height: ", goomba_height, ")")
	
	obstacle_container.add_child(obstacle)
	
	# FIX: Faster spawn rate with speed_multiplier
	# At higher speeds, obstacles spawn more frequently
	# REDUCED: Halved spawn interval for tighter obstacle spacing
	var spawn_interval = randf_range(0.6, 1.0) / speed_multiplier
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

# ========================================
# DEBUG HELPER (Optional)
# ========================================
# Uncomment to visualize collision boxes
# func _draw():
# 	# Draw floor line for reference
# 	draw_line(Vector2(0, FLOOR_Y), Vector2(640, FLOOR_Y), Color.RED, 2.0)
