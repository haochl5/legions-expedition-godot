extends Control

signal restart_game

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_restart_button_pressed():
	restart_game.emit()

func final_gold_level(gold: int, level: int):
	$CenterContainer/VBoxContainer/GameOverStatus.text = "Gold: %d\nLevel: %d" % [gold, level]
