extends AnimatedSprite2D

func _ready():
	z_index = 100
	z_as_relative = false 
	
	# Changed "default" to "new_animation" to match your SpriteFrames!
	sprite_frames.set_animation_loop("new_animation", false)
	animation_finished.connect(_on_anim_finished)
	
	frame = 0
	# Changed "default" to "new_animation"!
	play("new_animation")

func _on_anim_finished():
	queue_free()
