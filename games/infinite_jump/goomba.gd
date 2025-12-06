extends Area2D

func _ready():
	# Trigger visual redraw
	if has_node("Visual"):
		$Visual.queue_redraw()
