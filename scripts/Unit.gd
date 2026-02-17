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

var player: Node2D 

# --- UPDATED SETUP ---
# We now accept 'new_player' so we know who to follow!
func setup(new_data: ChampionData, level: int, new_player: Node2D):
	data = new_data
	star_level = level
	player = new_player # Store the reference
	
	# ... (Existing Stats Calculation) ...
	var multiplier = 1.0 + ((star_level - 1) * 0.5)
	current_hp = data.hp * multiplier
	scale = Vector2.ONE * 4.0 * (1.0 + (0.2 * (star_level - 1)))

# --- UPDATED PHYSICS ---
func _physics_process(_delta):
	if is_attacking: return

	# 1. AI: Find a target if we don't have one
	if target == null or not is_instance_valid(target):
		target = find_nearest_enemy()

	# 2. MOVEMENT DECISION
	var desired_velocity = Vector2.ZERO
	
	if target and is_instance_valid(target):
		# STATE A: Chase Enemy
		# (Note: Children like Ranger/Squire might stop earlier to attack)
		desired_velocity = global_position.direction_to(target.global_position) * speed

	elif player and is_instance_valid(player):
		# STATE B: Follow Commander
		# Only move if we are far away (prevents stacking directly on top of player)
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player > 120.0: # "Leash" distance
			desired_velocity = global_position.direction_to(player.global_position) * speed

	# 3. APPLY MOVEMENT
	velocity = desired_velocity
	move_and_slide()

	# 4. VISUALS
	update_facing_direction()
	update_visuals()

# --- NEW HELPER FUNCTION ---
func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return null
		
	var nearest_enemy = null
	var shortest_dist = INF # Infinite
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < shortest_dist:
			shortest_dist = dist
			nearest_enemy = enemy
			
	return nearest_enemy
	

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
