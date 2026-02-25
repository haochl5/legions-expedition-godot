extends MobBase

# Added HIT and DYING states for better control
enum State { CHASE, WINDUP, ATTACK, COOLDOWN, HIT, DYING }
var current_state = State.CHASE

var attack_range = 35
var boss_damage = 3
var cooldown_timer = 0.0

func setup_behavior():
	max_hp = 500
	hp = max_hp
	speed = 30
	
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

func movement_pattern(delta: float):
	# If dying, do absolutely nothing
	if current_state == State.DYING:
		return

	if not target or not is_instance_valid(target):
		return
		
	var dist_to_target = global_position.distance_to(target.global_position)
	var dir_to_target = (target.global_position - global_position).normalized()
	
	match current_state:
		State.CHASE:
			if dist_to_target <= attack_range and cooldown_timer <= 0:
				start_windup(dir_to_target)
			else:
				velocity = dir_to_target * speed
				sprite.play("walk")
				sprite.flip_h = dir_to_target.x > 0 
				
			if cooldown_timer > 0:
				cooldown_timer -= delta
				
		State.WINDUP, State.ATTACK, State.HIT, State.COOLDOWN:
			# Stand still during these states
			velocity = Vector2.ZERO
			if current_state == State.COOLDOWN:
				cooldown_timer -= delta
				if cooldown_timer <= 0:
					current_state = State.CHASE

# --- ACTION FUNCTIONS ---

func start_windup(dir: Vector2):
	current_state = State.WINDUP
	sprite.play("charge_left" if dir.x < 0 else "charge_right")
	sprite.flip_h = false

func start_attack():
	current_state = State.ATTACK
	sprite.play("attack_left" if sprite.animation == "charge_left" else "attack_right")
	
	if target and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= attack_range + 20.0: 
			if target.has_method("take_damage"):
				target.take_damage(boss_damage, "Samurai Boss")

# --- OVERRIDES ---

func flash_red():
	# Ignore hits if already attacking or dying
	if current_state in [State.WINDUP, State.ATTACK, State.DYING]:
		return

	if sprite.sprite_frames.has_animation("hit"):
		current_state = State.HIT
		sprite.play("hit")
		velocity = Vector2.ZERO

func die():
	# 1. Prevent multiple death calls if hit by multiple bullets at once
	if current_state == State.DYING:
		return
		
	current_state = State.DYING
	
	# 2. Disable collisions immediately so the player can walk through the corpse
	collision.set_deferred("disabled", true)
	
	# 3. Create a "Death Effect" using a Tween
	var death_tween = create_tween().set_parallel(true)
	
	# Fade him out (Transparency)
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	
	# Shrink him slightly
	death_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.8)
	
	# Spin him a little bit for flair
	death_tween.tween_property(sprite, "rotation", deg_to_rad(90), 0.8)
	
	# 4. Wait for the tween to finish, then drop loot and delete
	death_tween.chain().tween_callback(func():
		drop_items()
		queue_free()
	)

func _on_animation_finished():
	match current_state:
		State.WINDUP:
			start_attack()
		State.ATTACK:
			current_state = State.COOLDOWN
			cooldown_timer = 1.0
			sprite.play("idle")
		State.HIT:
			current_state = State.CHASE
		State.DYING:
			# Only now do we actually remove him from the game
			call_deferred("drop_items")
			queue_free()

func drop_items():
	# We override the base loot logic to give the player a huge reward!
	
	# 1. Drop a massive burst of gold
	# We temporarily change the base variables just for this moment
	var original_gold_count = gold_drop_count
	var original_gold_spread = drop_spread_radius
	
	gold_drop_count = 15     # 15 coins instead of 3!
	drop_spread_radius = 100.0 # Spread them out in a wide circle
	
	drop_gold() # This calls the logic from MobBase
	
	# 2. Drop a high-value EXP burst
	var original_exp_count = exp_drop_count
	exp_drop_count = 10      # 10 gems instead of 3!
	exp_drop_spread_radius = 100.0
	
	drop_exp() # This calls the logic from MobBase
	
	# Reset variables back (good practice, though the boss is about to be deleted)
	gold_drop_count = original_gold_count
	drop_spread_radius = original_gold_spread
