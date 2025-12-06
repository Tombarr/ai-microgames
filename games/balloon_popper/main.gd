extends Microgame

# Sound effects
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
const SFX_HIT = preload("res://games/balloon_popper/assets/sfx_hit.wav")

# Balloon colors (main, highlight, shadow)
const BALLOON_COLORS = [
	{"main": Color(0.9, 0.1, 0.1), "highlight": Color(1.0, 0.5, 0.5), "shadow": Color(0.6, 0.0, 0.0)},  # Red
	{"main": Color(0.1, 0.6, 0.9), "highlight": Color(0.5, 0.8, 1.0), "shadow": Color(0.0, 0.3, 0.6)},  # Blue
	{"main": Color(0.1, 0.8, 0.3), "highlight": Color(0.5, 1.0, 0.6), "shadow": Color(0.0, 0.5, 0.1)},  # Green
	{"main": Color(0.9, 0.7, 0.1), "highlight": Color(1.0, 0.9, 0.5), "shadow": Color(0.6, 0.4, 0.0)},  # Yellow
	{"main": Color(0.8, 0.2, 0.8), "highlight": Color(1.0, 0.6, 1.0), "shadow": Color(0.5, 0.0, 0.5)},  # Purple
	{"main": Color(0.9, 0.5, 0.2), "highlight": Color(1.0, 0.7, 0.5), "shadow": Color(0.6, 0.3, 0.0)},  # Orange
]

const NUM_BALLOONS: int = 3
const BALLOONS_TO_POP: int = 3  # Pop all balloons to win
var balloons: Array = []  # Array of dictionaries with balloon data
var balloons_popped: int = 0

var base_speed: float = 180.0
var viewport_size: Vector2
var time_elapsed: float = 0.0
var game_ended: bool = false

# Balloon visual class using _draw() for high-quality graphics
class BalloonVisual extends Node2D:
	var balloon_color: Color = Color(0.9, 0.1, 0.1)
	var highlight_color: Color = Color(1.0, 0.5, 0.5)
	var shadow_color: Color = Color(0.6, 0.0, 0.0)

	func _draw():
		var center = Vector2(0, -10)

		# Shadow side (right)
		draw_circle(center + Vector2(8, 0), 32, shadow_color)
		# Main body
		draw_circle(center, 36, balloon_color)
		# Highlight (top-left shine)
		draw_circle(center + Vector2(-12, -12), 14, highlight_color)
		draw_circle(center + Vector2(-8, -8), 8, Color(1.0, 0.9, 0.9, 0.8))

		# Balloon knot (bottom)
		var knot_y = 32
		draw_polygon([
			Vector2(-6, knot_y),
			Vector2(0, knot_y + 10),
			Vector2(6, knot_y)
		], [shadow_color])

		# String
		var string_color = Color(0.4, 0.3, 0.2)
		draw_line(Vector2(0, knot_y + 10), Vector2(-4, knot_y + 30), string_color, 2.0)
		draw_line(Vector2(-4, knot_y + 30), Vector2(2, knot_y + 50), string_color, 2.0)
		draw_line(Vector2(2, knot_y + 50), Vector2(-2, knot_y + 70), string_color, 2.0)

func _ready():
	instruction = "POP ALL!"
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

	# Create multiple balloons
	for i in range(NUM_BALLOONS):
		_create_balloon(i)

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

func _create_balloon(index: int) -> void:
	var color_data = BALLOON_COLORS[index % BALLOON_COLORS.size()]

	var balloon_node = Area2D.new()
	# Spread balloons across the screen
	var start_x = 80 + (index % 3) * 200 + randf_range(-40, 40)
	var start_y = 150 + (index / 3) * 200 + randf_range(-40, 40)
	balloon_node.position = Vector2(start_x, start_y)
	add_child(balloon_node)

	# Add visual
	var balloon_visual = BalloonVisual.new()
	balloon_visual.balloon_color = color_data["main"]
	balloon_visual.highlight_color = color_data["highlight"]
	balloon_visual.shadow_color = color_data["shadow"]
	balloon_node.add_child(balloon_visual)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	collision.shape = shape
	balloon_node.add_child(collision)

	# Random direction with varied speeds
	var direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var speed = base_speed + randf_range(-50, 50)

	balloons.append({
		"node": balloon_node,
		"direction": direction,
		"speed": speed,
		"popped": false
	})

func _add_clouds():
	for i in range(4):
		var cloud = Node2D.new()
		cloud.position = Vector2(randf_range(50, 590), randf_range(50, 150))
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
	draw_circle(Vector2(-20, 5), 20, shadow_color)
	draw_circle(Vector2(20, 5), 22, shadow_color)
	draw_circle(Vector2(0, 0), 28, cloud_color)
	draw_circle(Vector2(-25, 0), 18, cloud_color)
	draw_circle(Vector2(25, 0), 20, cloud_color)
"""
	script.reload()
	return script

func _process(delta):
	time_elapsed += delta * speed_multiplier

	# Timeout check
	if time_elapsed >= time_limit:
		if not game_ended:
			$sfx_lose.play()
			end_game()
			game_ended = true
		return

	if game_ended:
		return

	# Move all balloons
	for balloon_data in balloons:
		if balloon_data["popped"]:
			continue

		var balloon = balloon_data["node"] as Area2D
		if not is_instance_valid(balloon):
			continue

		var direction = balloon_data["direction"] as Vector2
		var spd = balloon_data["speed"] as float

		balloon.position += direction * spd * delta * speed_multiplier

		# Bounce off walls
		var radius = 40.0
		if balloon.position.x < radius:
			balloon.position.x = radius
			balloon_data["direction"].x *= -1
		elif balloon.position.x > viewport_size.x - radius:
			balloon.position.x = viewport_size.x - radius
			balloon_data["direction"].x *= -1

		if balloon.position.y < radius:
			balloon.position.y = radius
			balloon_data["direction"].y *= -1
		elif balloon.position.y > viewport_size.y - radius:
			balloon.position.y = viewport_size.y - radius
			balloon_data["direction"].y *= -1

func _input(event):
	if game_ended:
		return

	var pos: Vector2
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
	else:
		return

	# Check all balloons
	for balloon_data in balloons:
		if balloon_data["popped"]:
			continue

		var balloon = balloon_data["node"] as Area2D
		if not is_instance_valid(balloon):
			continue

		if pos.distance_to(balloon.position) < 45:
			# Pop this balloon!
			$sfx_hit.play()
			balloon_data["popped"] = true
			balloon.queue_free()
			balloons_popped += 1
			add_score(10)

			# Check win condition
			if balloons_popped >= BALLOONS_TO_POP:
				$sfx_win.play()
				end_game()
				game_ended = true
			break  # Only pop one balloon per click
