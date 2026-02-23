# scripts/mobs/bear.gd
class_name BearMob
extends MobBase

# Bear special states
enum State {
	SLOW,   # slow random movement
	FAST    # fast toward commander
}

var current_state: State = State.SLOW
var state_timer: float = 0.0
var slow_direction: Vector2 = Vector2.ZERO

const SLOW_SPEED = 25
const FAST_SPEED = 80
const STATE_CHANGE_INTERVAL = 2.0  # switch state ever two second

func setup_animation():
	sprite.play("bear_down")

func setup_behavior():
	max_hp = 60  
	hp = max_hp
	damage = 2
	speed = SLOW_SPEED  
	
	_choose_random_direction()

func movement_pattern(delta: float):
	# update timer
	state_timer += delta
	
	# switch state every two second
	if state_timer >= STATE_CHANGE_INTERVAL:
		_switch_state()
		state_timer = 0.0
	
	if current_state == State.SLOW:
		_move_slow()
	else:  # State.FAST
		_move_fast()

func _switch_state():
	if current_state == State.SLOW:
		current_state = State.FAST
		speed = FAST_SPEED
	else:
		current_state = State.SLOW
		speed = SLOW_SPEED
		_choose_random_direction()

func _move_slow():
	var desired_velocity = slow_direction * speed
	velocity = velocity.lerp(desired_velocity, 0.05) # Bears turn very slow!
	_update_animation(slow_direction)

func _move_fast():
	if target == null: return
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target > 15:
		var direction = (target.global_position - global_position).normalized()
		var desired_velocity = direction * speed
		velocity = velocity.lerp(desired_velocity, 0.1)
		_update_animation(direction)
	else:
		velocity = velocity.lerp(Vector2.ZERO, 0.2)

func _choose_random_direction():
	var random_angle = randf_range(0, 2 * PI)
	slow_direction = Vector2(cos(random_angle), sin(random_angle))

func _update_animation(direction: Vector2):
	var abs_x = abs(direction.x)
	var abs_y = abs(direction.y)
	
	if abs_x > abs_y:
		if direction.x > 0:
			sprite.play("bear_right")
		else:
			sprite.play("bear_left")
	else:
		if direction.y > 0:
			sprite.play("bear_down")
		else:
			sprite.play("bear_up")
