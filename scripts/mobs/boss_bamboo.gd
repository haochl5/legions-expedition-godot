extends MobBase

# Bamboo Boss: periodic radial wave attack using stationary spikes.
# Wave effect is created by spawning spikes further away with small delays.

enum State { CHASE, WINDUP, COOLDOWN, HIT, DYING }
var current_state: State = State.CHASE

# --- Basic combat tuning ---
@export var attack_interval_sec: float = 5.0
@export var cooldown_after_attack: float = 0.5

@export var move_speed: float = 30.0
@export var max_health: int = 500

# --- Wave pattern tuning (the "shockwave" feeling) ---
@export var wave_segments: int = 7          # How many "steps" per direction
@export var start_distance: float = 40.0    # First spike distance from boss
@export var segment_spacing: float = 55.0   # Distance between steps
@export var step_delay: float = 0.06        # Delay between steps (controls wave speed)

# --- Damage tuning for spikes ---
@export var spike_damage: int = 1

# Drag & drop your bamboo_spike.tscn here in the Inspector (recommended).
@export var bamboo_spike_scene: PackedScene

# If you prefer hardcoding, set a correct path in your project.
const DEFAULT_SPIKE_PATH := "res://scenes/Projectiles/Bamboo_Spike.tscn"

var _attack_timer: Timer
var _is_casting: bool = false


func _ready() -> void:
	# Call base class _ready() (sets hp, connects notifier, calls setup_behavior, etc.)
	super._ready()

	# Start a repeating timer for periodic attacks
	_attack_timer = Timer.new()
	_attack_timer.wait_time = attack_interval_sec
	_attack_timer.one_shot = false
	_attack_timer.autostart = true
	add_child(_attack_timer)
	_attack_timer.timeout.connect(_on_attack_timer_timeout)


func setup_behavior() -> void:
	mob_name = "Bamboo Boss"
	max_hp = max_health
	hp = max_hp
	speed = move_speed

	sprite.animation_finished.connect(_on_animation_finished)

func movement_pattern(delta: float) -> void:
	# Do nothing if dying
	if current_state == State.DYING:
		velocity = Vector2.ZERO
		return

	if not target or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	match current_state:
		State.CHASE:
			var dir := (target.global_position - global_position).normalized()
			velocity = dir * speed
			if sprite:
				sprite.play("walk")

		State.WINDUP, State.COOLDOWN, State.HIT:
			# Stand still during casting / cooldown / hit reaction
			velocity = Vector2.ZERO


# -------------------------
# Periodic attack trigger
# -------------------------

func _on_attack_timer_timeout() -> void:
	
	if current_state == State.DYING: return
	if _is_casting: 
		return
	if current_state in [State.WINDUP, State.COOLDOWN]:
		return

	start_windup()


func start_windup() -> void:
	_is_casting = true
	current_state = State.WINDUP

	if sprite:
		if sprite.sprite_frames.has_animation("charge"):
			sprite.play("charge")
		else:
			_on_animation_finished() 
	else:
		_on_animation_finished()


# -------------------------
# Animation chaining
# -------------------------

func _on_animation_finished() -> void:
	var anim_name = sprite.animation if sprite else "unknown"

	if current_state == State.DYING: return

	if current_state == State.WINDUP:
		_do_radial_wave() 

		current_state = State.COOLDOWN
		if sprite and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

		_finish_cast_after_delay()


func _finish_cast_after_delay() -> void:
	# Use a one-shot timer to end cooldown and allow next cast.
	var t := get_tree().create_timer(cooldown_after_attack)
	t.timeout.connect(func():
		if current_state != State.DYING:
			current_state = State.CHASE
		_is_casting = false
	)


# -------------------------
# Radial wave logic
# -------------------------

func _do_radial_wave() -> void:
	if bamboo_spike_scene == null:
		if ResourceLoader.exists(DEFAULT_SPIKE_PATH):
			bamboo_spike_scene = load(DEFAULT_SPIKE_PATH)
		else:
			_is_casting = false
			current_state = State.CHASE
			return

	var dirs := [
		Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP,
		Vector2(1, 1).normalized(), Vector2(1, -1).normalized(),
		Vector2(-1, 1).normalized(), Vector2(-1, -1).normalized()
	]

	_spawn_wave_sequential(dirs)


func _spawn_wave_async(dirs: Array) -> void:
	# Fire-and-forget async function state
	_spawn_wave_coroutine(dirs)


func _spawn_wave_coroutine(dirs: Array) -> void:
	# This function uses await timers. It will naturally stop doing useful work if boss dies.
	# Note: In GDScript, calling it starts execution until the first await.

	# We use an inner async style via create_timer().timeout connections to avoid deep nesting.
	# Simpler: sequential awaits per segment.
	_call_spawn_wave_sequential(dirs)


func _call_spawn_wave_sequential(dirs: Array) -> void:
	# Run as a coroutine using await
	_spawn_wave_sequential(dirs)


@warning_ignore("unused_parameter")
func _spawn_wave_sequential(dirs: Array) -> void:
	for i in range(wave_segments):
		if current_state == State.DYING or not is_instance_valid(self):
			return

		var dist := start_distance + float(i) * segment_spacing

		for dir in dirs:
			_spawn_one_spike(global_position + dir * dist)

		await get_tree().create_timer(step_delay).timeout

func _spawn_one_spike(pos: Vector2) -> void:
	var spike = bamboo_spike_scene.instantiate()
	spike.global_position = pos
	

	if "damage" in spike:
		spike.damage = spike_damage
	
	var root = get_tree().current_scene
	root.add_child(spike)


# -------------------------
# Hit / death overrides
# -------------------------

func flash_red() -> void:
	# Optional hit reaction, only if "hit" animation exists
	if current_state in [State.WINDUP, State.DYING]:
		return

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hit"):
		current_state = State.HIT
		sprite.play("hit")
		velocity = Vector2.ZERO

		# Return to chase shortly after hit (or when animation ends if you prefer)
		get_tree().create_timer(0.15).timeout.connect(func():
			if current_state != State.DYING:
				current_state = State.CHASE
		)
	else:
		# Fallback to base red flash effect
		super.flash_red()


func die() -> void:
	# Prevent multiple death calls
	if current_state == State.DYING:
		return

	current_state = State.DYING
	_is_casting = false

	# Stop periodic attacks
	if _attack_timer:
		_attack_timer.stop()

	# Disable collision immediately
	if collision:
		collision.set_deferred("disabled", true)

	# Death tween effect (no death animation required)
	var death_tween := create_tween().set_parallel(true)

	if sprite:
		death_tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
		death_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.8)
		death_tween.tween_property(sprite, "rotation", deg_to_rad(90), 0.8)

	death_tween.chain().tween_callback(func():
		drop_items()
		queue_free()
	)
