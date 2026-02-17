extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update_hp(current_hp: int):
	$HPLabel.text = "HP: " + str(current_hp) + "/ 10"

func update_gold(current_gold: int):
	$GoldLabel.text = str(current_gold) + " G"
