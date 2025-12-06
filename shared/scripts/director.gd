extends Node

## Director: Orchestrates the flow of microgames.
## Scans for games, plays them, handles scoring and speed.

@export var games_dir: String = "res://games/"
@export var initial_speed: float = 1.0

# Static list of games for web export compatibility (DirAccess doesn't work in browser)
# See GAME_CATEGORIES.md for detailed game organization
const GAME_LIST: Array[String] = [
	# Grid-Based Puzzles (turn-based, strategic)
	"box_pusher",      # Sokoban - STYLE_GUIDE_GRID_PUZZLE.md
	"geo_stacker",     # Tetris-style
	"loop_connect",    # Path puzzle
	"minesweeper",     # Classic sweep

	# Platformers & Runners (physics-based, reflex)
	"infinite_jump",   # Mario runner - STYLE_GUIDE_PLATFORMER.md
	"flappy_bird",     # Vertical scroller

	# Action & Timing (tap targets, real-time)
	"balloon_popper",  # Single target
	"dont_touch",      # Resist clicking buttons
	"money_grabber",   # Collection game
	"space_invaders",  # Shooter
	"whack_a_mole",    # Timing game
]
@export var speed_increment: float = 0.2
@export var max_speed: float = 5.0
@export var max_lives: int = 3

var current_game: Microgame
var current_game_id: String = ""  # Track current game ID for sharing
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
var countdown_label: Label  # Shows 3, 2, 1, 0 countdown synced to beats
var last_countdown_beat: int = -1  # Track last shown countdown beat
var game_title_label: Label
var status_label: Label
var game_debugger: Node

# Beat-based timing (120 BPM)
const BPM: float = 120.0
const BEAT_DURATION: float = 60.0 / BPM  # 0.5 seconds per beat
const NORMAL_GAME_BEATS: int = 8  # 4 seconds
const LONG_GAME_BEATS: int = 16  # 8 seconds
const INTERMISSION_BEATS: int = 4  # 2 seconds
const COUNTDOWN_BEATS: int = 4  # Last 4 beats show 3, 2, 1, 0

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
	# Check for Tab key to show leaderboard (hold Tab to view)
	if Input.is_physical_key_pressed(KEY_TAB) and game_active:
		_on_tab_pressed()
		return

	if not game_active:
		return

	# Timer speeds up with game speed - faster games have faster timers
	game_timer += delta * current_speed_multiplier
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

	# Update beat-synced countdown (3, 2, 1, 0 in last 4 beats)
	var beats_remaining = int(ceil(time_remaining / BEAT_DURATION))
	if beats_remaining <= COUNTDOWN_BEATS and beats_remaining >= 0:
		countdown_label.visible = true
		var countdown_num = beats_remaining  # 3, 2, 1, 0
		countdown_label.text = str(countdown_num)

		# Pulse effect on beat change
		if countdown_num != last_countdown_beat:
			last_countdown_beat = countdown_num
			# Scale up then back to normal
			countdown_label.scale = Vector2(1.5, 1.5)
			var tween = create_tween()
			tween.tween_property(countdown_label, "scale", Vector2(1.0, 1.0), BEAT_DURATION * 0.3)

			# Color based on urgency
			if countdown_num <= 1:
				countdown_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))  # Red
			elif countdown_num == 2:
				countdown_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1))  # Yellow
			else:
				countdown_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		countdown_label.visible = false

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

	# Create countdown label (bottom left, shows 3, 2, 1, 0 synced to beats)
	countdown_label = Label.new()
	countdown_label.position = Vector2(20, viewport_size.y - 80)
	countdown_label.add_theme_font_size_override("font_size", 48)
	countdown_label.add_theme_color_override("font_color", Color.WHITE)
	countdown_label.add_theme_color_override("font_outline_color", Color.BLACK)
	countdown_label.add_theme_constant_override("outline_size", 4)
	countdown_label.visible = false
	countdown_label.z_index = 101  # Above progress bar
	add_child(countdown_label)

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

	# Check for game ID in URL query parameter
	var url_game = _get_url_game_param()
	if url_game != "" and url_game in GAME_LIST:
		print("Director: Starting with game from URL - " + url_game)
		_load_and_start_game(url_game)
	else:
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

	# Store current game ID for sharing
	current_game_id = game_id

	# Update URL with current game (for sharing)
	_update_url_game_param(game_id)

	# Beat-based timing: 8 beats = 4 seconds at 120 BPM
	current_time_limit = NORMAL_GAME_BEATS * BEAT_DURATION  # 4 seconds
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

	# Read back time_limit in case game overrode it in _ready()
	current_time_limit = current_game.time_limit

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

	# Hide countdown label
	countdown_label.visible = false

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

	# Wait 2 beats to show result (1 second at 120 BPM)
	await get_tree().create_timer(BEAT_DURATION * 2).timeout

	# Play countdown sound with pitch based on speed multiplier
	# Formula: pitch increases as speed increases (1.0x = 1.0 pitch, 5.0x = 2.0 pitch)
	countdown_player.pitch_scale = 0.8 + (current_speed_multiplier - 1.0) * 0.3
	countdown_player.play()

	# Wait remaining 2 beats for countdown (total 4 beats = 2 seconds)
	await get_tree().create_timer(BEAT_DURATION * 2).timeout

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
	# NO TITLE SCREEN: Show game immediately with title overlay
	# Game is already at full opacity from creation
	current_game.modulate.a = 1.0

	# Show progress bar and start game timer immediately
	progress_bar.visible = true
	progress_bar_bg.visible = true
	game_active = true
	game_timer = 0.0

	# Reset countdown state
	last_countdown_beat = -1
	countdown_label.visible = false
	countdown_label.add_theme_color_override("font_color", Color.WHITE)

	# Show game title as brief overlay on top of game
	game_title_label.text = title
	game_title_label.visible = true

	# Fade in title quickly
	var fade_in = create_tween()
	fade_in.tween_property(game_title_label, "modulate:a", 1.0, 0.2)

	# Wait 1 second showing title, then fade out
	await get_tree().create_timer(1.0).timeout

	var fade_out = create_tween()
	fade_out.tween_property(game_title_label, "modulate:a", 0.0, 0.3)

	await fade_out.finished
	game_title_label.visible = false

