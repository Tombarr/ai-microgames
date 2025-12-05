extends Microgame

# Constants
const GAME_DURATION: float = 5.0
const GRAVITY: float = 980.0
const JUMP_VELOCITY: float = -350.0
const BIRD_SIZE: float = 24.0
const PIPE_WIDTH: float = 60.0
const PIPE_GAP: float = 180.0
const PIPE_SPEED: float = 200.0
const PIPE_SPACING: float = 400.0  # Increased spacing between pipes
const TARGET_SCORE: int = 3  # Need to pass 3 pipes in 5 seconds

# Sound effects
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
const SFX_FLAP = preload("res://games/flappy_bird/assets/sfx_flap.wav")
const SFX_PASS = preload("res://games/flappy_bird/assets/sfx_pass.wav")

# State
var bird: Area2D
var bird_velocity: float = 0.0
var pipes: Array[Node2D] = []
var time_elapsed: float = 0.0
var viewport_size: Vector2
var pipes_passed: int = 0
var next_pipe_x: float = 0.0
var game_ended: bool = false
var grace_period: float = 0.3  # Give player time to react before gravity

# Bird visual class using _draw() for pixel-art style
class BirdVisual extends Node2D:
	var flap_angle: float = 0.0

	func _draw():
		# Main body (yellow/orange)
		var body_color = Color(1.0, 0.85, 0.2)
		var dark_color = Color(0.9, 0.65, 0.1)
		var white = Color(1, 1, 1)
		var black = Color(0, 0, 0)

		# Body shadow
		draw_circle(Vector2(2, 2), 20, dark_color)
		# Main body
		draw_circle(Vector2(0, 0), 20, body_color)

		# Wing (flaps up and down)
		var wing_offset = sin(flap_angle) * 4
		draw_polygon([
			Vector2(-8, -2 + wing_offset),
			Vector2(-18, 8 + wing_offset),
			Vector2(-5, 6 + wing_offset)
		], [dark_color])

		# Eye white
		draw_circle(Vector2(8, -6), 10, white)
		# Pupil
		draw_circle(Vector2(11, -6), 5, black)
		# Eye shine
		draw_circle(Vector2(9, -8), 2, white)

		# Beak (orange)
		var beak_color = Color(1.0, 0.5, 0.1)
		draw_polygon([
			Vector2(14, 0),
			Vector2(28, 4),
			Vector2(14, 8)
		], [beak_color])

		# Beak highlight
		draw_polygon([
			Vector2(14, 0),
			Vector2(24, 2),
			Vector2(14, 4)
		], [Color(1.0, 0.7, 0.3)])

# Pipe visual class
class PipeVisual extends Node2D:
	var is_top: bool = false
	var pipe_height: float = 400.0

	func _draw():
		var stem_color = Color(0.0, 0.72, 0.0)
		var highlight_color = Color(0.2, 0.85, 0.2)
		var shadow_color = Color(0.0, 0.5, 0.0)
		var rim_color = Color(0.0, 0.85, 0.0)

		var width = 60.0
		var rim_height = 26.0
		var rim_extra = 8.0

		if is_top:
			# Pipe going up (rim at bottom)
			# Main stem
			draw_rect(Rect2(-width/2, -pipe_height, width, pipe_height - rim_height), stem_color)
			# Highlight
			draw_rect(Rect2(-width/2 + 4, -pipe_height, 10, pipe_height - rim_height), highlight_color)
			# Shadow
			draw_rect(Rect2(width/2 - 12, -pipe_height, 8, pipe_height - rim_height), shadow_color)

			# Rim (at bottom of top pipe)
			draw_rect(Rect2(-width/2 - rim_extra, -rim_height, width + rim_extra*2, rim_height), rim_color)
			# Rim highlight
			draw_rect(Rect2(-width/2 - rim_extra + 4, -rim_height, width - 8, 6), Color(0.3, 0.95, 0.3))
			# Rim shadow
			draw_rect(Rect2(-width/2 - rim_extra, -4, width + rim_extra*2, 4), shadow_color)
		else:
			# Pipe going down (rim at top)
			# Rim first
			draw_rect(Rect2(-width/2 - rim_extra, 0, width + rim_extra*2, rim_height), rim_color)
			# Rim highlight
			draw_rect(Rect2(-width/2 - rim_extra + 4, 0, width - 8, 6), Color(0.3, 0.95, 0.3))
			# Rim shadow
			draw_rect(Rect2(-width/2 - rim_extra, rim_height - 4, width + rim_extra*2, 4), shadow_color)

			# Main stem
			draw_rect(Rect2(-width/2, rim_height, width, pipe_height), stem_color)
			# Highlight
			draw_rect(Rect2(-width/2 + 4, rim_height, 10, pipe_height), highlight_color)
			# Shadow
			draw_rect(Rect2(width/2 - 12, rim_height, 8, pipe_height), shadow_color)

