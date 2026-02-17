extends Unit

# ASSETS (SamuraiBlue)
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Attack.png")
const R_SPECIAL = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/SamuraiBlue/SeparateAnim/Special1.png")

const ARROW_SCENE = preload("res://scenes/projectiles/arrow.tscn")

var attack_range = 250.0 # Ranged distance

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
	
	# 1. Visuals
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1
	$Sprite2D.frame = facing_dir
	
	# 2. Windup
	await get_tree().create_timer(0.3).timeout
	
	# 3. Shoot Arrow
	fire_arrow()
	
	# 4. Cooldown
	await get_tree().create_timer(0.4).timeout
	is_attacking = false

func fire_arrow():
	var arrow = ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = global_position
	
	# Aim Logic
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		arrow.direction = dir
		arrow.rotation = dir.angle()
	else:
		# Fallback aim
		var dirs = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
		arrow.direction = dirs[facing_dir]
		arrow.rotation = arrow.direction.angle()
