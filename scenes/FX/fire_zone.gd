extends Area2D

var tick_damage: int = 10 # How much damage per burn tick
var tick_rate: float = 0.5 # Apply damage every 0.5 seconds
var time_since_last_tick: float = 0.0

var enemies_inside: Array = []

func _ready():
	$AnimatedSprite2D.play("new_animation") # Or "new_animation" if you kept that name
	await get_tree().create_timer(4.0).timeout
	queue_free()

func _physics_process(delta):
	# 1. Add up the time
	time_since_last_tick += delta
	
	# 2. When half a second passes, burn everything inside!
	if time_since_last_tick >= tick_rate:
		time_since_last_tick = 0.0 # Reset the timer
		
		for enemy in enemies_inside:
			if is_instance_valid(enemy):
				enemy.take_damage(tick_damage)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		enemies_inside.append(body)

func _on_body_exited(body):
	if body in enemies_inside:
		enemies_inside.erase(body)