func _on_game_timeout() -> void:
	if not game_active:
		return

	print("Director: Game timed out! Player loses.")

	# Show explosion effect at countdown position
	_show_explosion_effect()

	# Hide countdown
	countdown_label.visible = false

	# Timeout always means loss - call _on_game_over with score 0
	_on_game_over(0)

func _show_explosion_effect() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var explosion_pos = Vector2(60, viewport_size.y - 60)  # Near countdown position

	# Create explosion particles using custom drawing
	var explosion = Node2D.new()
	explosion.position = explosion_pos
	explosion.z_index = 102
	add_child(explosion)

	# Create multiple particle circles that expand outward
	var colors = [Color(1.0, 0.8, 0.0), Color(1.0, 0.4, 0.0), Color(1.0, 0.2, 0.0), Color(0.8, 0.0, 0.0)]

	for i in range(12):
		var particle = ColorRect.new()
		particle.size = Vector2(16, 16)
		particle.position = Vector2(-8, -8)  # Center it
		particle.color = colors[i % colors.size()]
		particle.pivot_offset = Vector2(8, 8)
		explosion.add_child(particle)

		# Animate each particle outward
		var angle = (i / 12.0) * TAU
		var distance = randf_range(60, 100)
		var target_pos = Vector2(cos(angle), sin(angle)) * distance

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_property(particle, "scale", Vector2(0.2, 0.2), 0.4)

	# Clean up after animation
	get_tree().create_timer(0.5).timeout.connect(func(): explosion.queue_free())

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

	# Show game over UI with final score
	ui_layer.visible = true

	# Update labels
	message_label.text = "GAME OVER"
	score_label.text = "Final Score: %d" % score
	lives_label.text = ""

	# Wait for game over sound to finish (3.5 seconds)
	await get_tree().create_timer(3.5).timeout

	# Auto-submit score if > 0
	if score > 0:
		# Check if player made top 10 - let them enter name
		if LeaderboardManager.is_top_10(score):
			await _show_name_entry()
		else:
			# Auto-submit with default name for non-top-10 scores
			message_label.text = "SUBMITTING..."
			LeaderboardManager.add_entry("PLAYER", score)
			await LeaderboardManager.score_submitted
			await _show_leaderboard(false)
	else:
		# Score is 0, just show leaderboard
		await _show_leaderboard(false)

