extends Node

# @export var mob_scene: PackedScene

@onready var mob_spawner = $MobSpawner

# --- NODES --- 
# Grab a reference to the screen you just dragged in
@onready var reinforcement_screen = $CanvasLayer/Control
@onready var title_screen = $CanvasLayer/TitleScreen
@onready var game_over_screen = $CanvasLayer/GameOverScreen
@onready var ingame_UI = $CanvasLayer/UI

# Talo
var _game_start_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
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
	title_screen_ready()
	
	# for Talo
	await _init_player()
	
	
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
	game_over_screen.hide()
	ingame_UI.hide()
	title_screen.show()
	
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
	
	# HP is usually still on the Commander because it's physical, 
	# but you can move that too if you want stats to persist between runs!
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
	
	# Refresh the shop UI with the correct Global Gold
	reinforcement_screen.on_shop_opened()
