extends Node

@export var reinforcement_screen: Control
@export var player: Node2D 

# DELETE THIS LINE: You don't need a generic unit scene anymore!
# @export var unit_scene: PackedScene 

var squad_roster: Array[Unit] = []

func _ready():
	if reinforcement_screen:
		reinforcement_screen.unit_purchased.connect(_on_unit_bought)

func _on_unit_bought(unit_data: ChampionData):
	spawn_unit(unit_data, 1)
	check_for_merge(unit_data.id)

func spawn_unit(data: ChampionData, level: int):
	# --- CRITICAL CHANGE HERE ---
	# We instantiate the SPECIFIC scene from the card data (e.g., Sorcerer.tscn)
	var new_unit = data.unit_scene.instantiate() 
	
	get_parent().add_child(new_unit)
	
	var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
	new_unit.global_position = player.global_position + offset
	
	new_unit.setup(data, level, player)
	squad_roster.append(new_unit)


# --- THE MERGE LOGIC ---
func check_for_merge(unit_id: String):
	# 1. Find all 1-star units of this specific type
	var matching_units = []
	for unit in squad_roster:
		if unit.data.id == unit_id and unit.star_level == 1:
			matching_units.append(unit)
	
	# 2. If we have 3 or more, merge them!
	if matching_units.size() >= 3:
		print("MERGE HAPPENING: ", unit_id)
		
		# Grab the first 3
		var units_to_remove = matching_units.slice(0, 3)
		
		# Calculate the average position for the merge effect
		var merge_pos = Vector2.ZERO
		for u in units_to_remove:
			merge_pos += u.global_position
			squad_roster.erase(u) # Remove from array
			u.queue_free()        # Delete from world
		merge_pos /= 3.0
		
		# Spawn the tier 2 unit
		var upgrade_data = units_to_remove[0].data
		spawn_unit(upgrade_data, 2)
		
		# (Optional) Recursion: Check if we now have three 2-star units!
		# check_for_merge_tier_2(unit_id)
