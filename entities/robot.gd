class_name Robot extends Area2D

@export var speed = 400
@export var build_manager: PackedScene
@onready var tile_map: TileMapLayer = get_tree().get_root().get_node("main").get_node("tile_map")
@onready var main = get_tree().get_root().get_node("main")

enum state {
	IDLE,
	HARVESTING,
	RECHARGING,
	BUILDING
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
var build_target: String = ""
var build_pos: Vector2i
var hp = 10
var power = 1
var energy = 100

func _ready():
	claimed_pos = tile_map.local_to_map(position)
	tile_map.claim_pos(claimed_pos, true, true)
	main.stop_time.connect(_on_timestop)
	
func _process(delta):
	$status_label.text = var_to_str(status)
	if not stopped:
		if $sprite/attack_highlight.color.a > 0:
			$sprite/attack_highlight.color.a -= 0.01
			
		$sprite/select_highlight.visible = selected
		$work_bar.visible = $work_bar.value > 0

		#############################################################		
		# FIRST:
		# if low on energy and a charger is in range, start recharging
		#############################################################
		if energy <= 20 and (status != state.RECHARGING or (status == state.RECHARGING and path.is_empty())):
			var charger_list = get_tree().get_nodes_in_group("chargers")
			var charger_pos = tile_map.local_to_map(charger_list[0].position)
			if in_range(charger_pos, 10):
				status = state.RECHARGING
				path = navigate(charger_pos)
				if !path.is_empty():
					update_claimed_position(charger_pos)
			
		########################################
		# SECOND: 
		# if already on a path, continue walking
		########################################
		if not path.is_empty():
			var target = tile_map.map_to_local(path[0])
			global_position = global_position.move_toward(target, speed * delta)
			
			# if we've reached the point, remove it from the path
			if global_position == target:
				energy -= 1
				path.pop_front()
				
				# if this is the destination, free the indicator
				if path.is_empty():
					tile_map.free_indicator(tile_map.local_to_map(target))

		##############################################################
		# THIRD:
		# if recharging or idle and standing on a charger, gain energy
		##############################################################
		elif (status == state.RECHARGING or status == state.IDLE) and energy < 100 and get_overlapping_areas().any(func(x): return x.is_in_group("chargers")):
			energy += 1
			if energy >= 100:
				# if we were in the middle of harvesting, return to harvesting instead of idle
				if harvest_target != null:
					status = state.HARVESTING
					if item == 1:
						path = navigate(repository_pos)
						if !path.is_empty():
							update_claimed_position(repository_pos)
					else:
						path = navigate(harvest_pos)
						if !path.is_empty():
							update_claimed_position(harvest_pos)
				
				# if we were in the middle of building, return to building instead of idle
				if build_target != "":
					status = state.BUILDING
							
				else:
					status = state.IDLE
		
		############################################################
		# FOURTH:
		# if assigned a build and missing materials, go pick them up
		############################################################
		elif status == state.BUILDING and item == 0 and claimed_pos != repository_pos:
			path = navigate(repository_pos)
			if not path.is_empty():
				update_claimed_position(repository_pos)
		
		###########################################################################
		# FIFTH:
		# if assigned a build and standing on the repository, pick up the materials
		###########################################################################
		elif status == state.BUILDING and item == 0 and claimed_pos == repository_pos:
			item = 1
			main.update_resource("metals", -10)
				
		###############################################################################
		# SIXTH:
		# if assigned a build and holding materials but not at the site, go to the site
		###############################################################################
		elif status == state.BUILDING and item == 1 and claimed_pos != build_pos:
			path = navigate(build_pos)
			if not path.is_empty():
				update_claimed_position(build_pos)
				
		##########################################################
		# SEVENTH:
		# if assigned a build and at the build site, make progress
		##########################################################
		elif status == state.BUILDING and item == 1 and claimed_pos == build_pos:
			$work_bar.value += 0.5
			if $work_bar.value >= 100:
				var b
				match build_target:
					"repository": b = preload("res://buildings/repository.tscn").instantiate()
					"factory": b = preload("res://buildings/robot_factory.tscn").instantiate()
					"charger": b = preload("res://buildings/charger.tscn").instantiate()
					"mine": b = preload("res://buildings/mine.tscn").instantiate()
					_: print("what have you done?!")
						
				b.position = tile_map.map_to_local(build_pos)
				main.add_child(b)
				$work_bar.value = 0
				build_target = ""
				status = state.IDLE
				
		################################################################
		# EIGTH: 
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
		# NINTH:
		# if harvesting and standing on a harvestable object, bring item to repository
		##############################################################################
		elif status == state.HARVESTING and get_overlapping_areas().any(func(x): return x.has_meta("harvestable") and x.get_meta("harvestable")):
			harvest_target.inventory -= 20
			harvest_target.update()
			item = 1
			path = navigate(repository_pos)
			if not path.is_empty():
				update_claimed_position(repository_pos)
		
