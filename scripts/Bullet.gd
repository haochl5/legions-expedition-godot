extends Area2D

# constants
const SPEED = 800.0           # speed (px/s)
const LIFETIME = 3.0          # the existence time
const DAMAGE = 10             # damage
const SIZE = 8.0              # bullet size

# runtime variables
var direction: Vector2 = Vector2.RIGHT  # shooting direction, set when generated
var velocity: Vector2 = Vector2.ZERO
var lifetime_timer: float = 0.0

func _ready():
	# velocity vector
	velocity = direction.normalized() * SPEED
	lifetime_timer = LIFETIME
	
	# connet signal
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# fix direction
	position += velocity * delta
	
	# lifetime countdown
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		queue_free()  # delete this bullet

func _on_body_entered(body):
	# collision logic
	if body.is_in_group("enemy"):
		# TODO: damage enemy
		queue_free()  # delete bullet after hurting enemy(maybe want to change this logic)
