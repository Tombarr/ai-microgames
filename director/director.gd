extends Node

var current_game = null
var games = {
	"sokoban": "res://games/micro_sokoban/main.tscn"
}

func _ready():
	# For now, just load the first game
	load_game("sokoban")

func load_game(game_name):
	if games.has(game_name):
		var game_path = games[game_name]
		var game_scene = load(game_path)
		if game_scene:
			if current_game:
				current_game.queue_free()
			
			current_game = game_scene.instance()
			add_child(current_game)
	else:
		print("Game not found: ", game_name)
