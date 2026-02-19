extends Unit

# ASSETS (SamuraiRed)
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Special1.png")

var attack_range = 40.0 # Pixel distance for melee
var damage = 15

var attack_counter: int = 0
var special_trigger: int = 4 # Every 4th attack


func _ready():
	# Setup Visuals
	tex_idle = R_IDLE
	tex_walk = R_WALK
	tex_attack = R_ATTACK
	tex_special = R_SPECIAL
	$Sprite2D.texture = tex_idle

func _physics_process(delta):
	if is_attacking: return

	# MELEE LOGIC:
	# If we have a target and we are close enough...
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		attack()
	else:
		# Otherwise, run the normal movement code from Unit.gd
		super(delta)

# Replace your 'attack()' function with this logic:
func attack():
	is_attacking = true
	attack_counter += 1
	
	# DECIDE: Normal or Special?
	if attack_counter >= special_trigger:
		attack_counter = 0
		perform_whirlwind()
	else:
		perform_normal_attack()

func perform_normal_attack():
	# 1. Visuals
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir
	
	# 2. Windup
	await get_tree().create_timer(0.3).timeout
	
	# 3. Damage
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_range + 20: 
			target.take_damage(damage)
	
	# 4. Cooldown
	await get_tree().create_timer(0.5).timeout
	is_attacking = false

func perform_whirlwind():
	# 1. Visual Spin
	var tween = create_tween()
	tween.tween_property($Sprite2D, "rotation_degrees", 360.0, 0.4).as_relative()
	
	# 2. Damage ALL enemies around
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		# Hitting everything within 100px
		if global_position.distance_to(enemy.global_position) <= 100.0:
			enemy.take_damage(damage * 2) # Double Damage!
			
	await get_tree().create_timer(0.4).timeout
	$Sprite2D.rotation_degrees = 0 # Reset rotation
	is_attacking = false
