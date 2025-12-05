extends Node

## Leaderboard Manager: Handles online leaderboard via Supabase

# Supabase Configuration
const SUPABASE_URL = "https://yyafrfrgayzgclwudkhp.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5YWZyZnJnYXl6Z2Nsd3Vka2hwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1MjkwNjEsImV4cCI6MjA4MDEwNTA2MX0.zcaX8McWxdTnthlejjWt8KoJ_g-16jfRIxm1QXArVbI"
const TABLE_NAME = "leaderboard"
const MAX_ENTRIES = 10

var leaderboard_data: Array[Dictionary] = []
var http_request: HTTPRequest
var is_loading: bool = false
var is_submitting: bool = false

signal leaderboard_loaded(success: bool)
signal score_submitted(success: bool, rank: int)

func _ready():
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	_load_leaderboard()

func _load_leaderboard() -> void:
	if is_loading:
		return

	is_loading = true
	print("Fetching leaderboard from Supabase...")

	# Add cache-busting parameter to bypass service worker cached gzip responses
	var cache_bust = str(Time.get_unix_time_from_system())
	var url = SUPABASE_URL + "/rest/v1/" + TABLE_NAME + "?select=*&order=score.desc&limit=" + str(MAX_ENTRIES) + "&_cb=" + cache_bust

	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json",
		"Accept-Encoding: identity",  # Request uncompressed response for web builds
		"Cache-Control: no-cache, no-store, must-revalidate",  # Prevent caching
		"Pragma: no-cache"  # HTTP/1.0 compatibility
	]

	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if error != OK:
		push_error("Failed to send leaderboard request: " + str(error))
		is_loading = false
		leaderboard_loaded.emit(false)

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

	# Add cache-busting parameter to bypass service worker
	var cache_bust = str(Time.get_unix_time_from_system())
	var url = SUPABASE_URL + "/rest/v1/" + TABLE_NAME + "?_cb=" + cache_bust

	var headers = [
		"apikey: " + SUPABASE_KEY,
		"Authorization: Bearer " + SUPABASE_KEY,
		"Content-Type: application/json",
		"Prefer: return=representation",
		"Accept-Encoding: identity",  # Request uncompressed response for web builds
		"Cache-Control: no-cache, no-store, must-revalidate",
		"Pragma: no-cache"
	]

	var body = JSON.stringify(new_entry)

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		push_error("Failed to send score submission request: " + str(error))
		is_submitting = false
		score_submitted.emit(false, -1)

func get_leaderboard() -> Array[Dictionary]:
	return leaderboard_data.duplicate()

func get_rank_suffix(rank: int) -> String:
	match rank:
		1: return "st"
		2: return "nd"
		3: return "rd"
		_: return "th"
