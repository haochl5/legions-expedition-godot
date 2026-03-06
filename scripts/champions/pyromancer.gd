extends Unit

const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Lion/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Lion/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Lion/SeparateAnim/Attack.png")
const FIRE_ZONE = preload("res://scenes/FX/fire_zone.tscn")

var attack_counter = 0

func _ready():
	super()
	tex_idle = R_IDLE; tex_walk = R_WALK; tex_attack = R_ATTACK
	$Sprite2D.texture = tex_idle
	
	is_melee = false
	aggro_range = 250.0
	base_attack_cooldown = 1.5

func attack():
	is_attacking = true
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1 
	$Sprite2D.frame = facing_dir
	
	await get_tree().create_timer(0.3 * attack_speed_modifier).timeout 
	
	if target and is_instance_valid(target):
		var fire_offsets = [Vector2.ZERO, Vector2(25, 0), Vector2(-25, 0), Vector2(0, 25), Vector2(0, -25)]
		for offset in fire_offsets:
			var fire = FIRE_ZONE.instantiate()
			fire.set("damage_multiplier", damage_multiplier)
			fire.scale = Vector2(damage_multiplier, damage_multiplier)
			get_parent().add_child(fire)
			fire.global_position = target.global_position + offset
		
	await get_tree().create_timer(1.2 * attack_speed_modifier).timeout 
	is_attacking = false
