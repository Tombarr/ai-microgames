extends Node2D

func _draw():
	# Mario-style pixel art character (40x40 roughly)
	
	# Hat (Red)
	draw_rect(Rect2(-12, -20, 24, 8), Color(0.9, 0.1, 0.1))  # Red cap
	
	# Face/Head (Beige)
	draw_rect(Rect2(-10, -12, 20, 16), Color(0.95, 0.8, 0.6))  # Skin tone
	
	# Eyes (Black dots)
	draw_rect(Rect2(-6, -8, 3, 3), Color(0, 0, 0))  # Left eye
	draw_rect(Rect2(3, -8, 3, 3), Color(0, 0, 0))   # Right eye
	
	# Mustache (Brown)
	draw_rect(Rect2(-8, -2, 16, 4), Color(0.3, 0.15, 0.05))
	
	# Shirt (Red)
	draw_rect(Rect2(-10, 4, 20, 8), Color(0.9, 0.1, 0.1))
	
	# Overalls (Blue)
	draw_rect(Rect2(-8, 12, 16, 8), Color(0.2, 0.2, 0.8))  # Pants
	
	# Overall straps
	draw_rect(Rect2(-6, 4, 3, 8), Color(0.2, 0.2, 0.8))  # Left strap
	draw_rect(Rect2(3, 4, 3, 8), Color(0.2, 0.2, 0.8))   # Right strap
	
	# Buttons (Yellow)
	draw_circle(Vector2(-4, 8), 2, Color(0.9, 0.8, 0.1))  # Left button
	draw_circle(Vector2(4, 8), 2, Color(0.9, 0.8, 0.1))   # Right button
	
	# Shoes (Brown)
	draw_rect(Rect2(-10, 18, 8, 4), Color(0.4, 0.2, 0.05))  # Left shoe
	draw_rect(Rect2(2, 18, 8, 4), Color(0.4, 0.2, 0.05))    # Right shoe
