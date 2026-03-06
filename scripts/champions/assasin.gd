extends Unit

const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/RedGladiator/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/RedGladiator/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/RedGladiator/SeparateAnim/Attack.png")
const SLASH_FX = preload("res://scenes/FX/slash_fx.tscn")

var attack_range = 40 
var backstab_damage = 20

func _ready():
	super()
	tex_idle = R_IDLE; tex_walk = R_WALK; tex_attack = R_ATTACK
	$Sprite2D.texture = tex_idle
	
	is_melee = true
	aggro_range = 150.0
	base_attack_cooldown = 0.75 # Matches your windup + cooldown total

func attack():
	is_attacking = true
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir
	
	if target and is_instance_valid(target):
		var dir_to_enemy = (target.global_position - global_position).normalized()
		var dash_target = target.global_position + (dir_to_enemy * 30.0)
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", dash_target, 0.15 * attack_speed_modifier).set_trans(Tween.TRANS_SINE)
		await tween.finished
		
		if target and is_instance_valid(target):
			target.take_damage(int(backstab_damage * damage_multiplier))
			var slash = SLASH_FX.instantiate()
			get_parent().add_child(slash)
			slash.global_position = target.global_position
			slash.rotation = dir_to_enemy.angle() 
			
	await get_tree().create_timer(0.6 * attack_speed_modifier).timeout 
	is_attacking = false