func _show_name_entry() -> void:
	message_label.text = "TOP 10 SCORE!"
	score_label.text = "Final Score: %d\nEnter Your Name:" % score

	# Create name input field
	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "PLAYER"
	name_input.max_length = 12
	name_input.custom_minimum_size = Vector2(300, 50)
	name_input.add_theme_font_size_override("font_size", 24)
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Create submit button
	var submit_button = Button.new()
	submit_button.name = "SubmitButton"
	submit_button.text = "SUBMIT"
	submit_button.custom_minimum_size = Vector2(200, 60)
	submit_button.add_theme_font_size_override("font_size", 24)

	# Add to UI
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					subchild.add_child(name_input)
					subchild.add_child(submit_button)
					break
			break

	# Focus input
	name_input.grab_focus()

	# Connect signals
	submit_button.pressed.connect(_on_submit_name.bind(name_input))
	name_input.text_submitted.connect(func(_text): _on_submit_name(name_input))

func _on_submit_name(name_input: LineEdit) -> void:
	var player_name = name_input.text.strip_edges()

	if player_name.is_empty():
		player_name = "PLAYER"

	# Remove name entry UI
	var submit_button = ui_layer.get_node_or_null("CenterContainer/VBoxContainer/SubmitButton")
	if submit_button:
		submit_button.queue_free()
	name_input.queue_free()

	# Show submitting message
	message_label.text = "SUBMITTING..."
	score_label.text = "Please wait..."

	# Submit to leaderboard
	LeaderboardManager.add_entry(player_name, score)

	# Wait for submission to complete
	await LeaderboardManager.score_submitted

	# Show result
	message_label.text = "SCORE SUBMITTED!"
	score_label.text = "Final Score: %d" % score

	await get_tree().create_timer(1.5).timeout

	# Show leaderboard without leaderboard button
	await _show_leaderboard(false)

