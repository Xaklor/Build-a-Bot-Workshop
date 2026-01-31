extends CanvasLayer

@onready var main = get_tree().get_root().get_node("main")
@onready var tile_map: TileMapLayer = get_tree().get_root().get_node("main").get_node("tile_map")

var building: String
var robot: Robot
var building_pos: Vector2i
var repository_pos: Vector2i
var repository_target: Node2D
var step = 0

func _ready() -> void:
	main.timestop_toggle(true, true)
	$label.text = "Select a Repository to draw material from"

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("rc"):
		get_viewport().set_input_as_handled()
		main.timestop_toggle(true, false)
		queue_free()
	if Input.is_action_just_pressed("lc"):
		get_viewport().set_input_as_handled()
		match step:
			0:
				for repo in get_tree().get_nodes_in_group("repositories"):
					if repo.get_node("color").get_rect().has_point(repo.get_local_mouse_position()):
						var mouse_pos = tile_map.local_to_map($area.get_local_mouse_position())
						if robot.navigate(mouse_pos).is_empty():
							$label.text = "The robot cannot reach that Repository"
							break
						else:
							$repo_select.position = tile_map.map_to_local(mouse_pos) - Vector2(32, 32)
							$repo_select.visible = true
							$label.text = "Select a position to build"
							repository_pos = mouse_pos
							repository_target = repo
							step += 1
							break
			1:
				var mouse_pos = tile_map.local_to_map($area.get_local_mouse_position())
				var entity_placeable = true
				for entity in get_tree().get_nodes_in_group("entities"):
					if(tile_map.local_to_map(entity.position) == mouse_pos):
						entity_placeable = false
						break
						
				var building_placeable = true
				for building in get_tree().get_nodes_in_group("buildings"):
					if(tile_map.local_to_map(building.position) == mouse_pos):
						building_placeable = false
						break
				
				if entity_placeable and building_placeable:
					$target_select.position = tile_map.map_to_local(mouse_pos) - Vector2(32, 32)
					$target_select.visible = true
					$label.text = "Click anywhere to confirm, right click to cancel."
					building_pos = mouse_pos
					step += 1
				elif !entity_placeable:
					$label.text = "An Entity is blocking that location."
				else:
					$label.text = "A Building is blocking that location."
			2:
				robot.receive_orders(building, building_pos, repository_target, repository_pos)
				main.timestop_toggle(true, false)
				queue_free()
