extends Area2D

@onready var tile_map: TileMapLayer = get_tree().get_root().get_node("main").get_node("tile_map")
@onready var main = get_tree().get_root().get_node("main")

var hp = 50
var stopped = false

func _ready():
		main.stop_time.connect(_on_timestop)

func _process(delta: float) -> void:
	if not stopped:
		if $hurt_highlight.color.a > 0:
			$hurt_highlight.color.a -= 0.01
			
		if hp <= 0:
			queue_free()
			
		# if not moving, check adjacent tiles for targets
		if $attack_cooldown.time_left <= 0:
			var robot_list = get_tree().get_nodes_in_group("robots")
			for robot in robot_list:
				var robot_pos = tile_map.local_to_map(robot.position)
				var self_pos = tile_map.local_to_map(position)
				if abs(self_pos.x - robot_pos.x) + abs(self_pos.y - robot_pos.y) <= 1:
					robot.take_damage(5)
					$attack_cooldown.start()
					break
		
func take_damage(damage: int):
	hp -= damage
	$hurt_highlight.color.a = 1
	
func _on_timestop(b: bool):
	stopped = b
	$attack_cooldown.paused = b
