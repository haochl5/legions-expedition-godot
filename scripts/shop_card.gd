extends PanelContainer

signal card_clicked(data: ChampionData, card_ref: Control)

var my_data: ChampionData

@onready var name_lbl = $VBoxContainer/NameLabel
@onready var role_lbl = $VBoxContainer/RoleLabel
@onready var desc_lbl = $VBoxContainer/DescLabel
@onready var icon_rect = $VBoxContainer/IconRect
@onready var buy_btn = $VBoxContainer/BuyButton

func setup(data: ChampionData):
	my_data = data
	name_lbl.text = data.display_name
	role_lbl.text = "%s | HP: %d" % [data.role, data.hp]
	desc_lbl.text = "%s: %s" % [data.skill_name, data.description]
	buy_btn.text = "%d Gold" % data.cost
	
	# Apply color styling similar to HTML CSS
	self.modulate = data.color 
	
	# Connect the button internally
	if not buy_btn.pressed.is_connected(_on_buy_pressed):
		buy_btn.pressed.connect(_on_buy_pressed)

func _on_buy_pressed():
	# Emit signal up to the Shop Screen
	card_clicked.emit(my_data, self)
