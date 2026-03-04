extends Area2D

@export var damage: int = 1
@export var attacker_name: String = "Bamboo Boss"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# Prevent multi-hit on the same target
var _damaged: Dictionary = {}  # instance_id -> true


func _ready() -> void:
	# Play grow animation
	if sprite:
		sprite.play("grow")
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)

	# IMPORTANT:
	# - body_entered is for PhysicsBody2D (e.g., Champion / Unit if it's a body)
	# - area_entered is for Area2D (e.g., Commander is an Area2D)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)


func _on_body_entered(body: Node) -> void:
	_try_damage_target(body)


func _on_area_entered(area: Area2D) -> void:
	_try_damage_target(area)


func _try_damage_target(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return

	# Don't damage enemies/mobs (optional safety)
	# Adjust group names if your project uses different ones.
	if target.is_in_group("enemy") or target.is_in_group("mobs"):
		return

	# Dedup per target
	var id := target.get_instance_id()
	if _damaged.has(id):
		return
	_damaged[id] = true

	# 1) Champion: base class Unit -> Unit.take_damage(amount:int)
	if target is Unit:
		target.take_damage(damage)
		return

	# 2) Commander: Commander.take_damage(damage:int, attacker_name:String="Unknown")
	if target.has_method("take_damage"):
		var argc := _get_take_damage_argc(target)
		if argc >= 2:
			target.call("take_damage", damage, attacker_name)
		else:
			target.call("take_damage", damage)


func _get_take_damage_argc(obj: Object) -> int:
	# Reflection to avoid signature mismatch (Unit has 1 arg, Commander has 2 args)
	for m in obj.get_method_list():
		if m.has("name") and m["name"] == "take_damage":
			if m.has("args"):
				return m["args"].size()
			return 0
	return 0


func _on_animation_finished() -> void:
	# After grow finishes, keep it briefly, then vanish
	if sprite and sprite.animation == "grow":
		_start_disappearing_sequence()


func _start_disappearing_sequence() -> void:
	# Keep spike alive a little to allow collision/hits
	await get_tree().create_timer(1.0).timeout

	# Disable collision while vanishing
	if collision:
		collision.set_deferred("disabled", true)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

	tween.chain().tween_callback(queue_free)
