extends CanvasLayer

## Game Debugger: Quick access to test individual games
## Press F3 to toggle

signal game_selected(game_id: String)

var debug_panel: Panel
var game_list_container: VBoxContainer
var scroll_container: ScrollContainer
var is_visible: bool = false

func _ready():
	layer = 1000  # Above everything else
	visible = false
	call_deferred("_create_ui")

func _input(event):
	if event.is_action_pressed("toggle_debugger"):
		toggle_debugger()
		get_viewport().set_input_as_handled()

func toggle_debugger():
	is_visible = !is_visible
	visible = is_visible

	if is_visible:
		_populate_game_list()

func _create_ui():
	var viewport_size = get_viewport().get_visible_rect().size

	# Semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.size = viewport_size
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Debug panel
	debug_panel = Panel.new()
	debug_panel.position = Vector2(viewport_size.x * 0.2, viewport_size.y * 0.1)
	debug_panel.size = Vector2(viewport_size.x * 0.6, viewport_size.y * 0.8)
	add_child(debug_panel)

	# Container for panel contents
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = debug_panel.size - Vector2(40, 40)
	debug_panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "GAME DEBUGGER (ESC to close)"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)

	# Instructions
	var instructions = Label.new()
	instructions.text = "Click a game to play it immediately"
	instructions.add_theme_font_size_override("font_size", 18)
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instructions)

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	# Scroll container for game list
	scroll_container = ScrollContainer.new()
	scroll_container.custom_minimum_size = Vector2(0, viewport_size.y * 0.5)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll_container)

	# Game list container
	game_list_container = VBoxContainer.new()
	game_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(game_list_container)

func _populate_game_list():
	# Clear existing items
	for child in game_list_container.get_children():
		child.queue_free()

	# Get game list from Director's static list
	var games_dir = "res://games/"
	var game_list = [
		"box_pusher",
		"flappy_bird",
		"geo_stacker",
		"money_grabber",
		"sample_ai_game",
	]

	for game_id in game_list:
		var scene_path = games_dir + game_id + "/main.tscn"
		if not ResourceLoader.exists(scene_path):
			continue

		# Create button for each game
		var button = Button.new()
		button.text = _format_game_name(game_id)
		button.custom_minimum_size = Vector2(0, 50)
		button.add_theme_font_size_override("font_size", 24)

		# Store game_id in metadata
		button.set_meta("game_id", game_id)

		# Connect button press
		button.pressed.connect(_on_game_button_pressed.bind(game_id))

		game_list_container.add_child(button)

func _format_game_name(game_id: String) -> String:
	# Convert "flappy_bird" to "Flappy Bird"
	var words = game_id.split("_")
	var formatted = ""
	for word in words:
		if formatted != "":
			formatted += " "
		formatted += word.capitalize()
	return formatted

func _on_game_button_pressed(game_id: String):
	print("Debugger: Selected game - " + game_id)
	game_selected.emit(game_id)
	toggle_debugger()  # Close debugger after selection
