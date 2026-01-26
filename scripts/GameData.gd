extends Node

# Global Config
const WAVE_TIME = 25
const WORLD_SIZE = 3000

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

# Player State (Gold, Wave, etc.)
var gold: int = 0
var wave: int = 1
var current_squad: Array = [] # Will hold the units the player has bought
