extends Control

# Preload the card scene we made in Step 2
const SHOP_CARD_SCENE = preload("res://scenes/ShopCard.tscn")

# Signals to communicate with the main Game Loop
signal unit_purchased(unit_data: ChampionData)
signal wave_started

# State
var available_champions: Array[ChampionData] = []
var available_buffs: Array[ChampionData] = []

# UI References
@onready var bank_label = $VBoxContainer/BankLabel
@onready var cards_container = $VBoxContainer/CardsContainer
@onready var lock_shop_btn = $VBoxContainer/Buttons/LockShopButton
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
	
	# Facesets for Lifepot
	var lifepot_face = preload("res://assets/Ninja Adventure - Asset Pack/Items/Potion/LifePot.png")
	var damage_face = preload("res://assets/Ninja Adventure - Asset Pack/Items/Food/Beaf.png")
	var firerate_face = preload("res://assets/Ninja Adventure - Asset Pack/Items/Object/Hourglass.png")
	var barrel_face = preload("res://assets/Ninja Adventure - Asset Pack/Items/Projectile/Shuriken.png")

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
	
	# --- LIFEPOT (Cost 10) ---
	# --- LIFEPOT (Cost 10) ---
	var lifepot = ChampionData.new()
	lifepot.id = "lifepot"
	lifepot.display_name = "Life Pot"
	lifepot.role = "Item"
	lifepot.icon = lifepot_face
	lifepot.cost = 10

	# Use hp field as "heal amount" (because ShopCard already displays HP)
	lifepot.hp = 3
	lifepot.skill_name = "Heal"
	lifepot.description = "Instantly heals the Commander by 3 HP."
	lifepot.unit_scene = null # IMPORTANT: not a Champion scene
	available_champions.append(lifepot)
	
	# --- PLAYER BUFFS ---
	# You can reuse the lifepot icon or add new icons later!
	var buff_dmg = ChampionData.new()
	buff_dmg.id = "buff_damage"
	buff_dmg.display_name = "Hollow Points"
	buff_dmg.role = "Player Buff"
	buff_dmg.icon = damage_face 
	buff_dmg.cost = 10
	buff_dmg.description = "Increases Commander bullet damage by 5."
	buff_dmg.unit_scene = null
	available_buffs.append(buff_dmg)

	var buff_spd = ChampionData.new()
	buff_spd.id = "buff_firerate"
	buff_spd.display_name = "Hair Trigger"
	buff_spd.role = "Player Buff"
	buff_spd.icon = firerate_face
	buff_spd.cost = 10
	buff_spd.description = "Increases Commander shooting speed by 15%."
	buff_spd.unit_scene = null
	available_buffs.append(buff_spd)

	var buff_multi = ChampionData.new()
	buff_multi.id = "buff_multishot"
	buff_multi.display_name = "Twin Barrels"
	buff_multi.role = "Player Buff"
	buff_multi.icon = barrel_face
	buff_multi.cost = 10
	buff_multi.description = "Fires an additional bullet in a spread pattern."
	buff_multi.unit_scene = null
	available_buffs.append(buff_multi)

# --- 2. SHOP LOGIC ---
func generate_shop_items():
	for child in cards_container.get_children():
		child.queue_free()
	
	# 1. Roll to see if a Player Buff appears (e.g., 25% chance)
	var show_buff = randf() < 0.25 
	# If true, pick a random slot (0, 1, or 2) for the buff to sit in
	var buff_slot = randi() % 3 if show_buff else -1
	
	for i in range(3):
		var card_instance = SHOP_CARD_SCENE.instantiate()
		var chosen_data: ChampionData
		
		# 2. Check if this specific slot is the chosen Buff Slot
		if i == buff_slot:
			chosen_data = available_buffs.pick_random()
		else:
			chosen_data = get_random_champion() # Normal unit/lifepot logic
			
		cards_container.add_child(card_instance)
		card_instance.setup(chosen_data)
		card_instance.card_clicked.connect(_on_card_clicked)


func _on_card_clicked(data: ChampionData, card_ref: Control):
	if GameData.gold >= data.cost:
		GameData.gold -= data.cost
		
		GameData.gold_spent_in_game += data.cost
		
		
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
		
		# If they manually hit reroll, pop the button back up!
		if lock_shop_btn.button_pressed:
			lock_shop_btn.button_pressed = false
			
		generate_shop_items()
		update_ui()

func _on_deploy_pressed():
	wave_started.emit()
	self.visible = false # Hide shop

func update_ui():
	bank_label.text = "BANK: %d g" % GameData.gold
	
func on_shop_opened():
	update_ui()
	
	# Check the button's built-in pressed property
	if lock_shop_btn.button_pressed:
		# The shop is locked! We DO NOT generate new items.
		# Automatically un-toggle the lock button so it pops back up!
		lock_shop_btn.button_pressed = false 
		print("Shop was locked! Keeping previous cards.")
	else:
		generate_shop_items()

# Connect Buttons via Editor or _ready
func _on_reroll_btn_down():
	_on_reroll_pressed()

func _on_deploy_btn_down():
	_on_deploy_pressed()


# --- CUSTOM RANDOM PICKER ---
func get_random_champion() -> ChampionData:
	var roll = randf()
	# 10% chance to show LifePot
	if roll > 0.90:
		var items = available_champions.filter(func(x): return x.id == "lifepot")
		if not items.is_empty():
			return items.pick_random()

	var target_cost = 3
	if roll > 0.70:
		target_cost = 4

	var valid_pool = available_champions.filter(func(champ): return champ.cost == target_cost)
	if valid_pool.is_empty():
		return available_champions.pick_random()
	return valid_pool.pick_random()

func _on_lock_shop_toggled(toggled_on: bool):
	if toggled_on:
		lock_shop_btn.text = "LOCKED"
		# Optional: Tint it red so the player definitely notices it's active
		lock_shop_btn.modulate = Color(0.9, 0.3, 0.3) 
	else:
		lock_shop_btn.text = "Lock Shop"
		lock_shop_btn.modulate = Color(1, 1, 1) # Resets to normal
