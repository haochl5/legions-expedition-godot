extends Area2D

class_name DragonWaterAttack

@export var target_offset: Vector2 = Vector2(0, 10)
@export var damage: int = 1
@export var player_group_name: String = "commander"

var target: Node2D = null
var locked_position: Vector2 = Vector2.ZERO
var has_damaged_player: bool = false
var attack_active: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if collision_shape:
		collision_shape.disabled = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if target == null:
		var players := get_tree().get_nodes_in_group(player_group_name)
		if players.size() > 0 and players[0] is Node2D:
			target = players[0]

	if target == null or not is_instance_valid(target):
		queue_free()
		return

	locked_position = target.global_position + target_offset
	global_position = locked_position

	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

	animation_player.play("prepare_phase")


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "prepare_phase":
		_start_attack_phase()
	elif anim_name == "attack_phase":
		queue_free()


func _start_attack_phase() -> void:
	attack_active = true
	has_damaged_player = false

	if collision_shape:
		collision_shape.disabled = false

	animation_player.play("attack_phase")


func _on_body_entered(body: Node) -> void:
	if not attack_active:
		return

	if has_damaged_player:
		return

	if body == null or not is_instance_valid(body):
		return

	# 只打 player
	if not body.is_in_group(player_group_name):
		return

	has_damaged_player = true

	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	elif body.has_method("hurt"):
		body.call("hurt", damage)

	_disable_attack_hitbox()


func _on_area_entered(area: Area2D) -> void:
	if not attack_active:
		return

	if has_damaged_player:
		return

	if area == null or not is_instance_valid(area):
		return

	if not area.is_in_group(player_group_name):
		return

	has_damaged_player = true

	if area.has_method("take_damage"):
		area.call("take_damage", damage)
	elif area.has_method("hurt"):
		area.call("hurt", damage)

	_disable_attack_hitbox()


func _disable_attack_hitbox() -> void:
	attack_active = false
	if collision_shape:
		collision_shape.disabled = true
