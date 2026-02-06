class_name Factory extends Area2D

@onready var tile_map: TileMapLayer = get_tree().get_root().get_node("main").get_node("tile_map")
@onready var main: Node = get_tree().get_root().get_node("main")
@export var robot_scene: PackedScene
@export var upgrade_manager: PackedScene

var pos

func _ready():
	pos = tile_map.local_to_map(position)
	
func _process(delta: float) -> void:
	if $error_highlight.color.a > 0:
		$error_highlight.color.a -= 0.01
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc") and $color.get_rect().has_point(get_local_mouse_position()):
		if main.metals < 10 or tile_map.land_astar.is_point_solid(pos + Vector2i(0, 1)):
			$error_highlight.color.a = 1
			
		else:
			var manager = upgrade_manager.instantiate()
			manager.factory = self
			main.add_child(manager)

func receive_orders(stats: Array[int], uniques: Array[String]):
	main.update_resource("metals", -10)
	var robot = robot_scene.instantiate()
	robot.position = tile_map.map_to_local(pos + Vector2i(0, 1))
	robot.hp += stats[0]
	robot.max_hp += stats[0]
	robot.energy += stats[1]
	robot.max_energy += stats[1]
	robot.power += stats[2]
	robot.speed += stats[3]
	robot.capacity += stats[4]
	robot.build_speed += stats[5]
	robot.unique_upgrades = uniques
	main.add_child(robot)
	
