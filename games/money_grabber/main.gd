extends Microgame

# Game Design Constants
const TARGET_SCORE: int = 30
const HAND_Y_OFFSET: float = 100.0 # From bottom
const SPAWN_MARGIN: float = 50.0

# Sound effects
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")
const SFX_COLLECT_LOW = preload("res://games/money_grabber/assets/sfx_collect_low.wav")
const SFX_COLLECT_MID = preload("res://games/money_grabber/assets/sfx_collect_mid.wav")
const SFX_COLLECT_HIGH = preload("res://games/money_grabber/assets/sfx_collect_high.wav")

# Ruby Types configuration (now with highlight and shadow colors)
const RUBY_TYPES = [
	{ "name": "green", "value": 1, "color": Color(0.2, 0.85, 0.3), "highlight": Color(0.5, 1.0, 0.6), "shadow": Color(0.1, 0.5, 0.15), "weight": 60, "base_speed": 400.0 },
	{ "name": "blue", "value": 5, "color": Color(0.3, 0.5, 0.95), "highlight": Color(0.6, 0.75, 1.0), "shadow": Color(0.15, 0.25, 0.6), "weight": 30, "base_speed": 600.0 },
	{ "name": "red", "value": 20, "color": Color(0.95, 0.2, 0.2), "highlight": Color(1.0, 0.6, 0.6), "shadow": Color(0.6, 0.1, 0.1), "weight": 10, "base_speed": 900.0 }
]

# State
var hand: Area2D
var rubies: Array[Area2D] = []
var spawn_timer: float = 0.0
var current_spawn_interval: float = 0.4
var viewport_size: Vector2
var game_active: bool = true
var time_elapsed: float = 0.0
const GAME_DURATION: float = 5.0

# UI
var score_label: Label

# Hand visual class using _draw()
class HandVisual extends Node2D:
	func _draw():
		var skin_color = Color(0.95, 0.8, 0.65)
		var shadow_color = Color(0.85, 0.65, 0.5)
		var outline_color = Color(0.6, 0.4, 0.3)

		# Palm (main body)
		draw_rect(Rect2(-25, -15, 50, 45), skin_color)
		# Palm shadow
		draw_rect(Rect2(-25, 20, 50, 10), shadow_color)
		# Palm outline
		draw_rect(Rect2(-27, -17, 54, 4), outline_color)
		draw_rect(Rect2(-27, 28, 54, 4), outline_color)
		draw_rect(Rect2(-27, -17, 4, 49), outline_color)
		draw_rect(Rect2(23, -17, 4, 49), outline_color)

		# Fingers
		var finger_positions = [-20, -7, 6, 19]
		for i in range(4):
			var x = finger_positions[i]
			# Finger
			draw_rect(Rect2(x, -40, 12, 28), skin_color)
			# Finger highlight
			draw_rect(Rect2(x + 2, -40, 4, 24), Color(1.0, 0.9, 0.8))
			# Finger tip (rounded)
			draw_circle(Vector2(x + 6, -40), 6, skin_color)
			draw_circle(Vector2(x + 4, -42), 3, Color(1.0, 0.9, 0.8))

		# Thumb
		draw_rect(Rect2(-35, -5, 14, 25), skin_color)
		draw_circle(Vector2(-28, -5), 7, skin_color)
		draw_rect(Rect2(-33, -3, 4, 20), Color(1.0, 0.9, 0.8))

