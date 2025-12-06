extends Node

## Test Harness for Microgame Winnability Testing
## Runs each game with different strategies and reports results
## Usage: godot4 --headless --script res://shared/scripts/test_harness.gd

const GAMES_DIR = "res://games/"

# Game list (same as Director)
const GAME_LIST: Array[String] = [
	"box_pusher",
	"geo_stacker",
	"loop_connect",
	"minesweeper",
	"infinite_jump",
	"flappy_bird",
	"balloon_popper",
	"dont_touch",
	"money_grabber",
	"space_invaders",
	"whack_a_mole",
]

# Test strategies
enum Strategy { DO_NOTHING, PERFECT_PLAY }

# Expected outcomes per game/strategy
# Format: { "game_id": { Strategy.DO_NOTHING: expected_win, Strategy.PERFECT_PLAY: expected_win } }
const EXPECTED_OUTCOMES = {
	"box_pusher": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"geo_stacker": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"loop_connect": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"minesweeper": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"infinite_jump": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"flappy_bird": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"balloon_popper": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"dont_touch": { Strategy.DO_NOTHING: true, Strategy.PERFECT_PLAY: true },  # Win by doing nothing!
	"money_grabber": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"space_invaders": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
	"whack_a_mole": { Strategy.DO_NOTHING: false, Strategy.PERFECT_PLAY: true },
}

# Test state
var current_game: Microgame = null
var current_game_id: String = ""
var current_strategy: Strategy = Strategy.DO_NOTHING
var current_speed: float = 1.0
var game_result: int = -1  # -1 = pending, 0 = lose, 1+ = win
var test_queue: Array = []
var test_results: Array = []
var tests_passed: int = 0
var tests_failed: int = 0

# AI player state
var ai_click_timer: float = 0.0
var ai_action_interval: float = 0.1  # How often AI tries to act

func _ready():
	print("\n============================================================")
	print("MICROGAME TEST HARNESS")
	print("============================================================\n")

	# Build test queue
	_build_test_queue()

	# Start first test
	_run_next_test()

func _build_test_queue():
	# Test each game at speed 1.0 and 5.0 with both strategies
	for game_id in GAME_LIST:
		var scene_path = GAMES_DIR + game_id + "/main.tscn"
		if not ResourceLoader.exists(scene_path):
			print("SKIP: %s (scene not found)" % game_id)
			continue

		# Test at speed 1.0
		test_queue.append({
			"game_id": game_id,
			"speed": 1.0,
			"strategy": Strategy.PERFECT_PLAY
		})

		# Test at speed 5.0 (max difficulty)
		test_queue.append({
			"game_id": game_id,
			"speed": 5.0,
			"strategy": Strategy.PERFECT_PLAY
		})

		# Test do_nothing at speed 1.0 (verify lose condition works)
		test_queue.append({
			"game_id": game_id,
			"speed": 1.0,
			"strategy": Strategy.DO_NOTHING
		})

func _run_next_test():
	if test_queue.is_empty():
		_print_summary()
		get_tree().quit()
		return

	var test = test_queue.pop_front()
	current_game_id = test["game_id"]
	current_speed = test["speed"]
	current_strategy = test["strategy"]
	game_result = -1
	ai_click_timer = 0.0

	var strategy_name = "PERFECT" if current_strategy == Strategy.PERFECT_PLAY else "DO_NOTHING"
	print("Testing: %s | Speed: %.1fx | Strategy: %s" % [current_game_id, current_speed, strategy_name])

	# Load and start game
	_load_game(current_game_id)

func _load_game(game_id: String):
	# Cleanup previous game
	if current_game:
		current_game.queue_free()
		current_game = null

	var scene_path = GAMES_DIR + game_id + "/main.tscn"
	var game_scene = load(scene_path)

	if not game_scene:
		_record_result(false, "Failed to load scene")
		_run_next_test()
		return

	current_game = game_scene.instantiate()

	if not current_game is Microgame:
		_record_result(false, "Not a Microgame")
		current_game.queue_free()
		_run_next_test()
		return

	# Configure game
	current_game.speed_multiplier = current_speed
	current_game.time_limit = 4.0  # Standard duration

	# Connect signals
	current_game.game_over.connect(_on_game_over)

	add_child(current_game)

func _on_game_over(score: int):
	game_result = score

	var won = score > 0
	var strategy_name = "PERFECT" if current_strategy == Strategy.PERFECT_PLAY else "DO_NOTHING"

	# Check expected outcome
	var expected_win = EXPECTED_OUTCOMES.get(current_game_id, {}).get(current_strategy, null)
	var test_passed = (expected_win == null) or (won == expected_win)

	_record_result(test_passed, "Score: %d | Won: %s | Expected: %s" % [
		score,
		"YES" if won else "NO",
		"WIN" if expected_win else "LOSE" if expected_win == false else "N/A"
	])

	# Cleanup and next test
	if current_game:
		current_game.queue_free()
		current_game = null

	# Small delay before next test
	await get_tree().create_timer(0.1).timeout
	_run_next_test()