		########################################################################
		# TENTH:
		# if harvesting and standing on a repository, insert item and fetch more
		########################################################################
		elif status == state.HARVESTING and get_overlapping_areas().any(func(x): return x == repository_target):
			main.update_resource("metals", 10)
			item = 0
			if harvest_target.inventory > 0:
				path = navigate(harvest_pos)
				if not path.is_empty():
					update_claimed_position(harvest_pos)
			else:
				status = state.IDLE
				harvest_target = null
				repository_target = null
				
		##############################################################
		# ELEVENTH: 
		# if idle and holding a ranged weapon, attack enemies in range
		##############################################################
		elif status == state.IDLE and $attack_cooldown.time_left <= 0:
			var enemy_list = get_tree().get_nodes_in_group("enemies")
			for enemy in enemy_list:
				var enemy_pos = tile_map.local_to_map(enemy.position)
				if in_range(enemy_pos, 3):
					enemy.take_damage(power)
					$sprite/attack_highlight.color.a = 1
					$attack_cooldown.start()
					energy -= 5
					break

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		$menu.visible = false
		if selected:
			var click_pos = tile_map.local_to_map(get_global_mouse_position())
			path = navigate(click_pos)
			if not path.is_empty():
				selected = false
				update_claimed_position(click_pos)
				
		# select self to listen to orders
		elif $color.get_rect().has_point(get_local_mouse_position()):
			selected = true
			
	elif Input.is_action_just_pressed("rc"):
		if $color.get_rect().has_point(get_local_mouse_position()):
			$menu.visible = !$menu.visible

func _on_menu_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("rc"):
		get_viewport().set_input_as_handled()
	if Input.is_action_just_pressed("lc"):
		get_viewport().set_input_as_handled()
		match $menu.current_tab:
			0:
				if $menu/upgrade/MarginContainer1/land_row/ColorRect.get_rect().has_point($menu/upgrade/MarginContainer1/land_row.get_local_mouse_position()):
					mobility = "land"
					$color.color = 0xc74462ff
				if $menu/upgrade/MarginContainer2/water_row/ColorRect.get_rect().has_point($menu/upgrade/MarginContainer2/water_row.get_local_mouse_position()):
					mobility = "water"
					$color.color = 0x78b2f8ff
				if $menu/upgrade/MarginContainer3/flight_row/ColorRect.get_rect().has_point($menu/upgrade/MarginContainer3/flight_row.get_local_mouse_position()):
					mobility = "flight"
					$color.color = 0xebd680ff
			1:
				if $menu/build/MarginContainer/ScrollContainer/VBoxContainer/repository.get_rect().has_point($menu/build/MarginContainer/ScrollContainer.get_local_mouse_position()) and main.metals >= 10:
					start_build_manager("repository")
				if $menu/build/MarginContainer/ScrollContainer/VBoxContainer/factory.get_rect().has_point($menu/build/MarginContainer/ScrollContainer.get_local_mouse_position()) and main.metals >= 10:
					start_build_manager("factory")
				if $menu/build/MarginContainer/ScrollContainer/VBoxContainer/charger.get_rect().has_point($menu/build/MarginContainer/ScrollContainer.get_local_mouse_position()) and main.metals >= 10:
					start_build_manager("charger")
				if $menu/build/MarginContainer/ScrollContainer/VBoxContainer/mine.get_rect().has_point($menu/build/MarginContainer/ScrollContainer.get_local_mouse_position()) and main.metals >= 10:
					start_build_manager("mine")

func update_claimed_position(pos: Vector2i):
	tile_map.claim_pos(claimed_pos, false)
	claimed_pos = pos
	tile_map.claim_pos(claimed_pos)
	
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
	
func start_build_manager(building: String):
	var manager = build_manager.instantiate()
	manager.building = building
	manager.robot = self
	main.add_child(manager)
	$menu.visible = false
	
func receive_orders(building: String, building_position: Vector2i, repository: Node2D, repository_position: Vector2i):
	status = state.BUILDING
	build_target = building
	build_pos = building_position
	repository_target = repository
	repository_pos = repository_position
	
func in_range(pos: Vector2i, dist: int) -> bool:
	var self_pos = tile_map.local_to_map(position)
	return abs(self_pos.x - pos.x) + abs(self_pos.y - pos.y) <= dist

func take_damage(damage: int):
	hp -= damage
	if hp <= 0:
		tile_map.claim_pos(claimed_pos, false)
		queue_free()
	
func _on_timestop(b: bool):
	stopped = b
	$attack_cooldown.paused = b
