extends Microgame

# Game state
var time_elapsed: float = 0.0
var game_ended: bool = false
const GAME_DURATION: float = 5.0

# Player
var player_ship: Area2D
var player_speed: float = 300.0
var player_x: float = 320.0

# Aliens
var aliens: Array = []
var alien_rows: int = 2
var alien_cols: int = 5
var alien_direction: int = 1  # 1 = right, -1 = left
var alien_speed: float = 50.0
var alien_move_down: float = 10.0

# Bullets
var bullets: Array = []
var bullet_speed: float = 400.0
var bullet_scene: PackedScene

# Touch/Mouse input
var touch_position: Vector2 = Vector2.ZERO
var is_touching: bool = false

# Audio
var win_sound: AudioStreamPlayer
var lose_sound: AudioStreamPlayer
var laser_sound: AudioStreamPlayer
var explosion_sound: AudioStreamPlayer

# Player ship visual class
class ShipVisual extends Node2D:
	func _draw():
		var main_color = Color(0.2, 0.75, 0.3)
		var highlight_color = Color(0.4, 0.95, 0.5)
		var shadow_color = Color(0.1, 0.5, 0.15)
		var cockpit_color = Color(0.3, 0.7, 0.95)

		# Ship body (main hull)
		draw_polygon([
			Vector2(0, -20),     # Nose
			Vector2(-8, -8),     # Left shoulder
			Vector2(-20, 16),    # Left wing tip
			Vector2(-12, 16),    # Left wing inner
			Vector2(-8, 8),      # Left body
			Vector2(8, 8),       # Right body
			Vector2(12, 16),     # Right wing inner
			Vector2(20, 16),     # Right wing tip
			Vector2(8, -8),      # Right shoulder
		], [main_color])

		# Hull highlight (left side)
		draw_polygon([
			Vector2(0, -20),
			Vector2(-6, -8),
			Vector2(-6, 6),
			Vector2(0, 6)
		], [highlight_color])

		# Hull shadow (right side)
		draw_polygon([
			Vector2(0, -16),
			Vector2(6, -6),
			Vector2(6, 6),
			Vector2(0, 6)
		], [shadow_color])

		# Cockpit (cyan glass)
		draw_polygon([
			Vector2(0, -14),
			Vector2(-4, -6),
			Vector2(-4, 2),
			Vector2(4, 2),
			Vector2(4, -6)
		], [cockpit_color])

		# Cockpit shine
		draw_circle(Vector2(-1, -8), 2, Color(1, 1, 1, 0.7))

		# Engine glow
		draw_circle(Vector2(-6, 14), 4, Color(1, 0.5, 0.1, 0.8))
		draw_circle(Vector2(6, 14), 4, Color(1, 0.5, 0.1, 0.8))
		draw_circle(Vector2(-6, 14), 2, Color(1, 0.9, 0.3))
		draw_circle(Vector2(6, 14), 2, Color(1, 0.9, 0.3))

# Alien visual class
class AlienVisual extends Node2D:
	var alien_type: int = 0  # Different types for variety

	func _draw():
		var main_color = Color(0.85, 0.2, 0.25)
		var highlight_color = Color(1.0, 0.5, 0.5)
		var shadow_color = Color(0.55, 0.1, 0.15)
		var eye_color = Color(1, 1, 0.3)

		# Main body (octopus-like shape)
		# Head
		draw_circle(Vector2(0, -8), 16, main_color)
		draw_circle(Vector2(-5, -12), 8, highlight_color)  # Highlight

		# Eyes
		draw_circle(Vector2(-8, -10), 6, Color.WHITE)
		draw_circle(Vector2(8, -10), 6, Color.WHITE)
		draw_circle(Vector2(-6, -10), 3, Color.BLACK)
		draw_circle(Vector2(10, -10), 3, Color.BLACK)

		# Angry eyebrows
		draw_line(Vector2(-14, -16), Vector2(-4, -14), Color.BLACK, 3)
		draw_line(Vector2(14, -16), Vector2(4, -14), Color.BLACK, 3)

		# Tentacles/legs
		var tentacle_color = shadow_color
		for i in range(4):
			var x_offset = -15 + i * 10
			var wave = sin(i * 0.5) * 3
			draw_polygon([
				Vector2(x_offset, 4),
				Vector2(x_offset + 6, 4),
				Vector2(x_offset + 4 + wave, 18),
				Vector2(x_offset + 2 + wave, 18)
			], [tentacle_color])

		# Teeth/fangs
		draw_polygon([
			Vector2(-6, 0),
			Vector2(-4, 6),
			Vector2(-2, 0)
		], [Color.WHITE])
		draw_polygon([
			Vector2(2, 0),
			Vector2(4, 6),
			Vector2(6, 0)
		], [Color.WHITE])

