class_name Projectile
extends Area2D

# 1. CONSTANTS -> EXPORTS
@export var speed: float = 200
@export var damage: int = 10
@export var lifetime: float = 3.0

# 2. NEW: Explosion Stats (Disabled by default)
@export var is_explosive: bool = false
@export var explosion_radius: float = 50

# Bullet Rotation
@export var rotation_speed: float = 40.0 # Radians per second

var direction: Vector2 = Vector2.RIGHT

func _ready():
	rotation = direction.angle()
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	position += direction * speed * delta
	
	rotation += rotation_speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	# 1. Did we hit an enemy?
	if body.is_in_group("enemy"):
		# CASE A: EXPLOSION (Sorcerer Special)
		if is_explosive:
			explode()
			call_deferred("queue_free") # <--- CHANGED HERE
			return # Stop here so we don't hit the single target twice
			
		# CASE B: STANDARD HIT (Ranger/Normal Sorcerer)
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
	# 2. Destroy the bullet unconditionally!
	# (Because this is pushed back to the left margin, it runs for enemies AND trees)
	call_deferred("queue_free") # <--- CHANGED HERE

func explode():
	# 1. Visual Feedback (Scale up and fade out)
	# We create a simple visual effect using the projectile's own sprite
	# (In a real game, you would spawn an Explosion.tscn particle effect here)
	var tween = create_tween()
	# <--- Lowered scale from (4, 4) down to (2, 2) or (2.5, 2.5)
	tween.tween_property(self, "scale", Vector2(2, 2), 0.1) 
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
