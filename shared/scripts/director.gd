extends Node

## Director: Orchestrates the flow of microgames.
## Scans for games, plays them, handles scoring and speed.

@export var games_dir: String = "res://games/"
@export var initial_speed: float = 1.0

# Static list of games for web export compatibility (DirAccess doesn't work in browser)
const GAME_LIST: Array[String] = [
	"box_pusher",
	"flappy_bird",
	"geo_stacker",
	"infinite_jump2",
	"loop_connect",
	"money_grabber",
	"sample_ai_game",
]
@export var speed_increment: float = 0.2
@export var max_speed: float = 5.0
@export var max_lives: int = 3

var current_game: Microgame
var current_speed_multiplier: float = 1.0
var score: int = 0
var lives: int = 3
var current_time_limit: float = 5.0
var game_timer: float = 0.0
var game_active: bool = false
var game_started: bool = false  # Track if initial game start sequence has played

# UI Elements
var ui_layer: CanvasLayer
var lives_label: Label
var score_label: Label
var message_label: Label
var progress_bar: ColorRect
var progress_bar_bg: ColorRect
var game_title_label: Label
var status_label: Label
var game_debugger: Node

# Audio
var countdown_player: AudioStreamPlayer
var game_start_player: AudioStreamPlayer
var game_over_player: AudioStreamPlayer

func _ready() -> void:
	_setup_ui()
	_setup_audio()
	_setup_debugger()
	_reset_game_state()
	# We start the loop deferred to ensure everything is initialized
	call_deferred("start_game_loop")

func _process(delta: float) -> void:
	if not game_active:
		return
	
	game_timer += delta
	var time_remaining = max(0, current_time_limit - game_timer)
	var progress = time_remaining / current_time_limit
	
	# Update progress bar
	if progress_bar:
		var viewport_size = get_viewport().get_visible_rect().size
		var bar_margin = 5
		progress_bar.size.x = (viewport_size.x - 2 * bar_margin) * progress
		
		# Color transitions from green to yellow to red
		if progress > 0.5:
			progress_bar.color = Color(0.2, 0.8, 0.2)  # Green
		elif progress > 0.25:
			progress_bar.color = Color(0.9, 0.7, 0.1)  # Yellow
		else:
			progress_bar.color = Color(0.9, 0.2, 0.2)  # Red
	
	# Check for timeout
	if time_remaining <= 0:
		_on_game_timeout()

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
	
	# Create progress bar at bottom (always visible during game)
	var viewport_size = get_viewport().get_visible_rect().size
	var bar_height = 20
	var bar_margin = 5
	
	progress_bar_bg = ColorRect.new()
	progress_bar_bg.color = Color(0.2, 0.2, 0.2)
	progress_bar_bg.position = Vector2(bar_margin, viewport_size.y - bar_height - bar_margin)
	progress_bar_bg.size = Vector2(viewport_size.x - 2 * bar_margin, bar_height)
	progress_bar_bg.visible = false
	progress_bar_bg.z_index = 100  # Ensure timer is on top of game content
	add_child(progress_bar_bg)

	progress_bar = ColorRect.new()
	progress_bar.color = Color(0.2, 0.8, 0.2)  # Start green
	progress_bar.position = Vector2(bar_margin, viewport_size.y - bar_height - bar_margin)
	progress_bar.size = Vector2(viewport_size.x - 2 * bar_margin, bar_height)
	progress_bar.visible = false
	progress_bar.z_index = 100  # Ensure timer is on top of game content
	add_child(progress_bar)
	
	# Create game title label (centered, for intro animation)
	game_title_label = Label.new()
	game_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_title_label.add_theme_font_size_override("font_size", 72)
	game_title_label.size = viewport_size
	game_title_label.modulate = Color(1, 1, 1, 0)  # Start transparent
	game_title_label.visible = false
	game_title_label.z_index = 100  # Ensure on top of game content
	add_child(game_title_label)

	# Create status label (Win/Lose, centered)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 96)
	status_label.size = viewport_size
	status_label.modulate = Color(1, 1, 1, 0)  # Start transparent
	status_label.visible = false
	status_label.z_index = 100  # Ensure on top of game content
	add_child(status_label)

