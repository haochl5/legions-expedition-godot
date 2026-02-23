# scripts/ghost.gd
class_name GhostMob
extends MobBase


func setup_animation():
	sprite.play("movement")

func setup_behavior():
	speed = 80
	# TODO: set damage to mobs, not 1 dmg for every hit
	damage = 1

func movement_pattern(delta: float):
	if target == null:
		return
	
	# Direction toward the Player
	var direction = (target.global_position - global_position).normalized()
	
	# Set rotation so the mob faces the player
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
	
	# Set velocity
	linear_velocity = direction * speed
