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

func receive_orders(upgrades: Array[Lib.Upgrade]):
	main.update_resource("metals", -10)
	var robot = robot_scene.instantiate()
	robot.position = tile_map.map_to_local(pos + Vector2i(0, 1))
	var health = 0
	var loose_count = 0
	for upgrade in upgrades:
		match(upgrade.effect):
			"health":
				if upgrade.loose:
					loose_count += 1
					health += upgrade.effect_strength / 2
				else:
					health += upgrade.effect_strength
			"energy":
				if upgrade.loose:
					loose_count += 1
					robot.energy += upgrade.effect_strength / 2
				else:
					robot.energy += upgrade.effect_strength
			"power":
				if upgrade.loose:
					loose_count += 1
					robot.power += upgrade.effect_strength / 2
				else:
					robot.power += upgrade.effect_strength
			"speed":
				if upgrade.loose:
					loose_count += 1
					robot.speed += upgrade.effect_strength / 2
				else:
					robot.speed += upgrade.effect_strength
					
	if loose_count >= 2:
		robot.hp = max(robot.hp / pow(2, loose_count - 1), 1)
	else:
		robot.hp += health
		
	main.add_child(robot)
	
