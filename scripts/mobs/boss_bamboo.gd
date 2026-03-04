extends MobBase

# Bamboo Boss: only uses animations: walk, idle, charge, attack, hit
# No left/right animations, no flipping.

enum State { CHASE, WINDUP, ATTACK, COOLDOWN, HIT, DYING }
var current_state: State = State.CHASE

@export var attack_range: float = 35.0
@export var boss_damage: int = 3
@export var cooldown_duration: float = 1.0

var cooldown_timer: float = 0.0


func setup_behavior():
	mob_name = "Bamboo Boss"
	max_hp = 500
	hp = max_hp
	speed = 30

	# Make sure we can chain charge -> attack -> cooldown based on animation end
	if sprite and not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)


func movement_pattern(delta: float) -> void:
	# If dying, do absolutely nothing
	if current_state == State.DYING:
		return

	if not target or not is_instance_valid(target):
		return

	var dist_to_target := global_position.distance_to(target.global_position)
	var dir_to_target := (target.global_position - global_position).normalized()

	match current_state:
		State.CHASE:
			# Cooldown ticking
			if cooldown_timer > 0.0:
				cooldown_timer -= delta

			if dist_to_target <= attack_range and cooldown_timer <= 0.0:
				start_windup()
			else:
				velocity = dir_to_target * speed
				# Only one walk animation, no flip
				if sprite:
					sprite.play("walk")

		State.WINDUP, State.ATTACK, State.HIT, State.COOLDOWN:
			velocity = Vector2.ZERO

			if current_state == State.COOLDOWN:
				cooldown_timer -= delta
				if cooldown_timer <= 0.0:
					current_state = State.CHASE


# --- ACTION FUNCTIONS ---

func start_windup() -> void:
	current_state = State.WINDUP
	if sprite:
		sprite.play("charge")


func start_attack() -> void:
	current_state = State.ATTACK
	if sprite:
		sprite.play("attack")

	# Apply damage once at the start of ATTACK (simple + reliable)
	if target and is_instance_valid(target):
		if global_position.distance_to(target.global_position) <= attack_range + 20.0:
			if target.has_method("take_damage"):
				target.take_damage(boss_damage, mob_name)


# --- OVERRIDES ---

func flash_red() -> void:
	# Ignore hits if already winding up, attacking, or dying
	if current_state in [State.WINDUP, State.ATTACK, State.DYING]:
		return

	# If you have a "hit" animation, play it; otherwise fall back to base behavior if needed
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hit"):
		current_state = State.HIT
		sprite.play("hit")
		velocity = Vector2.ZERO


func die() -> void:
	# Prevent multiple death calls
	if current_state == State.DYING:
		return

	current_state = State.DYING

	# Disable collisions immediately
	if collision:
		collision.set_deferred("disabled", true)

	# Tween death effect (no dying animation required)
	var death_tween = create_tween().set_parallel(true)

	if sprite:
		death_tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
		death_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.8)
		death_tween.tween_property(sprite, "rotation", deg_to_rad(90), 0.8)

	death_tween.chain().tween_callback(func():
		drop_items()
		queue_free()
	)


func _on_animation_finished() -> void:
	# Only react to animations when not dying
	if current_state == State.DYING:
		return

	match current_state:
		State.WINDUP:
			# charge finished -> attack
			start_attack()

		State.ATTACK:
			# attack finished -> cooldown -> idle
			current_state = State.COOLDOWN
			cooldown_timer = cooldown_duration
			if sprite:
				sprite.play("idle")

		State.HIT:
			# hit finished -> chase
			current_state = State.CHASE


func drop_items() -> void:
	# If you want bamboo drops same as samurai, keep these values.
	# If not, adjust them here.

	var original_gold_count = gold_drop_count
	var original_gold_spread = drop_spread_radius
	var original_exp_count = exp_drop_count
	var original_exp_spread = exp_drop_spread_radius

	gold_drop_count = 15
	drop_spread_radius = 100.0
	drop_gold()

	exp_drop_count = 10
	exp_drop_spread_radius = 100.0
	drop_exp()

	# Reset (good practice)
	gold_drop_count = original_gold_count
	drop_spread_radius = original_gold_spread
	exp_drop_count = original_exp_count
	exp_drop_spread_radius = original_exp_spread
