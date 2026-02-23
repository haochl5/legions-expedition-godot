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
	
	# Set rotation so the mob faces the player
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
	
	# Set velocity
	velocity = direction * speed
