# scripts/ghost.gd
class_name GhostMob
extends MobBase


func setup_animation():
	sprite.play("movement")

func setup_behavior():
	speed = 40
	damage = 1

func movement_pattern(delta: float):
	if target == null:
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# 1. CALCULATE THE DIRECTION FIRST!
	var direction = (target.global_position - global_position).normalized()
	
	# 2. Now we can safely use 'direction' to flip the sprite
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
		
	# 3. Apply the velocity (keeping a tiny stopping distance prevents jitter!)
	# 3. Apply the velocity smoothly using lerp!
	if distance_to_target > 5.0:
		var desired_velocity = direction * speed
		velocity = velocity.lerp(desired_velocity, 0.1) # 0.1 is the "turn speed"
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.2)
