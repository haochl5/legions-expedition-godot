class_name Unit
extends CharacterBody2D

# --- DATA & STATS ---
var data: ChampionData
var star_level: int = 1
var current_hp: int
var target: Node2D = null

# --- TEXTURE SLOTS ---
var tex_idle: Texture2D    # 1x4 Strip
var tex_walk: Texture2D    # 4x4 Grid
var tex_attack: Texture2D  # 1x4 Strip
var tex_special: Texture2D # 1x1 Single Frame

# --- STATE VARIABLES ---
var facing_dir: int = 0  # 0:Down, 1:Up, 2:Left, 3:Right
var is_attacking: bool = false
var speed: int = 150

var player: Node2D

# Add state variable to remember what we are doing
var state_is_following: bool = false

@export var move_speed: float = 150
@onready var comfort_zone: Area2D = $ComfortZone
@export var comfort_force: float = 50.0 # Gentle push

var velocity_component: Vector2 = Vector2.ZERO
const OVERLAP_THRESHOLD = 100

@export var friction: float = 0.15  # <--- NEW: Controls movement smoothness (0.1 = slippery, 0.5 = snappy)

# --- UPDATED SETUP ---
func setup(new_data: ChampionData, level: int, new_player: Node2D):
	data = new_data
	star_level = level
	player = new_player 
	
	var multiplier = 1.0 + ((star_level - 1) * 0.5)
	current_hp = data.hp * multiplier

func _physics_process(_delta):
	if is_attacking: return

	# 1. AI: Find Target
	if target == null or not is_instance_valid(target):
		target = find_nearest_enemy()

	var desired_velocity = Vector2.ZERO
	var dist_to_player = 0.0
	
	if player and is_instance_valid(player):
		dist_to_player = global_position.distance_to(player.global_position)
	
	# --- BEHAVIOR SELECTION ---
	
	# CASE A: The Leash (Player walked too far away, drop everything and follow!)
	if player and is_instance_valid(player) and dist_to_player > 300:
		target = null # Forget the enemy, the boss is leaving!
		var dir = global_position.direction_to(player.global_position)
		desired_velocity = dir * speed

	# CASE B: Fighting (Only if target is valid and we haven't been leashed)
	elif target and is_instance_valid(target):
		var dist_to_target = global_position.distance_to(target.global_position)
		
		# If the enemy runs too far away, drop aggro so we don't chase them forever
		if dist_to_target > 400:
			target = null
		else:
			var dir = global_position.direction_to(target.global_position)
			desired_velocity = dir * speed

	# CASE C: Following Commander (The "Polite" Mode)
	elif player and is_instance_valid(player):
		if dist_to_player > 50:
			var dir = global_position.direction_to(player.global_position)
			desired_velocity = dir * speed
			
		else:
			desired_velocity = Vector2.ZERO
			var push = get_comfort_push()
			if push != Vector2.ZERO:
				desired_velocity = push * comfort_force

	# --- PHYSICS APPLICATION ---
	velocity = velocity.lerp(desired_velocity, friction)

	if velocity.length() < 5.0:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	update_facing_direction()
	update_visuals()

# --- SOCIAL DISTANCING MATH ---
func get_comfort_push() -> Vector2:
	var total_push = Vector2.ZERO
	var neighbors = comfort_zone.get_overlapping_areas() 
	
	if neighbors.is_empty():
		return Vector2.ZERO
	
	for area in neighbors:
		var neighbor_unit = area.get_parent() 
		
		# --- THE FIX: SAFETY CHECKS ---
		# 1. Skip if the parent isn't a 2D node (prevents the Window crash!)
		# 2. Skip if the unit is accidentally detecting itself
		if not neighbor_unit is Node2D or neighbor_unit == self:
			continue
			
		var vector_to_me = global_position - neighbor_unit.global_position
		var dist = vector_to_me.length()
		
		# Only push if we are strictly closer than the threshold
		# (And ensure dist > 0 so we don't divide by zero if perfectly stacked)
		if dist < OVERLAP_THRESHOLD and dist > 0:
			total_push += vector_to_me.normalized()
			
	if total_push == Vector2.ZERO:
		return Vector2.ZERO
		
	return total_push.normalized()
# --- HELPER FUNCTION ---
func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return null
		
	var nearest_enemy = null
	var shortest_dist = INF 
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		
		# Only aggro if they are actually nearby (e.g., within 250 pixels)
		if dist < shortest_dist and dist < 250:
			shortest_dist = dist
			nearest_enemy = enemy
			
	return nearest_enemy

# --- DIRECTION LOGIC ---
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

# --- VISUALS LOGIC ---
func update_visuals():
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

# --- VIRTUAL FUNCTIONS ---
func attack():
	pass

func take_damage(amount: int):
	current_hp -= amount
	if current_hp <= 0:
		die()

func die():
	queue_free()