func _show_play_again_button() -> void:
	# Create "Play Again" button
	var play_again_button = Button.new()
	play_again_button.name = "PlayAgainButton"
	play_again_button.text = "PLAY AGAIN"
	play_again_button.custom_minimum_size = Vector2(200, 60)
	play_again_button.add_theme_font_size_override("font_size", 20)
	play_again_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Add "View Leaderboard" button
	var leaderboard_button = Button.new()
	leaderboard_button.name = "LeaderboardButton"
	leaderboard_button.text = "LEADERBOARD"
	leaderboard_button.custom_minimum_size = Vector2(400, 60)
	leaderboard_button.add_theme_font_size_override("font_size", 24)

	# Create "Share" button
	var share_button = Button.new()
	share_button.text = "SHARE"
	share_button.custom_minimum_size = Vector2(200, 60)
	share_button.add_theme_font_size_override("font_size", 20)
	share_button.name = "ShareButton"
	share_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Create HBoxContainer for Play Again and Share buttons (side by side)
	var hbox = HBoxContainer.new()
	hbox.name = "ButtonRow"
	hbox.add_theme_constant_override("separation", 10)
	hbox.add_child(play_again_button)
	hbox.add_child(share_button)

	# Position buttons below score
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					subchild.add_child(hbox)
					subchild.add_child(leaderboard_button)
					break
			break

	# Connect button signals
	play_again_button.pressed.connect(_on_play_again_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	share_button.pressed.connect(_on_share_pressed)

func _on_leaderboard_pressed() -> void:
	await _show_leaderboard()

func _show_leaderboard(show_leaderboard_button: bool = true) -> void:
	# Clear existing buttons and UI elements
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					# Remove button row container if present
					var button_row = subchild.get_node_or_null("ButtonRow")
					if button_row:
						button_row.queue_free()
					# Remove individual buttons
					var button = subchild.get_node_or_null("PlayAgainButton")
					if button:
						button.queue_free()
					button = subchild.get_node_or_null("LeaderboardButton")
					if button:
						button.queue_free()
					button = subchild.get_node_or_null("ShareButton")
					if button:
						button.queue_free()
					button = subchild.get_node_or_null("SubmitButton")
					if button:
						button.queue_free()
					# Remove existing scroll container if present
					var scroll = subchild.get_node_or_null("LeaderboardScroll")
					if scroll:
						scroll.queue_free()
					break
			break

	message_label.text = "LEADERBOARD"
	score_label.text = "Loading..."

	# Fetch leaderboard
	LeaderboardManager._load_leaderboard()
	await LeaderboardManager.leaderboard_loaded

	# Display leaderboard in a scrollable container
	var leaderboard = LeaderboardManager.get_leaderboard()

	# Create ScrollContainer for leaderboard
	var scroll_container = ScrollContainer.new()
	scroll_container.name = "LeaderboardScroll"
	scroll_container.custom_minimum_size = Vector2(400, 200)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	# Create label for leaderboard entries
	var leaderboard_label = Label.new()
	leaderboard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_label.add_theme_font_size_override("font_size", 20)

	var text = ""
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		var rank = i + 1
		var suffix = LeaderboardManager.get_rank_suffix(rank)
		text += "%d%s: %s - %d\n" % [rank, suffix, entry["name"], entry["score"]]

	if leaderboard.is_empty():
		text = "No scores yet!\nBe the first!"

	leaderboard_label.text = text
	scroll_container.add_child(leaderboard_label)

	# Add scroll container to UI
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					subchild.add_child(scroll_container)
					break
			break

	# Clear score_label since we're using the scroll container now
	score_label.text = ""

	# Show buttons (with or without leaderboard button)
	if show_leaderboard_button:
		_show_play_again_button()
	else:
		_show_play_again_and_share_only()

func _show_play_again_and_share_only() -> void:
	# Check if buttons already exist to prevent duplicates
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					var existing_row = subchild.get_node_or_null("ButtonRow")
					if existing_row and is_instance_valid(existing_row) and not existing_row.is_queued_for_deletion():
						return  # Buttons already exist, don't create duplicates
					break
			break

	# Create "Play Again" button
	var play_again_button = Button.new()
	play_again_button.name = "PlayAgainButton"
	play_again_button.text = "PLAY AGAIN"
	play_again_button.custom_minimum_size = Vector2(200, 60)
	play_again_button.add_theme_font_size_override("font_size", 20)
	play_again_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Create "Share" button
	var share_button = Button.new()
	share_button.text = "SHARE"
	share_button.custom_minimum_size = Vector2(200, 60)
	share_button.add_theme_font_size_override("font_size", 20)
	share_button.name = "ShareButton"
	share_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Create HBoxContainer for buttons side by side
	var hbox = HBoxContainer.new()
	hbox.name = "ButtonRow"
	hbox.add_theme_constant_override("separation", 10)
	hbox.add_child(play_again_button)
	hbox.add_child(share_button)

	# Position buttons below leaderboard
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					subchild.add_child(hbox)
					break
			break

	# Connect button signals
	play_again_button.pressed.connect(_on_play_again_pressed)
	share_button.pressed.connect(_on_share_pressed)

func _on_play_again_pressed() -> void:
	# Remove ALL dynamic UI elements (buttons, scroll containers, etc.)
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					# Remove button row container
					var button_row = subchild.get_node_or_null("ButtonRow")
					if button_row:
						button_row.queue_free()
					# Remove leaderboard scroll container
					var scroll = subchild.get_node_or_null("LeaderboardScroll")
					if scroll:
						scroll.queue_free()
					# Remove any individual buttons
					for button_child in subchild.get_children():
						if button_child is Button or button_child is ScrollContainer or button_child is HBoxContainer:
							button_child.queue_free()
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

# =============================================================================
# URL Sharing Functions (Web Export Only)
# =============================================================================

## Get game ID from URL query parameter (?game=xxx)
func _get_url_game_param() -> String:
	if OS.has_feature("web"):
		var js_code = """
			(function() {
				var params = new URLSearchParams(window.location.search);
				return params.get('game') || '';
			})();
		"""
		var result = JavaScriptBridge.eval(js_code)
		if result != null and result is String:
			return result
	return ""

## Update URL with current game ID (without page reload)
func _update_url_game_param(game_id: String) -> void:
	if OS.has_feature("web"):
		var js_code = """
			(function() {
				var url = new URL(window.location);
				url.searchParams.set('game', '%s');
				window.history.replaceState({}, '', url);
			})();
		""" % game_id
		JavaScriptBridge.eval(js_code)

## Share the current game using Web Share API or clipboard fallback
func _share_current_game() -> void:
	if not OS.has_feature("web"):
		print("Share is only available in web builds")
		return

	if current_game_id.is_empty():
		print("No game to share")
		return

	var game_name = _format_game_name(current_game_id)
	var js_code = """
		(function() {
			var shareData = {
				title: 'Play %s!',
				text: 'Try this microgame!',
				url: window.location.href
			};
			if (navigator.share) {
				navigator.share(shareData).catch(function(err) {
					// User cancelled or error - fall back to clipboard
					navigator.clipboard.writeText(window.location.href);
				});
			} else {
				navigator.clipboard.writeText(window.location.href).then(function() {
					// Success - clipboard API worked
				}).catch(function() {
					// Fallback for older browsers
					var textArea = document.createElement('textarea');
					textArea.value = window.location.href;
					document.body.appendChild(textArea);
					textArea.select();
					document.execCommand('copy');
					document.body.removeChild(textArea);
				});
			}
			return true;
		})();
	""" % game_name
	JavaScriptBridge.eval(js_code)

func _on_share_pressed() -> void:
	_share_current_game()

	# Update button text to show feedback
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					var share_button = subchild.get_node_or_null("ShareButton")
					if share_button:
						share_button.text = "LINK COPIED!"
						# Reset text after 2 seconds
						get_tree().create_timer(2.0).timeout.connect(func():
							if is_instance_valid(share_button):
								share_button.text = "SHARE"
						)
					break
			break

func _on_tab_pressed() -> void:
	# Stop game timer but don't pause the tree yet
	game_active = false

	# Hide progress bar
	progress_bar.visible = false
	progress_bar_bg.visible = false

	# Show leaderboard overlay
	message_label.text = "GAME PAUSED"
	score_label.text = "Current Score: %d" % score
	lives_label.text = ""
	ui_layer.visible = true

	# Create resume button
	var resume_button = Button.new()
	resume_button.name = "ResumeButton"
	resume_button.text = "RESUME"
	resume_button.custom_minimum_size = Vector2(400, 60)
	resume_button.add_theme_font_size_override("font_size", 24)
	resume_button.pressed.connect(_on_resume_pressed)

	# Add resume button to UI
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					subchild.add_child(resume_button)
					break
			break

	# Show leaderboard below
	await _show_leaderboard(false)

	# Now pause the tree after everything is set up
	# Set UI layer to process even when paused
	ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func _on_resume_pressed() -> void:
	# Unpause the tree first
	get_tree().paused = false
	ui_layer.process_mode = Node.PROCESS_MODE_INHERIT

	# Remove pause UI elements
	for child in ui_layer.get_children():
		if child is CenterContainer:
			for subchild in child.get_children():
				if subchild is VBoxContainer:
					# Remove all buttons and containers
					var resume_button = subchild.get_node_or_null("ResumeButton")
					if resume_button:
						resume_button.queue_free()
					var button_row = subchild.get_node_or_null("ButtonRow")
					if button_row:
						button_row.queue_free()
					var scroll = subchild.get_node_or_null("LeaderboardScroll")
					if scroll:
						scroll.queue_free()
					break
			break

	# Hide UI layer
	ui_layer.visible = false
	message_label.text = ""
	score_label.text = ""

	# Show progress bar again
	progress_bar.visible = true
	progress_bar_bg.visible = true

	# Resume the game
	game_active = true
