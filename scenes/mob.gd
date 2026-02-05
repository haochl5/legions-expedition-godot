extends RigidBody2D

var target: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimatedSprite2D.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Direction toward the Player
	var direction = (target.global_position - global_position).normalized()
		
	# Set rotation so the mob faces the player
	rotation = direction.angle()
	# Set velocity
	var velocity = randf_range(150.0, 250.0)
	linear_velocity = direction * velocity
