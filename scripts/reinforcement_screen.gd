extends Control

# Preload the card scene we made in Step 2
const SHOP_CARD_SCENE = preload("res://scenes/ShopCard.tscn")

# Signals to communicate with the main Game Loop
signal unit_purchased(unit_data: ChampionData)
signal wave_started

# State
var gold: int = 10 # Starting gold for testing
var available_champions: Array[ChampionData] = []

# UI References
@onready var bank_label = $VBoxContainer/BankLabel
@onready var cards_container = $VBoxContainer/CardsContainer

func _ready():
	_init_champion_database()
	update_ui()
	generate_shop_items()

# --- 1. DATA INITIALIZATION (The 3 Champions) ---
func _init_champion_database():
	# In a real project, you would load these from .tres files.
	# Here, we create them via code to match your request immediately.
	# (Make sure this path matches exactly where you put it in your FileSystem!)
	var samurai_face1 = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiRed/Faceset.png")
	var samurai_face2 = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/Faceset.png")
	var samurai_face3 = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Samurai/Faceset.png")
	# 1. SQUIRE (Tank)
	var squire = ChampionData.new()
	squire.id = "squire"
	squire.display_name = "Squire"
	squire.icon = samurai_face1
	squire.role = "Tank"
	squire.sprite = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiRed/SeparateAnim/Idle.png")
	squire.cost = 3
	squire.hp = 120
	squire.skill_name = "Iron Will"
	squire.description = "Gains Shield & emits Burning Aura."
	available_champions.append(squire)
	
	# 2. RANGER (DPS)
	var ranger = ChampionData.new()
	ranger.id = "ranger"
	ranger.icon = samurai_face2
	ranger.sprite = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Idle.png")
	ranger.display_name = "Ranger"
	ranger.role = "DPS"
	ranger.cost = 3
	ranger.hp = 60
	ranger.skill_name = "Magic Arrows"
	ranger.description = "Arrows gain velocity & pierce."
	available_champions.append(ranger)

	# 3. ALCHEMIST (Mage)
	var alch = ChampionData.new()
	alch.id = "alchemist"
	alch.icon = samurai_face3
	alch.display_name = "Alchemist"
	alch.sprite = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Samurai/SeparateAnim/Idle.png")
	alch.role = "Mage"
	alch.cost = 3
	alch.hp = 60
	alch.skill_name = "Concoction"
	alch.description = "Explosives leave Acid Pools."
	available_champions.append(alch)

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
	if gold >= data.cost:
		gold -= data.cost
		
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
	if gold >= 2:
		gold -= 2
		generate_shop_items()
		update_ui()

func _on_deploy_pressed():
	wave_started.emit()
	self.visible = false # Hide shop

func update_ui():
	bank_label.text = "BANK: %d g" % gold

# Connect Buttons via Editor or _ready
func _on_reroll_btn_down():
	_on_reroll_pressed()

func _on_deploy_btn_down():
	_on_deploy_pressed()