# Bullet visual class
class BulletVisual extends Node2D:
	func _draw():
		# Laser bolt
		draw_rect(Rect2(-2, -8, 4, 16), Color(1, 1, 0.3))
		draw_rect(Rect2(-1, -6, 2, 12), Color(1, 1, 0.9))
		# Glow effect
		draw_circle(Vector2(0, -6), 4, Color(1, 1, 0.5, 0.5))

func _ready():
	instruction = "SHOOT!"
	super._ready()

	# Override time limit - Space Invaders needs more time (16 beats = 8 seconds at 120 BPM)
	time_limit = 8.0

	_setup_game()

func _setup_game():
	# Create starfield background
	_create_background()

	# Create player ship
	player_ship = Area2D.new()
	player_ship.position = Vector2(320, 580)
	add_child(player_ship)

	# Player visual using custom class
	var player_visual = ShipVisual.new()
	player_ship.add_child(player_visual)

	# Player collision
	var player_collision = CollisionShape2D.new()
	var player_shape = RectangleShape2D.new()
	player_shape.size = Vector2(32, 32)
	player_collision.shape = player_shape
	player_ship.add_child(player_collision)

	# Setup aliens in formation
	_setup_aliens()

	# Setup audio
	win_sound = AudioStreamPlayer.new()
	win_sound.stream = load("res://shared/assets/sfx_win.wav")
	add_child(win_sound)

	lose_sound = AudioStreamPlayer.new()
	lose_sound.stream = load("res://shared/assets/sfx_lose.wav")
	add_child(lose_sound)

	laser_sound = AudioStreamPlayer.new()
	laser_sound.stream = load("res://shared/assets/sfx_laser_shoot.wav")
	add_child(laser_sound)

	explosion_sound = AudioStreamPlayer.new()
	explosion_sound.stream = load("res://shared/assets/sfx_alien_explode.wav")
	add_child(explosion_sound)

func _create_background():
	# Dark space background
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.08)
	bg.size = Vector2(640, 640)
	bg.z_index = -10
	add_child(bg)

	# Starfield
	var stars = Node2D.new()
	stars.z_index = -5

	var script = GDScript.new()
	script.source_code = """
extends Node2D

func _draw():
	# Draw random stars
	for i in range(50):
		var x = hash(i * 123) % 640
		var y = hash(i * 456) % 640
		var brightness = 0.3 + (hash(i * 789) % 70) / 100.0
		var size = 1 + (hash(i * 321) % 2)
		draw_circle(Vector2(x, y), size, Color(brightness, brightness, brightness + 0.1))

	# A few brighter stars
	for i in range(10):
		var x = hash(i * 999) % 640
		var y = hash(i * 888) % 640
		draw_circle(Vector2(x, y), 2, Color(1, 1, 0.9, 0.8))
		draw_circle(Vector2(x, y), 4, Color(1, 1, 0.9, 0.2))
"""
	script.reload()
	stars.set_script(script)
	add_child(stars)

