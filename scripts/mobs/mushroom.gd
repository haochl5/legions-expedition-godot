# scripts/mobs/mushroom.gd
class_name MushroomMob
extends MobBase

@export var chase_speed: float = 70
@export var holding_speed: float = 35
@export var slow_radius: float = 30  # slow down radius
@export var slow_factor: float = 0.5   # slow down factor

var affected_units: Array = []

# Area2D to detect the object nearby
var slow_area: Area2D

func setup_animation():
	sprite.play("mushroom_idle")

func setup_behavior():
	mob_name = "Mushroom"
	max_hp = 20
	hp = max_hp
	# Move fast toward player, move slow once player is within the slow are range
	speed = chase_speed
	damage = 0
	
	# create slow down area
	_setup_slow_area()

func _setup_slow_area():
	
	# --- ADD THIS CHECK AT THE VERY TOP ---
	if has_node("SlowAreaNode"): # Give it a unique name to check against
		return 
	# ---------------------------------------
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
	slow_area.name = "SlowAreaNode"
	slow_area.collision_layer = 0
	slow_area.collision_mask = 2
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
	slow_down_circle.width = 5.0 # Increased from 3.0 to make it thicker!
	slow_down_circle.default_color = Color(1, 0.8, 0, 0.5) 
	
	# THE FIX: Change this to 0 or 1 so it renders on top of the grass!
	slow_down_circle.z_index = 0 
	
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
	
	# 1. Basic Movement Logic
	var vector = target.global_position - global_position
	var distance = vector.length()
	var direction = vector.normalized()
	
	if distance <= slow_radius:
		speed = holding_speed
	else:
		speed = chase_speed
	
	if direction.x > 0:
		sprite.flip_h = false
	elif direction.x < 0:
		sprite.flip_h = true
	
	var desired_velocity = direction * speed

	# 2. THE FIX: ADD SEPARATION FORCE
	# This prevents the "blob" by pushing away from nearby mobs
	var separation_force = Vector2.ZERO
	var neighbor_radius = 25.0 # How much "personal space" each mushroom wants
	
	# Get all mobs currently in the game
	var mobs = get_tree().get_nodes_in_group("mobs") 
	
	for mob in mobs:
		if mob != self and is_instance_valid(mob):
			var dist_to_mob = global_position.distance_to(mob.global_position)
			if dist_to_mob < neighbor_radius:
				# Calculate a push vector away from the neighbor
				# The closer they are, the harder they push away
				var push_dir = (global_position - mob.global_position).normalized()
				separation_force += push_dir * (neighbor_radius - dist_to_mob)

	# 3. Apply Velocity with the Push Force included
	# We multiply separation by a strength factor (e.g., 2.0) to make it effective
	velocity = velocity.lerp(desired_velocity + (separation_force * 2.0), 0.1)

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
