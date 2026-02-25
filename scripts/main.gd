extends Node

# --- MAP GENERATION EXPORTS ---
# --- MAP GENERATION EXPORTS ---
@export var tree_scenes: Array[PackedScene]
@export var rock_scenes: Array[PackedScene]
@export var building_scenes: Array[PackedScene]
@export var statue_scene: PackedScene

@onready var grid_background = $GridBackground
@onready var dirt_layer = $DirtLayer
@onready var decor_layer = $DecorationsLayer

var map_width = 150
var map_height = 150
var world_size = 2400 # map_width * 16 pixels
var num_blockers = 150

# --- EXISTING NODES --- 
@onready var mob_spawner = $MobSpawner
@onready var reinforcement_screen = $CanvasLayer/Control
@onready var title_screen = $CanvasLayer/TitleScreen
@onready var game_over_screen = $CanvasLayer/GameOverScreen
@onready var ingame_UI = $CanvasLayer/UI

# Talo
var _game_start_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	title_screen_ready()
	# Connect the shop's deploy button to unpause the game
	reinforcement_screen.wave_started.connect(_on_wave_started)
	GameData.leveled_up.connect(_on_level_up)
	mob_spawner.set_wave_config([
		{"type": "bear", "weight": 0.2},
		{"type": "ghost", "weight": 0.2},
		{"type": "mushroom", "weight": 0.6},
		
	])
	title_screen.start_game.connect(_on_start_game)
	game_over_screen.restart_game.connect(_on_restart_game)
  
  # Generate the world right when the scene loads!
	generate_ground()
	spawn_blockers()
	setup_boundaries()
	
	# for Talo
	await _init_player()
	
	
func _init_player() -> void:
	var final_id = ""
	print("[Talo Debug] Starting player identification...")
	
	if Talo.settings and Talo.settings.get("access_key"):
		print("[Talo Debug] Access Key found in settings! Length: ", Talo.settings.access_key.length())
	else:
		print("[Talo Debug] ERROR: Access Key missing in Talo.settings!")
	
	if OS.get_name() == "Web":
		print("[Talo Debug] Platform detected: Web")
		final_id = JavaScriptBridge.eval("localStorage.getItem('talo_player_id') || ''")
		
		if final_id == "":
			final_id = "guest_" + str(randi()) + str(Time.get_ticks_msec())
			JavaScriptBridge.eval("localStorage.setItem('talo_player_id', '%s')" % final_id)
			print("[Talo Debug] Created new Web ID: ", final_id)
		else:
			print("[Talo Debug] Found existing Web ID: ", final_id)
	else:
		print("[Talo Debug] Platform detected: Desktop/Other")
		final_id = Talo.players.generate_identifier()
		print("[Talo Debug] Generated Desktop ID: ", final_id)
	
	print("[Talo Debug] Calling Talo.players.identify for ID: ", final_id)
	
	# Attempt identification
	await Talo.players.identify("guest", final_id)
	
	# Check if Talo singleton is actually initialized
	if Talo.current_alias:
		print("[Talo Debug] Success! Alias identified: ", Talo.current_alias.identifier)
	else:
		print("[Talo Debug] Failure: Talo.current_alias is still null after await")

	print("Talo player ID: ", Talo.current_alias.identifier if Talo.current_alias else "FAILED")
	
func title_screen_ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	game_over_screen.hide()
	ingame_UI.hide()
	title_screen.show()
	
func _on_start_game():
	# Only confine the mouse if we are NOT playing on the web
	if not OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		
	title_screen.hide()
	ingame_UI.show()
	get_tree().paused = false
	new_game()
	
func game_over():
	var duration = int(Time.get_unix_time_from_system() - _game_start_time)
	Talo.events.track("game_over", {
		"duration_seconds": str(duration),
		"gold_collected": str(GameData.total_gold_collected),
		"level_reached": str(GameData.level)
	})
	await Talo.events.flush()  
	print("Talo flush done")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$MobTimer.stop()
	game_over_screen_ready()

func game_over_screen_ready():
	get_tree().paused = true
	game_over_screen.final_gold_level(GameData.gold, GameData.level)
	game_over_screen.show()

func _on_restart_game():
	GameData.reset_gamedata()
	get_tree().paused = false
	get_tree().reload_current_scene()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update UI from GameData (Source of Truth)
	ingame_UI.update_gold(GameData.gold)
	ingame_UI.update_exp(GameData.current_exp, GameData.exp_to_level_up)
	ingame_UI.update_level(GameData.level)
	
	if has_node("Commander"):
		ingame_UI.update_hp($Commander.hp, $Commander.max_hp)

