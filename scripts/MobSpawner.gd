extends Node

# Define all available mob types
const MOB_TYPES = {
	"ghost": preload("res://scenes/mobs/ghost.tscn"),
	"bear": preload("res://scenes/mobs/bear.tscn"),
	"mushroom": preload("res://scenes/mobs/mushroom.tscn"),
	"boss": preload("res://scenes/mobs/boss1.tscn"),
	"boss_bamboo": preload("res://scenes/mobs/boss_bamboo.tscn"),
	"boss_dragon": preload("res://scenes/mobs/boss_dragon.tscn"),
}

# Current wave's mob configuration
@export var wave_config = [
	{"type": "ghost", "weight": 0.5},
	{"type": "bear", "weight": 0.5}
]

# --- Boss Tracking Variables (Samurai boss) ---
@export var boss_interval: int = 5 # Spawn every 5 levels (5, 10, 15...)
var last_boss_level: int = 0

# --- NEW: Bamboo Boss Tracking Variables ---
@export var bamboo_boss_first_level: int = 2
@export var bamboo_boss_interval: int = 7 # Spawn at 1, 7, 14, 21...
var last_bamboo_boss_level: int = 0

# --- NEW: Dragon Boss Tracking Variables ---
@export var dragon_boss_first_level: int = 2
@export var dragon_boss_interval: int = 13 # Spawn at 13, 26
var last_dragon_boss_level: int = 0


# Global scaling (applies to all mobs spawned via spawn_mob)
var health_multiplier: float = 1.0

# for bgm changing
signal dragon_spawned
signal dragon_died


# generate a random mob
func spawn_random_mob(position: Vector2, target: Node2D) -> MobBase:
	var mob_type = _get_random_mob_type()
	return spawn_mob(mob_type, position, target)

# Generate a mob of a specified type
func spawn_mob(type: String, position: Vector2, target: Node2D):
	if type not in MOB_TYPES:
		push_error("Unknown mob type: " + type)
		return null
	
	var mob = MOB_TYPES[type].instantiate()
	
	# Scale Health (assumes mob already has max_hp set by its script/scene)
	mob.max_hp = int(mob.max_hp * health_multiplier)
	mob.hp = mob.max_hp
	
	mob.global_position = position
	mob.target = target
	
	return mob

# The mob type is randomly selected based on weight.
func _get_random_mob_type() -> String:
	var total_weight = 0.0
	for config in wave_config:
		total_weight += config["weight"]
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for config in wave_config:
		current_weight += config["weight"]
		if random_value <= current_weight:
			return config["type"]
	
	return wave_config[0]["type"]

# Set the mob configuration for the current wave.
func set_wave_config(configs):
	wave_config = configs

# Spawn a cluster of mobs with spacing
func spawn_cluster(type: String, position: Vector2, target: Node2D, count: int = 1):
	for i in range(count):
		# INCREASED OFFSET: changed from 80 to 150 to prevent overlapping blobs
		var offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
		var mob = spawn_mob(type, position + offset, target)
		if mob:
			get_parent().add_child(mob)

# ==========================================
# BOSS SPAWNING LOGIC
# - Samurai boss: level 5,10,15... count = level/5
# - Bamboo boss:  level 1,7,14...  count = level/7 (but level 1 => 1 for testing)
# ==========================================

func try_spawn_boss(current_level: int, position: Vector2, target: Node2D):
	# -------------------------
	# 1) Samurai Boss (existing)
	# -------------------------
	if current_level >= boss_interval and current_level % boss_interval == 0:
		if last_boss_level != current_level:
			# Level 5 = 1, Level 10 = 2, Level 15 = 3 ...
			var boss_count: int = current_level / boss_interval
			
			for i in range(boss_count):
				var offset = Vector2(randf_range(-250, 250), randf_range(-250, 250))
				var boss = spawn_mob("boss", position + offset, target)
				if boss:
					get_parent().call_deferred("add_child", boss)
			
			last_boss_level = current_level
			print("WAVE ", current_level, ": ", boss_count, " SAMURAI BOSSES SPAWNED!")

	# -------------------------
	# 2) Bamboo Boss (NEW)
	# Spawn at level  7, 14, 21...
	# Count algorithm same style as samurai:
	#   level 7 => 1, level 14 => 2, ...
	# -------------------------
	var should_spawn_bamboo := current_level % bamboo_boss_interval == 0
	if should_spawn_bamboo:
		var bamboo_count: int =  int(current_level / bamboo_boss_interval)
		
		for i in range(bamboo_count):
			var offset = Vector2(randf_range(-250, 250), randf_range(-250, 250))
			var bamboo = spawn_mob("boss_bamboo", position + offset, target)
			if bamboo:
				get_parent().call_deferred("add_child", bamboo)
		
		last_bamboo_boss_level = current_level
		print("WAVE ", current_level, ": ", bamboo_count, " BAMBOO BOSSES SPAWNED!")
	
	
	# -------------------------
	# 2) Dragon
	# Spawn at level  13, 26...
	# Count algorithm same style as samurai:
	#   level 13 => 1, level 26 => 2, ...
	# -------------------------	
	var should_spawn_dragon := current_level % dragon_boss_interval == 0
	if should_spawn_dragon:
		var dragon_count: int =  int(current_level / dragon_boss_interval)
		
		for i in range(dragon_count):
			var offset = Vector2(randf_range(-250, 250), randf_range(-250, 250))
			var dragon = spawn_mob("boss_dragon", position + offset, target)
			if dragon:
				get_parent().call_deferred("add_child", dragon)
				dragon.boss_dragon_spawned.connect(func(): dragon_spawned.emit())
				dragon.boss_dragon_died.connect(func(): dragon_died.emit())
				
		
		last_dragon_boss_level = current_level
		print("WAVE ", current_level, ": ", dragon_count, " dragon BOSSES SPAWNED!")
