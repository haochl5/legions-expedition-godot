extends Marker2D

@onready var label = $Label

func setup(damage_amount: int):
	# Set the text
	label.text = str(damage_amount)
	
	# Randomize the float direction slightly so multiple numbers don't overlap perfectly
	var x_offset = randf_range(-30.0, 30.0)
	var target_position = position + Vector2(x_offset, -60.0) # Floats up and to the side
	
	# Animate using a Tween
	var tween = create_tween().set_parallel(true)
	
	# 1. Pop the scale up briefly
	scale = Vector2(0.5, 0.5)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1)
	
	# 2. Float up
	tween.tween_property(self, "position", target_position, 0.6).set_ease(Tween.EASE_OUT)
	
	# 3. Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.3)
	
	# 4. Delete itself when the tween chain finishes
	tween.chain().tween_callback(queue_free)
