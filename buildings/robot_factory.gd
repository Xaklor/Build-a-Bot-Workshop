extends Area2D

@onready var tile_map: TileMapLayer = get_tree().get_root().get_node("main").get_node("tile_map")
@onready var main: Node = get_tree().get_root().get_node("main")
@export var robot_scene: PackedScene

var pos

func _ready():
	pos = tile_map.local_to_map(position)
	
func _process(delta: float) -> void:
	if $error_highlight.color.a > 0:
		$error_highlight.color.a -= 0.01
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc") and $color.get_rect().has_point(get_local_mouse_position()):
		var repository = get_tree().get_nodes_in_group("repositories")[0]
		if repository.inventory <= 0:
			$error_highlight.color.a = 1
			
		else:
			repository.inventory -= 10
			repository.update()
			var target = pos
			if not tile_map.land_astar.is_point_solid(pos + Vector2i(1, 0)):
				target = pos + Vector2i(1, 0)
			elif not tile_map.land_astar.is_point_solid(pos + Vector2i(-1, 0)):
				target = pos + Vector2i(-1, 0)
			elif not tile_map.land_astar.is_point_solid(pos + Vector2i(0, 1)):
				target = pos + Vector2i(0, 1)
			elif not tile_map.land_astar.is_point_solid(pos + Vector2i(0, -1)):
				target = pos + Vector2i(0, -1)
				
			if target != pos:
				var robot = robot_scene.instantiate()
				robot.position = tile_map.map_to_local(target)
				main.add_child(robot)
	
