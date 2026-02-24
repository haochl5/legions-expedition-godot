extends Unit

# UPDATE THESE PATHS to your chosen Pyromancer assets!
const R_IDLE = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Lion/SeparateAnim/Idle.png")
const R_WALK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Lion/SeparateAnim/Walk.png")
const R_ATTACK = preload("res://assets/Ninja Adventure - Asset Pack/Actor/Characters/Lion/SeparateAnim/Attack.png")

const FIRE_ZONE = preload("res://scenes/FX/fire_zone.tscn")

var attack_range = 60.0 # Close range
var attack_counter = 0

func _ready():
	tex_idle = R_IDLE; tex_walk = R_WALK; tex_attack = R_ATTACK
	$Sprite2D.texture = tex_idle

func _physics_process(delta):
	if is_attacking: return
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range:
		attack()
	else:
		super(delta)

func attack():
	is_attacking = true
	$AnimationPlayer.stop()
	$Sprite2D.texture = tex_attack
	$Sprite2D.hframes = 4
	$Sprite2D.vframes = 1 
	$Sprite2D.frame = facing_dir
	
	await get_tree().create_timer(0.3).timeout # Windup
	
	if target and is_instance_valid(target):
		# Create a 5-point cross pattern (Center, Right, Left, Down, Up)
		# The "25" is the pixel distance between the fires. 
		var fire_offsets = [
			Vector2.ZERO,
			Vector2(25, 0),
			Vector2(-25, 0),
			Vector2(0, 25),
			Vector2(0, -25)
		]
		
		# Loop through all 5 positions and spawn a fire at each one!
		for offset in fire_offsets:
			var fire = FIRE_ZONE.instantiate()
			get_parent().add_child(fire)
			fire.global_position = target.global_position + offset
		
	await get_tree().create_timer(1.2).timeout # Cooldown
	is_attacking = false
