extends Node

@export var reinforcement_screen: Control
@export var player: Node2D
@export var merge_fx_scene: PackedScene # <-- ADD THIS!

# DELETE THIS LINE: You don't need a generic unit scene anymore!
# @export var unit_scene: PackedScene 

var squad_roster: Array[Unit] = []

func _ready():
	if reinforcement_screen:
		# Listen for purchases to spawn the units behind the scenes
		reinforcement_screen.unit_purchased.connect(_on_unit_bought)
		
		# NEW: Listen for the deploy button to trigger the merges!
		reinforcement_screen.wave_started.connect(process_all_merges)

func _on_unit_bought(unit_data: ChampionData):
	spawn_unit(unit_data, 1)

func spawn_unit(data: ChampionData, level: int):
	var new_unit = data.unit_scene.instantiate() 
	get_parent().add_child(new_unit)
	
	# 1. Pick a random angle (0 to 360 degrees)
	var angle = randf() * TAU 
	
	# 2. Pick a closer random distance (e.g., between 20px and 50px away)
	# This keeps them right next to the Commander without overlapping perfectly.
	var distance = randf_range(20.0, 50.0) 
	
	# 3. Calculate the offset vector
	var spawn_offset = Vector2(cos(angle), sin(angle)) * distance
	
	# 4. Apply
	new_unit.global_position = player.global_position + spawn_offset
	
	new_unit.setup(data, level, player)
	squad_roster.append(new_unit)
	return new_unit

func process_all_merges():
	# 1. Figure out which unique unit types we currently own
	var unique_ids = []
	for unit in squad_roster:
		# Check if the unit is still valid (hasn't been deleted by a previous merge)
		if is_instance_valid(unit) and not unique_ids.has(unit.data.id):
			unique_ids.append(unit.data.id)
			
	# 2. Run the merge check for each type of unit
	for id in unique_ids:
		check_for_merge(id)
		

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
		
		# Spawn the tier 2 unit AND save a reference to it
		var upgrade_data = units_to_remove[0].data
		var upgraded_unit = spawn_unit(upgrade_data, 2)
		
		# 1. Override the random player offset and move it directly to the merge center!
		upgraded_unit.global_position = merge_pos
		
		# 2. Spawn the visual effect directly on the new unit
		if merge_fx_scene:
			var fx_instance = merge_fx_scene.instantiate()
			upgraded_unit.add_child(fx_instance)
			# (Optional) Tweak this Vector2 if the sparkle isn't perfectly centered on their body
			# fx_instance.position = Vector2(0, -10) 
		
		# (Optional) Recursion: Check if we now have three 2-star units!
		# check_for_merge_tier_2(unit_id)
