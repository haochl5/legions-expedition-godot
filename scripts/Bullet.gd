class_name Projectile
extends Area2D

# 1. CONSTANTS -> EXPORTS
@export var speed: float = 800.0
@export var damage: int = 10
@export var lifetime: float = 3.0

# 2. NEW: Explosion Stats (Disabled by default)
@export var is_explosive: bool = false
@export var explosion_radius: float = 120.0

var direction: Vector2 = Vector2.RIGHT

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		# CASE A: EXPLOSION (Sorcerer Special)
		if is_explosive:
			explode()
			queue_free()
			return # Stop here so we don't hit the single target twice
			
		# CASE B: STANDARD HIT (Ranger/Normal Sorcerer)
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
		queue_free()

func explode():
	# 1. Visual Feedback (Scale up and fade out)
	# We create a simple visual effect using the projectile's own sprite
	# (In a real game, you would spawn an Explosion.tscn particle effect here)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(4, 4), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	
	# 2. Area Damage Logic
	# We manually find all enemies in range because the Area2D is already being deleted
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= explosion_radius:
			if enemy.has_method("take_damage"):
				# Explosions deal 50% extra damage!
				enemy.take_damage(int(damage * 1.5))
