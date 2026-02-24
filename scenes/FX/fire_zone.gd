extends Area2D

var dps: int = 20 # Damage per second
var enemies_inside: Array = []

func _ready():
	$AnimatedSprite2D.play("default")
	# Fire burns for 4 seconds before disappearing
	await get_tree().create_timer(4.0).timeout
	queue_free()

func _physics_process(delta):
	# Damage everything standing in the fire every frame!
	for enemy in enemies_inside:
		if is_instance_valid(enemy):
			# delta ensures damage scales smoothly with frame rate
			enemy.take_damage(dps * delta) 

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		enemies_inside.append(body)

func _on_body_exited(body):
	if body in enemies_inside:
		enemies_inside.erase(body)