# Gem/Ruby visual class using _draw()
class GemVisual extends Node2D:
	var gem_color: Color = Color.GREEN
	var highlight_color: Color = Color(0.5, 1.0, 0.5)
	var shadow_color: Color = Color(0.0, 0.5, 0.0)
	var gem_value: int = 1

	func _draw():
		# Diamond/gem shape
		var points = [
			Vector2(0, -18),      # Top
			Vector2(14, -6),      # Top right
			Vector2(14, 8),       # Bottom right
			Vector2(0, 18),       # Bottom
			Vector2(-14, 8),      # Bottom left
			Vector2(-14, -6),     # Top left
		]

		# Shadow/outline
		var shadow_points = []
		for p in points:
			shadow_points.append(p + Vector2(2, 2))
		draw_polygon(shadow_points, [shadow_color])

		# Main gem body
		draw_polygon(points, [gem_color])

		# Facet highlights (top facets)
		draw_polygon([
			Vector2(0, -18),
			Vector2(14, -6),
			Vector2(0, 0),
			Vector2(-14, -6)
		], [highlight_color])

		# Inner shine
		draw_polygon([
			Vector2(-4, -10),
			Vector2(4, -10),
			Vector2(2, -4),
			Vector2(-2, -4)
		], [Color(1, 1, 1, 0.7)])

		# Small sparkle
		draw_circle(Vector2(-6, -8), 3, Color(1, 1, 1, 0.9))

		# Value indicator (small dots for higher values)
		if gem_value >= 5:
			draw_circle(Vector2(0, 6), 3, Color(1, 1, 1, 0.6))
		if gem_value >= 20:
			draw_circle(Vector2(-5, 6), 3, Color(1, 1, 1, 0.6))
			draw_circle(Vector2(5, 6), 3, Color(1, 1, 1, 0.6))

func _ready():
	instruction = "GRAB 30!"
	super._ready()

	viewport_size = get_viewport_rect().size

	# Create gradient background (treasure cave)
	_create_background()

	# Create score display
	score_label = Label.new()
	score_label.position = Vector2(20, 20)
	score_label.z_index = 100
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_color_override("font_outline_color", Color.BLACK)
	score_label.add_theme_constant_override("outline_size", 4)
	score_label.text = "0 / 30"
	add_child(score_label)

	# Create Hand with custom visual
	hand = _create_hand(Vector2(viewport_size.x / 2, viewport_size.y - HAND_Y_OFFSET))

	# Setup audio
	var sfx_win = AudioStreamPlayer.new()
	sfx_win.name = "sfx_win"
	sfx_win.stream = SFX_WIN
	add_child(sfx_win)

	var sfx_lose = AudioStreamPlayer.new()
	sfx_lose.name = "sfx_lose"
	sfx_lose.stream = SFX_LOSE
	add_child(sfx_lose)

	var sfx_collect_low = AudioStreamPlayer.new()
	sfx_collect_low.name = "sfx_collect_low"
	sfx_collect_low.stream = SFX_COLLECT_LOW
	add_child(sfx_collect_low)

	var sfx_collect_mid = AudioStreamPlayer.new()
	sfx_collect_mid.name = "sfx_collect_mid"
	sfx_collect_mid.stream = SFX_COLLECT_MID
	add_child(sfx_collect_mid)

	var sfx_collect_high = AudioStreamPlayer.new()
	sfx_collect_high.name = "sfx_collect_high"
	sfx_collect_high.stream = SFX_COLLECT_HIGH
	add_child(sfx_collect_high)

	# Adjust difficulty based on speed_multiplier
	current_spawn_interval = 0.4 / speed_multiplier

	print("Money Grabber Started! Collect " + str(TARGET_SCORE) + " value!")

func _create_background():
	# Dark cave background
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.1, 0.2)
	bg.size = viewport_size
	bg.z_index = -10
	add_child(bg)

	# Add some sparkle/treasure particles in background
	var sparkle_node = Node2D.new()
	sparkle_node.z_index = -5

	var script = GDScript.new()
	script.source_code = """
extends Node2D

func _draw():
	# Sparkle stars in background
	var sparkle_color = Color(1, 1, 0.8, 0.3)
	for i in range(20):
		var x = hash(i * 123) % 640
		var y = hash(i * 456) % 400
		var size = (hash(i * 789) % 3) + 1
		draw_circle(Vector2(x, y), size, sparkle_color)

	# Treasure chest at bottom
	var chest_color = Color(0.55, 0.35, 0.15)
	var gold_color = Color(0.95, 0.8, 0.2)

	# Chest body
	draw_rect(Rect2(250, 560, 140, 60), chest_color)
	draw_rect(Rect2(245, 550, 150, 15), Color(0.65, 0.45, 0.2))

	# Gold peeking out
	draw_circle(Vector2(280, 555), 12, gold_color)
	draw_circle(Vector2(310, 550), 10, gold_color)
	draw_circle(Vector2(340, 555), 14, gold_color)
	draw_circle(Vector2(365, 552), 11, gold_color)

	# Chest lock
	draw_rect(Rect2(310, 565, 20, 25), Color(0.7, 0.6, 0.1))
"""
	script.reload()
	sparkle_node.set_script(script)
	add_child(sparkle_node)

