extends Node

# Global Config
const WAVE_TIME = 25
const WORLD_SIZE = 3000


signal gold_changed(new_amount)
signal exp_changed(current, max)
signal leveled_up(new_level)

# The "Database" of all units
# We use a Dictionary so we can look them up by key string "squire", "ranger", etc.
var CHAMPS = {
	"squire": { 
		"name": "Squire", 
		"cost": 3, 
		"role": "Tank", 
		"color": Color("#27ae60"), # converted hex to Godot Color
		"hp": 120, 
		"dmg": 8, 
		"cd": 1.0, 
		"speed": 110, 
		"range": 50, 
		"type": "melee",
		# We will create this scene later
		"scene_path": "res://scenes/units/squire_visuals.tscn" 
	},
	"ranger": { 
		"name": "Ranger", 
		"cost": 3, 
		"role": "DPS", 
		"color": Color("#f1c40f"), 
		"hp": 60, 
		"dmg": 8, 
		"cd": 0.8, 
		"speed": 120, 
		"range": 350, 
		"type": "ranged" 
	},
	"alchemist": { 
		"name": "Alchemist", 
		"cost": 3, 
		"role": "Mage", 
		"color": Color("#9b59b6"), 
		"hp": 60, 
		"dmg": 10, 
		"cd": 1.5, 
		"speed": 90, 
		"range": 250, 
		"type": "ranged" 
	}
}


# Player State
var gold: int = 5
var current_exp: int = 0
var level: int = 1
var exp_to_level_up: int = 50

# Talo tracking
var total_gold_collected: int = 0
var gold_spent_in_game: int = 0
var session_start_time: float = 0.0
var highest_level_reached: int = 1
var level_start_time: float = 0.0
var time_taken_per_level: Array[int] = [] 

var killer_name: String = "Unknown"


var total_actions: int = 0
# Add this near your other variables
var gold_drop_chance: float = 1.0

var total_exp_collected: int = 0

# --- META DATA (Persists across deaths) ---
var meta_crystals: int = 0 # The permanent currency they spend in the menu
var upgrade_hp_level: int = 0
var upgrade_speed_level: int = 0
var upgrade_gold_level: int = 0

var is_quick_restart: bool = false

func sync_from_talo():
	if not Talo.current_player:
		return
	
	# Talo stores props as strings, so we cast them back to integers!
	# We use get_prop() with a fallback of "0" just in case they are a new player.
	meta_crystals = int(Talo.current_player.get_prop("meta_crystals", "0"))
	upgrade_hp_level = int(Talo.current_player.get_prop("upgrade_hp_level", "0"))
	upgrade_speed_level = int(Talo.current_player.get_prop("upgrade_speed_level", "0"))
	
	print("Cloud Save Loaded! Crystals: ", meta_crystals)


# Logic
func add_gold(amount: int):
	gold += amount
	total_gold_collected += amount
	gold_changed.emit(gold)

func add_exp(amount: int):
	current_exp += amount
	total_exp_collected += amount
	
	# Check for level up loop (in case you get huge XP at once)
	while current_exp >= exp_to_level_up:
		current_exp -= exp_to_level_up
		level_up()
	
	exp_changed.emit(current_exp, exp_to_level_up)

func level_up():
	var now = Time.get_unix_time_from_system() - session_start_time
	var duration = int(now - level_start_time)
	time_taken_per_level.append(duration)
	level_start_time = now
	
	level += 1
	
	if level == 15:
		Talo.events.track("content_exhausted", {
			"time_taken_seconds": str(int(Time.get_unix_time_from_system() - session_start_time))
		})
		await Talo.events.flush()
	
	if level > highest_level_reached:
		highest_level_reached = level

	# --- THE NEW MATH ---
	# Fast L1, steady mid-game, flat late-game
	exp_to_level_up = int(exp_to_level_up * 1.05) + 35
	# --------------------
	
	leveled_up.emit(level)

func reset_gamedata():
	gold = 5
	current_exp = 0
	level = 1
	exp_to_level_up = 50
	total_gold_collected = 0
	gold_spent_in_game = 0
	time_taken_per_level.clear()
	level_start_time = Time.get_unix_time_from_system()
	killer_name = "Unknown"
	total_actions = 0
	gold_drop_chance = 1.0
	total_exp_collected = 0
