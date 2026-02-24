extends Unit

# UPDATE THESE PATHS!
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Tengu2/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Tengu2/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Tengu2/SeparateAnim/Attack.png")

const LIGHTNING_BOLT = preload("res://scenes/FX/lightning_bolt.tscn")
var attack_range = 100 # Long range

func _ready():
	tex_idle = R_IDLE; tex_walk = R_WALK; tex_attack = R_ATTACK
	$Sprite2D.texture = tex_idle

func _physics_process(delta):
	if is_attacking: return
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		attack()
	else:
		super(delta)

func attack():
	is_attacking = true
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir
	
	# Fast windup
	await get_tree().create_timer(0.2).timeout 
	
	if target and is_instance_valid(target):
		# 1. Deal the damage instantly! (Adjust the 25 to whatever feels balanced)
		target.take_damage(25)
		
		# 2. Spawn the lightning strike effect
		var bolt = LIGHTNING_BOLT.instantiate()
		get_parent().add_child(bolt)
		
		# 3. Snap the bolt perfectly to the enemy's coordinates
		bolt.global_position = target.global_position
		
		# Notice we completely deleted all the direction, rotation, and speed math!
		
	# Cooldown
	await get_tree().create_timer(0.8).timeout 
	is_attacking = false
