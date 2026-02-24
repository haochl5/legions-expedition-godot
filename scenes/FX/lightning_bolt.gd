extends Area2D # Keeping Area2D so you don't have to rebuild the node tree!

func _ready():
	$AnimatedSprite2D.play("default")
	
	# Keep it alive just long enough for the animation to finish
	# Adjust this 0.4 up or down depending on how fast your animation plays!
	await get_tree().create_timer(0.4).timeout
	queue_free()
