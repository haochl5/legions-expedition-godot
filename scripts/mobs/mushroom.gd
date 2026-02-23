# scripts/mobs/mushroom.gd
class_name MushroomMob
extends MobBase

@export var chase_speed: float = 200.0
@export var holding_speed: float = 150
@export var slow_radius: float = 120.0  # slow down radius
@export var slow_factor: float = 0.5   # slow down factor

var affected_units: Array = []

# Area2D to detect the object nearby
var slow_area: Area2D

func setup_animation():
	sprite.play("mushroom_idle")

func setup_behavior():
	max_hp = 20
	hp = max_hp
	# Move fast toward player, move slow once player is within the slow are range
	speed = chase_speed
	damage = 0
	
	# create slow down area
	_setup_slow_area()

func _setup_slow_area():
	# calculate the sprite centered offset
	var sprite_center_offset = Vector2.ZERO
	
	# if sprite is not centered, calculate the offset
	if sprite and not sprite.centered:
		# frame size
		var current_animation = sprite.animation
		var current_frame = sprite.frame
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(current_animation):
			var frame_texture = sprite.sprite_frames.get_frame_texture(current_animation, current_frame)
			if frame_texture:
				var frame_size = frame_texture.get_size()
				sprite_center_offset = (frame_size * sprite.scale) / 2.0
	
	# create a area2d node
	slow_area = Area2D.new()
	slow_area.collision_layer = 0
	slow_area.collision_mask = 1
	add_child(slow_area)
	
	# cicle shape collsion detection
	var shape = CircleShape2D.new()
	shape.radius = slow_radius
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	collision_shape.position = sprite_center_offset  # apply offset
	slow_area.add_child(collision_shape)
	
	# connect signal
	slow_area.body_entered.connect(_on_slow_area_entered)
	slow_area.body_exited.connect(_on_slow_area_exited)
	
	# visualize cicle
	var slow_down_circle = Line2D.new()
	slow_down_circle.width = 3.0
	slow_down_circle.default_color = Color(1, 0.8, 0, 0.5) 
	slow_down_circle.z_index = -10 
	slow_down_circle.z_as_relative = false  
	
	var points = PackedVector2Array()
	for i in range(33):
		var angle = i * 2 * PI / 32
		var point = Vector2(cos(angle), sin(angle)) * slow_radius
		points.append(point + sprite_center_offset)  # apply offset
	slow_down_circle.points = points
	slow_down_circle.closed = true
	
	add_child(slow_down_circle)
	

func movement_pattern(delta: float):
	if target == null:
		return
	
	# Direction toward the Player
	var vector = target.global_position - global_position
	var distance = vector.length()
	var direction = vector.normalized()
	
	# pattern: if commander is within the slow radius, move slowly, keep slowing player down
	# if outside, move fast to reach the player
	if distance <= slow_radius:
		speed = holding_speed
	else:
		speed = chase_speed
	
	# Set rotation so the mob faces the player
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
	
	# Set velocity
	linear_velocity = direction * speed

func _on_slow_area_entered(body):
	
	if body.has_meta("commander"):
		var commander = body.get_meta("commander")
		commander.apply_slow(slow_factor)
		affected_units.append(commander)
	elif body.has_method("apply_slow"):
		body.apply_slow(slow_factor)
		affected_units.append(body)

func _on_slow_area_exited(body):
	
	if body.has_meta("commander"):
		var commander = body.get_meta("commander")
		if commander in affected_units:
			commander.remove_slow()
			affected_units.erase(commander)
	elif body in affected_units:
		if body.has_method("remove_slow"):
			body.remove_slow()
		affected_units.erase(body)

func die():
	for unit in affected_units:
		if is_instance_valid(unit) and unit.has_method("remove_slow"):
			unit.remove_slow()
	
	affected_units.clear()
	
	super.die()
