extends Microgame

var target: Area2D
var speed: float = 200.0
var direction: Vector2
var viewport_size: Vector2
var time_elapsed: float = 0.0
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

	print("Sample Game Started: TAP THE TARGET!")

func _process(delta):
	if not is_instance_valid(target):
		return

	time_elapsed += delta

	# Timeout check
	if time_elapsed >= GAME_DURATION:
		add_score(0)
		end_game()
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
		add_score(100)
		end_game()
		print("TARGET HIT!")
		target.queue_free()
