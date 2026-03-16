extends MobBase

# Using the Boss State logic you like
enum State { CHASE, ATTACK, HIT, DYING }
var current_state = State.CHASE

@export var fire_projectile_scene: PackedScene
@export var preferred_distance: float = 250.0 
@export var stop_threshold: float = 20.0      
@export var attack_cooldown: float = 2.0
@export var accuracy_variance: float = 0.3

var shoot_timer: float = 0.0

func setup_behavior():
	mob_name = "Flamethrower"
	max_hp = 15
	hp = max_hp
	speed = 25.0
	
	# Match the Boss signal connection
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

func movement_pattern(delta: float):
	if current_state == State.DYING:
		return

	if not target or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
		
	var dist_to_target = global_position.distance_to(target.global_position)
	var dir_to_target = (target.global_position - global_position).normalized()
	
	match current_state:
		State.CHASE:
			# Distance logic for long-range unit
			if dist_to_target > preferred_distance + stop_threshold:
				velocity = dir_to_target * speed
				sprite.play("movement")
			elif dist_to_target < preferred_distance - stop_threshold:
				velocity = -dir_to_target * (speed * 0.5)
				sprite.play("movement")
			else:
				# In the Sweet Spot: Wait to shoot
				velocity = Vector2.ZERO
				sprite.play("movement") # Or "idle" if you have one
				
				if shoot_timer <= 0:
					start_attack_sequence()
			
			if shoot_timer > 0:
				shoot_timer -= delta
				
		State.ATTACK, State.HIT:
			velocity = Vector2.ZERO

	# Flip sprite logic
	if dir_to_target.x != 0:
		sprite.flip_h = dir_to_target.x > 0

# --- ACTION FUNCTIONS ---

func start_attack_sequence():
	current_state = State.ATTACK
	if sprite.sprite_frames.has_animation("fire"):
		sprite.play("fire")
	else:
		# Fallback if fire anim is missing
		_spawn_projectile()
		_on_attack_finished()

func _spawn_projectile():
	if not fire_projectile_scene: return
	
	var dir_to_target = (target.global_position - global_position).normalized()
	var proj = fire_projectile_scene.instantiate()
	
	var random_offset = randf_range(-accuracy_variance, accuracy_variance)
	var final_dir = dir_to_target.rotated(random_offset)
	
	proj.direction = final_dir
	proj.global_position = global_position
	get_parent().add_child(proj)

func _on_attack_finished():
	current_state = State.CHASE
	shoot_timer = attack_cooldown

# --- OVERRIDES ---

func flash_red():
	if current_state == State.DYING:
		return

	if sprite.sprite_frames.has_animation("hit"):
		current_state = State.HIT
		sprite.play("hit")
		velocity = Vector2.ZERO
	
	# Always call the red color flash from MobBase
	super.flash_red()

func _on_animation_finished():
	match current_state:
		State.ATTACK:
			_spawn_projectile()
			_on_attack_finished()
		State.HIT:
			current_state = State.CHASE
		State.DYING:
			queue_free()

func die():
	if current_state == State.DYING: return
	current_state = State.DYING
	
	collision.set_deferred("disabled", true)
	drop_items()
	
	# Quick fade out like the boss
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
