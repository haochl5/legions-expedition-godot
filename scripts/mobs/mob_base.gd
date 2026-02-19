# scripts/mob_base.gd
class_name MobBase
extends RigidBody2D

# general attributes
@export var max_hp: int = 30
@export var speed: float = 150.0
@export var damage: int = 10

# gold logic
@export var coin_scene: PackedScene
@export var gold_drop_count: int = 3  
@export var gold_drop_value: int = 10  
@export var drop_spread_radius: float = 30.0 

# exp logic
@export var exp_scene: PackedScene
@export var exp_drop_count: int = 3
@export var exp_drop_value: int = 5
@export var exp_drop_spread_radius: float = 30.0

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
	# Mob should keep following the player outside the screen
	pass
	
func take_damage(damage_amount: int):
	hp -= damage_amount
	hp = max(hp, 0)
	
	if hp <= 0:
		die()
		
	flash_red()
	
func die():
	call_deferred("drop_items")
	queue_free()
	
func flash_red():
	sprite.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func drop_items():
	drop_gold()
	drop_exp()

func drop_exp():
	if not exp_scene:
		return
	
	for i in range(exp_drop_count):
		var exp_instance = exp_scene.instantiate()
		
		var random_offset = Vector2(
			randf_range(-exp_drop_spread_radius, exp_drop_spread_radius),
			randf_range(-exp_drop_spread_radius, exp_drop_spread_radius)
		)
		
		exp_instance.global_position = global_position + random_offset
		
		# Pass the specific value each gem is worth
		exp_instance.exp_value = exp_drop_value
		
		get_parent().add_child(exp_instance)
	
func drop_gold():
	if not coin_scene:
		return
	
	for i in range(gold_drop_count):
		var coin = coin_scene.instantiate()
		
		var random_offset = Vector2(
			randf_range(-drop_spread_radius, drop_spread_radius),
			randf_range(-drop_spread_radius, drop_spread_radius)
		)
		
		coin.global_position = global_position + random_offset
		coin.gold_value = gold_drop_value
		
		get_parent().add_child(coin)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_body_entered(body):
	pass
