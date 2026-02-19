extends Unit

# --- 1. ASSET LOADING ---
# (Make sure these paths match exactly where you put your files!)
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Special1.png")

# We need a projectile scene to shoot!
# (Double check capitalization: is it magic_orb.tscn or MagicOrb.tscn?)
const PROJECTILE_SCENE = preload("res://scenes/Projectiles/magic_orb.tscn")

var attack_counter: int = 0

func _ready():
	# --- 2. SETUP PARENT VARIABLES ---
	# We assign our specific textures to the slots in Unit.gd
	tex_idle = R_IDLE
	tex_walk = R_WALK
	tex_attack = R_ATTACK
	tex_special = R_SPECIAL
	
	# Set initial state
	$Sprite2D.texture = tex_idle
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	
	# OPTIONAL: Set a tint if you want to differentiate this unit visually
	# modulate = Color(1.0, 0.8, 0.5) 

# --- 3. ATTACK LOGIC ---
func attack():
	# ... (Standard start logic) ...
	is_attacking = true
	
	# Visuals ...
	
	# Windup
	await get_tree().create_timer(0.3).timeout
	
	attack_counter += 1
	var is_special_turn = false
	
	if attack_counter >= 3:
		attack_counter = 0
		is_special_turn = true
		
	fire_orb(is_special_turn)
	
	# Cooldown
	await get_tree().create_timer(0.5).timeout
	is_attacking = false

func fire_orb(is_special: bool):
	if not PROJECTILE_SCENE: return

	var orb = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(orb)
	orb.global_position = global_position
	
	# Aiming
	var dir = Vector2.RIGHT
	if target and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	
	orb.direction = dir
	orb.rotation = dir.angle()
	
	# --- THE SPECIAL SAUCE ---
	if is_special:
		orb.is_explosive = true
		orb.modulate = Color(1, 0.2, 0.2) # Red Orb
		orb.scale = Vector2(1.5, 1.5)     # Big Orb
		orb.speed = 400 # Slower, heavier orb
	
func _physics_process(delta):
	if is_attacking: return

	# Sorcerer Range (e.g., 200px)
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= 200:
		attack()
	else:
		super(delta)
