extends Control

signal restart_game

# --- SHOP PRICES ---
var base_hp_cost = 50
var base_speed_cost = 100

@onready var status_label = $CenterContainer/VBoxContainer/GameOverStatus

# --- MAKE SURE YOU ADD THESE 3 NODES IN YOUR SCENE ---
@onready var crystal_label = $CenterContainer/VBoxContainer/CrystalLabel
@onready var hp_btn = $CenterContainer/VBoxContainer/HPUpgradeButton
@onready var speed_btn = $CenterContainer/VBoxContainer/SpeedUpgradeButton

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Automatically connect the upgrade buttons via code 
	# (so you don't have to use the Node tab in the editor)
	if hp_btn: hp_btn.pressed.connect(_on_hp_upgrade_pressed)
	if speed_btn: speed_btn.pressed.connect(_on_speed_upgrade_pressed)

func _process(delta: float) -> void:
	pass

func save_to_cloud():
	if Talo.current_player:
		Talo.current_player.set_prop("meta_crystals", str(GameData.meta_crystals))
		Talo.current_player.set_prop("upgrade_hp_level", str(GameData.upgrade_hp_level))
		Talo.current_player.set_prop("upgrade_speed_level", str(GameData.upgrade_speed_level))
		
		# Flush immediately so they don't lose it if they close the browser!
		Talo.events.flush()


# Your existing restart function
func _on_restart_button_pressed():
	restart_game.emit()

# Your existing function, updated to trigger the shop refresh!
func final_gold_level(gold: int, level: int):
	status_label.text = "Gold: %d\nLevel: %d" % [gold, level]
	
	# Update the shop UI right when the game over screen pops up
	if crystal_label:
		refresh_upgrade_ui()

# --- NEW: SHOP LOGIC ---
func refresh_upgrade_ui():
	# 1. Show current wallet
	crystal_label.text = "Meta Crystals: " + str(GameData.meta_crystals)
	
	# 2. Calculate current costs (Cost increases by 50% each level)
	var current_hp_cost = int(base_hp_cost * pow(1.5, GameData.upgrade_hp_level))
	var current_speed_cost = int(base_speed_cost * pow(1.5, GameData.upgrade_speed_level))
	
	# 3. Update Button Text
	hp_btn.text = "Upgrade Max HP (Lv %d) - Cost: %d" % [GameData.upgrade_hp_level, current_hp_cost]
	speed_btn.text = "Upgrade Speed (Lv %d) - Cost: %d" % [GameData.upgrade_speed_level, current_speed_cost]
	
	# 4. Disable buttons if the player is broke
	hp_btn.disabled = GameData.meta_crystals < current_hp_cost
	speed_btn.disabled = GameData.meta_crystals < current_speed_cost

func _on_hp_upgrade_pressed():
	var cost = int(base_hp_cost * pow(1.5, GameData.upgrade_hp_level))
	if GameData.meta_crystals >= cost:
		GameData.meta_crystals -= cost
		GameData.upgrade_hp_level += 1
		refresh_upgrade_ui() # Instantly update the text/buttons
		save_to_cloud()

func _on_speed_upgrade_pressed():
	var cost = int(base_speed_cost * pow(1.5, GameData.upgrade_speed_level))
	if GameData.meta_crystals >= cost:
		GameData.meta_crystals -= cost
		GameData.upgrade_speed_level += 1
		refresh_upgrade_ui()
		save_to_cloud()
