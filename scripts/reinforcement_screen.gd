extends Control

# Preload the card scene we made in Step 2
const SHOP_CARD_SCENE = preload("res://scenes/ShopCard.tscn")

# Signals to communicate with the main Game Loop
signal unit_purchased(unit_data: ChampionData)
signal wave_started

# State
var available_champions: Array[ChampionData] = []

# UI References
@onready var bank_label = $VBoxContainer/BankLabel
@onready var cards_container = $VBoxContainer/CardsContainer



func _ready():
	_init_champion_database()

# --- 1. DATA INITIALIZATION (The 3 Champions) ---
func _init_champion_database():
	# In a real project, you would load these from .tres files.
	# Here, we create them via code to match your request immediately.
	# (Make sure this path matches exactly where you put it in your FileSystem!)
	var knight_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/Faceset.png")
	var samurai_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/Faceset.png")
	var sorcerer_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/Faceset.png")
	# 1. SQUIRE
	var squire = ChampionData.new()
	squire.id = "squire"
	squire.display_name = "Squire"
	squire.role = "Tank"
	squire.icon = knight_face
	squire.cost = 3
	squire.hp = 120
	# CHANGE: Load the SCENE, not the png
	squire.unit_scene = preload("res://scenes/champions/Squire.tscn") 
	available_champions.append(squire)
	
	# 2. RANGER
	var ranger = ChampionData.new()
	ranger.id = "ranger"
	ranger.display_name = "Ranger"
	ranger.role = "DPS"
	ranger.icon = samurai_face
	ranger.cost = 3
	ranger.hp = 60
	# CHANGE: Load the SCENE
	ranger.unit_scene = preload("res://scenes/champions/Ranger.tscn") 
	available_champions.append(ranger)

	# 3. SORCERER (Replaces Alchemist)
	var sorc = ChampionData.new()
	sorc.id = "sorcerer"
	sorc.display_name = "Sorcerer"
	sorc.role = "Mage"
	sorc.icon = sorcerer_face # Or your new Sorcerer face
	sorc.cost = 3
	sorc.hp = 60
	# CHANGE: Load the SCENE
	sorc.unit_scene = preload("res://scenes/champions/Sorcerer.tscn") 
	available_champions.append(sorc)

# --- 2. SHOP LOGIC ---
func generate_shop_items():
	# Clear existing cards
	for child in cards_container.get_children():
		child.queue_free()
	
	# Create 3 new cards (simulating your random logic)
	for i in range(3):
		var card_instance = SHOP_CARD_SCENE.instantiate()
		var random_champ = available_champions.pick_random()
		cards_container.add_child(card_instance)
		
		# Setup data and connect signal
		card_instance.setup(random_champ)
		card_instance.card_clicked.connect(_on_card_clicked)

func _on_card_clicked(data: ChampionData, card_ref: Control):
	if GameData.gold >= data.cost:
		GameData.gold -= data.cost
		
		# Visual feedback (Hide card effectively "buying" it)
		# In Godot, usually better to disable or replace with "Sold" label
		card_ref.modulate.a = 0.5
		card_ref.get_node("VBoxContainer/BuyButton").disabled = true
		card_ref.get_node("VBoxContainer/BuyButton").text = "DEPLOYED"
		
		unit_purchased.emit(data)
		update_ui()
	else:
		# Shake animation or sound could go here
		print("Not enough gold!")

func _on_reroll_pressed():
	if GameData.gold >= 2:
		GameData.gold -= 2
		generate_shop_items()
		update_ui()

func _on_deploy_pressed():
	wave_started.emit()
	self.visible = false # Hide shop

func update_ui():
	bank_label.text = "BANK: %d g" % GameData.gold
	
func on_shop_opened():
	update_ui()
	generate_shop_items()

# Connect Buttons via Editor or _ready
func _on_reroll_btn_down():
	_on_reroll_pressed()

func _on_deploy_btn_down():
	_on_deploy_pressed()
