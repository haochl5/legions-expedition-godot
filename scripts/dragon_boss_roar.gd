extends Area2D

signal roar_finished

@export var expand_speed: float = 900.0
@export var max_radius: float = 5000.0
@export var ring_thickness: float = 80.0

# 这个值很重要：
# 它表示你那张“原始声波贴图”在 scale = (1,1) 时，
# 从中心到圆环边缘大概是多少像素。
# 你需要按你的素材微调它。
@export var base_visual_radius: float = 64.0

# 玩家受到的伤害
@export var player_damage: int = 0

# 对 mob 用的大伤害值
@export var mob_damage: int = 999999

# 分组名可改
@export var mob_group_name: String = "mobs"
@export var player_group_name: String = "commander"

# 是否在扩散时同步放大 CircleShape2D（主要用于调试观察）
@export var update_collision_shape_radius: bool = true

var current_radius: float = 0.0
var _already_hit: Dictionary = {}
var _started: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	current_radius = 0.0
	scale = Vector2.ZERO

	if animated_sprite:
		animated_sprite.play()

	# 初始把碰撞圆也设小一点（虽然我们不用它做真正判定）
	_update_collision_debug_radius()

	_started = true


func _physics_process(delta: float) -> void:
	if not _started:
		return

	current_radius += expand_speed * delta

	_update_visual_scale()
	_update_collision_debug_radius()
	_check_targets_in_ring()

	if current_radius >= max_radius:
		_finish_roar()


func _update_visual_scale() -> void:
	if base_visual_radius <= 0.0:
		return

	var ratio := current_radius / base_visual_radius
	scale = Vector2(ratio, ratio)


func _update_collision_debug_radius() -> void:
	if not update_collision_shape_radius:
		return

	if collision_shape == null:
		return

	if collision_shape.shape is CircleShape2D:
		var circle := collision_shape.shape as CircleShape2D
		circle.radius = current_radius


func _check_targets_in_ring() -> void:
	# 1) 清 mob
	var mobs := get_tree().get_nodes_in_group(mob_group_name)
	for mob in mobs:
		_try_hit_mob(mob)

	# 2) 打 player / commander
	var players := get_tree().get_nodes_in_group(player_group_name)
	for player in players:
		_try_hit_player(player)


func _try_hit_mob(mob: Node) -> void:
	if mob == null or not is_instance_valid(mob):
		return

	if mob == self:
		return

	# 不要误伤生成这个 roar 的 boss 本体
	if get_parent() == mob:
		return

	if _already_hit.has(mob):
		return

	if not (mob is Node2D):
		return

	var target_pos := (mob as Node2D).global_position
	if not _is_position_inside_ring(target_pos):
		return

	_already_hit[mob] = true

	# 优先调用现有逻辑
	if mob.has_method("take_damage"):
		mob.call("take_damage", mob_damage)
	elif mob.has_method("die"):
		mob.call("die")
	else:
		mob.queue_free()


func _try_hit_player(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return

	if _already_hit.has(player):
		return

	if not (player is Node2D):
		return

	var target_pos := (player as Node2D).global_position
	if not _is_position_inside_ring(target_pos):
		return

	_already_hit[player] = true

	if player.has_method("take_damage"):
		player.call("take_damage", player_damage)
	elif player.has_method("hurt"):
		player.call("hurt", player_damage)
	# 如果你的 commander 用的是别的受伤函数名，
	# 到这里改成你自己的方法名即可。


func _is_position_inside_ring(target_global_pos: Vector2) -> bool:
	var dist := global_position.distance_to(target_global_pos)
	return dist >= (current_radius - ring_thickness) and dist <= current_radius


func _finish_roar() -> void:
	emit_signal("roar_finished")
	queue_free()
