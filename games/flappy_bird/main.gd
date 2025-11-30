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

func _ready():
	instruction = "TAP!"
	super._ready()

	viewport_size = get_viewport_rect().size

	# Create bird
	bird = Area2D.new()
	bird.position = Vector2(viewport_size.x * 0.15, viewport_size.y * 0.4)  # Start slightly higher
	add_child(bird)

	# Bird visual (yellow circle)
	var bird_visual = _create_circle(BIRD_SIZE, Color.YELLOW)
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

	# Visual
	var height = viewport_size.y if is_top else viewport_size.y
	var visual = ColorRect.new()
	visual.color = Color.GREEN
	visual.size = Vector2(PIPE_WIDTH, height)

	if is_top:
		visual.position = Vector2(-PIPE_WIDTH / 2, -height)
	else:
		visual.position = Vector2(-PIPE_WIDTH / 2, 0)

	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pipe_area.add_child(visual)

	# Border
	var border = ReferenceRect.new()
	border.editor_only = false
	border.border_color = Color.DARK_GREEN
	border.border_width = 3.0
	border.size = visual.size
	border.position = visual.position
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pipe_area.add_child(border)

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

func _create_circle(radius: float, color: Color) -> Node2D:
	var circle = Node2D.new()

	var grad_tex = GradientTexture2D.new()
	grad_tex.width = int(radius * 2)
	grad_tex.height = int(radius * 2)
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)

	var grad = Gradient.new()
	grad.colors = [color, color, Color(color.r, color.g, color.b, 0.0)]
	grad.offsets = [0.0, 0.9, 1.0]
	grad_tex.gradient = grad

	var sprite = Sprite2D.new()
	sprite.texture = grad_tex
	circle.add_child(sprite)

	return circle
