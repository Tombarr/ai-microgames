extends Node2D

func _draw():
	# Goomba mushroom enemy
	
	# Body/Stalk (Beige)
	draw_rect(Rect2(4, 16, 24, 16), Color(0.9, 0.75, 0.5))
	
	# Mushroom cap (Brown)
	draw_rect(Rect2(0, 0, 32, 18), Color(0.67, 0.33, 0.0))
	
	# Cap highlight (lighter brown)
	draw_circle(Vector2(10, 6), 6, Color(0.8, 0.5, 0.2))
	
	# Eyes (White background)
	draw_rect(Rect2(6, 8, 8, 6), Color(1, 1, 1))  # Left eye white
	draw_rect(Rect2(18, 8, 8, 6), Color(1, 1, 1)) # Right eye white
	
	# Pupils (Black)
	draw_rect(Rect2(8, 10, 4, 3), Color(0, 0, 0))  # Left pupil
	draw_rect(Rect2(20, 10, 4, 3), Color(0, 0, 0)) # Right pupil
	
	# Angry eyebrows
	draw_line(Vector2(6, 7), Vector2(12, 9), Color(0, 0, 0), 2)  # Left brow
	draw_line(Vector2(20, 9), Vector2(26, 7), Color(0, 0, 0), 2) # Right brow
	
	# Fangs (White)
	draw_polygon([Vector2(10, 14), Vector2(12, 18), Vector2(14, 14)], [Color(1, 1, 1)])  # Left fang
	draw_polygon([Vector2(18, 14), Vector2(20, 18), Vector2(22, 14)], [Color(1, 1, 1)]) # Right fang
	
	# Feet (Dark brown)
	draw_rect(Rect2(2, 28, 10, 4), Color(0.4, 0.2, 0))  # Left foot
	draw_rect(Rect2(20, 28, 10, 4), Color(0.4, 0.2, 0)) # Right foot
