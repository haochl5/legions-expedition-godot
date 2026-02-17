class_name Projectile
extends Area2D

# 1. Change CONSTANTS to EXPORT VARS so we can edit them in Inspector
@export var speed: float = 800.0
@export var damage: int = 10
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

func _ready():
	# We remove the velocity calculation here to avoid bugs if
	# direction is set AFTER add_child()
	
	# Connect signal if not already connected via Editor
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Calculate movement dynamically (safer)
	position += direction * speed * delta
	
	# Lifetime countdown
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
