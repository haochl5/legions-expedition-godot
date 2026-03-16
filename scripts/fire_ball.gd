extends Area2D

@export var speed: float = 100.0
@export var damage: int = 1
@export var attacker_name: String = "Flamethrower"
@export var lifetime: float = 2.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var direction: Vector2 = Vector2.ZERO
var _damaged: Dictionary = {} 

func _ready() -> void:
	# Start the projectile's internal 'fire' animation
	if sprite and sprite.sprite_frames.has_animation("fire"):
		sprite.play("fire")
	
	# Cleanup timer to prevent memory leaks
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	# Setup collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
		# Face the direction of travel
		rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	_try_damage_target(body)

func _on_area_entered(area: Area2D) -> void:
	_try_damage_target(area)

func _try_damage_target(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return

	# Ignore friendly fire
	if target.is_in_group("enemy") or target.is_in_group("mobs"):
		return

	# Only damage each target once per projectile
	var id := target.get_instance_id()
	if _damaged.has(id):
		return
	_damaged[id] = true

	# Robust damage handling (Bamboo Boss Style)
	if target.has_method("take_damage"):
		var argc := _get_take_damage_argc(target)
		if argc >= 2:
			target.call("take_damage", damage, attacker_name)
		else:
			target.call("take_damage", damage)
		
		# Projectile disappears on impact
		queue_free()

func _get_take_damage_argc(obj: Object) -> int:
	for m in obj.get_method_list():
		if m["name"] == "take_damage":
			return m["args"].size()
	return 0