func _process(delta):
	if not current_game or game_result != -1:
		return

	# Run AI player based on strategy
	if current_strategy == Strategy.PERFECT_PLAY:
		ai_click_timer += delta
		if ai_click_timer >= ai_action_interval:
			ai_click_timer = 0.0
			_execute_perfect_play()

func _execute_perfect_play():
	# Game-specific AI strategies
	match current_game_id:
		"balloon_popper":
			_ai_click_target("Balloon")
		"whack_a_mole":
			_ai_click_moles()
		"money_grabber":
			_ai_click_collectibles()
		"infinite_jump":
			_ai_jump_obstacles()
		"flappy_bird":
			_ai_flap_bird()
		"dont_touch":
			pass  # Do nothing - that's the winning strategy!
		"box_pusher":
			_ai_solve_puzzle()
		"geo_stacker":
			_ai_stack_blocks()
		"loop_connect":
			_ai_connect_loops()
		"minesweeper":
			_ai_sweep_mines()
		"space_invaders":
			_ai_shoot_invaders()

# =============================================================================
# AI STRATEGIES
# =============================================================================

func _ai_click_target(node_name: String):
	var target = current_game.get_node_or_null(node_name)
	if target and target is Node2D:
		_simulate_click(target.global_position)

func _ai_click_moles():
	# Find visible moles and click them
	for child in current_game.get_children():
		if "mole" in child.name.to_lower() or child.has_method("is_active"):
			if child is Node2D and child.visible:
				_simulate_click(child.global_position)
				return

func _ai_click_collectibles():
	# Click on money/collectibles
	for child in current_game.get_children():
		if "money" in child.name.to_lower() or "coin" in child.name.to_lower():
			if child is Node2D:
				_simulate_click(child.global_position)
				return
	# Also try clicking center if nothing found
	_simulate_click(Vector2(320, 320))

func _ai_jump_obstacles():
	# Jump when obstacle is approaching
	var player = current_game.get_node_or_null("Player")
	if not player:
		return

	# Check if on floor and obstacle is close
	if player.is_on_floor():
		var obstacle_container = current_game.get_node_or_null("ObstacleContainer")
		if obstacle_container:
			for obstacle in obstacle_container.get_children():
				var dist = obstacle.position.x - player.position.x
				if dist > 0 and dist < 200:  # Obstacle approaching
					_simulate_click(player.global_position)
					return

func _ai_flap_bird():
	# Flap to maintain altitude
	var player = current_game.get_node_or_null("Player")
	if player and player is Node2D:
		if player.position.y > 400:  # Too low, flap
			_simulate_click(player.global_position)

func _ai_solve_puzzle():
	# Simple puzzle solving - try clicking interactive elements
	for child in current_game.get_children():
		if child is Node2D and child.has_method("push"):
			_simulate_click(child.global_position)
			return

func _ai_stack_blocks():
	# Click to drop blocks
	_simulate_click(Vector2(320, 100))

func _ai_connect_loops():
	# Click grid cells to rotate/connect
	_simulate_click(Vector2(320, 320))

func _ai_sweep_mines():
	# Click on safe cells
	_simulate_click(Vector2(320, 320))

func _ai_shoot_invaders():
	# Click to shoot at invaders
	for child in current_game.get_children():
		if "invader" in child.name.to_lower() or "enemy" in child.name.to_lower():
			if child is Node2D:
				_simulate_click(child.global_position)
				return
	_simulate_click(Vector2(320, 100))

# =============================================================================
# INPUT SIMULATION
# =============================================================================

func _simulate_click(pos: Vector2):
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	event.global_position = pos

	# Send to game
	if current_game:
		current_game._input(event)

	# Also send release
	var release = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = pos
	release.global_position = pos

	if current_game:
		current_game._input(release)

func _simulate_key(keycode: int):
	var event = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true

	if current_game:
		current_game._input(event)

# =============================================================================
# RESULTS
# =============================================================================

func _record_result(passed: bool, message: String):
	var strategy_name = "PERFECT" if current_strategy == Strategy.PERFECT_PLAY else "DO_NOTHING"
	var status = "PASS" if passed else "FAIL"
	var icon = "✓" if passed else "✗"

	var result = {
		"game": current_game_id,
		"speed": current_speed,
		"strategy": strategy_name,
		"passed": passed,
		"message": message
	}
	test_results.append(result)

	if passed:
		tests_passed += 1
	else:
		tests_failed += 1

	print("  %s %s: %s" % [icon, status, message])

func _print_summary():
	print("\n============================================================")
	print("TEST SUMMARY")
	print("============================================================")
	print("Total: %d | Passed: %d | Failed: %d" % [
		tests_passed + tests_failed,
		tests_passed,
		tests_failed
	])

	if tests_failed > 0:
		print("\nFailed Tests:")
		for result in test_results:
			if not result["passed"]:
				print("  - %s (%.1fx, %s): %s" % [
					result["game"],
					result["speed"],
					result["strategy"],
					result["message"]
				])

	print("\n============================================================")

	if tests_failed == 0:
		print("ALL TESTS PASSED!")
	else:
		print("SOME TESTS FAILED")
	print("============================================================\n")