func _ready():
	instruction = "TAP!"
	super._ready()

	viewport_size = get_viewport_rect().size

	# Create sky background
	var bg = ColorRect.new()
	bg.color = Color(0.4, 0.75, 0.95)  # Light blue sky
	bg.size = viewport_size
	bg.z_index = -10
	add_child(bg)

	# Add ground
	_create_ground()

	# Add clouds
	_add_clouds()

	# Create bird
	bird = Area2D.new()
	bird.position = Vector2(viewport_size.x * 0.15, viewport_size.y * 0.4)  # Start slightly higher
	add_child(bird)

	# Bird visual using custom _draw() class
	var bird_visual = BirdVisual.new()
	bird.add_child(bird_visual)

	# Bird collision
	var bird_collision = CollisionShape2D.new()
	var bird_shape = CircleShape2D.new()
	bird_shape.radius = BIRD_SIZE
	bird_collision.shape = bird_shape
	bird.add_child(bird_collision)

	# Setup audio
	var sfx_win = AudioStreamPlayer.new()
	sfx_win.name = "sfx_win"
	sfx_win.stream = SFX_WIN
	add_child(sfx_win)

	var sfx_lose = AudioStreamPlayer.new()
	sfx_lose.name = "sfx_lose"
	sfx_lose.stream = SFX_LOSE
	add_child(sfx_lose)

	var sfx_flap = AudioStreamPlayer.new()
	sfx_flap.name = "sfx_flap"
	sfx_flap.stream = SFX_FLAP
	add_child(sfx_flap)

	var sfx_pass = AudioStreamPlayer.new()
	sfx_pass.name = "sfx_pass"
	sfx_pass.stream = SFX_PASS
	add_child(sfx_pass)

	# Spawn first pipe farther away to give player time to react
	# Use bird's starting Y position for the first pipe gap to ensure it's safe
	next_pipe_x = viewport_size.x * 0.8  # Start at 80% from left (near right edge)
	_spawn_pipe(bird.position.y)

	print("Flappy Bird Started! Pass " + str(TARGET_SCORE) + " pipes!")

func _create_ground():
	var ground = Node2D.new()
	ground.z_index = 10

	var script = GDScript.new()
	script.source_code = """
extends Node2D

func _draw():
	# Ground base (brown)
	draw_rect(Rect2(0, 600, 640, 40), Color(0.6, 0.4, 0.2))

	# Grass on top
	draw_rect(Rect2(0, 590, 640, 12), Color(0.3, 0.75, 0.25))

	# Grass highlight
	draw_rect(Rect2(0, 590, 640, 4), Color(0.4, 0.85, 0.35))

	# Dirt texture lines
	for i in range(5):
		var y = 610 + i * 6
		draw_line(Vector2(0, y), Vector2(640, y), Color(0.5, 0.3, 0.15), 1)
"""
	script.reload()
	ground.set_script(script)
	add_child(ground)

func _add_clouds():
	for i in range(3):
		var cloud = Node2D.new()
		cloud.position = Vector2(100 + i * 200, 80 + randf_range(-30, 30))
		cloud.z_index = -5

		var script = GDScript.new()
		script.source_code = """
extends Node2D

func _draw():
	var cloud_color = Color(1.0, 1.0, 1.0, 0.95)
	var shadow_color = Color(0.9, 0.95, 1.0, 0.8)
	# Cloud shadow
	draw_circle(Vector2(3, 5), 25, shadow_color)
	draw_circle(Vector2(-18, 8), 18, shadow_color)
	draw_circle(Vector2(23, 8), 20, shadow_color)
	# Cloud puffs
	draw_circle(Vector2(0, 0), 25, cloud_color)
	draw_circle(Vector2(-20, 5), 18, cloud_color)
	draw_circle(Vector2(22, 5), 20, cloud_color)
"""
		script.reload()
		cloud.set_script(script)
		add_child(cloud)

