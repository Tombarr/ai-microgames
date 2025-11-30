extends MicrogameAI

var target: Area2D
var speed: float = 200.0
var direction: Vector2
var viewport_size: Vector2

func _on_game_start() -> void:
	game_duration = 5.0
	background_color = Color("222244")
	viewport_size = get_viewport_rect().size
	
	# Spawn a target (using fallback texture if file missing)
	target = spawn_area("target", viewport_size / 2, 60)
	
	# Visual Fallback: Red Circle
	_create_fallback_visual(target, Color.RED, 40.0)
	
	# Random direction
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	print("Sample AI Game Started: TAP THE TARGET!")

func _on_game_update(delta: float) -> void:
	if not is_instance_valid(target):
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

func _on_input_event(pos: Vector2) -> void:
	if is_instance_valid(target):
		# Check distance to target (Area2D position)
		if pos.distance_to(target.position) < 80:
			win()
			print("TARGET HIT!")
			target.queue_free()

func _create_fallback_visual(node: Node2D, color: Color, radius: float) -> void:
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
			
			# Create a circle using GradientTexture2D
			var grad_tex = GradientTexture2D.new()
			grad_tex.width = int(radius * 2)
			grad_tex.height = int(radius * 2)
			grad_tex.fill = GradientTexture2D.FILL_RADIAL
			grad_tex.fill_from = Vector2(0.5, 0.5)
			grad_tex.fill_to = Vector2(0.5, 0.0) # From center to edge
			
			var grad = Gradient.new()
			# Solid color until 90%, then fade to transparent
			grad.colors = [color, color, Color(color.r, color.g, color.b, 0.0)]
			grad.offsets = [0.0, 0.9, 1.0]
			grad_tex.gradient = grad
			
			var new_sprite = Sprite2D.new()
			new_sprite.texture = grad_tex
			node.add_child(new_sprite)
