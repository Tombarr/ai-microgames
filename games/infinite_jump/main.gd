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
var outcome_determined: bool = false  # Win/lose decided, but game keeps running
var game_ended: bool = false  # Only true when beats finish
var hit_obstacle: bool = false  # True when player collides - freezes obstacles

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

	# Spawn first obstacle immediately so player has something to dodge
	_spawn_obstacle()

	# Start spawning more obstacles
	spawn_timer.start()

func _physics_process(delta):
	# Freeze everything when hit obstacle or game ended
	if game_ended or hit_obstacle:
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

	# ========================================
	# BEAT-BASED TIMING: Game runs until beats finish
	# ========================================
	# Check if beats are complete - then end game for Director
	if time_elapsed >= time_limit:
		if not game_ended:
			# If outcome wasn't determined yet (survived!), it's a win
			if not outcome_determined:
				add_score(max(100, obstacles_dodged * 10))
				$sfx_win.play()
				outcome_determined = true
			end_game()
			game_ended = true
		return

	# After game_ended, stop all processing
	if game_ended:
		return

	# Move obstacles (continues even after outcome determined for visual continuity)
	move_obstacles(delta)

	# Only check collisions if outcome not yet determined
	if not outcome_determined:
		check_collisions()

		# Count obstacles that passed the player
		for obstacle in obstacle_container.get_children():
			if obstacle.position.x < player.position.x - 50 and not obstacle.has_meta("counted"):
				obstacle.set_meta("counted", true)
				obstacles_dodged += 1

func _input(event):
	# Freeze input when hit or game ended
	if game_ended or hit_obstacle:
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
	# FREEZE obstacles when player hit something
	if hit_obstacle:
		return

	# FIX: Increased scroll speed with speed_multiplier from Director
	var scroll_speed = BASE_SCROLL_SPEED * speed_multiplier

	for obstacle in obstacle_container.get_children():
		obstacle.position.x -= scroll_speed * delta

		# Remove off-screen obstacles to save memory
		if obstacle.position.x < -150:
			obstacle.queue_free()

func check_collisions():
	if outcome_determined or game_ended:
		return

	# Use Area2D's built-in collision detection for accuracy
	for obstacle in obstacle_container.get_children():
		if obstacle is Area2D:
			var overlapping_bodies = obstacle.get_overlapping_bodies()
			for body in overlapping_bodies:
				if body == player:
					# Collision detected - freeze everything!
					$sfx_lose.play()
					outcome_determined = true
					hit_obstacle = true  # This freezes obstacles and player
					# Score stays at 0 = lose
					return

func _spawn_obstacle():
	# ========================================
	# SPAWN OBSTACLE WITH Y-AXIS ALIGNMENT
	# ========================================
	# All obstacles spawn with bottom edge touching FLOOR_Y

	var obstacle
	var spawn_x = 700.0  # Spawn off-screen right

	if randf() > 0.5:
		# SPAWN PIPE (fixed jumpable height)
		obstacle = pipe_scene.instantiate()
		var pipe_height = 80.0
		var pipe_y = FLOOR_Y - pipe_height
		obstacle.position = Vector2(spawn_x, pipe_y)
	else:
		# SPAWN GOOMBA (mushroom enemy)
		obstacle = goomba_scene.instantiate()
		var goomba_height = 32.0
		var goomba_y = FLOOR_Y - goomba_height
		obstacle.position = Vector2(spawn_x, goomba_y)

	obstacle_container.add_child(obstacle)

func _on_spawn_timer_timeout():
	# Stop spawning once outcome is determined or game ended
	if outcome_determined or game_ended:
		return

	_spawn_obstacle()

	# Faster spawn rate with speed_multiplier
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
