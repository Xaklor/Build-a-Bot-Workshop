extends Area2D

@export var speed = 400
@onready var tile_map = $"../tile_map"

var path: Array[Vector2i]
var idle = true
var selected = false

func _ready():
	pass

func _process(delta):
	# if we have a path that's been set, move to the next point in the path
	if not path.is_empty():
		var target = tile_map.map_to_local(path[0])
		global_position = global_position.move_toward(target, speed * delta)
		
		# if we've reached the point, remove it from the path
		if global_position == target:
			path.pop_front()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		var click_pos = get_global_mouse_position()
		if selected and tile_map.is_point_walkable(click_pos):
			selected = false
			$color.color = Color(0.78, 0.265, 0.383)
			path = tile_map.astar.get_id_path(
				tile_map.local_to_map(global_position),
				tile_map.local_to_map(click_pos)
				# ignore the first item in the array, it's our current position
				).slice(1)
				
		elif $color.get_rect().has_point(get_local_mouse_position()):
			selected = true
			$color.color = Color(0.879, 0.353, 0.462)
