class_name Robot extends Area2D

@export var speed = 400
@export var build_manager: PackedScene
@export var upgrade_manager: PackedScene
@onready var tile_map: TileMapLayer = get_tree().get_root().get_node("main").get_node("tile_map")
@onready var main = get_tree().get_root().get_node("main")
@onready var entities = main.get_node("entities")

enum state {
	IDLE,
	HARVESTING,
	RECHARGING,
	BUILDING
}

var flipped: bool = false
var status: state = state.IDLE
var path: Array[Vector2i]
var move_target: Vector2 = Vector2(-1, -1)
var selected = false
var stopped = false
var tick_lockout: int = 0
var item: String = ""
var item_amount: int = 0
var claimed_pos: Vector2i
var grid_pos: Vector2i
var harvest_target: Node2D
var harvest_pos: Vector2i
var repository_target: Node2D
var repository_pos: Vector2i
var build_target: String = ""
var build_pos: Vector2i
var max_hp = 10
var hp = 10
var power = 1
var max_energy = 100
var energy = 100
var build_speed = 1
var capacity = 10
var unique_upgrades: Array[String]
var equipped_parts: Array[Part]

func _ready():
	claimed_pos = tile_map.local_to_map(position)
	grid_pos = claimed_pos
	tile_map.claim_pos(claimed_pos, true, true)
	main.stop_time.connect(_on_timestop)
	main.tick.connect(_on_tick)
	
func _process(delta):
	$status_label.text = var_to_str(status)
	$sprite/select_highlight.visible = selected
	$work_bar.visible = $work_bar.value > 0
	if !stopped:
		if $sprite/attack_highlight.color.a > 0:
			$sprite/attack_highlight.color.a -= 0.01
			
		# if moving, keep moving
		if move_target != Vector2(-1, -1):
			var new_position = global_position.move_toward(move_target, speed * delta)
			if new_position.x - global_position.x < 0 and not flipped:
				$sprite.flip_h = true
				flipped = true
			elif new_position.x - global_position.x > 0 and flipped:
				$sprite.flip_h = false
				flipped = false
			global_position = new_position
			grid_pos = tile_map.local_to_map(global_position)
			
			# if we've reached the point, remove it from the path
			if global_position == move_target:
				energy -= 1
				path.pop_front()
				# if this is the destination, free the indicator
				if path.is_empty():
					tile_map.free_indicator(tile_map.local_to_map(move_target))
				
				move_target = Vector2(-1, -1)
			
		# otherwise, grab the next position in the path
		elif !path.is_empty():
			move_target = tile_map.map_to_local(path[0])

