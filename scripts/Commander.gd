extends CharacterBody2D

# Movement parameters
const SPEED = 400.0
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 1.0

# Shooting parameters
const SHOOT_COOLDOWN = 0.3    # shooting interval
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

func _ready():
	# lock mouse to the window
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

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
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				shoot()

func _physics_process(delta):
	# dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if shoot_cooldown_timer > 0:
		shoot_cooldown_timer -= delta
	
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
		
		# normal movement
		if direction != Vector2.ZERO:
			velocity = direction.normalized() * SPEED
			$AnimatedSprite2D.play()
		else:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED)
			$AnimatedSprite2D.stop()
		
		if velocity.x < 0:
			$AnimatedSprite2D.animation = "walk_left"
		elif velocity.x > 0:
			$AnimatedSprite2D.animation = "walk_right"
		elif velocity.y < 0:
			$AnimatedSprite2D.animation = "walk_up"
		else:
			$AnimatedSprite2D.animation = "walk_down"
		
	
	move_and_slide()

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
	
	# Set the initial position of the bullet (slightly in front of the character).
	bullet.global_position = global_position + shoot_direction * BULLET_OFFSET
	
	bullet.direction = shoot_direction
	
	# Add the bullet to the scene tree (add it to the World hierarchy, not as a child node of the Commander).
	get_parent().add_child(bullet)
