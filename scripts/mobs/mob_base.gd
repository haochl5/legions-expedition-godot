# scripts/mob_base.gd
class_name MobBase
extends RigidBody2D

# general attributes
@export var max_hp: int = 30
@export var speed: float = 150.0
@export var damage: int = 10

var hp: int
var target: Node2D

# reference to nodes
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready():
	hp = max_hp
	
	if screen_notifier:
		screen_notifier.screen_exited.connect(_on_screen_exited)
	
	
	body_entered.connect(_on_body_entered)
	
	setup_animation()
	setup_behavior()
	
	
func setup_animation():
	pass
	
func setup_behavior():
	pass
	
func movement_pattern(delta: float):
	pass
	
func attack_pattern(target_node: Node2D):
	pass
func _physics_process(delta):
	movement_pattern(delta)
	
func _on_screen_exited():
	queue_free()
	
func take_damage(damage_amount: int):
	hp -= damage_amount
	hp = max(hp, 0)
	
	if hp <= 0:
		die()
		
	flash_red()
	
func die():
	queue_free()
	
func flash_red():
	sprite.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_body_entered(body):
	pass
