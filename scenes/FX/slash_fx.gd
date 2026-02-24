extends AnimatedSprite2D

func _ready():
	z_index = 50 # Render on top
	sprite_frames.set_animation_loop("default", false)
	animation_finished.connect(queue_free)
	frame = 0
	play("default")
