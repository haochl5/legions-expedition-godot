extends Unit

# --- 1. ASSET LOADING ---
# (Make sure these paths match exactly where you put your files!)
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/SeparateAnim/Special1.png")

# We need a projectile scene to shoot!
const PROJECTILE_SCENE = preload("res://scenes/Projectiles/magic_orb.tscn")

var attack_counter: int = 0

func _ready():
	super()
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
	
	# --- THE FIX: Pass the multiplier to the orb! ---
	orb.set("damage_multiplier", damage_multiplier)
	# ------------------------------------------------
	
	get_parent().add_child(orb)
	orb.global_position = global_position
	
	var dir = Vector2.RIGHT
	if target and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	
	orb.direction = dir
	orb.rotation = dir.angle()
	
	if is_special:
		orb.is_explosive = true
		orb.modulate = Color(1, 0.2, 0.2) 
		# Scale the massive special orb by the multiplier too!
		orb.scale = Vector2(1.5 * damage_multiplier, 1.5 * damage_multiplier)
		orb.speed = 400 
	else:
		# Scale the normal orbs
		orb.scale = Vector2(damage_multiplier, damage_multiplier)

func _physics_process(delta):
	if is_attacking: return

	# Sorcerer Range (e.g., 200px)
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= 150:
		attack()
	else:
		super(delta)
