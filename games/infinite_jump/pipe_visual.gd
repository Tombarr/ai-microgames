extends Node2D

func _draw():
	# Pipe dimensions - shorter to be jumpable (80 total height)
	var stem_width = 48
	var stem_height = 60  # Reduced from 140
	var rim_height = 20
	var rim_width = 56

	# Main stem (Green)
	var stem_color = Color(0.0, 0.72, 0.0)
	draw_rect(Rect2(0, rim_height, stem_width, stem_height), stem_color)

	# Highlight (left side - lighter green)
	var highlight_color = Color(0.2, 0.85, 0.2)
	draw_rect(Rect2(4, rim_height, 8, stem_height), highlight_color)

	# Shadow (right side - darker green)
	var shadow_color = Color(0.0, 0.5, 0.0)
	draw_rect(Rect2(stem_width - 10, rim_height, 8, stem_height), shadow_color)

	# Top rim (Lighter green, wider)
	var rim_color = Color(0.0, 0.85, 0.0)
	draw_rect(Rect2(-4, 0, rim_width, rim_height), rim_color)

	# Rim highlight
	draw_rect(Rect2(0, 0, rim_width - 8, 6), Color(0.3, 0.95, 0.3))

	# Rim shadow (bottom edge)
	draw_rect(Rect2(-4, rim_height - 4, rim_width, 4), Color(0.0, 0.6, 0.0))
