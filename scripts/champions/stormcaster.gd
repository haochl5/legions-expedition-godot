extends Unit

const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Tengu2/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Tengu2/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Tengu2/SeparateAnim/Attack.png")
const LIGHTNING_BOLT = preload("res://scenes/FX/lightning_bolt.tscn")

func _ready():
	super()
	tex_idle = R_IDLE; tex_walk = R_WALK; tex_attack = R_ATTACK
	$Sprite2D.texture = tex_idle
	
	is_melee = false
	aggro_range = 300.0
	base_attack_cooldown = 1.0

func attack():
	is_attacking = true
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir
	
	await get_tree().create_timer(0.2 * attack_speed_modifier).timeout 
	
	if target and is_instance_valid(target):
		target.take_damage(int(25 * damage_multiplier))
		var bolt = LIGHTNING_BOLT.instantiate()
		get_parent().add_child(bolt)
		bolt.global_position = target.global_position
		
	await get_tree().create_timer(0.8 * attack_speed_modifier).timeout 
	is_attacking = false