func _process(delta):
	time_elapsed += delta

	# Check timeout - surviving 5 seconds is a win!
	if time_elapsed >= GAME_DURATION:
		if not game_ended:
			add_score(100)  # Win by survival
			$sfx_win.play()
			end_game()
			game_ended = true
		return

	# Stop game logic after game ends
	if game_ended:
		return

	# Apply gravity with speed multiplier (after grace period)
	if time_elapsed > grace_period:
		bird_velocity += GRAVITY * speed_multiplier * delta
	bird.position.y += bird_velocity * delta

	# Check if bird hit floor or ceiling
	if bird.position.y < BIRD_SIZE or bird.position.y > viewport_size.y - BIRD_SIZE:
		$sfx_lose.play()
		end_game()  # Fail
		game_ended = true
		return

	# Move pipes with speed multiplier
	for pipe in pipes:
		pipe.position.x -= PIPE_SPEED * speed_multiplier * delta

	# Check collisions and scoring
	for i in range(pipes.size() - 1, -1, -1):
		var pipe = pipes[i]

		# Check if bird passed the pipe (just for scoring, not for win condition)
		if not pipe.get_meta("passed") and pipe.position.x + PIPE_WIDTH < bird.position.x:
			pipe.set_meta("passed", true)
			pipes_passed += 1
			$sfx_pass.play()
			print("Passed pipe! Total: " + str(pipes_passed))

		# Check collision with pipe
		var top_pipe = pipe.get_node("TopPipe")
		var bottom_pipe = pipe.get_node("BottomPipe")

		if bird.overlaps_area(top_pipe) or bird.overlaps_area(bottom_pipe):
			$sfx_lose.play()
			end_game()  # Fail
			game_ended = true
			return

		# Remove off-screen pipes
		if pipe.position.x < -PIPE_WIDTH:
			pipes.remove_at(i)
			pipe.queue_free()

	# Spawn new pipes
	if pipes.is_empty() or pipes[pipes.size() - 1].position.x < viewport_size.x - PIPE_SPACING:
		_spawn_pipe()

func _input(event):
	# Ignore input after game ends
	if game_ended:
		return

	# Touch/tap input for jumping
	if event is InputEventScreenTouch and event.pressed:
		bird_velocity = JUMP_VELOCITY
		$sfx_flap.play()
	# Mouse click for desktop compatibility
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		bird_velocity = JUMP_VELOCITY
		$sfx_flap.play()

func _spawn_pipe(safe_gap_y: float = -1.0):
	var pipe = Node2D.new()

	# Position for next pipe
	if next_pipe_x == 0.0:
		next_pipe_x = viewport_size.x

	pipe.position.x = next_pipe_x
	next_pipe_x += PIPE_SPACING

	add_child(pipe)
	pipe.set_meta("passed", false)

	# Random gap position (keep it reasonable for 5-second gameplay)
	# Use safe_gap_y for first pipe to align with bird's starting position
	var gap_y: float
	if safe_gap_y > 0:
		gap_y = safe_gap_y
	else:
		# Keep gaps in the middle 60% of screen to avoid spawning too high/low
		var min_gap = viewport_size.y * 0.3
		var max_gap = viewport_size.y * 0.7
		gap_y = randf_range(min_gap, max_gap)

	# Top pipe
	var top_pipe = _create_pipe_segment(gap_y - PIPE_GAP / 2, true)
	top_pipe.name = "TopPipe"
	pipe.add_child(top_pipe)

	# Bottom pipe
	var bottom_pipe = _create_pipe_segment(gap_y + PIPE_GAP / 2, false)
	bottom_pipe.name = "BottomPipe"
	pipe.add_child(bottom_pipe)

	pipes.append(pipe)

func _create_pipe_segment(y_pos: float, is_top: bool) -> Area2D:
	var pipe_area = Area2D.new()
	pipe_area.position.y = y_pos

	# Use custom PipeVisual class for better graphics
	var height = viewport_size.y
	var visual = PipeVisual.new()
	visual.is_top = is_top
	visual.pipe_height = height
	pipe_area.add_child(visual)

	# Collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(PIPE_WIDTH, height)
	collision.shape = shape

	if is_top:
		collision.position.y = -height / 2
	else:
		collision.position.y = height / 2

	pipe_area.add_child(collision)

	return pipe_area