func _on_tick():
	if tick_lockout > 0:
		tick_lockout -= 1
	else:
		##############################################################
		# if low on energy and a charger is in range, start recharging
		##############################################################
		if energy <= 20 and status != state.RECHARGING:
			var charger_list = get_tree().get_nodes_in_group("chargers")
			var charger_pos = tile_map.local_to_map(charger_list[0].position)
			if in_range(charger_pos, 10):
				path = navigate(charger_pos)
				if !path.is_empty():
					update_claimed_position(charger_pos)
					status = state.RECHARGING
		
		##############################################################
		# if recharging or idle and standing on a charger, gain energy
		##############################################################
		elif (status == state.RECHARGING or status == state.IDLE) and energy < max_energy and get_overlapping_areas().any(func(x): return x.is_in_group("chargers")):
			energy += 1
			if energy >= max_energy:
				# if we were in the middle of harvesting, return to harvesting instead of idle
				if harvest_target != null:
					status = state.HARVESTING
					if item_amount > 0:
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
		# if assigned a build and missing materials, go pick them up
		############################################################
		elif status == state.BUILDING and item_amount == 0 and claimed_pos != repository_pos:
			path = navigate(repository_pos)
			if not path.is_empty():
				update_claimed_position(repository_pos)
		
		###########################################################################
		# if assigned a build and standing on the repository, pick up the materials
		###########################################################################
		elif status == state.BUILDING and item_amount == 0 and claimed_pos == repository_pos:
			item = "metals"
			item_amount = 10
			main.update_resource("metals", -10)
				
		###############################################################################
		# if assigned a build and holding materials but not at the site, go to the site
		###############################################################################
		elif status == state.BUILDING and item_amount > 0 and claimed_pos != build_pos:
			path = navigate(build_pos)
			if not path.is_empty():
				update_claimed_position(build_pos)
				
		##########################################################
		# if assigned a build and at the build site, make progress
		##########################################################
		elif status == state.BUILDING and item_amount > 0 and claimed_pos == build_pos:
			$work_bar.value += build_speed
			if $work_bar.value >= 100:
				item = ""
				item_amount = 0
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
		# if harvesting and standing on a harvestable object, bring item to repository
		##############################################################################
		elif status == state.HARVESTING and get_overlapping_areas().any(func(x): return x.has_meta("harvestable") and x.get_meta("harvestable")):
			item = harvest_target.resource
			item_amount = min(capacity, harvest_target.inventory)
			harvest_target.inventory -= item_amount
			harvest_target.update()
			path = navigate(repository_pos)
			if not path.is_empty():
				update_claimed_position(repository_pos)
		
		########################################################################
		# if harvesting and standing on a repository, insert item and fetch more
		########################################################################
		elif status == state.HARVESTING and get_overlapping_areas().any(func(x): return x == repository_target):
			main.update_resource(item, item_amount)
			item = ""
			item_amount = 0
			if harvest_target.inventory > 0:
				path = navigate(harvest_pos)
				if not path.is_empty():
					update_claimed_position(harvest_pos)
			else:
				status = state.IDLE
				harvest_target = null
				repository_target = null
				
		###############################
		# if idle, attack nearest enemy
		###############################
		elif status == state.IDLE:
			var target = null
			var dist = 50000000
			for entity in entities.get_children():
				if entity is Enemy and get_dist(grid_pos, entity.grid_pos) < dist:
					target = entity
					dist = get_dist(grid_pos, entity.grid_pos)
					
			if target != null and dist <= 3:
				target.take_damage(power)
				$sprite/attack_highlight.color.a = 1
				tick_lockout = 20
				energy -= 5

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		$menu.visible = false
		if selected:
			var click_pos = tile_map.local_to_map(get_global_mouse_position())
			tile_map.claim_pos(claimed_pos, false)
			path = navigate(click_pos)
			if not path.is_empty():
				selected = false
				claimed_pos = click_pos
				tile_map.claim_pos(click_pos)
				
			else:
				tile_map.claim_pos(claimed_pos)
				
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
		if $menu.current_tab == 1:
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
	if "flight" in unique_upgrades:
		if tile_map.is_point_walkable(target, "flight"):
			out = tile_map.flight_astar.get_id_path(grid_pos, target).slice(1)
	elif "swim" in unique_upgrades:
		if tile_map.is_point_walkable(target, "water"):
			out = tile_map.water_astar.get_id_path(grid_pos, target).slice(1)
	else:
		if tile_map.is_point_walkable(target, "land"):
			out = tile_map.land_astar.get_id_path(grid_pos, target).slice(1)

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
	
# takes tile coords
func in_range(pos: Vector2i, dist: int) -> bool:
	return abs(grid_pos.x - pos.x) + abs(grid_pos.y - pos.y) <= dist
	
# takes tile coords
func get_dist(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func take_damage(damage: int):
	hp -= damage
	if hp <= 0:
		tile_map.claim_pos(claimed_pos, false)
		queue_free()
	
func _on_timestop(b: bool):
	stopped = b

func _on_upgrade_button_pressed() -> void:
	var factory_list = get_tree().get_nodes_in_group("factories")
	for factory in factory_list:
		if factory.position == self.position + Vector2(0, -64):
			var manager = upgrade_manager.instantiate()
			manager.robot = self
			main.add_child(manager)
			manager.insert_parts(equipped_parts)
	$menu.visible = false
	
func update_upgrades(stats: Array[int], uniques: Array[String], parts: Array[Part]):
	max_hp = 10 + stats[0]
	hp = min(hp, max_hp)
	max_energy = 100 + stats[1]
	energy = min(energy, max_energy)
	power = 1 + stats[2]
	speed = 400 + stats[3]
	capacity = 10 + stats[4]
	build_speed = 1 + stats[5]
	unique_upgrades = uniques
	equipped_parts = []
	for part in parts:
		equipped_parts.append(part.clone())
