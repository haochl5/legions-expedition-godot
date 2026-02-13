extends Area2D

signal hit

# Movement parameters
var base_speed: float = 400.0  
var current_speed: float = 400.0 
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 2.0

# Health
const MAX_HP = 10
var hp = MAX_HP

# Invincibility after being hit
const INVINCIBILITY_TIME = 1.0
var is_invincible = false
var invincibility_timer = 0.0

# Shooting parameters
const SHOOT_COOLDOWN = 0.5    # shooting interval
const BULLET_OFFSET = 40.0     # Bullet generation offset distance

var bullet_scene = preload("res://scenes/Bullet.tscn")

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

@onready var physics_body = $StaticBody2D

func _ready():
	# lock mouse to the window
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	current_speed = base_speed
	
	# let the physical_body could reference back to Commander
	physics_body.set_meta("commander", self)
	

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
	
	# reset timer
	shoot_cooldown_timer = SHOOT_COOLDOWN
	
	# create a instance of a bullet
	var bullet = bullet_scene.instantiate()
	
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	
	bullet.direction = shoot_direction
	
	# Set the initial position of the bullet (slightly in front of the character).
	bullet.global_position = global_position + shoot_direction * BULLET_OFFSET
	
	get_tree().root.add_child(bullet)


func _on_body_entered(body: Node2D) -> void:
	# Take damage only when it collided with the mob
	if body.is_in_group("enemy"):
		take_damage(1)

func take_damage(damage: int):
	if is_invincible:
		return
	
	hp -= damage
	hp = max(hp, 0)
	
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
	hp = MAX_HP
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
		print("Commander slowed! Speed: ", base_speed, " -> ", current_speed)
	slow_stacks += 1

func remove_slow():
	slow_stacks -= 1
	if slow_stacks <= 0:
		# remove slow down effect
		current_speed = base_speed
		slow_stacks = 0
		print("Commander speed restored! Speed: ", current_speed)
