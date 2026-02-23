extends Node

# --- MAP GENERATION EXPORTS ---
@export var tree_scene: PackedScene
@export var rock_scene: PackedScene
@export var building_scene: PackedScene

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
	
	# Generate the world right when the scene loads!
	generate_ground()
	spawn_blockers()
	setup_boundaries()
	
	# for Talo
	await _init_player()
	
	# Connect the shop's deploy button to unpause the game
	reinforcement_screen.wave_started.connect(_on_wave_started)
	GameData.leveled_up.connect(_on_level_up)
	mob_spawner.set_wave_config([
		{"type": "bear", "weight": 0.5},
		{"type": "ghost", "weight": 0.8},
		{"type": "mushroom", "weight": 0.8},
		
	])
	title_screen.start_game.connect(_on_start_game)
	game_over_screen.restart_game.connect(_on_restart_game)
	
	
func _init_player() -> void:
	var saved_id = ""
	
	if OS.get_name() == "Web":
		saved_id = JavaScriptBridge.eval("localStorage.getItem('talo_player_id') || ''")
	
	if saved_id != "":
		await Talo.players.identify("guest", saved_id)
	else:
		await Talo.players.identify("guest", Talo.players.generate_identifier())
		if OS.get_name() == "Web":
			var new_id = Talo.current_alias.identifier
			JavaScriptBridge.eval("localStorage.setItem('talo_player_id', '%s')" % new_id)
	
	print("Talo player ID: ", Talo.current_alias.identifier)
	
func title_screen_ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	title_screen.show()
	game_over_screen.hide()
	ingame_UI.hide()
	
func _on_start_game():
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
	var mob_spawn_location = $Commander/MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	# use mobspawner to generate a mob
	var mob = mob_spawner.spawn_random_mob(
		mob_spawn_location.global_position + Vector2(100, 0),
		$Commander
	)
	
	# add to scene
	add_child(mob)

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	
# --- SHOP LOGIC ---
func _on_wave_started():
	# Unpause the game world when "Deploy" is clicked
	get_tree().paused = false

# (Optional: Just for testing right now, let's open it when you press 'Tab')
func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next"): # Usually the 'Tab' key
		open_shop()
		
func _on_level_up(new_level: int):
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
	if not tree_scene or not rock_scene or not building_scene:
		print("WARNING: Blocker scenes are not assigned in the Main Inspector!")
		return
		
	var valid_positions: Array[Vector2] = []
	var min_distance = 120.0 # How far apart obstacles must be (tweak this!)
	var safe_spawn_radius = 400.0 # How big the empty circle around the player is
	var spawn_point = $StartPosition.position
		
	for i in range(num_blockers):
		var blocker_instance
		var rand_type = randf()
		
		if rand_type < 0.5:
			blocker_instance = tree_scene.instantiate()
		elif rand_type < 0.8:
			blocker_instance = rock_scene.instantiate()
		else:
			blocker_instance = building_scene.instantiate()
			
		var spawn_pos = Vector2.ZERO
		var is_valid_position = false
		var attempts = 0
		
		# Try up to 15 times to find a valid spot for this blocker
		while not is_valid_position and attempts < 15:
			var margin = 64
			var spawn_x = randf_range(-world_size / 2 + margin, world_size / 2 - margin)
			var spawn_y = randf_range(-world_size / 2 + margin, world_size / 2 - margin)
			spawn_pos = Vector2(spawn_x, spawn_y)
			
			is_valid_position = true
			
			# 1. Check Player Spawn Safe Zone
			if spawn_pos.distance_to(spawn_point) < safe_spawn_radius:
				is_valid_position = false
				attempts += 1
				continue
				
			# 2. Check Overlap with previously placed blockers
			for pos in valid_positions:
				if spawn_pos.distance_to(pos) < min_distance:
					is_valid_position = false
					break
			
			attempts += 1
			
		# If we found a good spot after trying, place it!
		if is_valid_position:
			valid_positions.append(spawn_pos)
			blocker_instance.position = spawn_pos
			add_child(blocker_instance)
		else:
			# If we couldn't find a spot after 15 tries (map is getting full), delete it
			blocker_instance.queue_free()

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
