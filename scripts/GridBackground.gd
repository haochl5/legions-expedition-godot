extends Node2D

const GRID_SIZE = 64 
const GRID_COLOR = Color(0.9, 0.3, 0.35, 1.0)
const LINE_WIDTH = 2.0

func _ready():
	queue_redraw()

func _draw():
	var viewport_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d()
	
	if camera:
		var camera_pos = camera.global_position
		var half_viewport = viewport_size / 2
		
		# visible area
		var start_x = int((camera_pos.x - half_viewport.x) / GRID_SIZE) * GRID_SIZE
		var end_x = int((camera_pos.x + half_viewport.x) / GRID_SIZE) * GRID_SIZE + GRID_SIZE
		var start_y = int((camera_pos.y - half_viewport.y) / GRID_SIZE) * GRID_SIZE
		var end_y = int((camera_pos.y + half_viewport.y) / GRID_SIZE) * GRID_SIZE + GRID_SIZE
		
		# vertical line
		for x in range(start_x, end_x + 1, GRID_SIZE):
			draw_line(Vector2(x, start_y), Vector2(x, end_y), GRID_COLOR, LINE_WIDTH)
		
		# horizontal line
		for y in range(start_y, end_y + 1, GRID_SIZE):
			draw_line(Vector2(start_x, y), Vector2(end_x, y), GRID_COLOR, LINE_WIDTH)
