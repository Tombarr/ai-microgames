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

# Ruby Types configuration
const RUBY_TYPES = [
	{ "name": "green", "value": 1, "color": Color.GREEN, "weight": 60, "base_speed": 400.0 },
	{ "name": "blue", "value": 5, "color": Color.BLUE, "weight": 30, "base_speed": 600.0 },
	{ "name": "red", "value": 20, "color": Color.RED, "weight": 10, "base_speed": 900.0 }
]

# State
var hand: Area2D
var rubies: Array[Area2D] = []
var spawn_timer: float = 0.0
var current_spawn_interval: float = 0.4
var viewport_size: Vector2
var game_active: bool = true

func _ready():
	instruction = "COLLECT!"
	super._ready()

	viewport_size = get_viewport_rect().size

	# Create Hand
	hand = _create_area(Vector2(viewport_size.x / 2, viewport_size.y - HAND_Y_OFFSET), 30.0, Color("ffccaa"), Vector2(60, 60))

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

func _process(delta):
	if not game_active:
		return

	# 1. Move Hand (Follow Touch/Mouse X position directly)
	var target_x = get_viewport().get_mouse_position().x
	# Smooth follow for more natural movement
	hand.position.x = lerp(hand.position.x, target_x, 20.0 * delta)
	hand.position.x = clamp(hand.position.x, 30, viewport_size.x - 30)

	# 2. Spawn Rubies
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_ruby()
		spawn_timer = (current_spawn_interval * randf_range(0.8, 1.2))

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

	# Create ruby
	var ruby = _create_area(start_pos, 25.0, type.color, Vector2(30, 30))

	# Store data on the node
	ruby.set_meta("value", type.value)
	ruby.set_meta("speed", type.base_speed)

	rubies.append(ruby)

func _collect_ruby(ruby: Area2D) -> void:
	var value = ruby.get_meta("value")
	add_score(value)
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

func _create_area(pos: Vector2, radius: float, color: Color, size: Vector2) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	area.add_child(collision)

	# Add visual (ColorRect)
	var rect = ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = -size / 2
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(rect)

	# Add border
	var border = ReferenceRect.new()
	border.editor_only = false
	border.border_color = Color.WHITE
	border.border_width = 2.0
	border.size = size
	border.position = -size / 2
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(border)

	return area
