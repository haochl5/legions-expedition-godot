extends Area2D

signal hit

# Movement parameters
var base_speed: float = 80  
var current_speed: float = 80
const DASH_SPEED = 500
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 2.0

# Health
var max_hp = 10
var hp = max_hp

# Invincibility after being hit
const INVINCIBILITY_TIME = 1.0
var is_invincible = false
var invincibility_timer = 0.0

# Shooting parameters
var shoot_cooldown: float = 0.5  # Changed from const to var so we can upgrade it!
const BULLET_OFFSET = 20
var bullet_scene = preload("res://scenes/Projectiles/Bullet.tscn")

# --- NEW: PLAYER BUFF VARIABLES ---
var bonus_damage: int = 0
var multi_shot: int = 1 # Number of barrels/bullets fired at once
var spread_angle: float = 15.0 # Degrees between multiple bullets
var has_explosive_rounds: bool = false

# Dash state
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO

# Shooting state
var shoot_cooldown_timer = 0.0

# Mouse-based rotation
var mouse_control_enabled = true

# Movement
var velocity = Vector2.ZERO
var slow_stacks: int = 0

# gold logic
signal gold_changed(new_amount)

var last_attacker: String = "Unknown"

# --- GRACE PERIOD SHIELD VARIABLES ---
var shield_hits_remaining: int = 3
var shield_active: bool = true
var speed_boost_timer: Timer
var shield_expiration_timer: Timer
# -------------------------------------

@onready var physics_body = $StaticBody2D
@onready var magnet_area: Area2D = $MagnetArea

func _ready():
	# lock mouse to the window
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	current_speed = base_speed
	
	# let the physical_body could reference back to Commander
	physics_body.set_meta("commander", self)
	
	magnet_area.area_entered.connect(_on_magnet_area_entered)
	
	# --- SHIELD TIMERS SETUP ---
	shield_expiration_timer = Timer.new()
	shield_expiration_timer.wait_time = 90
	shield_expiration_timer.one_shot = true
	shield_expiration_timer.timeout.connect(_on_shield_expired)
	add_child(shield_expiration_timer)

	speed_boost_timer = Timer.new()
	speed_boost_timer.wait_time = 2.0
	speed_boost_timer.one_shot = true
	speed_boost_timer.timeout.connect(_on_speed_boost_ended)
	add_child(speed_boost_timer)
	# ---------------------------

func _input(event):
	# ESC exit mouse control
	if event.is_action_pressed("ui_cancel"):  # ESC key
		mouse_control_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# click screen to re-enter mouse control
	if event is InputEventMouseButton and event.pressed:
		if not mouse_control_enabled:
			mouse_control_enabled = true
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED

func _process(delta):
	
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			$AnimatedSprite2D.visible = true
		else:
			$AnimatedSprite2D.visible = int(invincibility_timer * 10) % 2 == 0

	if not is_invincible:
		# Get a list of every physics body currently inside our Area2D
		var overlapping = get_overlapping_bodies()
		for body in overlapping:
			if body.is_in_group("enemy"):
				take_damage(body.damage)
				break # Take damage from one enemy, become invincible, and stop checking
	
	# dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if shoot_cooldown_timer > 0:
		shoot_cooldown_timer -= delta
	
	if mouse_control_enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		shoot()
	
	# dash logic
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * DASH_SPEED
		
		if dash_timer <= 0:
			is_dashing = false
			velocity = Vector2.ZERO
	else:
		# WASD + Arrow keys
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		# Dash
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and direction != Vector2.ZERO:
			start_dash(direction)
		
	
		if direction != Vector2.ZERO:
			velocity = direction.normalized() * current_speed
			$AnimatedSprite2D.play()
		else:
			velocity = velocity.move_toward(Vector2.ZERO, current_speed)
			$AnimatedSprite2D.stop()
		
		if velocity.x < 0:
			$AnimatedSprite2D.animation = "walk_left"
		elif velocity.x > 0:
			$AnimatedSprite2D.animation = "walk_right"
		elif velocity.y < 0:
			$AnimatedSprite2D.animation = "walk_up"
		else:
			$AnimatedSprite2D.animation = "walk_down"
	
	# wall collision - moved outside else block
	var motion = velocity * delta
	var collision = physics_body.move_and_collide(motion, false, 0.08, true)

	if collision:
		motion = velocity.slide(collision.get_normal()) * delta
		physics_body.position = Vector2.ZERO
		global_position += motion
	else:
		physics_body.position = Vector2.ZERO
		global_position += motion

func start_dash(direction: Vector2):
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	dash_direction = direction.normalized()

func shoot():
	if shoot_cooldown_timer > 0:
		return
	
	shoot_cooldown_timer = shoot_cooldown # Use the new variable here!
	
	var base_dir = (get_global_mouse_position() - global_position).normalized()
	
	# Calculate the starting angle so multi-shot spreads are perfectly centered
	var start_angle = base_dir.angle() - deg_to_rad(spread_angle * (multi_shot - 1) / 2.0)
	
	# Fire a bullet for every barrel/multi-shot we have!
	for i in range(multi_shot):
		var bullet = bullet_scene.instantiate()
		
		# Calculate this specific bullet's angle
		var current_angle = start_angle + deg_to_rad(spread_angle * i)
		var shoot_direction = Vector2.RIGHT.rotated(current_angle)
		
		bullet.direction = shoot_direction
		bullet.global_position = global_position + shoot_direction * BULLET_OFFSET
		
		# --- APPLY PLAYER BUFFS ---
		bullet.damage += bonus_damage
		if has_explosive_rounds:
			bullet.is_explosive = true
		
		get_tree().root.add_child(bullet)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("mobs"): # Ensure this matches your mob group name
		# Use the custom mob_name property if it exists
		var killer_name = body.get("mob_name") if body.get("mob_name") else body.name
		take_damage(body.damage, killer_name)

