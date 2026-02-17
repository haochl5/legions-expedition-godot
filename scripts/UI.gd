extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update_hp(current_hp: int, max_hp: int):
	$HPContainer/HPBar.max_value = max_hp
	$HPContainer/HPBar.value = current_hp
	$HPContainer/HPLabel.text = "HP: " + str(current_hp) + "/ 10"

func update_gold(current_gold: int):
	$GoldLabel.text = str(current_gold) + " G"

func update_exp(current: int, maximum: int):
	$EXPContainer/EXPBar.max_value = maximum
	$EXPContainer/EXPBar.value = current

func update_level(level: int):
	$EXPContainer/LevelLabel.text = "Level: " + str(level)
