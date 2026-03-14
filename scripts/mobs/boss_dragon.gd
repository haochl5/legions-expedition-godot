extends CharacterBody2D

class_name BossDragon

enum State {
	IDLE,
	CHASE,
	HIT,
	DYING
}

# =========================
# Basic stats
# =========================
@export var mob_name: String = "Boss Dragon"
@export var max_hp: int = 500
@export var speed: float = 60.0
@export var damage: int = 1

# =========================
# Target / movement
# =========================
@export var aggro_distance: float = 2000.0
@export var keep_distance: float = 140.0

# =========================
# Visual animation tuning
# =========================
@export var bob_amplitude: float = 6.0
@export var bob_speed: float = 2.0

@export var wing_flap_degrees: float = 18.0
@export var wing_flap_speed: float = 7.0

@export var head_sway_degrees: float = 6.0
@export var body_sway_degrees: float = 4.0
@export var sway_speed: float = 3.0
@export var body_segment_delay: float = 0.35

# =========================
# Drop logic (copied from mob_base.gd)
# =========================
@export var coin_scene: PackedScene
@export var gold_drop_count: int = 3
@export var gold_drop_value: int = 10
@export var drop_spread_radius: float = 30.0
@export var coin_drop_chance: float = 0.3

@export var exp_scene: PackedScene
@export var exp_drop_count: int = 3
@export var exp_drop_value: int = 5
@export var exp_drop_spread_radius: float = 30.0

# =========================
# Runtime
# =========================
var hp: int
var target: Node2D = null
var current_state: State = State.IDLE

var _time: float = 0.0
var _is_dead: bool = false
var _hit_recovering: bool = false

# =========================
# Node references
# =========================
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var head_node: Node2D = $head_node
@onready var body1_node: Node2D = $body1_node
@onready var body2_node: Node2D = $body2_node
@onready var tail_node: Node2D = $tail_node
@onready var left_wing_node: Node2D = $left_wing_node
@onready var right_wing_node: Node2D = $right_wing_node

@onready var head: Sprite2D = $head_node/head
@onready var body1: Sprite2D = $body1_node/body1
@onready var body2: Sprite2D = $body2_node/body2
@onready var tail: Sprite2D = $tail_node/tail
@onready var left_wing: Sprite2D = $left_wing_node/left_wing
@onready var right_wing: Sprite2D = $right_wing_node/right_wing

# Optional collision nodes:
# You said you'll use one vertical strip and one horizontal strip.
# These are optional-safe, so the script won't crash if names are missing.
@onready var collision_vertical: CollisionShape2D = get_node_or_null("CollisionVertical")
@onready var collision_horizontal: CollisionShape2D = get_node_or_null("CollisionHorizontal")

# Optional notifier
@onready var screen_notifier: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D")

var _all_parts: Array[CanvasItem] = []

# Base transforms for procedural animation
var _head_base_pos: Vector2
var _body1_base_pos: Vector2
var _body2_base_pos: Vector2
var _tail_base_pos: Vector2
var _left_wing_base_pos: Vector2
var _right_wing_base_pos: Vector2

var _head_base_rot: float
var _body1_base_rot: float
var _body2_base_rot: float
var _tail_base_rot: float
var _left_wing_base_rot: float
var _right_wing_base_rot: float


func _ready() -> void:
	hp = max_hp

	_head_base_pos = head_node.position
	_body1_base_pos = body1_node.position
	_body2_base_pos = body2_node.position
	_tail_base_pos = tail_node.position
	_left_wing_base_pos = left_wing_node.position
	_right_wing_base_pos = right_wing_node.position

	_head_base_rot = head_node.rotation
	_body1_base_rot = body1_node.rotation
	_body2_base_rot = body2_node.rotation
	_tail_base_rot = tail_node.rotation
	_left_wing_base_rot = left_wing_node.rotation
	_right_wing_base_rot = right_wing_node.rotation

	_all_parts = [
		head,
		body1,
		body2,
		tail,
		left_wing,
		right_wing
	]

	if screen_notifier:
		screen_notifier.screen_exited.connect(_on_screen_exited)

	current_state = State.CHASE


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_time += delta

	_update_state()
	_update_movement()
	_update_visual_animation()

	move_and_slide()


# =========================
# State / movement
# =========================
func _update_state() -> void:
	if current_state == State.DYING:
		velocity = Vector2.ZERO
		return

	if _hit_recovering:
		current_state = State.HIT
		velocity = Vector2.ZERO
		return

	if target == null or not is_instance_valid(target):
		current_state = State.IDLE
		return

	var dist := global_position.distance_to(target.global_position)
	if dist <= aggro_distance:
		current_state = State.CHASE
	else:
		current_state = State.IDLE


func _update_movement() -> void:
	match current_state:
		State.DYING, State.HIT:
			velocity = Vector2.ZERO

		State.IDLE:
			velocity = Vector2.ZERO

		State.CHASE:
			if target == null or not is_instance_valid(target):
				velocity = Vector2.ZERO
				return

			var to_target := target.global_position - global_position
			var dist := to_target.length()

			if dist > keep_distance:
				velocity = to_target.normalized() * speed
			else:
				velocity = Vector2.ZERO


