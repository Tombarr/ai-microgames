extends Node

## Leaderboard Manager: Handles online leaderboard via Supabase
## Uses JavaScript fetch API on web builds to avoid gzip decompression issues

# Supabase Configuration
const SUPABASE_URL = "https://yyafrfrgayzgclwudkhp.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5YWZyZnJnYXl6Z2Nsd3Vka2hwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1MjkwNjEsImV4cCI6MjA4MDEwNTA2MX0.zcaX8McWxdTnthlejjWt8KoJ_g-16jfRIxm1QXArVbI"
const TABLE_NAME = "leaderboard"
const MAX_ENTRIES = 10

var leaderboard_data: Array[Dictionary] = []
var http_request: HTTPRequest
var is_loading: bool = false
var is_submitting: bool = false
var is_web: bool = false

signal leaderboard_loaded(success: bool)
signal score_submitted(success: bool, rank: int)

func _ready():
	# Check if running in web browser
	# JavaScriptBridge is only available in web exports
	is_web = OS.has_feature("web")

	if not is_web:
		# Create HTTP request node for native builds
		http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(_on_request_completed)

	_load_leaderboard()

func _load_leaderboard() -> void:
	if is_loading:
		return

	is_loading = true
	print("Fetching leaderboard from Supabase...")

	var url = SUPABASE_URL + "/rest/v1/" + TABLE_NAME + "?select=*&order=score.desc&limit=" + str(MAX_ENTRIES)

	if is_web:
		# Use JavaScript fetch API to avoid Godot's gzip decompression issues
		# Store result in window and poll for it
		JavaScriptBridge.eval("window._godot_leaderboard_result = null; window._godot_leaderboard_loading = true;")

		var js_code = """
		console.log('JS LOAD: Starting fetch...');
		fetch('%s', {
			method: 'GET',
			headers: {
				'apikey': '%s',
				'Authorization': 'Bearer %s',
				'Content-Type': 'application/json'
			}
		})
		.then(response => {
			console.log('JS LOAD: Got response', response.status);
			return response.json();
		})
		.then(data => {
			console.log('JS LOAD: Got data', data.length, 'entries');
			window._godot_leaderboard_result = JSON.stringify({success: true, data: data});
			window._godot_leaderboard_loading = false;
			console.log('JS LOAD: Result stored!');
		})
		.catch(error => {
			console.log('JS LOAD: Error', error.message);
			window._godot_leaderboard_result = JSON.stringify({success: false, error: error.message});
			window._godot_leaderboard_loading = false;
		});
		""" % [url, SUPABASE_KEY, SUPABASE_KEY]

		JavaScriptBridge.eval(js_code)
		print("JS fetch initiated for leaderboard load")

		# Poll for result
		_poll_load_result()
	else:
		# Use Godot HTTPRequest for native builds
		var headers = [
			"apikey: " + SUPABASE_KEY,
			"Authorization: Bearer " + SUPABASE_KEY,
			"Content-Type: application/json"
		]

		var error = http_request.request(url, headers, HTTPClient.METHOD_GET)

		if error != OK:
			push_error("Failed to send leaderboard request: " + str(error))
			is_loading = false
			leaderboard_loaded.emit(false)

func _poll_load_result() -> void:
	# Poll every frame until result is ready
	while true:
		await get_tree().process_frame
		var loading = JavaScriptBridge.eval("window._godot_leaderboard_loading")
		if not loading:
			break

	# Get the result
	var result_str = str(JavaScriptBridge.eval("window._godot_leaderboard_result"))
	print("Godot: Got load result, length: ", result_str.length())

	is_loading = false

	var json = JSON.new()
	var parse_result = json.parse(result_str)

	if parse_result != OK:
		push_error("Failed to parse JS response: " + json.get_error_message())
		leaderboard_loaded.emit(false)
		return

	var response = json.get_data()

	if response.get("success", false):
		var data = response.get("data", [])
		leaderboard_data.clear()
		for entry in data:
			leaderboard_data.append(entry)
		print("Loaded ", leaderboard_data.size(), " leaderboard entries from Supabase (via JS)")
		leaderboard_loaded.emit(true)
	else:
		push_error("JS fetch failed: " + str(response.get("error", "Unknown error")))
		leaderboard_loaded.emit(false)

