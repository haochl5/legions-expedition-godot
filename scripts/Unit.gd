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
var speed: int = 70

var attack_timer: float = 0.0
var base_attack_cooldown: float = 1.0

var damage_multiplier: float = 1.0
var attack_speed_modifier: float = 1.0 # Smaller number = faster attacks!

@export var tether_distance: float = 250.0
@export var is_melee: bool = false 
@export var aggro_range: float = 200.0

var player: Node2D

# Add state variable to remember what we are doing
var state_is_following: bool = false

@export var move_speed: float = 150
@onready var comfort_zone: Area2D = $ComfortZone
@export var comfort_force: float = 50.0 # Gentle push

var velocity_component: Vector2 = Vector2.ZERO
const OVERLAP_THRESHOLD = 100

@export var friction: float = 0.15  # Controls movement smoothness

# taking damage
var is_invincible: bool = false
var invincibility_timer: float = 0.0
const INVINCIBILITY_TIME = 0.8

# --- UPDATED SETUP ---
func setup(new_data: ChampionData, level: int, new_player: Node2D):
	data = new_data
	star_level = level
	player = new_player 
	
	# Tier 1 = 1.0, Tier 2 = 1.5, Tier 3 = 2.0
	var stat_multiplier = 1.0 + ((star_level - 1) * 0.5)
	current_hp = data.hp * stat_multiplier
	
	# Apply extra damage per tier
	damage_multiplier = stat_multiplier 
	
	# Reduce timer cooldowns per tier
	attack_speed_modifier = 1.0 - ((star_level - 1) * 0.2)
	
	# Automatically set the correct scale right when they spawn
	var visual_scale = 1.0 + ((star_level - 1) * 0.3)
	scale = Vector2(visual_scale, visual_scale)

func _ready():
	if has_node("Hurtbox"):
		$Hurtbox.body_entered.connect(_on_hurtbox_entered)
		$Hurtbox.area_entered.connect(_on_hurtbox_entered)
	else:
		push_error("CRITICAL ERROR: Could not find a node named exactly 'Hurtbox' on " + self.name)
	
func _on_hurtbox_entered(node: Node2D):
	
	# If we have 0 HP, heal to 100 just for testing!
	if current_hp <= 0:
		current_hp = 100
		
	if is_invincible:
		return
		
	# Find out if the node (or its parent) is the enemy
	var enemy_node = node
	if not (enemy_node.is_in_group("enemy") or enemy_node is MobBase):
		enemy_node = node.get_parent()
		
	if enemy_node and (enemy_node.is_in_group("enemy") or enemy_node is MobBase):
		var damage_to_take = enemy_node.get("damage")
		if damage_to_take == null:
			damage_to_take = 15 
			
		take_damage(damage_to_take)

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
			desired_velocity = Vector2.ZERO
			var push = get_comfort_push()
			if push != Vector2.ZERO:
				desired_velocity = push * comfort_force

	# PRIORITY 4: Ranged Combat
	if not is_melee and target and is_instance_valid(target):
		var dist_to_target = global_position.distance_to(target.global_position)
		if dist_to_target <= aggro_range:
			if attack_timer <= 0:
				attack() 
				attack_timer = base_attack_cooldown * attack_speed_modifier
		else:
			target = null 

	# --- TICK COOLDOWN TIMERS ---
	if attack_timer > 0:
		attack_timer -= delta
		
	# --- INVINCIBILITY & DAMAGE FLICKER ---
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false

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
		
		# Skip if the parent isn't a 2D node or if detecting itself
		if not neighbor_unit is Node2D or neighbor_unit == self:
			continue
			
		var vector_to_me = global_position - neighbor_unit.global_position
		var dist = vector_to_me.length()
		
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
		if not is_instance_valid(enemy): continue
		var dist = global_position.distance_to(enemy.global_position)
		
		# Use aggro_range instead of a hardcoded value
		if dist < shortest_dist and dist < aggro_range:
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
	# Protect the attack animations from being overwritten!
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

# --- VIRTUAL FUNCTIONS ---
func attack():
	pass

func take_damage(amount: int):
	if is_invincible:
		return
		
	current_hp -= amount
	
	if current_hp <= 0:
		print("champion died")
		die()
	else:
		is_invincible = true
		invincibility_timer = INVINCIBILITY_TIME
		var tween = create_tween()
		tween.tween_property($Sprite2D, "modulate", Color.RED, 0.1)
		tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)

func die():
	queue_free()