func new_game():
	_game_start_time = Time.get_unix_time_from_system()
	$Commander.start($StartPosition.position)
	$StartTimer.start()

func _on_mob_timer_timeout() -> void:
	# random spown position
	var mob_spawn_location = get_mob_spawn_position()
	
	# use mobspawner to generate a mob
	var mob = mob_spawner.spawn_random_mob(
		mob_spawn_location + Vector2(100, 0),
		$Commander
	)
	
	# add to scene
	add_child(mob)

func _on_ghost_timer_timeout() -> void:
	var mob_spawn_location = get_mob_spawn_position()
	mob_spawner.spawn_cluster("ghost", mob_spawn_location, $Commander, randi_range(1, 5))

func _on_bear_timer_timeout() -> void:
	var mob_spawn_location = get_mob_spawn_position()
	mob_spawner.spawn_cluster("bear", mob_spawn_location, $Commander)

func _on_mushroom_timer_timeout() -> void:
	var mob_spawn_location = get_mob_spawn_position()
	mob_spawner.spawn_cluster("bear", mob_spawn_location, $Commander, randi_range(1, 2))

func get_mob_spawn_position():
	var mob_spawn_location = $Commander/MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	return mob_spawn_location.global_position

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	
	$GhostTimer.start()
	$BearTimer.start()
	$MushroomTimer.start()
	
# --- SHOP LOGIC ---
func _on_wave_started():
	# Unpause the game world when "Deploy" is clicked
	get_tree().paused = false

# (Optional: Just for testing right now, let's open it when you press 'Tab')
func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next"): # Usually the 'Tab' key
		open_shop()
	# --- DEBUG: PRESS 'F' TO SPAWN BOSS ---
	if OS.is_debug_build() and event is InputEventKey:
		if event.pressed and event.keycode == KEY_F:
			print("[DEBUG] Forced Boss Spawn!")
			var spawn_pos = get_mob_spawn_position()
			# We force the call to spawn_mob directly from the dictionary
			var boss = mob_spawner.spawn_mob("boss", spawn_pos, $Commander)
			if boss:
				add_child(boss)

func _on_level_up(new_level: int):
	var spawn_pos = get_mob_spawn_position()
	mob_spawner.try_spawn_boss(new_level, spawn_pos, $Commander)
	print("Level Up! Opening Shop...")
	open_shop()
	
func open_shop():
	get_tree().paused = true
	reinforcement_screen.visible = true
	reinforcement_screen.on_shop_opened()


# ==========================================
# --- MAP GENERATION LOGIC ---
# ==========================================
func generate_ground():
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	
	# 1. Use Simplex Smooth instead of Perlin for rounder, "blobby" shapes
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	# 2. Turn OFF the rough edges completely to stop the "hairy" spikes
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	# 3. Zoom in just a little bit more to make the clearings larger
	noise.frequency = 0.015 

	var dirt_cells: Array[Vector2i] = []

	for x in range(-map_width / 2, map_width / 2):
		for y in range(-map_height / 2, map_height / 2):
			var cell_coords = Vector2i(x, y)
			var noise_val = noise.get_noise_2d(x, y)
			
			# Grass base
			grid_background.set_cell(cell_coords, 0, Vector2i(1, 7)) 
			
			# 4. Higher threshold + Simplex = natural, isolated dirt clearings
			if noise_val > 0.2:
				dirt_cells.append(cell_coords)
			else:
				# 3. Decoration Layer (Only on Grass)
				var rand_decor = randf()
				if rand_decor > 0.95: 
					var pebble_coords = Vector2i(15, 18) 
					if randf() > 0.5:
						pebble_coords = Vector2i(16, 18) 
					decor_layer.set_cell(cell_coords, 2, pebble_coords)

	# Tell Godot to connect the dirt on the Dirt layer
	dirt_layer.set_cells_terrain_connect(dirt_cells, 0, 0)

