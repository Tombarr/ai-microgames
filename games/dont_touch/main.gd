extends Microgame

var time_elapsed: float = 0.0
var game_ended: bool = false
# Uses default 4 seconds (8 beats at 120 BPM) from Director

# Button texts to entice clicking
const BUTTON_TEXTS = [
	"CLICK ME!",
	"PRESS HERE!",
	"DO IT!",
	"TAP NOW!",
	"YOU KNOW YOU WANT TO",
	"JUST ONE CLICK",
	"PUSH THIS",
	"DON'T RESIST",
	"PRESS ME",
	"TOUCH HERE",
	"GO AHEAD",
	"I DARE YOU"
]

# Button colors (main, highlight, shadow)
const BUTTON_COLOR_SETS = [
	[Color(0.9, 0.2, 0.2), Color(1.0, 0.5, 0.5), Color(0.6, 0.1, 0.1)],  # Red
	[Color(0.2, 0.85, 0.2), Color(0.5, 1.0, 0.5), Color(0.1, 0.55, 0.1)],  # Green
	[Color(0.2, 0.4, 0.9), Color(0.5, 0.6, 1.0), Color(0.1, 0.2, 0.6)],  # Blue
	[Color(0.95, 0.85, 0.2), Color(1.0, 0.95, 0.5), Color(0.7, 0.6, 0.1)],  # Yellow
	[Color(0.9, 0.2, 0.9), Color(1.0, 0.5, 1.0), Color(0.6, 0.1, 0.6)],  # Magenta
	[Color(0.2, 0.85, 0.85), Color(0.5, 1.0, 1.0), Color(0.1, 0.55, 0.55)],  # Cyan
	[Color(0.95, 0.5, 0.1), Color(1.0, 0.7, 0.4), Color(0.7, 0.3, 0.05)],  # Orange
]

var buttons: Array[Button] = []
var button_tweens: Array[Tween] = []

# Sound effects
const SFX_BUTTON_PRESS = preload("res://shared/assets/sfx_button_press.wav")
const SFX_WIN = preload("res://shared/assets/sfx_win.wav")
const SFX_LOSE = preload("res://shared/assets/sfx_lose.wav")

# Visual class for decorative danger signs
class DangerSign extends Node2D:
	func _draw():
		# Warning triangle
		var triangle_color = Color(0.95, 0.8, 0.1)
		var border_color = Color(0.1, 0.1, 0.1)

		# Triangle border
		draw_polygon([
			Vector2(0, -25),
			Vector2(-22, 18),
			Vector2(22, 18)
		], [border_color])

		# Triangle fill
		draw_polygon([
			Vector2(0, -20),
			Vector2(-18, 15),
			Vector2(18, 15)
		], [triangle_color])

		# Exclamation mark
		draw_rect(Rect2(-3, -12, 6, 14), border_color)
		draw_circle(Vector2(0, 10), 4, border_color)

func _ready():
	instruction = "DON'T TOUCH!"
	super._ready()

	# Create themed background
	_create_background()

	# Setup audio
	var sfx_button = AudioStreamPlayer.new()
	sfx_button.name = "sfx_button_press"
	sfx_button.stream = SFX_BUTTON_PRESS
	add_child(sfx_button)

	var sfx_win = AudioStreamPlayer.new()
	sfx_win.name = "sfx_win"
	sfx_win.stream = SFX_WIN
	add_child(sfx_win)

	var sfx_lose = AudioStreamPlayer.new()
	sfx_lose.name = "sfx_lose"
	sfx_lose.stream = SFX_LOSE
	add_child(sfx_lose)

	# Create tempting buttons
	_create_buttons()

	# Add danger signs in corners
	_add_danger_signs()

func _create_background():
	var viewport_size = get_viewport_rect().size

	# Dark gradient-like background with diagonal stripes (warning pattern)
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.12, 0.18)
	bg.size = viewport_size
	bg.z_index = -10
	add_child(bg)

	# Add hazard stripes around edges
	_add_hazard_stripes()

func _add_hazard_stripes():
	var viewport_size = get_viewport_rect().size
	var stripe_node = Node2D.new()
	stripe_node.z_index = -5

	# Create a script for drawing hazard stripes
	var script = GDScript.new()
	script.source_code = """
extends Node2D

func _draw():
	var stripe_width = 20
	var colors = [Color(0.1, 0.1, 0.1), Color(0.95, 0.75, 0.1)]

	# Top edge
	for i in range(35):
		var x = i * stripe_width * 2 - 20
		draw_polygon([
			Vector2(x, 0),
			Vector2(x + stripe_width, 0),
			Vector2(x + stripe_width + 15, 15),
			Vector2(x + 15, 15)
		], [colors[1]])

	# Bottom edge
	for i in range(35):
		var x = i * stripe_width * 2 - 20
		draw_polygon([
			Vector2(x, 625),
			Vector2(x + stripe_width, 625),
			Vector2(x + stripe_width + 15, 640),
			Vector2(x + 15, 640)
		], [colors[1]])
"""
	script.reload()
	stripe_node.set_script(script)
	add_child(stripe_node)

func _add_danger_signs():
	var positions = [
		Vector2(50, 50),
		Vector2(590, 50),
		Vector2(50, 590),
		Vector2(590, 590)
	]

	for pos in positions:
		var sign = DangerSign.new()
		sign.position = pos
		sign.z_index = 5
		add_child(sign)

