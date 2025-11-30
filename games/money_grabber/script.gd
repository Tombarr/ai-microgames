extends MicrogameAI

# Game Design Constants
const TARGET_SCORE: int = 30
const HAND_Y_OFFSET: float = 100.0 # From bottom
const SPAWN_MARGIN: float = 50.0

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

func _on_game_start() -> void:
	# WarioWare style: fast!
	game_duration = 5.0
	viewport_size = get_viewport_rect().size
	
	# Create Hand
	# Spawn at center, near bottom
	hand = spawn_area("hand", Vector2(viewport_size.x / 2, viewport_size.y - HAND_Y_OFFSET), 30.0)
	_create_fallback_visual(hand, Color("ffccaa"), Vector2(60, 60))
	
	# Adjust difficulty based on speed_multiplier
	# Higher multiplier = faster spawn, faster fall
	current_spawn_interval = 0.4 / speed_multiplier
	
	print("Money Grabber Started! Collect " + str(TARGET_SCORE) + " value!")

func _on_game_update(delta: float) -> void:
	# 1. Move Hand (Follow Mouse/Touch X)
	var mouse_x = get_viewport().get_mouse_position().x
	# Lerp for slight smoothness, but snappy
	hand.position.x = lerp(hand.position.x, mouse_x, 30.0 * delta)
	# Clamp to screen
	hand.position.x = clamp(hand.position.x, 30, viewport_size.x - 30)
	
	# 2. Spawn Rubies
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_ruby()
		# Reset timer with some randomness
		spawn_timer = (current_spawn_interval * randf_range(0.8, 1.2))
	
	# 3. Move Rubies & Check Collisions
	# Iterate backwards to safely remove items
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
	
	# Spawn using base class helper
	var ruby = spawn_area("ruby_" + type.name, start_pos, 25.0)
	
	# Store data on the node
	ruby.set_meta("value", type.value)
	ruby.set_meta("speed", type.base_speed)
	
	# Visuals
	_create_fallback_visual(ruby, type.color, Vector2(30, 30))
	
	rubies.append(ruby)

func _collect_ruby(ruby: Area2D) -> void:
	var value = ruby.get_meta("value")
	add_score(value)
	print("Collected " + str(value) + "! Total: " + str(current_score))
	
	# Cleanup ruby
	ruby.queue_free()
	
	# Check win condition
	if current_score >= TARGET_SCORE:
		win()

func _create_fallback_visual(node: Node2D, color: Color, size: Vector2) -> void:
	# Find the Sprite2D created by spawn_area
	var sprite: Sprite2D = null
	for child in node.get_children():
		if child is Sprite2D:
			sprite = child
			break
			
	# If sprite exists and has a placeholder texture (or failed to load), replace visual
	if sprite:
		var texture = sprite.texture
		# PlaceholderTexture2D is used by MicrogameAI when asset is missing
		if texture is PlaceholderTexture2D or texture == null:
			sprite.visible = false # Hide the placeholder
			
			var rect = ColorRect.new()
			rect.color = color
			rect.size = size
			rect.position = -size / 2 # Center the rect
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Don't block mouse
			node.add_child(rect)
			
			# Add a simple border for visibility
			var border = ReferenceRect.new()
			border.editor_only = false
			border.border_color = Color.WHITE
			border.border_width = 2.0
			border.size = size
			border.position = -size / 2
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.add_child(border)
