extends Microgame

var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

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

# Button colors
const BUTTON_COLORS = [
	Color(1.0, 0.2, 0.2),  # Bright red
	Color(0.2, 1.0, 0.2),  # Bright green
	Color(0.2, 0.2, 1.0),  # Bright blue
	Color(1.0, 1.0, 0.2),  # Yellow
	Color(1.0, 0.2, 1.0),  # Magenta
	Color(0.2, 1.0, 1.0),  # Cyan
	Color(1.0, 0.5, 0.0),  # Orange
]

var buttons: Array[Button] = []
var button_tweens: Array[Tween] = []

# Sound effects
const SFX_BUTTON_PRESS = preload("res://shared/assets/sfx_button_press.wav")

func _ready():
	instruction = "DON'T TOUCH!"
	super._ready()

	# Setup audio
	var sfx_button = AudioStreamPlayer.new()
	sfx_button.name = "sfx_button_press"
	sfx_button.stream = SFX_BUTTON_PRESS
	add_child(sfx_button)

	# Create tempting buttons
	_create_buttons()

func _create_buttons():
	# Create 8-12 buttons scattered across the screen
	var num_buttons = randi_range(8, 12)

	for i in range(num_buttons):
		var button = Button.new()

		# Random text
		button.text = BUTTON_TEXTS[randi() % BUTTON_TEXTS.size()]

		# Random color
		var color = BUTTON_COLORS[randi() % BUTTON_COLORS.size()]

		# Create StyleBoxFlat for custom button appearance
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = color
		style_normal.corner_radius_top_left = 10
		style_normal.corner_radius_top_right = 10
		style_normal.corner_radius_bottom_left = 10
		style_normal.corner_radius_bottom_right = 10
		style_normal.border_width_left = 3
		style_normal.border_width_right = 3
		style_normal.border_width_top = 3
		style_normal.border_width_bottom = 3
		style_normal.border_color = Color.WHITE

		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = color.lightened(0.2)
		style_hover.corner_radius_top_left = 10
		style_hover.corner_radius_top_right = 10
		style_hover.corner_radius_bottom_left = 10
		style_hover.corner_radius_bottom_right = 10
		style_hover.border_width_left = 4
		style_hover.border_width_right = 4
		style_hover.border_width_top = 4
		style_hover.border_width_bottom = 4
		style_hover.border_color = Color.YELLOW

		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_hover)

		# Random size
		var width = randf_range(100, 180)
		var height = randf_range(50, 80)
		button.custom_minimum_size = Vector2(width, height)

		# Random position (avoid edges)
		var x = randf_range(50, 590 - width)
		var y = randf_range(50, 590 - height)
		button.position = Vector2(x, y)

		# Make font bigger and bold
		button.add_theme_font_size_override("font_size", 18)

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

	time_elapsed += delta

	# Check timeout - if player resisted all buttons, they win!
	if time_elapsed >= GAME_DURATION:
		if not game_ended:
			add_score(100)  # Win!
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
