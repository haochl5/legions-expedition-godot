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
	# If this purchase is an Item (no unit scene), apply its effect immediately.
	if unit_data == null:
		return

	# Option A (recommended): identify by id
	if unit_data.id == "lifepot":
		_apply_lifepot(unit_data)
		return

	# Option B (fallback): identify by missing scene
	# if unit_data.unit_scene == null:
	#     return

	# Otherwise, it's a normal champion
	spawn_unit(unit_data, 1)
	
func _apply_lifepot(item_data: ChampionData) -> void:
	var heal_amount: int = int(item_data.hp)

	if player == null or not is_instance_valid(player):
		return

	var old_hp = player.hp
	player.hp = min(player.max_hp, player.hp + heal_amount)

	print("LifePot used: +%d HP (%d -> %d)" % [heal_amount, old_hp, player.hp])

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
# --- THE UPGRADED MERGE LOGIC ---
func check_for_merge(unit_id: String):
	# Loop through level 1, then level 2. (We don't check level 3, because it's the max!)
	for current_tier in [1, 2]:
		var matching_units = []
		
		# Find all units of this specific ID and Tier
		for unit in squad_roster:
			if unit.data.id == unit_id and unit.star_level == current_tier:
				matching_units.append(unit)
		
		# If we have 3 or more of this tier, merge them!
		if matching_units.size() >= 3:
			var new_tier = current_tier + 1
			print("MERGE HAPPENING: ", unit_id, " TO TIER ", new_tier)
			
			Talo.events.track("champion_merged", {
				"champion_id": unit_id,
				"new_tier": str(new_tier),
				"current_level": str(GameData.level) 
			})
			
			# Grab the first 3
			var units_to_remove = matching_units.slice(0, 3)
			
			# Calculate the average position for the merge center
			var merge_pos = Vector2.ZERO
			for u in units_to_remove:
				merge_pos += u.global_position
				squad_roster.erase(u) 
				u.queue_free()        
			merge_pos /= 3.0
			
			# Spawn the upgraded unit
			var upgrade_data = units_to_remove[0].data
			var upgraded_unit = spawn_unit(upgrade_data, new_tier)
			upgraded_unit.global_position = merge_pos
			
			# Calculate dynamic scale: Tier 1 = 1.0, Tier 2 = 1.3, Tier 3 = 1.6
			var target_scale = 1.0 + ((new_tier - 1) * 0.3)
			upgraded_unit.scale = Vector2(1.0, 1.0) # Start normal size
			
			var tween = create_tween()
			tween.tween_property(upgraded_unit, "scale", Vector2(target_scale, target_scale), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
			if merge_fx_scene:
				var fx_instance = merge_fx_scene.instantiate()
				upgraded_unit.add_child(fx_instance)
				
			# THE MAGIC RECURSIVE CALL: 
			# If merging these three Level 1s just created our third Level 2, 
			# we instantly call this function again to trigger the Level 3 merge!
			check_for_merge(unit_id)
			return # Exit the current loop since the recursive call handles the rest
