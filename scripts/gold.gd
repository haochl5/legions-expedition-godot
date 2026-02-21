class_name Coin
extends Area2D

@export var gold_value: int = 1
@export var magnet_speed: float = 300.0

var player: Node2D = null
var is_magnetized: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	area_entered.connect(_on_area_entered) 
	
	if sprite:
		sprite.play("gold") 
	
	add_drop_animation()
	
func _physics_process(delta):
	if is_magnetized and player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta

func add_drop_animation():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 20, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position:y", position.y, 0.2).set_trans(Tween.TRANS_BOUNCE)

func start_magnetize(target: Node2D):
	is_magnetized = true
	player = target

func _on_area_entered(area):
	
	# Magnet the gold to the Commander
	if area.name == "MagnetArea":
		start_magnetize(area.get_parent())
	
	# Collect the gold and release the gold after the Commander touches it
	elif area.name == "Commander":
		collect(area)

func collect(collector):
	if collector.has_method("add_gold"):
		collector.add_gold(gold_value)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
