extends Node

# @export var mob_scene: PackedScene

@onready var mob_spawner = $MobSpawner

# --- NODES ---
# Grab a reference to the screen you just dragged in
@onready var reinforcement_screen = $CanvasLayer/Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect the shop's deploy button to unpause the game
	reinforcement_screen.wave_started.connect(_on_wave_started)
	mob_spawner.set_wave_config([
		{"type": "bear", "weight": 0.5},
		{"type": "ghost", "weight": 0.8},
		{"type": "mushroom", "weight": 0.8},
		
	])
	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$CanvasLayer/UI.update_hp($Commander.hp)

func game_over() -> void:
	$MobTimer.stop()

func new_game():
	$Commander.start($StartPosition.position)
	$StartTimer.start()

func _on_mob_timer_timeout() -> void:
	# random spown position
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	# use mobspawner to generate a mob
	var mob = mob_spawner.spawn_random_mob(
		mob_spawn_location.position + Vector2(100, 0),
		$Commander
	)
	
	# add to scene
	add_child(mob)

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	
# --- SHOP LOGIC ---

func open_shop():
	# 1. Pause the game world
	get_tree().paused = true
	
	# 2. Show the shop
	reinforcement_screen.visible = true
	
	# 3. Tell the shop to generate new random cards
	reinforcement_screen.generate_shop_items()

func _on_wave_started():
	# Unpause the game world when "Deploy" is clicked
	get_tree().paused = false

# (Optional: Just for testing right now, let's open it when you press 'Tab')
func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next"): # Usually the 'Tab' key
		open_shop()
