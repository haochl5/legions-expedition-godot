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
	if is_attacking: return
	is_attacking = true
	
	# A. VISUALS: Force the Attack Texture (1x4 Strip)
	$AnimationPlayer.stop() # Stop walking
	
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir # Uses the direction variable from Unit.gd!
	
	# B. TIMING: Windup (0.3 seconds)
	await get_tree().create_timer(0.3).timeout
	
	# C. ACTION: Fire!
	fire_projectile()
	
	# D. TIMING: Cooldown (0.2 seconds)
	await get_tree().create_timer(0.2).timeout
	
	# E. RESET: Go back to normal behavior
	is_attacking = false

func fire_projectile():
	if not PROJECTILE_SCENE:
		print("Error: No Projectile Scene assigned in Sorcerer.gd!")
		return

	var orb = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(orb)
	
	# Start at Sorcerer's position
	orb.global_position = global_position
	
	# AIMING LOGIC
	var shot_dir = Vector2.RIGHT # Default
	
	if target and is_instance_valid(target):
		# 1. Aim at the enemy
		shot_dir = (target.global_position - global_position).normalized()
	else:
		# 2. Fallback: If target is dead, shoot where we are facing
		match facing_dir:
			0: shot_dir = Vector2.DOWN
			1: shot_dir = Vector2.UP
			2: shot_dir = Vector2.LEFT
			3: shot_dir = Vector2.RIGHT
	
	# 3. Apply the math to the Orb
	orb.direction = shot_dir        # Tells the script where to move
	orb.rotation = shot_dir.angle() # Rotates the sprite visuals

# --- 4. SPECIAL SKILL (Optional) ---
func cast_special():
	if is_attacking: return
	is_attacking = true
	
	$AnimationPlayer.stop()
	
	# Special is a Single Frame (1x1)
	$Sprite2D.texture = tex_special
	$Sprite2D.hframes = 1
	$Sprite2D.vframes = 1
	$Sprite2D.frame = 0
	
	# Hold the pose for 1 second
	await get_tree().create_timer(1.0).timeout
	
	is_attacking = false
	
func _physics_process(delta):
	if is_attacking: return

	# Sorcerer Range (e.g., 200px)
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= 200:
		attack()
	else:
		super(delta)
