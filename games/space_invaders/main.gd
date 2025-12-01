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

func _ready():
	instruction = "SHOOT!"
	super._ready()

	_setup_game()

func _setup_game():
	# Create player ship
	player_ship = Area2D.new()
	player_ship.position = Vector2(320, 580)
	add_child(player_ship)

	# Player visual (triangle pointing up)
	var player_visual = Polygon2D.new()
	player_visual.polygon = PackedVector2Array([
		Vector2(0, -16),    # Top
		Vector2(-16, 16),   # Bottom left
		Vector2(16, 16)     # Bottom right
	])
	player_visual.color = Color(0.2, 0.8, 0.2)  # Green
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

			# Alien visual (bigger rectangle - 40x40 instead of 20x20)
			var alien_visual = ColorRect.new()
			alien_visual.size = Vector2(40, 40)
			alien_visual.position = Vector2(-20, -20)  # Center it
			alien_visual.color = Color(0.8, 0.2, 0.2)  # Red
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
	time_elapsed += delta

	# Always let full 5 seconds run for Director timing
	if time_elapsed >= GAME_DURATION:
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

	# Bullet visual
	var bullet_visual = ColorRect.new()
	bullet_visual.size = Vector2(4, 12)
	bullet_visual.position = Vector2(-2, -6)  # Center it
	bullet_visual.color = Color(1, 1, 0)  # Yellow
	bullet.add_child(bullet_visual)

	# Bullet collision
	var bullet_collision = CollisionShape2D.new()
	var bullet_shape = RectangleShape2D.new()
	bullet_shape.size = Vector2(4, 12)
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
