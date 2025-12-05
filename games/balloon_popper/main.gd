extends Microgame

# Sound effects
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
const SFX_HIT = preload("res://games/balloon_popper/assets/sfx_hit.wav")

var target: Area2D
var speed: float = 200.0
var direction: Vector2
var viewport_size: Vector2
var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

# Balloon visual class using _draw() for high-quality graphics
class BalloonVisual extends Node2D:
	var balloon_color: Color = Color(0.9, 0.1, 0.1)
	var highlight_color: Color = Color(1.0, 0.5, 0.5)
	var shadow_color: Color = Color(0.6, 0.0, 0.0)

	func _draw():
		# Balloon body (oval shape using multiple ellipses)
		var center = Vector2(0, -10)
		var width = 40.0
		var height = 50.0

		# Main balloon body (draw as overlapping circles for oval effect)
		# Shadow side (right)
		draw_circle(center + Vector2(8, 0), 32, shadow_color)
		# Main body
		draw_circle(center, 36, balloon_color)
		# Highlight (top-left shine)
		draw_circle(center + Vector2(-12, -12), 14, highlight_color)
		draw_circle(center + Vector2(-8, -8), 8, Color(1.0, 0.8, 0.8))

		# Balloon knot (bottom)
		var knot_y = 32
		draw_polygon([
			Vector2(-6, knot_y),
			Vector2(0, knot_y + 10),
			Vector2(6, knot_y)
		], [Color(0.7, 0.0, 0.0)])

		# String
		var string_color = Color(0.4, 0.3, 0.2)
		draw_line(Vector2(0, knot_y + 10), Vector2(-4, knot_y + 30), string_color, 2.0)
		draw_line(Vector2(-4, knot_y + 30), Vector2(2, knot_y + 50), string_color, 2.0)
		draw_line(Vector2(2, knot_y + 50), Vector2(-2, knot_y + 70), string_color, 2.0)

func _ready():
	instruction = "POP!"
	super._ready()

	viewport_size = get_viewport_rect().size

	# Create sky background
	var bg = ColorRect.new()
	bg.color = Color(0.5, 0.8, 1.0)  # Light blue sky
	bg.size = viewport_size
	bg.z_index = -10
	add_child(bg)

	# Add some clouds for atmosphere
	_add_clouds()

	# Create target
	target = Area2D.new()
	target.position = viewport_size / 2
	add_child(target)

	# Add visual using custom _draw() class
	var balloon_visual = BalloonVisual.new()
	target.add_child(balloon_visual)

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

	print("Balloon Popper Started: POP THE BALLOON!")

func _add_clouds():
	# Add decorative clouds in background
	for i in range(4):
		var cloud = Node2D.new()
		cloud.position = Vector2(randf_range(50, 590), randf_range(50, 200))
		cloud.z_index = -5
		cloud.set_script(_create_cloud_script())
		add_child(cloud)

func _create_cloud_script() -> GDScript:
	var script = GDScript.new()
	script.source_code = """
extends Node2D

func _draw():
	var cloud_color = Color(1.0, 1.0, 1.0, 0.9)
	var shadow_color = Color(0.9, 0.9, 0.95, 0.7)
	# Cloud puffs (overlapping circles)
	draw_circle(Vector2(-20, 5), 20, shadow_color)
	draw_circle(Vector2(20, 5), 22, shadow_color)
	draw_circle(Vector2(0, 0), 28, cloud_color)
	draw_circle(Vector2(-25, 0), 18, cloud_color)
	draw_circle(Vector2(25, 0), 20, cloud_color)
"""
	script.reload()
	return script

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
		print("BALLOON POPPED!")
		target.queue_free()
