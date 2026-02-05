extends Node

@export var mob_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over() -> void:
	$MobTimer.stop()

func new_game():
	$Commander.start($StartPosition.position)
	$StartTimer.start()


func _on_mob_timer_timeout() -> void:
	# create new instance for Mob
	var mob = mob_scene.instantiate()
	
	# choose random location on Path2D
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	# Set the mob's position
	mob.position = mob_spawn_location.position + Vector2(100, 0)
	
	mob.target = $Commander
	
	# Spawn the mob
	add_child(mob)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
