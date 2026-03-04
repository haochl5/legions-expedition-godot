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

var damage_multiplier: float = 1.0

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
	if body.is_in_group("enemy"):
		if is_explosive:
			explode()
			call_deferred("queue_free") 
			return 
			
		if body.has_method("take_damage"):
			# --- THE FIX: Apply multiplier to the standard hit ---
			body.take_damage(int(damage * damage_multiplier))
			
	call_deferred("queue_free")

func explode():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2, 2), 0.1) 
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= explosion_radius:
			if enemy.has_method("take_damage"):
				# --- THE FIX: Apply multiplier to the explosion! ---
				enemy.take_damage(int(damage * 1.5 * damage_multiplier))