func _create_hand(pos: Vector2) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 35.0
	collision.shape = shape
	area.add_child(collision)

	# Add visual using custom class
	var visual = HandVisual.new()
	area.add_child(visual)

	return area

func _process(delta):
	time_elapsed += delta

	# Check timeout
	if time_elapsed >= GAME_DURATION:
		if game_active:
			game_active = false
			# Only win if reached target, otherwise lose
			if current_score >= TARGET_SCORE:
				$sfx_win.play()
			else:
				# Reset score to 0 for loss
				current_score = 0
				$sfx_lose.play()
			end_game()
		return

	if not game_active:
		return

	# 1. Move Hand (Follow Touch/Mouse X position directly)
	var target_x = get_viewport().get_mouse_position().x
	# Smooth follow for more natural movement
	hand.position.x = lerp(hand.position.x, target_x, 20.0 * delta)
	hand.position.x = clamp(hand.position.x, 30, viewport_size.x - 30)

	# 2. Spawn Rubies (accelerate with speed_multiplier)
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_ruby()
		# Spawn faster at higher speeds
		spawn_timer = (current_spawn_interval * randf_range(0.8, 1.2)) / speed_multiplier

	# 3. Move Rubies & Check Collisions
	for i in range(rubies.size() - 1, -1, -1):
		var ruby = rubies[i]

		# Move down
		var speed = ruby.get_meta("speed") * speed_multiplier
		ruby.position.y += speed * delta

		# Check collision with hand
		if ruby.overlaps_area(hand):
			_collect_ruby(ruby)
			rubies.remove_at(i)
			continue

		# Check if off screen
		if ruby.position.y > viewport_size.y + 50:
			rubies.remove_at(i)
			ruby.queue_free()

func _spawn_ruby() -> void:
	# Weighted random selection
	var roll = randi() % 100
	var type = RUBY_TYPES[0]
	var current_weight = 0

	for t in RUBY_TYPES:
		current_weight += t.weight
		if roll < current_weight:
			type = t
			break

	var x_pos = randf_range(SPAWN_MARGIN, viewport_size.x - SPAWN_MARGIN)
	var start_pos = Vector2(x_pos, -50)

	# Create ruby with custom visual
	var ruby = _create_gem(start_pos, type)

	# Store data on the node
	ruby.set_meta("value", type.value)
	ruby.set_meta("speed", type.base_speed)

	rubies.append(ruby)

func _create_gem(pos: Vector2, gem_type: Dictionary) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 18.0
	collision.shape = shape
	area.add_child(collision)

	# Add visual using custom GemVisual class
	var visual = GemVisual.new()
	visual.gem_color = gem_type.color
	visual.highlight_color = gem_type.highlight
	visual.shadow_color = gem_type.shadow
	visual.gem_value = gem_type.value
	area.add_child(visual)

	return area

func _collect_ruby(ruby: Area2D) -> void:
	var value = ruby.get_meta("value")
	add_score(value)

	# Update score display
	score_label.text = str(current_score) + " / 30"
	print("Collected " + str(value) + "! Total: " + str(current_score))

	# Play collection sound based on value
	if value >= 20:
		$sfx_collect_high.play()
	elif value >= 5:
		$sfx_collect_mid.play()
	else:
		$sfx_collect_low.play()

	# Cleanup ruby
	ruby.queue_free()

	# Check win condition
	if current_score >= TARGET_SCORE:
		game_active = false
		$sfx_win.play()
		end_game()
