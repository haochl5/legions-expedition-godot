extends Node

@export var mob_scene: PackedScene
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()

func new_game():
	score = 0
	$Commander.start($StartPosition.position)
	$StartTimer.start()


func _on_mob_timer_timeout() -> void:
	# create new instance for Mob
	var mob = mob_scene.instantiate()
	
	# choose random location on Path2D
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	# Set the mob's position
	mob.position = mob_spawn_location.global_position
	
	# Direction toward the Player
	var direction = ($Commander.global_position - mob.position).normalized()
	
	# Set rotation so the mob faces the player
	mob.rotation = direction.angle()
	# Set velocity
	var velocity = randf_range(150.0, 250.0)
	mob.linear_velocity = direction * velocity
	
	# Spawn the mob
	add_child(mob)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()


func _on_score_timer_timeout() -> void:
	score += 1
