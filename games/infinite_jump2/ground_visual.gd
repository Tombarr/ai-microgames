extends Node2D

func _draw():
	# Draw ground surface (centered at parent position)
	draw_rect(Rect2(-320, -60, 640, 120), Color(0.78, 0.3, 0.05))  # Brown ground
	
	# Draw grass on top
	draw_rect(Rect2(-320, -60, 640, 8), Color(0.2, 0.7, 0.2))  # Green grass
	
	# Add some texture - dirt lines
	for i in range(8):
		var y = -40 + (i * 12)
		draw_line(Vector2(-320, y), Vector2(320, y), Color(0.6, 0.2, 0.03), 2)