# =========================
# Visual animation
# =========================
func _update_visual_animation() -> void:
	var bob := sin(_time * bob_speed) * bob_amplitude

	head_node.position = _head_base_pos + Vector2(0, bob)
	body1_node.position = _body1_base_pos + Vector2(0, bob * 0.85)
	body2_node.position = _body2_base_pos + Vector2(0, bob * 0.65)
	tail_node.position = _tail_base_pos + Vector2(0, bob * 0.45)

	head_node.rotation = _head_base_rot + deg_to_rad(sin(_time * sway_speed) * head_sway_degrees)
	body1_node.rotation = _body1_base_rot + deg_to_rad(sin(_time * sway_speed - body_segment_delay) * body_sway_degrees)
	body2_node.rotation = _body2_base_rot + deg_to_rad(sin(_time * sway_speed - body_segment_delay * 2.0) * body_sway_degrees)
	tail_node.rotation = _tail_base_rot + deg_to_rad(sin(_time * sway_speed - body_segment_delay * 3.0) * body_sway_degrees * 1.2)

	var flap := deg_to_rad(sin(_time * wing_flap_speed) * wing_flap_degrees)
	left_wing_node.rotation = _left_wing_base_rot - flap
	right_wing_node.rotation = _right_wing_base_rot + flap

	if target and is_instance_valid(target) and current_state != State.DYING:
		var dir_x := target.global_position.x - global_position.x
		head_node.rotation += deg_to_rad(clamp(dir_x * 0.03, -8.0, 8.0))


# =========================
# Damage / death
# =========================
func take_damage(damage_amount: int) -> void:
	if _is_dead:
		return

	hp -= damage_amount
	hp = max(hp, 0)

	if hp <= 0:
		die()
		return

	flash_red()


func flash_red() -> void:
	if _is_dead or current_state == State.DYING:
		return

	_hit_recovering = true
	current_state = State.HIT
	velocity = Vector2.ZERO

	for part in _all_parts:
		if part:
			part.modulate = Color.RED

	var tween := create_tween()
	for part in _all_parts:
		if part:
			tween.parallel().tween_property(part, "modulate", Color.WHITE, 0.12)

	tween.finished.connect(func():
		if not _is_dead:
			_hit_recovering = false
			current_state = State.CHASE
	)

	var hit_tween := create_tween()
	hit_tween.tween_property(self, "scale", Vector2(1.06, 0.94), 0.05)
	hit_tween.tween_property(self, "scale", Vector2.ONE, 0.07)


func die() -> void:
	if _is_dead:
		return

	_is_dead = true
	current_state = State.DYING
	velocity = Vector2.ZERO

	if collision_vertical:
		collision_vertical.set_deferred("disabled", true)

	if collision_horizontal:
		collision_horizontal.set_deferred("disabled", true)

	var death_tween := create_tween().set_parallel(true)

	for part in _all_parts:
		if part:
			death_tween.tween_property(part, "modulate:a", 0.0, 0.8)

	death_tween.tween_property(self, "scale", Vector2(0.15, 0.15), 0.8)
	death_tween.tween_property(self, "rotation", rotation + deg_to_rad(90.0), 0.8)

	if audio_player:
		audio_player.play()

	death_tween.chain().tween_callback(func():
		drop_items()
		queue_free()
	)


# =========================
# Drops
# =========================
func drop_items() -> void:
	drop_gold()
	drop_exp()


func drop_exp() -> void:
	if not exp_scene:
		return

	for i in range(exp_drop_count):
		var exp_instance = exp_scene.instantiate()

		var random_offset := Vector2(
			randf_range(-exp_drop_spread_radius, exp_drop_spread_radius),
			randf_range(-exp_drop_spread_radius, exp_drop_spread_radius)
		)

		exp_instance.global_position = global_position + random_offset

		if "exp_value" in exp_instance:
			exp_instance.exp_value = exp_drop_value

		get_parent().call_deferred("add_child", exp_instance)


func drop_gold() -> void:
	if not coin_scene:
		return

	var final_drop_chance := coin_drop_chance
	if Engine.has_singleton("GameData"):
		final_drop_chance *= GameData.gold_drop_chance

	if randf() > final_drop_chance:
		return

	for i in range(gold_drop_count):
		var coin = coin_scene.instantiate()

		var random_offset := Vector2(
			randf_range(-drop_spread_radius, drop_spread_radius),
			randf_range(-drop_spread_radius, drop_spread_radius)
		)

		coin.global_position = global_position + random_offset

		if "gold_value" in coin:
			coin.gold_value = gold_drop_value

		get_parent().call_deferred("add_child", coin)


# =========================
# Utility
# =========================
func _on_screen_exited() -> void:
	# Keep boss alive even if it leaves the screen.
	pass
