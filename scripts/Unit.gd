class_name Unit
extends CharacterBody2D

# --- DATA & STATS ---
var data: ChampionData
var star_level: int = 1
var current_hp: int
var target: Node2D = null

# --- TEXTURE SLOTS ---
var tex_idle: Texture2D    
var tex_walk: Texture2D    
var tex_attack: Texture2D  
var tex_special: Texture2D 

# --- STATE VARIABLES ---
var facing_dir: int = 0  
var is_attacking: bool = false
var speed: int = 70

var attack_timer: float = 0.0
var base_attack_cooldown: float = 1.0 

var damage_multiplier: float = 1.0
var attack_speed_modifier: float = 1.0 

@export var tether_distance: float = 250.0
@export var is_melee: bool = false 
@export var aggro_range: float = 200.0

var player: Node2D
var state_is_following: bool = false

@export var move_speed: float = 150
@onready var comfort_zone: Area2D = $ComfortZone
@export var comfort_force: float = 70

var velocity_component: Vector2 = Vector2.ZERO
const OVERLAP_THRESHOLD = 100
@export var friction: float = 0.15

var cached_push_vector: Vector2 = Vector2.ZERO
var push_timer: int = 0

# --- UPDATED SETUP ---
func setup(new_data: ChampionData, level: int, new_player: Node2D):
	data = new_data
	star_level = level
	player = new_player 
	
	var stat_multiplier = 1.0 + ((star_level - 1) * 0.5)
	current_hp = data.hp * stat_multiplier
	damage_multiplier = stat_multiplier 
	attack_speed_modifier = 1.0 - ((star_level - 1) * 0.2)
	
	var visual_scale = 1.0 + ((star_level - 1) * 0.3)
	scale = Vector2(visual_scale, visual_scale)

func _physics_process(delta):
	var desired_velocity = Vector2.ZERO
	var dist_to_player = 0.0
	
	if player and is_instance_valid(player):
		dist_to_player = global_position.distance_to(player.global_position)
	
	# --- EVERYONE NEEDS TO LOOK FOR ENEMIES! ---
	if target == null or not is_instance_valid(target):
		target = find_nearest_enemy()
	
	# --- BEHAVIOR SELECTION (PRIORITY SYSTEM) ---
	
	# PRIORITY 1: The Leash (Sprint to catch up)
	if player and is_instance_valid(player) and dist_to_player > tether_distance:
		target = null 
		var dir = global_position.direction_to(player.global_position)
		desired_velocity = dir * (speed * 1.5) 

	# PRIORITY 2: Melee Movement
	elif is_melee and target and is_instance_valid(target):
		var dist_to_target = global_position.distance_to(target.global_position)
		var current_attack_range = get("attack_range") if get("attack_range") != null else 40.0
		
		if dist_to_target <= current_attack_range:
			desired_velocity = Vector2.ZERO
			if attack_timer <= 0:
				attack()
				attack_timer = base_attack_cooldown * attack_speed_modifier
		elif dist_to_target <= aggro_range:
			var dir = global_position.direction_to(target.global_position)
			desired_velocity = dir * speed
		else:
			target = null 

	# PRIORITY 3: Following Commander
	elif player and is_instance_valid(player):
		if dist_to_player > 50:
			var dir = global_position.direction_to(player.global_position)
			desired_velocity = dir * speed
		else:
			# THE FIX: We just tell them to stop. The global push handles the spacing.
			desired_velocity = Vector2.ZERO

	# PRIORITY 4: Ranged Combat
	if not is_melee and target and is_instance_valid(target):
		var dist_to_target = global_position.distance_to(target.global_position)
		if dist_to_target <= aggro_range and attack_timer <= 0:
			attack() 
			attack_timer = base_attack_cooldown * attack_speed_modifier


	# --- THE FIX: GLOBAL SOCIAL DISTANCING ---
	# Calculate the push force regardless of what state the unit is in
	push_timer -= 1
	if push_timer <= 0:
		cached_push_vector = get_comfort_push()
		# Randomize the timer so all 50 units don't run the math on the exact same frame!
		push_timer = randi_range(4, 8) 
		
	if cached_push_vector != Vector2.ZERO:
		desired_velocity += cached_push_vector * comfort_force
	# -----------------------------------------


	# --- TICK COOLDOWN TIMER ---
	if attack_timer > 0:
		attack_timer -= delta

	# --- PHYSICS APPLICATION ---
	velocity = velocity.lerp(desired_velocity, friction)
	if velocity.length() < 5.0:
		velocity = Vector2.ZERO
		
	move_and_slide()
	update_facing_direction()
	update_visuals()