func take_damage(damage: int, attacker_name: String = "Unknown"):
	if is_invincible:
		return
		
	# --- SHIELD INTERCEPT ---
	if shield_active:
		trigger_shield_hit()
		invincible_on() # Crucial: gives i-frames so the shield doesn't instantly double-break
		return
	# ------------------------
	
	hp -= damage
	hp = max(hp, 0)
	
	# Remember who actually managed to hurt the Commander!
	GameData.killer_name = attacker_name
	
	if hp <= 0:
		die()
	else:
		invincible_on()

func invincible_on():	
	is_invincible = true
	invincibility_timer = INVINCIBILITY_TIME

func die():
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)
	physics_body.get_node("CollisionShape2D").set_deferred("disabled", true)

func start(pos):
	position = pos
	
	# --- NEW: APPLY META UPGRADES ---
	# Base HP is 10. Add 5 HP for every upgrade level they bought!
	max_hp = 10 + (GameData.upgrade_hp_level * 5)
	hp = max_hp
	
	# Base speed is 80. Add 5 speed per upgrade level!
	base_speed = 80 + (GameData.upgrade_speed_level * 5)
	current_speed = base_speed
	
	# Start with bonus gold in the shop!
	if GameData.upgrade_gold_level > 0:
		GameData.add_gold(GameData.upgrade_gold_level * 5)
	# --------------------------------
	
	# --- RESET GRACE PERIOD SHIELD ---
	shield_hits_remaining = 3
	shield_active = true
	shield_expiration_timer.start(90) # Start the 2 minute clock
	
	if has_node("ShieldVisual"):
		$ShieldVisual.modulate = Color(1, 1, 1, 1) # Reset transparency
		$ShieldVisual.show()
		if has_node("ShieldVisual/AnimationPlayer"):
			$ShieldVisual/AnimationPlayer.play("pulse")
	# ---------------------------------
	
	is_invincible = false
	invincibility_timer = 0.0
	$AnimatedSprite2D.visible = true
	show()
	$CollisionShape2D.disabled = false
	physics_body.get_node("CollisionShape2D").disabled = false
	# reset speed
	slow_stacks = 0
	current_speed = base_speed
	
func apply_slow(factor: float):
	if slow_stacks == 0:
		current_speed = base_speed * factor
	slow_stacks += 1

func remove_slow():
	slow_stacks -= 1
	if slow_stacks <= 0:
		# remove slow down effect
		current_speed = base_speed
		slow_stacks = 0

func _on_magnet_area_entered(area):
	if area is Coin:
		area.start_magnetize(self)
	elif area is ExpereincePoints:
		area.start_magnetize(self)

func add_gold(amount: int):
	GameData.add_gold(amount)
	emit_signal("gold_changed", GameData.gold)

func add_exp(amount: int):
	# Delegate strictly to GameData
	GameData.add_exp(amount)


# ==========================================
# SHIELD LOGIC FUNCTIONS
# ==========================================
func trigger_shield_hit():
	shield_hits_remaining -= 1
	
	# 1. Apply the Panic Speed Boost
	if speed_boost_timer.is_stopped():
		current_speed = base_speed * 1.5 
	
	speed_boost_timer.start() 
	
	# 2. Visual Feedback (Fades out AND flashes red briefly)
	if has_node("ShieldVisual"):
		$ShieldVisual.modulate.a = float(shield_hits_remaining) / 3.0 
		$ShieldVisual.modulate = Color(1, 0.5, 0.5, $ShieldVisual.modulate.a) # Flash reddish
		
		# Tween color back to normal over 0.2 seconds
		var tween = create_tween()
		tween.tween_property($ShieldVisual, "modulate:r", 1.0, 0.2)
		tween.tween_property($ShieldVisual, "modulate:g", 1.0, 0.2)
		tween.tween_property($ShieldVisual, "modulate:b", 1.0, 0.2)
		
	print("[Shield] Hit taken! Absorbed. Remaining: ", shield_hits_remaining)
	
	# 3. Check if Shattered
	if shield_hits_remaining <= 0:
		break_shield()

func break_shield():
	shield_active = false
	shield_expiration_timer.stop()
	
	if has_node("ShieldVisual"):
		$ShieldVisual.hide() 
		
	print("[Shield] SHATTERED! Commander is now vulnerable.")

func _on_shield_expired():
	if shield_active:
		break_shield()
		print("[Shield] 2-Minute Grace Period Expired.")

func _on_speed_boost_ended():
	# Revert speed safely without breaking your 'slow' mechanic
	if slow_stacks <= 0:
		current_speed = base_speed

func apply_player_buff(buff_id: String):
	match buff_id:
		"buff_damage":
			bonus_damage += 5
			print("Buff Acquired: Damage +5")
		"buff_firerate":
			# Reduce cooldown by 15%, but cap it at a machine-gun speed of 0.1s
			shoot_cooldown = max(0.1, shoot_cooldown - 0.075)
			print("Buff Acquired: Faster Fire Rate")
		"buff_multishot":
			multi_shot += 1
			print("Buff Acquired: Extra Barrel!")
		"buff_explosive":
			has_explosive_rounds = true
			print("Buff Acquired: Explosive Rounds!")