func _create_buttons():
	# Create 8-12 buttons scattered across the screen
	var num_buttons = randi_range(8, 12)

	for i in range(num_buttons):
		var button = Button.new()

		# Random text
		button.text = BUTTON_TEXTS[randi() % BUTTON_TEXTS.size()]

		# Random color set (main, highlight, shadow)
		var color_set = BUTTON_COLOR_SETS[randi() % BUTTON_COLOR_SETS.size()]
		var main_color = color_set[0]
		var highlight_color = color_set[1]
		var shadow_color = color_set[2]

		# Create StyleBoxFlat for custom button appearance with 3D effect
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = main_color
		style_normal.corner_radius_top_left = 12
		style_normal.corner_radius_top_right = 12
		style_normal.corner_radius_bottom_left = 12
		style_normal.corner_radius_bottom_right = 12

		# 3D border effect (highlight on top/left, shadow on bottom/right)
		style_normal.border_width_left = 4
		style_normal.border_width_right = 4
		style_normal.border_width_top = 4
		style_normal.border_width_bottom = 6
		style_normal.border_color = shadow_color

		# Add inner shadow effect
		style_normal.shadow_color = Color(0, 0, 0, 0.3)
		style_normal.shadow_size = 4
		style_normal.shadow_offset = Vector2(2, 2)

		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = highlight_color
		style_hover.corner_radius_top_left = 12
		style_hover.corner_radius_top_right = 12
		style_hover.corner_radius_bottom_left = 12
		style_hover.corner_radius_bottom_right = 12
		style_hover.border_width_left = 4
		style_hover.border_width_right = 4
		style_hover.border_width_top = 4
		style_hover.border_width_bottom = 6
		style_hover.border_color = main_color
		style_hover.shadow_color = Color(0, 0, 0, 0.4)
		style_hover.shadow_size = 6
		style_hover.shadow_offset = Vector2(3, 3)

		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = shadow_color
		style_pressed.corner_radius_top_left = 12
		style_pressed.corner_radius_top_right = 12
		style_pressed.corner_radius_bottom_left = 12
		style_pressed.corner_radius_bottom_right = 12
		style_pressed.border_width_left = 4
		style_pressed.border_width_right = 4
		style_pressed.border_width_top = 6
		style_pressed.border_width_bottom = 2
		style_pressed.border_color = shadow_color.darkened(0.3)

		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_pressed)

		# Random size
		var width = randf_range(110, 190)
		var height = randf_range(55, 85)
		button.custom_minimum_size = Vector2(width, height)

		# Random position (avoid edges and hazard stripes)
		var x = randf_range(60, 580 - width)
		var y = randf_range(60, 580 - height)
		button.position = Vector2(x, y)

		# Make font bigger and bold with outline
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_outline_color", Color.BLACK)
		button.add_theme_constant_override("outline_size", 3)

		# Connect button press
		button.pressed.connect(_on_button_pressed.bind(button))

		# Add to scene
		add_child(button)
		buttons.append(button)

		# Create pulsing animation
		_create_button_animation(button, i)

func _create_button_animation(button: Button, index: int):
	# Create unique animation for each button
	var tween = create_tween()
	tween.set_loops()

	# Randomize animation type
	var anim_type = randi() % 3

	match anim_type:
		0:  # Pulsing scale
			var delay = randf_range(0.0, 1.0)
			tween.tween_interval(delay)
			tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		1:  # Bouncing
			var delay = randf_range(0.0, 1.0)
			tween.tween_interval(delay)
			var original_y = button.position.y
			tween.tween_property(button, "position:y", original_y - 10, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(button, "position:y", original_y, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
		2:  # Rotation wiggle
			var delay = randf_range(0.0, 1.0)
			tween.tween_interval(delay)
			tween.tween_property(button, "rotation_degrees", 5, 0.2)
			tween.tween_property(button, "rotation_degrees", -5, 0.4)
			tween.tween_property(button, "rotation_degrees", 0, 0.2)

	button_tweens.append(tween)

func _on_button_pressed(button: Button):
	if game_ended:
		return

	# Player failed - they clicked a button!
	$sfx_button_press.play()
	$sfx_lose.play()
	end_game()  # Score stays at 0 = loss
	game_ended = true

	# Stop all animations
	for tween in button_tweens:
		if tween:
			tween.kill()

	# Flash the clicked button
	var flash_tween = create_tween()
	flash_tween.tween_property(button, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(button, "modulate", Color.WHITE, 0.1)
	flash_tween.set_loops(3)

func _process(delta):
	if game_ended:
		return

	time_elapsed += delta * speed_multiplier

	# Check timeout - if player resisted all buttons, they win!
	if time_elapsed >= time_limit:
		if not game_ended:
			add_score(100)  # Win!
			$sfx_win.play()
			end_game()
			game_ended = true
		return

func _input(event):
	# Also catch screen touches that might miss button hitboxes
	if game_ended:
		return

	if event is InputEventScreenTouch and event.pressed:
		# Check if touch is on any button manually
		for button in buttons:
			var button_rect = Rect2(button.global_position, button.size)
			if button_rect.has_point(event.position):
				_on_button_pressed(button)
				break
