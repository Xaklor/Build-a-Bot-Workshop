extends Area2D

@export var speed = 800
@onready var tile_map: TileMapLayer = get_tree().get_root().get_node("main").get_node("tile_map")
@onready var main = get_tree().get_root().get_node("main")

enum state {
	IDLE,
	HARVESTING
}

var status: state = state.IDLE
var path: Array[Vector2i]
var selected = false
var stopped = false
var mobility = "land"
var item = 0
var claimed_pos: Vector2i
var harvest_target: Node2D
var harvest_pos: Vector2i
var repository_target: Node2D
var repository_pos: Vector2i
var weapon: Equipment.Weapon
var hp = 10

func _ready():
	claimed_pos = tile_map.local_to_map(position)
	tile_map.claim_pos(claimed_pos)
	main.stop_time.connect(_on_timestop)
	weapon = Equipment.weapons[0]
	
func _process(delta):
	if not stopped:
		if $attack_highlight.color.a > 0:
			$attack_highlight.color.a -= 0.01
			
		########################################
		# FIRST: 
		# if already on a path, continue walking
		########################################
		if not path.is_empty():
			var target = tile_map.map_to_local(path[0])
			global_position = global_position.move_toward(target, speed * delta)
			
			# if we've reached the point, remove it from the path
			if global_position == target:
				path.pop_front()
				
		################################################################
		# SECOND: 
		# if idle and standing on a harvestable object, start harvesting
		################################################################
		elif status == state.IDLE and get_overlapping_areas().any(func(x): return x.has_meta("harvestable") and x.get_meta("harvestable")):
			status = state.HARVESTING
			# record harvest target
			var harvest_list = get_overlapping_areas()
			harvest_target = harvest_list[harvest_list.find_custom(func(x): return x.get_meta("harvestable"))]
			harvest_pos = tile_map.local_to_map(harvest_target.position)
			# record repository target
			var repository_list = get_tree().get_nodes_in_group("repositories")
			repository_target = repository_list[0]
			repository_pos = tile_map.local_to_map(repository_target.position)

		##############################################################################
		# THIRD:
		# if harvesting and standing on a harvestable object, bring item to repository
		##############################################################################
		elif status == state.HARVESTING and get_overlapping_areas().any(func(x): return x.has_meta("harvestable") and x.get_meta("harvestable")):
			harvest_target.inventory -= 20
			harvest_target.update()
			path = navigate(repository_pos)
			if not path.is_empty():
				update_claimed_position(repository_pos)
		
		########################################################################
		# FOURTH:
		# if harvesting and standing on a repository, insert item and fetch more
		########################################################################
		elif status == state.HARVESTING and get_overlapping_areas().any(func(x): return x == repository_target):
			repository_target.inventory += 10
			repository_target.update()
			if harvest_target.inventory > 0:
				path = navigate(harvest_pos)
				if not path.is_empty():
					update_claimed_position(harvest_pos)
			else:
				status = state.IDLE
				
		##############################################################
		# FIFTH: 
		# if idle and holding a ranged weapon, attack enemies in range
		##############################################################
		elif status == state.IDLE and weapon.ranged and $attack_cooldown.time_left <= 0:
			var enemy_list = get_tree().get_nodes_in_group("enemies")
			for enemy in enemy_list:
				var enemy_pos = tile_map.local_to_map(enemy.position)
				var self_pos = tile_map.local_to_map(position)
				if abs(self_pos.x - enemy_pos.x) + abs(self_pos.y - enemy_pos.y) <= 3:
					enemy.take_damage(weapon.attack)
					$attack_highlight.color.a = 1
					$attack_cooldown.start()
					break

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		if selected:
			var click_pos = tile_map.local_to_map(get_global_mouse_position())
			path = navigate(click_pos)
			if not path.is_empty():
				selected = false
				$select_highlight.visible = false
				update_claimed_position(click_pos)
				
		# select self to listen to orders
		elif $color.get_rect().has_point(get_local_mouse_position()):
			selected = true
			$select_highlight.visible = true
			
	elif Input.is_action_just_pressed("rc"):
		if $color.get_rect().has_point(get_local_mouse_position()):
			match mobility:
				"land":
					mobility = "water"
					$color.color = 0x78b2f8ff
				"water":
					mobility = "flight"
					$color.color = 0xebd680ff
				"flight":
					mobility = "land"
					$color.color = 0xc74462ff
		
			
func update_claimed_position(pos: Vector2):
	tile_map.claim_pos(claimed_pos, false)
	claimed_pos = pos
	tile_map.claim_pos(claimed_pos)
	
func abandon_orders():
	pass
	
# returns shortest path to the target position if possible, takes grid coords
func navigate(target):
	var out: Array[Vector2i] = []
	if tile_map.is_point_walkable(target, mobility):
		match mobility:
			"land":
				out = tile_map.land_astar.get_id_path(tile_map.local_to_map(global_position),	target).slice(1)
			"water":
				out = tile_map.water_astar.get_id_path(tile_map.local_to_map(global_position),	target).slice(1)
			"flight":
				out = tile_map.flight_astar.get_id_path(tile_map.local_to_map(global_position), target).slice(1)
					
	return out
	
func take_damage(damage: int):
	hp -= damage
	if hp <= 0:
		queue_free()
	
func _on_timestop(b: bool):
	stopped = b
	$attack_cooldown.paused = b
	
	
