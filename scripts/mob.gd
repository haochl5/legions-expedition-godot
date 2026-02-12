extends RigidBody2D

var target: Node2D

# HP point
const MAX_HP = 30
var hp = MAX_HP

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
	var velocity = 150.0
	linear_velocity = direction * velocity

func take_damage(damage: int):
	hp -= damage
	hp = max(hp, 0)
	
	if hp <= 0:
		die()
	
	flash_red()

func die():
	queue_free()
	
func flash_red():
	var sprite = $AnimatedSprite2D
	sprite.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
