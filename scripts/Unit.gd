class_name Unit
extends CharacterBody2D

var data: ChampionData
var star_level: int = 1

# Setup function called immediately after spawning
func setup(new_data: ChampionData, level: int):
	data = new_data
	star_level = level
	
	# --- VISUAL SETUP ---
	# 1. Update the texture to match the champion
	$Sprite2D.texture = data.sprite
	
	# 2. Ensure the sprite sheet is cut correctly 
	# (Since all your assets are 4-frame strips, we set this here to be safe)
	$Sprite2D.hframes = 4
	
	# 3. Pick a frame (Frame 0 is usually facing Down)
	$Sprite2D.frame = 0
	
	# Scale size based on star level (Visual feedback for merging)
	scale = Vector2.ONE * 4.0 * (1.0 + (0.2 * (star_level - 1)))
	
	# Adjust stats based on star level (simple multiplier)
	# var multiplier = 1.0 + ((star_level - 1) * 2.0)
	# hp = data.hp * multiplier