func _setup_audio() -> void:
	# Create countdown sound player
	countdown_player = AudioStreamPlayer.new()
	countdown_player.name = "CountdownPlayer"
	countdown_player.stream = load("res://shared/assets/sfx_countdown.wav")
	countdown_player.volume_db = 6.0  # Increase volume by 6 decibels (about 2x louder)
	add_child(countdown_player)

	# Create game start sound player
	game_start_player = AudioStreamPlayer.new()
	game_start_player.name = "GameStartPlayer"
	game_start_player.stream = load("res://shared/assets/sfx_game_start.wav")
	game_start_player.volume_db = 6.0
	add_child(game_start_player)

	# Create game over sound player
	game_over_player = AudioStreamPlayer.new()
	game_over_player.name = "GameOverPlayer"
	game_over_player.stream = load("res://shared/assets/sfx_game_over.wav")
	game_over_player.volume_db = 6.0
	add_child(game_over_player)

func _setup_debugger() -> void:
	# Load and instantiate the game debugger
	var debugger_script = load("res://shared/scripts/game_debugger.gd")
	game_debugger = CanvasLayer.new()
	game_debugger.set_script(debugger_script)
	game_debugger.name = "GameDebugger"
	add_child(game_debugger)

	# Connect to game selection signal
	game_debugger.game_selected.connect(_on_debugger_game_selected)

func _on_debugger_game_selected(game_id: String) -> void:
	print("Director: Loading game from debugger - " + game_id)

	# Stop current game if running
	if current_game:
		await _cleanup_current_game()

	# Reset game state for fresh start
	game_active = false
	game_timer = 0.0

	# Hide UI elements
	progress_bar.visible = false
	progress_bar_bg.visible = false
	status_label.visible = false

	# Load the selected game
	_load_and_start_game(game_id)

func _cleanup_current_game():
	if is_instance_valid(current_game):
		current_game.queue_free()
		current_game = null
		# Wait one frame to ensure the game is fully removed
		await get_tree().process_frame

func _reset_game_state() -> void:
	current_speed_multiplier = initial_speed
	score = 0
	lives = max_lives
	print("Director: Game State Reset. Lives: ", lives, " Speed: ", current_speed_multiplier)

func start_game_loop() -> void:
	print("Director: Starting Game Loop")

	# Play game start countdown on first run
	if not game_started:
		await _show_game_start_sequence()
		game_started = true

	_play_random_game()

func _play_random_game() -> void:
	var games = _scan_games()
	if games.is_empty():
		push_error("No games found in " + games_dir)
		return
	
	var game_id = games.pick_random()
	_load_and_start_game(game_id)

func _scan_games() -> Array[String]:
	# Use static list for web compatibility (DirAccess doesn't work in browser)
	# Filter to only include games that exist
	var games: Array[String] = []
	for game_id in GAME_LIST:
		var scene_path = games_dir + game_id + "/main.tscn"
		if ResourceLoader.exists(scene_path):
			games.append(game_id)
	return games

func _load_and_start_game(game_id: String) -> void:
	print("Director: Loading game - ", game_id)
	
	# Generate random time limit between 5-10 seconds
	current_time_limit = randf_range(5.0, 10.0)
	game_timer = 0.0
	
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
	
	# Configure before adding to tree
	current_game.speed_multiplier = current_speed_multiplier
	current_game.time_limit = current_time_limit
	current_game.game_name = _format_game_name(game_id)
	
	# Make game invisible initially for intro animation
	current_game.modulate = Color(1, 1, 1, 0)
	add_child(current_game)
	
	# Connect signals
	current_game.game_over.connect(_on_game_over)
	
	# Start intro sequence
	_start_game_intro(current_game.game_name)
	
func _on_game_over(game_score: int) -> void:
	# Prevent double-handling (game already ended)
	if not game_active:
		return
	
	game_active = false
	print("Director: Game finished. Score: ", game_score)
	
	# Disconnect signal to prevent duplicate calls
	if is_instance_valid(current_game) and current_game.game_over.is_connected(_on_game_over):
		current_game.game_over.disconnect(_on_game_over)
	
	# Determine win/lose
	var did_win = game_score > 0
	
	# Show Win/Lose status
	await _show_game_result(did_win)
	
	# Cleanup current game
	if is_instance_valid(current_game):
		current_game.queue_free()
		
	# Logic
	var round_message: String = ""
	
	if did_win:
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

	# Wait 1 second to show result
	await get_tree().create_timer(1.0).timeout

	# Play countdown sound with pitch based on speed multiplier
	# Formula: pitch increases as speed increases (1.0x = 1.0 pitch, 5.0x = 2.0 pitch)
	countdown_player.pitch_scale = 0.8 + (current_speed_multiplier - 1.0) * 0.3
	countdown_player.play()

	# Wait for countdown to finish (1 second at normal speed, faster at higher speeds)
	var countdown_duration = 1.0 / countdown_player.pitch_scale
	await get_tree().create_timer(countdown_duration).timeout

	ui_layer.visible = false

	if is_game_over:
		# Show game over screen with play again button
		await _show_game_over_screen()
		# Note: _on_play_again_pressed will handle restart
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