func _setup_aliens():
	var start_x: float = 170.0
	var start_y: float = 100.0
	var spacing_x: float = 90.0
	var spacing_y: float = 70.0

	for row in range(alien_rows):
		for col in range(alien_cols):
			var alien = Area2D.new()
			alien.position = Vector2(
				start_x + col * spacing_x,
				start_y + row * spacing_y
			)
			add_child(alien)

			# Alien visual using custom class
			var alien_visual = AlienVisual.new()
			alien_visual.alien_type = (row + col) % 3
			alien.add_child(alien_visual)

			# Alien collision (bigger hitbox)
			var alien_collision = CollisionShape2D.new()
			var alien_shape = RectangleShape2D.new()
			alien_shape.size = Vector2(40, 40)
			alien_collision.shape = alien_shape
			alien.add_child(alien_collision)

			# Set collision layer/mask
			alien.collision_layer = 2
			alien.collision_mask = 4

			aliens.append(alien)

func _process(delta):
	time_elapsed += delta * speed_multiplier

	# Always let full time run for Director timing
	if time_elapsed >= time_limit:
		if not game_ended:
			_lose_game()
		return

	# Stop game logic after win/lose
	if game_ended:
		return

	# Update player position based on input
	if is_touching:
		player_x = touch_position.x

	# Clamp player position
	player_x = clamp(player_x, 16, 624)
	player_ship.position.x = player_x

	# Move aliens
	_move_aliens(delta)

	# Move bullets
	_move_bullets(delta)

	# Check collisions
	_check_collisions()

	# Check win condition
	if aliens.size() == 0:
		_win_game()

func _move_aliens(delta):
	var move_amount = alien_speed * speed_multiplier * delta * alien_direction
	var should_move_down = false

	# Check if any alien hits screen edge
	for alien in aliens:
		var new_x = alien.position.x + move_amount
		if new_x < 30 or new_x > 610:
			should_move_down = true
			break

	# Move aliens
	if should_move_down:
		alien_direction *= -1
		for alien in aliens:
			alien.position.y += alien_move_down
	else:
		for alien in aliens:
			alien.position.x += move_amount

func _move_bullets(delta):
	var bullets_to_remove = []

	for bullet in bullets:
		bullet.position.y -= bullet_speed * speed_multiplier * delta

		# Remove bullets that go off screen
		if bullet.position.y < -10:
			bullets_to_remove.append(bullet)

	for bullet in bullets_to_remove:
		bullets.erase(bullet)
		bullet.queue_free()

func _check_collisions():
	for bullet in bullets:
		var bullet_areas = bullet.get_overlapping_areas()

		for area in bullet_areas:
			if area in aliens:
				# Alien hit!
				explosion_sound.play()
				aliens.erase(area)
				area.queue_free()
				bullets.erase(bullet)
				bullet.queue_free()
				break

func _spawn_bullet():
	if game_ended:
		return

	# Play laser shoot sound
	laser_sound.play()

	var bullet = Area2D.new()
	bullet.position = player_ship.position + Vector2(0, -20)
	add_child(bullet)

	# Bullet visual using custom class
	var bullet_visual = BulletVisual.new()
	bullet.add_child(bullet_visual)

	# Bullet collision
	var bullet_collision = CollisionShape2D.new()
	var bullet_shape = RectangleShape2D.new()
	bullet_shape.size = Vector2(4, 16)
	bullet_collision.shape = bullet_shape
	bullet.add_child(bullet_collision)

	# Set collision layer/mask
	bullet.collision_layer = 4
	bullet.collision_mask = 2

	bullets.append(bullet)

func _input(event):
	if game_ended:
		return

	# Handle touch/click to shoot
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touching = true
			touch_position = event.position
			_spawn_bullet()
		else:
			is_touching = false

	# Handle touch/mouse drag for movement
	elif event is InputEventScreenDrag:
		is_touching = true
		touch_position = event.position

	# Handle mouse click to shoot
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			touch_position = event.position
			_spawn_bullet()

	# Handle mouse motion for movement
	elif event is InputEventMouseMotion:
		touch_position = event.position
		is_touching = true

func _win_game():
	if game_ended:
		return

	add_score(100)
	win_sound.play()
	end_game()
	game_ended = true

func _lose_game():
	if game_ended:
		return

	lose_sound.play()
	end_game()
	game_ended = true
