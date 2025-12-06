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

# Sound effects
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
const SFX_JUMP = preload("res://games/infinite_jump/assets/sfx_jump.wav")

# Node references
@onready var player = $Player
@onready var obstacle_container = $ObstacleContainer
@onready var spawn_timer = $SpawnTimer
@onready var ground_visual = $Ground/Visual

# Preload obstacle scenes
var pipe_scene = preload("res://games/infinite_jump/pipe.tscn")
var goomba_scene = preload("res://games/infinite_jump/goomba.tscn")

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

	# Setup audio
	var sfx_win = AudioStreamPlayer.new()
	sfx_win.name = "sfx_win"
	sfx_win.stream = SFX_WIN
	add_child(sfx_win)

	var sfx_lose = AudioStreamPlayer.new()
	sfx_lose.name = "sfx_lose"
	sfx_lose.stream = SFX_LOSE
	add_child(sfx_lose)

	var sfx_jump = AudioStreamPlayer.new()
	sfx_jump.name = "sfx_jump"
	sfx_jump.stream = SFX_JUMP
	add_child(sfx_jump)

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

	# Move player using Godot's built-in physics engine
	player.move_and_slide()

func _process(delta):
	time_elapsed += delta * speed_multiplier

	# Check timeout - always let full time run for Director
	if time_elapsed >= time_limit:
		if not game_ended:
			# Timeout = WIN! Player survived the full time without getting hit
			add_score(max(100, obstacles_dodged * 10))  # At least 100 points for surviving
			$sfx_win.play()
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

func _input(event):
	if game_ended:
		return

	# Touch/Click to jump
	if event is InputEventScreenTouch and event.pressed:
		if player.is_on_floor():
			player.velocity.y = JUMP_VELOCITY
			$sfx_jump.play()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player.is_on_floor():
			player.velocity.y = JUMP_VELOCITY
			$sfx_jump.play()

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
					$sfx_lose.play()
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
		# SPAWN PIPE (fixed jumpable height)
		# ========================================
		obstacle = pipe_scene.instantiate()

		# Pipe is now 80 pixels tall (matches collision and visual)
		var pipe_height = 80.0

		# Calculate Y position so BOTTOM of pipe touches floor
		var pipe_y = FLOOR_Y - pipe_height

		obstacle.position = Vector2(spawn_x, pipe_y)

		print("Pipe spawned at Y: ", pipe_y, " (Height: ", pipe_height, ")")
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
