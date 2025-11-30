extends Node

## Director: Orchestrates the flow of microgames.
## Scans for games, plays them, handles scoring and speed.

@export var games_dir: String = "res://games/"
@export var initial_speed: float = 1.0
@export var speed_increment: float = 0.2
@export var max_speed: float = 5.0
@export var max_lives: int = 3

var current_game: Microgame
var current_speed_multiplier: float = 1.0
var score: int = 0
var lives: int = 3

# UI Elements
var ui_layer: CanvasLayer
var lives_label: Label
var score_label: Label
var message_label: Label

func _ready() -> void:
	_setup_ui()
	_reset_game_state()
	# We start the loop deferred to ensure everything is initialized
	call_deferred("start_game_loop")

func _setup_ui() -> void:
	# Create CanvasLayer to sit above everything
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	ui_layer.visible = false
	add_child(ui_layer)

	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(bg)
	
	# Center Container for alignment
	var center_cont = CenterContainer.new()
	center_cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(center_cont)

	# VBox for text
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center_cont.add_child(vbox)
	
	# Message Label (PASSED/FAILED)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(message_label)
	
	# Lives Label
	lives_label = Label.new()
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lives_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(lives_label)
	
	# Score Label
	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(score_label)

func _reset_game_state() -> void:
	current_speed_multiplier = initial_speed
	score = 0
	lives = max_lives
	print("Director: Game State Reset. Lives: ", lives, " Speed: ", current_speed_multiplier)

func start_game_loop() -> void:
	print("Director: Starting Game Loop")
	_play_random_game()

func _play_random_game() -> void:
	var games = _scan_games()
	if games.is_empty():
		push_error("No games found in " + games_dir)
		return
	
	var game_id = games.pick_random()
	_load_and_start_game(game_id)

func _scan_games() -> Array[String]:
	var games: Array[String] = []
	var dir = DirAccess.open(games_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				# Check if it has main.tscn
				if FileAccess.file_exists(games_dir + file_name + "/main.tscn"):
					games.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open directory: " + games_dir)
	return games

func _load_and_start_game(game_id: String) -> void:
	print("Director: Loading game - ", game_id)
	
	# Path to scene
	var scene_path = games_dir + game_id + "/main.tscn"
	var game_scene = load(scene_path)
	
	if not game_scene:
		push_error("Failed to load scene: " + scene_path)
		return
		
	# Instantiate
	var game_instance = game_scene.instantiate()
	
	if not game_instance is Microgame:
		push_error("Game script must extend Microgame: " + scene_path)
		game_instance.free()
		return
		
	current_game = game_instance
	add_child(current_game)
	
	# Configure
	current_game.speed_multiplier = current_speed_multiplier
	
	# Connect signals
	current_game.game_over.connect(_on_game_over)
	
func _on_game_over(game_score: int) -> void:
	print("Director: Game finished. Score: ", game_score)
	
	# Cleanup current game
	if is_instance_valid(current_game):
		current_game.queue_free()
		
	# Logic
	var round_message: String = ""
	
	if game_score > 0:
		# Pass
		score += 1
		round_message = "PASSED!"
		print("PASSED! Total Score: ", score)
		_increase_difficulty()
	else:
		# Fail
		lives -= 1
		round_message = "FAILED!"
		print("FAILED! Total Score: ", score, " Lives: ", lives)
	
	var is_game_over = lives <= 0
	if is_game_over:
		round_message = "GAME OVER"
	
	# Show Transition UI
	_update_ui(round_message)
	ui_layer.visible = true
	
	# Wait 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	ui_layer.visible = false
	
	if is_game_over:
		_reset_game_state()
		# Optional: Show a title screen or just restart loop
		_play_random_game()
	else:
		_play_random_game()

func _update_ui(msg: String) -> void:
	message_label.text = msg
	score_label.text = "Score: %d" % score
	
	# Build hearts string
	var hearts_str = ""
	for i in range(lives):
		hearts_str += "<3 "
	if lives == 0 and hearts_str == "":
		hearts_str = "X"
		
	lives_label.text = "Lives: %s" % hearts_str

func _increase_difficulty() -> void:
	current_speed_multiplier += speed_increment
	if current_speed_multiplier > max_speed:
		current_speed_multiplier = max_speed
	print("Director: Speed increased to ", current_speed_multiplier)