func _on_js_load_complete(args) -> void:
	# Legacy callback - no longer used but kept for reference
	pass

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_string = body.get_string_from_utf8()

	if is_loading:
		is_loading = false

		# Enhanced error logging for debugging
		if result != HTTPRequest.RESULT_SUCCESS:
			push_error("HTTP Request failed with result code: " + str(result))
			print("Result code meanings: 1=Can't connect, 2=Can't resolve, 3=Connection error, 4=TLS error, 5=Request failed, 6=Redirect limit")
			leaderboard_loaded.emit(false)
			return

		if response_code == 200:
			var json = JSON.new()
			var parse_result = json.parse(body_string)

			if parse_result == OK:
				var data = json.get_data()
				if data is Array:
					leaderboard_data.clear()
					for entry in data:
						leaderboard_data.append(entry)
					print("Loaded ", leaderboard_data.size(), " leaderboard entries from Supabase")
					leaderboard_loaded.emit(true)
				else:
					push_error("Invalid leaderboard data format")
					leaderboard_loaded.emit(false)
			else:
				push_error("Failed to parse leaderboard response")
				leaderboard_loaded.emit(false)
		else:
			push_error("Failed to load leaderboard. Response code: " + str(response_code))
			print("Response body: ", body_string)
			if response_code == 0:
				print("Response code 0 often indicates CORS issues on web builds")
			leaderboard_loaded.emit(false)

	elif is_submitting:
		is_submitting = false

		if response_code == 201:
			print("Score submitted successfully!")
			# Reload leaderboard to get updated rankings
			_load_leaderboard()
			await leaderboard_loaded

			# Find player's rank
			var rank = -1
			for i in range(leaderboard_data.size()):
				if leaderboard_data[i].has("id"):
					# Try to match recent submission
					rank = i + 1
					break

			score_submitted.emit(true, rank)
		else:
			push_error("Failed to submit score. Response code: " + str(response_code))
			print("Response body: ", body_string)
			score_submitted.emit(false, -1)

func is_top_10(score: int) -> bool:
	# If less than 10 entries, always qualify
	if leaderboard_data.size() < MAX_ENTRIES:
		return true

	# Check if score is higher than lowest entry
	var lowest_score = leaderboard_data[leaderboard_data.size() - 1]["score"]
	return score > lowest_score

func add_entry(player_name: String, score: int) -> void:
	if is_submitting:
		return

	is_submitting = true
	print("Submitting score to Supabase...")

	var timestamp = Time.get_datetime_string_from_system()

	var new_entry = {
		"name": player_name.to_upper(),
		"score": score,
		"created_at": timestamp
	}

	var url = SUPABASE_URL + "/rest/v1/" + TABLE_NAME
	var body = JSON.stringify(new_entry)

	if is_web:
		# Use JavaScript fetch API to avoid Godot's gzip decompression issues
		# Store result in window and poll for it
		JavaScriptBridge.eval("window._godot_submit_result = null; window._godot_submit_loading = true;")

		# Escape the body JSON properly for embedding in JS string
		var escaped_body = body.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")

		var js_code = """
		console.log('JS SUBMIT: Starting fetch...');
		fetch('%s', {
			method: 'POST',
			headers: {
				'apikey': '%s',
				'Authorization': 'Bearer %s',
				'Content-Type': 'application/json',
				'Prefer': 'return=representation'
			},
			body: '%s'
		})
		.then(response => {
			console.log('JS SUBMIT: Got response', response.status);
			if (response.status === 201) {
				return response.json().then(data => ({success: true, data: data}));
			} else {
				return response.text().then(text => ({success: false, error: text}));
			}
		})
		.then(result => {
			console.log('JS SUBMIT: Result', result);
			window._godot_submit_result = JSON.stringify(result);
			window._godot_submit_loading = false;
			console.log('JS SUBMIT: Result stored!');
		})
		.catch(error => {
			console.log('JS SUBMIT: Error', error.message);
			window._godot_submit_result = JSON.stringify({success: false, error: error.message});
			window._godot_submit_loading = false;
		});
		""" % [url, SUPABASE_KEY, SUPABASE_KEY, escaped_body]

		JavaScriptBridge.eval(js_code)
		print("JS fetch initiated for score submit")

		# Poll for result
		_poll_submit_result()
	else:
		# Use Godot HTTPRequest for native builds
		var headers = [
			"apikey: " + SUPABASE_KEY,
			"Authorization: Bearer " + SUPABASE_KEY,
			"Content-Type: application/json",
			"Prefer: return=representation"
		]

		var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)

		if error != OK:
			push_error("Failed to send score submission request: " + str(error))
			is_submitting = false
			score_submitted.emit(false, -1)

func _poll_submit_result() -> void:
	# Poll every frame until result is ready
	while true:
		await get_tree().process_frame
		var loading = JavaScriptBridge.eval("window._godot_submit_loading")
		if not loading:
			break

	# Get the result
	var result_str = str(JavaScriptBridge.eval("window._godot_submit_result"))
	print("Godot: Got submit result, length: ", result_str.length())

	is_submitting = false

	var json = JSON.new()
	var parse_result = json.parse(result_str)

	if parse_result != OK:
		push_error("Failed to parse JS submit response: " + json.get_error_message())
		score_submitted.emit(false, -1)
		return

	var response = json.get_data()

	if response.get("success", false):
		print("Score submitted successfully! (via JS)")
		# Reload leaderboard to get updated rankings
		_load_leaderboard()
		await leaderboard_loaded

		# Find player's rank (simplified - just return 1 for now)
		var rank = 1
		for i in range(leaderboard_data.size()):
			if leaderboard_data[i].has("id"):
				rank = i + 1
				break

		score_submitted.emit(true, rank)
	else:
		push_error("JS submit failed: " + str(response.get("error", "Unknown error")))
		score_submitted.emit(false, -1)

func _on_js_submit_complete(args) -> void:
	# Legacy callback - no longer used but kept for reference
	pass

func get_leaderboard() -> Array[Dictionary]:
	return leaderboard_data.duplicate()

func get_rank_suffix(rank: int) -> String:
	match rank:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"
