extends Unit

# ASSETS (SamuraiBlue)
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Special1.png")

const ARROW_SCENE = preload("res://scenes/projectiles/arrow.tscn")

var attack_range = 250.0 # Ranged distance

var attack_counter: int = 0

func _ready():
	tex_idle = R_IDLE
	tex_walk = R_WALK
	tex_attack = R_ATTACK
	tex_special = R_SPECIAL
	$Sprite2D.texture = tex_idle

func _physics_process(delta):
	if is_attacking: return

	# RANGED LOGIC:
	# Stop and shoot if within range
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		attack()
	else:
		super(delta) # Chase the enemy if too far

func attack():
	is_attacking = true
	# ... (Visuals code same as before) ...
	
	# Windup
	await get_tree().create_timer(0.3).timeout
	
	attack_counter += 1
	if attack_counter >= 3:
		attack_counter = 0
		fire_special_shotgun()
	else:
		fire_normal_arrow()
		
	# Cooldown
	await get_tree().create_timer(0.4).timeout
	is_attacking = false

func fire_normal_arrow():
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		spawn_arrow(dir)
	else:
		# Fallback if target died during windup
		spawn_arrow(Vector2.RIGHT)

func fire_special_shotgun():
	if not target or not is_instance_valid(target): return
	
	var center_dir = (target.global_position - global_position).normalized()
	
	# Fire 3 arrows: Center, -15 degrees, +15 degrees
	spawn_arrow(center_dir) 
	spawn_arrow(center_dir.rotated(deg_to_rad(-15)))
	spawn_arrow(center_dir.rotated(deg_to_rad(15)))

func spawn_arrow(dir: Vector2):
	var arrow = ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = global_position
	arrow.direction = dir
	arrow.rotation = dir.angle()
