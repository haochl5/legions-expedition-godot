class_name Unit
extends CharacterBody2D

# --- DATA & STATS ---
var data: ChampionData
var star_level: int = 1
var current_hp: int
var target: Node2D = null

# --- TEXTURE SLOTS (Children like Sorcerer.gd will fill these!) ---
var tex_idle: Texture2D    # 1x4 Strip
var tex_walk: Texture2D    # 4x4 Grid
var tex_attack: Texture2D  # 1x4 Strip
var tex_special: Texture2D # 1x1 Single Frame

# --- STATE VARIABLES ---
var facing_dir: int = 0  # 0:Down, 1:Up, 2:Left, 3:Right
var is_attacking: bool = false
var speed: int = 150

# --- SETUP (Called when spawning) ---
func setup(new_data: ChampionData, level: int):
	data = new_data
	star_level = level
	
	# Calculate Stats
	var multiplier = 1.0 + ((star_level - 1) * 0.5)
	current_hp = data.hp * multiplier
	
	# Scale Visuals
	scale = Vector2.ONE * 4.0 * (1.0 + (0.2 * (star_level - 1)))

# --- PHYSICS LOOP ---
func _physics_process(_delta):
	# 1. If attacking, freeze movement
	if is_attacking:
		return 

	# 2. Movement Logic
	var move_vec = Vector2.ZERO
	if target and is_instance_valid(target):
		move_vec = global_position.direction_to(target.global_position)
		velocity = move_vec * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	# 3. Update Direction & Visuals
	update_facing_direction()
	update_visuals()

# --- DIRECTION LOGIC ---
func update_facing_direction():
	# If we are moving, use velocity to decide direction
	if velocity.length() > 10:
		if abs(velocity.x) > abs(velocity.y):
			facing_dir = 3 if velocity.x > 0 else 2 # Right : Left
		else:
			facing_dir = 0 if velocity.y > 0 else 1 # Down : Up
	
	# If not moving but we have a target, face the target!
	elif target and is_instance_valid(target):
		var aim = target.global_position - global_position
		if abs(aim.x) > abs(aim.y):
			facing_dir = 3 if aim.x > 0 else 2
		else:
			facing_dir = 0 if aim.y > 0 else 1

# --- VISUALS LOGIC (The Magic Part) ---
func update_visuals():
	# CASE A: MOVING -> Use Walk Animation (4x4 Grid)
	if velocity.length() > 10:
		# 1. Swap Texture to Walk Grid
		if $Sprite2D.texture != tex_walk and tex_walk != null:
			$Sprite2D.texture = tex_walk
			# Note: We don't set hframes/vframes here because the AnimationPlayer tracks do it!

		# 2. Play the correct animation column
		var anim_name = "WalkDown"
		match facing_dir:
			0: anim_name = "WalkDown"
			1: anim_name = "WalkUp"
			2: anim_name = "WalkLeft"
			3: anim_name = "WalkRight"
		
		$AnimationPlayer.play(anim_name)

	# CASE B: IDLE -> Use Idle Texture (1x4 Strip)
	else:
		$AnimationPlayer.stop()
		
		# 1. Swap Texture to Idle Strip
		if $Sprite2D.texture != tex_idle and tex_idle != null:
			$Sprite2D.texture = tex_idle
		
		# 2. MANUALLY set the grid for a strip
		# (Crucial: The Walk animation changed these to 4, so we must reset them to 1!)
		$Sprite2D.hframes = 4
		$Sprite2D.vframes = 1
		
		# 3. Pick the frame based on direction
		$Sprite2D.frame = facing_dir

# --- VIRTUAL FUNCTIONS (Children overwrite these) ---
func attack():
	pass

func take_damage(amount: int):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	queue_free()
