extends Unit

# ASSETS (SamuraiRed)
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/SeparateAnim/Special1.png")

var attack_range = 40.0 # Pixel distance for melee
var damage = 15

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

func attack():
	is_attacking = true
	
	# 1. Visuals
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir
	
	# 2. Windup (Sword swing delay)
	await get_tree().create_timer(0.3).timeout
	
	# 3. DEAL DAMAGE (Melee Check)
	# We check distance AGAIN to make sure enemy didn't run away
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_range + 10: # Small buffer
			if target.has_method("take_damage"):
				target.take_damage(damage)
	
	# 4. Cooldown
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
