extends Unit

const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Special1.png")
const PROJECTILE_SCENE = preload("res://scenes/Projectiles/magic_orb.tscn")

var attack_counter: int = 0

func _ready():
	tex_idle = R_IDLE; tex_walk = R_WALK; tex_attack = R_ATTACK; tex_special = R_SPECIAL
	$Sprite2D.texture = tex_idle
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	
	is_melee = false
	aggro_range = 250.0
	base_attack_cooldown = 0.8

func attack():
	is_attacking = true
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1 
	$Sprite2D.frame = facing_dir
	
	await get_tree().create_timer(0.3 * attack_speed_modifier).timeout
	
	attack_counter += 1
	var is_special_turn = false
	if attack_counter >= 3:
		attack_counter = 0
		is_special_turn = true
		
	fire_orb(is_special_turn)
	
	await get_tree().create_timer(0.5 * attack_speed_modifier).timeout
	is_attacking = false

func fire_orb(is_special: bool):
	if not PROJECTILE_SCENE: return
	var orb = PROJECTILE_SCENE.instantiate()
	orb.set("damage_multiplier", damage_multiplier)
	get_parent().add_child(orb)
	orb.global_position = global_position
	
	var dir = Vector2.RIGHT
	if target and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	
	orb.direction = dir
	orb.rotation = dir.angle()
	
	if is_special:
		orb.set("is_explosive", true)
		orb.modulate = Color(1, 0.2, 0.2) 
		orb.scale = Vector2(1.5 * damage_multiplier, 1.5 * damage_multiplier)
		orb.set("speed", 400) 
	else:
		orb.scale = Vector2(damage_multiplier, damage_multiplier)
