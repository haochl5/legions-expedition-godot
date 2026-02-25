extends Node

# Define all available mob types
const MOB_TYPES = {
	"ghost": preload("res://scenes/mobs/ghost.tscn"),
	"bear": preload("res://scenes/mobs/bear.tscn"),
	"mushroom": preload("res://scenes/mobs/mushroom.tscn"),
	# --- NEW: Add the Boss! (Verify this path matches your files) ---
	"boss": preload("res://scenes/mobs/boss1.tscn"),
}

# Current wave's mob configuration
@export var wave_config = [
	{"type": "ghost", "weight": 0.5},
	{"type": "bear", "weight": 0.5}
]

# --- NEW: Boss Tracking Variables ---
@export var boss_interval: int = 5 # Spawn every 5 levels (5, 10, 15...)
var last_boss_level: int = 0


# generate a random mob
func spawn_random_mob(position: Vector2, target: Node2D) -> MobBase:
	var mob_type = _get_random_mob_type()
	return spawn_mob(mob_type, position, target)

# Generate a mob of a specified type
func spawn_mob(type: String, position: Vector2, target: Node2D) -> MobBase:
	if type not in MOB_TYPES:
		push_error("Unknown mob type: " + type)
		return null
	
	var mob: MobBase = MOB_TYPES[type].instantiate()
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

# New function to handle groups
func spawn_cluster(type: String, position: Vector2, target: Node2D, count: int = 1):
	for i in range(count):
		# Add a small random offset so they don't overlap perfectly
		var offset = Vector2(randf_range(-80, 80), randf_range(-80, 80))
		var mob = spawn_mob(type, position + offset, target)
		if mob:
			get_parent().add_child(mob) # Adds to the Main scene

# ==========================================d
# --- NEW: BOSS SPAWNING LOGIC ---
# ==========================================

func try_spawn_boss(current_level: int, position: Vector2, target: Node2D):
	# 1. Check if we are at or above the threshold
	# 2. Check if the current level is a multiple of our interval
	# 3. Ensure we haven't already spawned a boss for THIS specific level
	if current_level >= boss_interval and current_level % boss_interval == 0:
		if last_boss_level != current_level:
			var boss = spawn_mob("boss", position, target)
			if boss:
				get_parent().call_deferred("add_child", boss)
				last_boss_level = current_level
				print("BOSS SPAWNED at Level: ", current_level)
