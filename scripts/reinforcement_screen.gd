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
	# Facesets for Tier 3
	var knight_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Knight/Faceset.png")
	var samurai_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/Faceset.png")
	var sorcerer_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SorcererOrange/Faceset.png")
	
	# Facesets for Tier 4 (Update these paths if needed!)
	var monk_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Lion/Faceset.png")
	var priest_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Tengu2/Faceset.png")
	var ninja_face = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/RedGladiator/Faceset.png")

	# --- TIER 3 CHAMPIONS (Cost 3) ---
	var squire = ChampionData.new()
	squire.id = "squire"
	squire.display_name = "Squire"
	squire.role = "Tank"
	squire.icon = knight_face
	squire.cost = 3
	squire.description = "Melee tank. Every 4th hit unleashes a spinning AoE whirlwind."
	squire.unit_scene = preload("res://scenes/champions/Squire.tscn") 
	available_champions.append(squire)
	
	var ranger = ChampionData.new()
	ranger.id = "ranger"
	ranger.display_name = "Ranger"
	ranger.role = "DPS"
	ranger.icon = samurai_face
	ranger.cost = 3
	ranger.description = "Ranged attacker. Every 3rd shot fires a spread of 3 arrows."
	ranger.unit_scene = preload("res://scenes/champions/Ranger.tscn") 
	available_champions.append(ranger)

	var sorc = ChampionData.new()
	sorc.id = "sorcerer"
	sorc.display_name = "Sorcerer"
	sorc.role = "Mage"
	sorc.icon = sorcerer_face
	sorc.cost = 3
	sorc.description = "Magic user. Every 3rd attack fires a heavy explosive orb."
	sorc.unit_scene = preload("res://scenes/champions/Sorcerer.tscn") 
	available_champions.append(sorc)

	# --- TIER 4 CHAMPIONS (Cost 4) ---
	var pyro = ChampionData.new()
	pyro.id = "pyromancer"
	pyro.display_name = "Pyromancer"
	pyro.role = "Mage"
	pyro.icon = monk_face
	pyro.cost = 4
	pyro.description = "Spawns a persistent fire zone that rapidly burns enemies over time."
	pyro.unit_scene = preload("res://scenes/champions/Pyromancer.tscn") 
	available_champions.append(pyro)
	
	var storm = ChampionData.new()
	storm.id = "stormcaster"
	storm.display_name = "Stormcaster"
	storm.role = "Mage"
	storm.icon = priest_face
	storm.cost = 4
	storm.description = "Calls down instant, long-range lightning strikes from the sky."
	storm.unit_scene = preload("res://scenes/champions/stormcaster.tscn") 
	available_champions.append(storm)
	
	var assassin = ChampionData.new()
	assassin.id = "assassin"
	assassin.display_name = "Assassin"
	assassin.role = "Melee"
	assassin.icon = ninja_face
	assassin.cost = 4
	assassin.description = "Instantly dashes behind enemies for massive backstab damage."
	assassin.unit_scene = preload("res://scenes/champions/assasin.tscn") 
	available_champions.append(assassin)

# --- 2. SHOP LOGIC ---
func generate_shop_items():
	# Clear existing cards
	for child in cards_container.get_children():
		child.queue_free()
	
	# Create 3 new cards (simulating your random logic)
	for i in range(3):
		var card_instance = SHOP_CARD_SCENE.instantiate()
		var random_champ = get_random_champion()
		cards_container.add_child(card_instance)
		
		# Setup data and connect signal
		card_instance.setup(random_champ)
		card_instance.card_clicked.connect(_on_card_clicked)

func _on_card_clicked(data: ChampionData, card_ref: Control):
	if GameData.gold >= data.cost:
		GameData.gold -= data.cost
		
		Talo.events.track("buy_champion", {
			"champion_id": data.id,
			"cost": str(data.cost),
			"current_level": str(GameData.level)
		})
		
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
		
		# --- NEW: TALO TRACKING (Ignored Cards) ---
		# Loop through all the current cards before deleting them
		for child in cards_container.get_children():
			var buy_btn = child.get_node("VBoxContainer/BuyButton")
			
			# If the button isn't disabled, it means the player didn't buy it!
			if not buy_btn.disabled:
				# We safely grab the champion's ID from 'my_data'
				var champ_id = "unknown"
				if "my_data" in child and child.my_data:
					champ_id = child.my_data.id
					
				Talo.events.track("shop_card_skipped", {
					"champion_id": champ_id,
					"current_level": str(GameData.level)
				})
		# ------------------------------------------
		
		Talo.events.track("shop_reroll", {
			"current_level": str(GameData.level)
		})
		
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


# --- CUSTOM RANDOM PICKER ---
func get_random_champion() -> ChampionData:
	var roll = randf() # Rolls a random decimal between 0.0 and 1.0
	var target_cost = 3
	
	# 30% chance to roll a Tier 4 champion. 70% chance for Tier 3.
	if roll > 0.70: 
		target_cost = 4
		
	# Gather all champions that match the target cost
	var valid_pool = available_champions.filter(func(champ): return champ.cost == target_cost)
	
	# Failsafe: if something goes wrong, just grab anyone
	if valid_pool.is_empty():
		return available_champions.pick_random()
		
	return valid_pool.pick_random()