func _format_game_name(game_id: String) -> String:
	# Convert snake_case or kebab-case to Title Case
	var words = game_id.replace("_", " ").replace("-", " ").split(" ")
	var formatted_words = []
	for word in words:
		if word.length() > 0:
			formatted_words.append(word.capitalize())
	return " ".join(formatted_words)

func _start_game_intro(title: String) -> void:
	# Show game title
	game_title_label.text = title
	game_title_label.visible = true

	# Fade in title over 0.15 seconds
	var tween = create_tween()
	tween.tween_property(game_title_label, "modulate:a", 1.0, 0.15)

	# Wait 0.4 seconds total (0.15 fade in + 0.25 display)
	await get_tree().create_timer(0.4).timeout

	# Fade out title and fade in game simultaneously
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(game_title_label, "modulate:a", 0.0, 0.15)
	fade_tween.tween_property(current_game, "modulate:a", 1.0, 0.15)

	await fade_tween.finished

	game_title_label.visible = false

	# Show progress bar and start game timer
	progress_bar.visible = true
	progress_bar_bg.visible = true
	game_active = true
	game_timer = 0.0

func _on_game_timeout() -> void:
	if not game_active:
		return
	
	print("Director: Game timed out! Player loses.")
	
	# Timeout always means loss - call _on_game_over with score 0
	_on_game_over(0)

func _show_game_start_sequence() -> void:
	# Show title screen with "GET READY!"
	game_title_label.text = "GET READY!"
	game_title_label.visible = true

	# Play countdown sound (same as between rounds)
	countdown_player.pitch_scale = 0.8 + (current_speed_multiplier - 1.0) * 0.3
	countdown_player.play()

	# Fade in over 0.3 seconds
	var tween = create_tween()
	tween.tween_property(game_title_label, "modulate:a", 1.0, 0.3)

	# Wait for countdown sound to finish
	var countdown_duration = 1.0 / countdown_player.pitch_scale
	await get_tree().create_timer(countdown_duration).timeout

	# Fade out
	var fade_out = create_tween()
	fade_out.tween_property(game_title_label, "modulate:a", 0.0, 0.3)

	await fade_out.finished
	game_title_label.visible = false

func _show_game_over_screen() -> void:
	# Play game over sound
	game_over_player.play()

	# Show game over UI with final score and play again button
	ui_layer.visible = true

	# Update labels
	message_label.text = "GAME OVER"
	score_label.text = "Final Score: %d" % score
	lives_label.text = ""

	# Create "Play Again" button
	var play_again_button = Button.new()
	play_again_button.text = "PLAY AGAIN"
	play_again_button.custom_minimum_size = Vector2(200, 60)

	# Style the button
	play_again_button.add_theme_font_size_override("font_size", 24)

	# Position button below score (find the vbox container)
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					play_again_button.name = "PlayAgainButton"
					subchild.add_child(play_again_button)
					break
			break

	# Connect button signal
	play_again_button.pressed.connect(_on_play_again_pressed)

	# Wait for game over sound to finish (3.5 seconds)
	await get_tree().create_timer(3.5).timeout

func _on_play_again_pressed() -> void:
	# Remove the play again button
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					var button = subchild.get_node_or_null("PlayAgainButton")
					if button:
						button.queue_free()
					break
			break

	# Hide UI
	ui_layer.visible = false

	# Reset game state
	_reset_game_state()

	# Start new game loop
	_play_random_game()

func _show_game_result(did_win: bool) -> void:
	# Hide progress bar
	progress_bar.visible = false
	progress_bar_bg.visible = false
	
	# Show Win/Lose status
	status_label.text = "WIN!" if did_win else "LOSE"
	status_label.modulate = Color(0.2, 0.9, 0.2, 0.0) if did_win else Color(0.9, 0.2, 0.2, 0.0)
	status_label.visible = true
	
	# Fade in status
	var tween = create_tween()
	tween.tween_property(status_label, "modulate:a", 1.0, 0.3)
	
	# Wait 1 second, then fade out
	await get_tree().create_timer(1.0).timeout
	
	var fade_out = create_tween()
	fade_out.tween_property(status_label, "modulate:a", 0.0, 0.3)
	
	await fade_out.finished
	status_label.visible = false
