extends Unit

const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Special1.png")

var attack_range = 40.0 
var damage = 15
var attack_counter: int = 0
var special_trigger: int = 4 

func _ready():
	super()
	tex_idle = R_IDLE; tex_walk = R_WALK; tex_attack = R_ATTACK; tex_special = R_SPECIAL
	$Sprite2D.texture = tex_idle
	
	is_melee = true
	aggro_range = 150.0
	base_attack_cooldown = 0.8

func attack():
	is_attacking = true
	attack_counter += 1
	
	if attack_counter >= special_trigger:
		attack_counter = 0
		perform_whirlwind()
	else:
		perform_normal_attack()

func perform_normal_attack():
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir
	
	await get_tree().create_timer(0.3 * attack_speed_modifier).timeout
	
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_range + 20: 
			target.take_damage(int(damage * damage_multiplier))
	
	await get_tree().create_timer(0.5 * attack_speed_modifier).timeout
	is_attacking = false

func perform_whirlwind():
	# --- THE FIX ---
	$AnimationPlayer.stop() # 1. Stop the walking animation
	$Sprite2D.texture = tex_special
	$Sprite2D.frame = 0     # 2. Reset the frame to 0 BEFORE changing hframes
	# ---------------
	
	$Sprite2D.hframes = 1 
	$Sprite2D.vframes = 1 
	
	var tween = create_tween()
	tween.tween_property($Sprite2D, "rotation_degrees", 360.0, 0.4).as_relative()
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= 50:
			enemy.take_damage(damage * damage_multiplier) 
			
	await get_tree().create_timer(0.4).timeout
	$Sprite2D.rotation_degrees = 0 
	is_attacking = false
