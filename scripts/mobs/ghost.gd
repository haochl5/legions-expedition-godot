# scripts/ghost.gd
class_name GhostMob
extends MobBase


func setup_animation():
	sprite.play("movement")

func setup_behavior():
	speed = 100
	damage = 1

func movement_pattern(delta: float):
	if target == null:
		return
	
	# Check the distance to the Commander
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# Only move if further away than the attack radius (e.g., 40 pixels)
	if distance_to_target > 5:
		# Direction toward the Player
		var direction = (target.global_position - global_position).normalized()
		
		# Set rotation so the mob faces the player
		rotation = direction.angle()
		
		# Set velocity
		velocity = direction * speed
	else:
		# We reached the Commander, stop pushing!
		velocity = Vector2.ZERO
