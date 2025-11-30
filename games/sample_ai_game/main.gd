extends Microgame

# Sound effects
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
const SFX_HIT = preload("res://games/sample_ai_game/assets/sfx_hit.wav")

var target: Area2D
var speed: float = 200.0
var direction: Vector2
var viewport_size: Vector2
var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

func _ready():
	instruction = "TAP!"
	super._ready()

	viewport_size = get_viewport_rect().size

	# Create target
	target = Area2D.new()
	target.position = viewport_size / 2
	add_child(target)

	# Add visual (red circle)
	var sprite = Sprite2D.new()
	var grad_tex = GradientTexture2D.new()
	grad_tex.width = 80
	grad_tex.height = 80
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)

	var grad = Gradient.new()
	grad.colors = [Color.RED, Color.RED, Color(1.0, 0.0, 0.0, 0.0)]
	grad.offsets = [0.0, 0.9, 1.0]
	grad_tex.gradient = grad

	sprite.texture = grad_tex
	target.add_child(sprite)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	collision.shape = shape
	target.add_child(collision)

	# Random direction
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

	# Setup audio
	var sfx_win = AudioStreamPlayer.new()
	sfx_win.name = "sfx_win"
	sfx_win.stream = SFX_WIN
	add_child(sfx_win)

	var sfx_lose = AudioStreamPlayer.new()
	sfx_lose.name = "sfx_lose"
	sfx_lose.stream = SFX_LOSE
	add_child(sfx_lose)

	var sfx_hit = AudioStreamPlayer.new()
	sfx_hit.name = "sfx_hit"
	sfx_hit.stream = SFX_HIT
	add_child(sfx_hit)

	print("Sample Game Started: TAP THE TARGET!")

func _process(delta):
	if not is_instance_valid(target):
		return

	time_elapsed += delta

	# Timeout check
	if time_elapsed >= GAME_DURATION:
		if not game_ended:
			$sfx_lose.play()
			end_game()
			game_ended = true
		return

	# Stop game logic after game ends
	if game_ended:
		return

	# Move target with Speed Multiplier
	target.position += direction * speed * delta * speed_multiplier

	# Bounce off walls
	var radius = 40.0

	if target.position.x < radius:
		target.position.x = radius
		direction.x *= -1
	elif target.position.x > viewport_size.x - radius:
		target.position.x = viewport_size.x - radius
		direction.x *= -1

	if target.position.y < radius:
		target.position.y = radius
		direction.y *= -1
	elif target.position.y > viewport_size.y - radius:
		target.position.y = viewport_size.y - radius
		direction.y *= -1

func _input(event):
	# Ignore input after game ends
	if game_ended:
		return

	if not is_instance_valid(target):
		return

	var pos: Vector2
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	else:
		return

	# Check distance to target
	if pos.distance_to(target.position) < 40:
		$sfx_hit.play()
		add_score(100)
		$sfx_win.play()
		end_game()
		game_ended = true
		print("TARGET HIT!")
		target.queue_free()