func get_comfort_push() -> Vector2:
	var neighbors = comfort_zone.get_overlapping_bodies() 
	if neighbors.is_empty(): return Vector2.ZERO
	
	var total_push = Vector2.ZERO
	var overlap_squared = OVERLAP_THRESHOLD * OVERLAP_THRESHOLD # Math trick!
	var processed_count = 0
	var max_neighbors_to_check = 6 # The Hard Cap
	
	for body in neighbors:
		if body == self or not body is CharacterBody2D:
			continue
			
		var vector_to_me = global_position - body.global_position
		
		# FAST CHECK: length_squared() doesn't use a square root!
		var dist_sq = vector_to_me.length_squared()
		
		if dist_sq == 0:
			vector_to_me = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
			dist_sq = 0.1
		
		# Only do the expensive math if they are definitely inside the threshold
		if dist_sq < overlap_squared:
			var dist = sqrt(dist_sq) # Now we do the square root just once
			var push_strength = 1.0 - (dist / OVERLAP_THRESHOLD)
			
			# MATH TRICK: dividing by 'dist' does the exact same thing as .normalized() but faster
			total_push += (vector_to_me / dist) * push_strength
			
			# Stop checking once we've processed 6 nearby units
			processed_count += 1
			if processed_count >= max_neighbors_to_check:
				break 
			
	return total_push.normalized() if total_push != Vector2.ZERO else Vector2.ZERO

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty(): return null
		
	var nearest_enemy = null
	var shortest_dist = INF 
	
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < shortest_dist and dist < aggro_range:
			shortest_dist = dist
			nearest_enemy = enemy
			
	return nearest_enemy

func update_facing_direction():
	if velocity.length() > 10:
		if abs(velocity.x) > abs(velocity.y):
			facing_dir = 3 if velocity.x > 0 else 2 
		else:
			facing_dir = 0 if velocity.y > 0 else 1 
	elif target and is_instance_valid(target):
		var aim = target.global_position - global_position
		if abs(aim.x) > abs(aim.y):
			facing_dir = 3 if aim.x > 0 else 2
		else:
			facing_dir = 0 if aim.y > 0 else 1

func update_visuals():
	# THE FIX: Don't override the attack texture with walking if they are currently swinging!
	if is_attacking: return 
	
	if velocity.length() > 10:
		if $Sprite2D.texture != tex_walk and tex_walk != null:
			$Sprite2D.texture = tex_walk

		var anim_name = "WalkDown"
		match facing_dir:
			0: anim_name = "WalkDown"
			1: anim_name = "WalkUp"
			2: anim_name = "WalkLeft"
			3: anim_name = "WalkRight"
		$AnimationPlayer.play(anim_name)
	else:
		$AnimationPlayer.stop()
		if $Sprite2D.texture != tex_idle and tex_idle != null:
			$Sprite2D.texture = tex_idle
		$Sprite2D.hframes = 4
		$Sprite2D.vframes = 1
		$Sprite2D.frame = facing_dir

func attack(): pass

func take_damage(amount: int):
	current_hp -= amount
	if current_hp <= 0: die()

func die(): queue_free()
