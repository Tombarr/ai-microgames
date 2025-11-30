extends Microgame
class_name MicrogameAI

## MicrogameAI: The robust base class for AI-generated microgames.
## This class provides a high-level API for the AI to interact with, 
## abstracting away complex node management and asset loading.

# Configuration
var game_duration: float = 5.0
var background_color: Color = Color("1a1a2e") # Dark Blue default

# Internal State
var _time_elapsed: float = 0.0
var _game_active: bool = false
var _assets_path: String = ""

# API: Spawning Functions

## Spawns a simple sprite from the assets folder
func spawn_sprite(texture_name: String, pos: Vector2) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = _load_texture(texture_name)
	sprite.position = pos
	add_child(sprite)
	return sprite

## Spawns an Area2D with a sprite and a circle collision shape
func spawn_area(texture_name: String, pos: Vector2, radius: float = 50.0) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)
	
	var sprite = Sprite2D.new()
	sprite.texture = _load_texture(texture_name)
	area.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	area.add_child(collision)
	
	return area

# API: Game Control

## Call this to win the game immediately
func win():
	if _game_active:
		_game_active = false
		print("AI Microgame Won!")
		add_score(100) # Base score
		game_over.emit(current_score) # From parent Microgame class

## Call this to lose the game immediately
func lose():
	if _game_active:
		_game_active = false
		print("AI Microgame Lost!")
		game_over.emit(0)

# Lifecycle Overrides (AI should override these)

func _on_game_start():
	pass

func _on_game_update(delta: float):
	pass

func _on_input_event(pos: Vector2):
	pass

# Internal Implementation

func _ready():
	# Setup path for assets
	# We prefer the script's location since we might be instantiating scripts directly
	var script_path = get_script().resource_path
	if script_path:
		_assets_path = script_path.get_base_dir() + "/assets/"
	else:
		# Fallback to scene path if script path is somehow missing (e.g. built-in script)
		_assets_path = scene_file_path.get_base_dir() + "/assets/"
	
	super._ready() # Call Microgame._ready()
	
	# Initialize environment
	RenderingServer.set_default_clear_color(background_color)
	
	_game_active = true
	_on_game_start()

func _process(delta: float):
	if not _game_active:
		return
		
	_time_elapsed += delta
	_on_game_update(delta)
	
	# Timeout check
	if _time_elapsed >= game_duration:
		# Default behavior: If time runs out and you haven't lost, did you win?
		# WarioWare usually has specific rules per game. 
		# We'll assume time-out is a WIN unless specified otherwise (survival),
		# OR a LOSS if it was a task to complete. 
		# For safety, let's default to LOSS if not completed, 
		# but AI can call win() early.
		lose() 

func _input(event):
	if not _game_active:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_input_event(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_on_input_event(event.position)

func _load_texture(name: String) -> Texture2D:
	# Clean name
	name = name.replace(".png", "").replace(".jpg", "")
	
	# Try local path first
	var path = _assets_path + name + ".png"
	if FileAccess.file_exists(path):
		return load(path)
	
	# Fallback to placeholder if allowed, or error
	push_warning("Asset not found: " + path)
	return PlaceholderTexture2D.new()
