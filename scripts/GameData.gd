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
var gold: int = 0
var current_exp: int = 0
var level: int = 1
var exp_to_level_up: int = 50

# Logic
func add_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)

func add_exp(amount: int):
	current_exp += amount
	
	# Check for level up loop (in case you get huge XP at once)
	while current_exp >= exp_to_level_up:
		current_exp -= exp_to_level_up
		level_up()
	
	exp_changed.emit(current_exp, exp_to_level_up)

func level_up():
	level += 1
	# Increase difficulty
	exp_to_level_up = int(exp_to_level_up * 1.2) + 20
	leveled_up.emit(level)

func reset_gamedata():
	gold = 0
	current_exp = 0
	level = 1
	exp_to_level_up = 50