func spawn_blockers():
	# Instead of just storing positions, we store a Dictionary with all info!
	var placed_objects: Array[Dictionary] = []
	
	# --- DISTANCE RULES ---
	var min_distance = 70.0 # Absolute minimum distance to prevent physical overlap
	var same_building_min_distance = 250.0 # How far away identical buildings must be
	var safe_spawn_radius = 80
	var spawn_point = $StartPosition.position
	
	# --- CLUSTER MAP ---
	var cluster_noise = FastNoiseLite.new()
	cluster_noise.seed = randi()
	cluster_noise.frequency = 0.025 # Creates distinct "islands" of obstacles
	
	# Dropped from 800 to 400 to heavily reduce overall map density
	var total_to_spawn = 300
	
	for i in range(total_to_spawn):
		var spawn_pos = Vector2.ZERO
		var is_valid_position = false
		var attempts = 0
		
		# Variables to hold our choice before we place it
		var scene_to_instantiate = null
		var is_building = false
		var resource_path = ""
		
		# Try up to 30 times to find a valid spot
		while not is_valid_position and attempts < 30:
			var margin = 100
			spawn_pos = Vector2(
				randf_range(-world_size / 2 + margin, world_size / 2 - margin),
				randf_range(-world_size / 2 + margin, world_size / 2 - margin)
			)
			
			# 1. Safe Zone Check
			if spawn_pos.distance_to(spawn_point) < safe_spawn_radius:
				attempts += 1
				continue
				
			# 2. CLUSTER CHECK (This forces everything to group together!)
			var n_val = cluster_noise.get_noise_2d(spawn_pos.x, spawn_pos.y)
			if n_val < 0.15: 
				# If noise is low, it's a Meadow. Force it to be empty!
				attempts += 1
				continue
				
			# 3. PRE-SELECT THE OBJECT
			# Since we are in a valid cluster, pick what we want to place here
			var rand = randf()
			if rand < 0.15 and building_scenes.size() > 0:       # 15% Buildings
				scene_to_instantiate = building_scenes.pick_random()
				is_building = true
			elif rand < 0.20 and statue_scene != null:           # 5% Statues
				scene_to_instantiate = statue_scene
			elif rand < 0.85 and tree_scenes.size() > 0:         # 65% Trees
				scene_to_instantiate = tree_scenes.pick_random()
			elif rock_scenes.size() > 0:                         # 15% Rocks
				scene_to_instantiate = rock_scenes.pick_random()
			else:
				attempts += 1
				continue
				
			# Grab the unique file path so we can identify exact duplicates
			resource_path = scene_to_instantiate.resource_path
			is_valid_position = true
			
			# 4. PROXIMITY & DUPLICATE CHECKS
			for placed in placed_objects:
				var dist = spawn_pos.distance_to(placed["pos"])
				
				# Rule A: Prevent clipping for everything
				if dist < min_distance:
					is_valid_position = false
					break
					
				# Rule B: Allow different buildings to be close, but ban identical ones!
				if is_building and placed["is_building"]:
					if dist < same_building_min_distance and resource_path == placed["path"]:
						is_valid_position = false
						break 
			
			attempts += 1
			
		# --- SPAWN LOGIC ---
		if is_valid_position and scene_to_instantiate != null:
			var blocker_instance = scene_to_instantiate.instantiate()
			
			# Save all the data into our dictionary list
			placed_objects.append({
				"pos": spawn_pos,
				"path": resource_path,
				"is_building": is_building
			})
			
			blocker_instance.position = spawn_pos
			
			# Add subtle random scaling to organic things
			if not is_building and not blocker_instance.name.contains("Statue"):
				var random_scale = randf_range(0.85, 1.15)
				blocker_instance.scale = Vector2(random_scale, random_scale)
				
			add_child(blocker_instance)
			

func setup_boundaries():
	var boundary_body = StaticBody2D.new()
	boundary_body.name = "MapBoundaries"
	
	# We use collision layer 1 so the Commander and Mobs collide with it
	add_child(boundary_body)
	
	var thickness = 200
	var half_size = world_size / 2
	
	# Define the 4 walls (Top, Bottom, Left, Right)
	var walls = [
		{"pos": Vector2(0, -half_size - thickness/2), "size": Vector2(world_size + thickness*2, thickness)}, # Top
		{"pos": Vector2(0, half_size + thickness/2), "size": Vector2(world_size + thickness*2, thickness)},  # Bottom
		{"pos": Vector2(-half_size - thickness/2, 0), "size": Vector2(thickness, world_size)}, # Left
		{"pos": Vector2(half_size + thickness/2, 0), "size": Vector2(thickness, world_size)}   # Right
	]
	
	# Build the walls
	for wall in walls:
		var collision = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = wall["size"]
		collision.shape = rect
		collision.position = wall["pos"]
		boundary_body.add_child(collision)
