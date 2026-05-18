class_name Enemy extends Area2D

@export var thoughts_filepath: String
@export var base_behavior_filepath: String
@export var level: int
@onready var main: Node = get_tree().get_root().get_node("main")
@onready var tile_map: TileMapLayer = main.get_node("tile_map")
@onready var entities: Node2D = main.get_node("entities")

var thoughts: Dictionary = {}
var base_behavior: Dictionary = {}
var tags: Dictionary = {}
var tick_lockout: int = 0
var seek_target: Node2D = null
var flee_target: Node2D = null
var move_path: Array[Vector2i] = []
var move_target: Vector2 = Vector2(-1, -1)
var grid_pos: Vector2i
var max_hp: int
var hp: int
var speed: int
var attack_damage: int
var special_damage: int
var sprite_flipped: bool
var stopped: bool = false

func _ready() -> void:
	grid_pos = tile_map.local_to_map(position)
	tile_map.claimed_positions[grid_pos] = true
	max_hp = 10
	hp = max_hp
	attack_damage = 1
	special_damage = 1
	speed = 400
	sprite_flipped = $sprite.flip_h
	main.tick.connect(on_tick)
	main.stop_time.connect(on_timestop)
	if FileAccess.file_exists(thoughts_filepath):
		var json = JSON.new()
		var result = json.parse(FileAccess.get_file_as_string(thoughts_filepath))
		if result == OK:
			thoughts = json.data
	
	if FileAccess.file_exists(base_behavior_filepath):
		var json = JSON.new()
		var result = json.parse(FileAccess.get_file_as_string(base_behavior_filepath))
		if result == OK:
			base_behavior = json.data
	
func _process(delta: float) -> void:
	if !stopped:
		# if already moving, keep moving
		if move_target != Vector2(-1, -1):
			var new_position = global_position.move_toward(move_target, speed * delta) 
			if new_position.x - global_position.x < 0 and not sprite_flipped:
				sprite_flipped = true
				$sprite.flip_h = true
			elif new_position.x - global_position.x > 0 and sprite_flipped:
				sprite_flipped = false
				$sprite.flip_h = false
			global_position = new_position
			var temp_grid_pos = tile_map.local_to_map(position)
			if grid_pos != temp_grid_pos:
				tile_map.claimed_positions.erase(grid_pos)
				tile_map.claimed_positions[temp_grid_pos] = true
				grid_pos = temp_grid_pos
				
			if global_position == move_target:
				move_target = Vector2(-1, -1)
		
		# if on a path, continue the path
		elif move_path.size() > 0:
			if grid_pos == move_path[0]:
				move_path.pop_front()
			if move_path.size() > 0:
				move_target = tile_map.map_to_local(move_path[0])
		
		# if we have a seek target, pick a tile to move towards
		elif seek_target != null and get_dist(grid_pos, tile_map.local_to_map(seek_target.position)) > 1:
			var theta = asin((seek_target.position - position).normalized().cross(Vector2(1, 0)))
			var temp_target = Vector2i(0, 0)
			if theta > PI/4:
				temp_target = Vector2i(grid_pos.x, grid_pos.y - 1)
			elif theta < -PI/4:
				temp_target = Vector2i(grid_pos.x, grid_pos.y + 1)
			elif seek_target.position.x > position.x:
				temp_target = Vector2i(grid_pos.x + 1, grid_pos.y)
			else:
				temp_target = Vector2i(grid_pos.x - 1, grid_pos.y)
				
			if tile_map.is_point_walkable(temp_target, "land"):
				move_target = tile_map.map_to_local(temp_target)
			
func on_tick():
	if tick_lockout > 0:
		tick_lockout -= 1
	else:
		var result = perform_thoughts(thoughts["thoughts"])
		if !result:
			perform_thoughts(base_behavior["behaviors"])
			
func on_timestop(b: bool):
	stopped = b
		
func get_dist(a: Vector2i, b: Vector2i) -> int:
	return abs(abs(a.x) - abs(b.x)) + abs(abs(a.y) - abs(b.y))

func in_range(a: Vector2i, b: Vector2i, dist: int) -> bool:
	return abs(abs(a.x) - abs(b.x)) + abs(abs(a.y) - abs(b.y)) <= dist
	
func take_damage(damage: int):
	hp -= damage
	if hp <= 0:
		tile_map.claimed_positions.erase(grid_pos)
		queue_free()
	
func get_nearest(classname: String) -> Node2D:
	# max int apparently doesn't exist???
	var dist = 5000000000
	var result: Node2D = null
	match classname:
		"robot":
			for entity in entities.get_children():
				if entity is Robot:
					var d = get_dist(grid_pos, tile_map.local_to_map(entity.position))
					if d < dist:
						dist = d
						result = entity

	return result
	
func clear_targets():
	seek_target = null
	flee_target = null
	move_path = []
	
# reads the list of thoughts and performs all actions as necessary
# returns true if a non-passing behavior was performed
func perform_thoughts(arr: Array) -> bool:
	var idx = 0
	var thinking = true
	var actions = []
	# finds actions whose associated conditions pass
	while thinking and idx < arr.size():
		var thought = arr[idx]
		match thought.get("condition", ""):
			"none":
				thinking = false
			"in range":
				match thought.get("arg1", ""):
					"robot":
						for entity in entities.get_children():
							if entity is Robot and thought.get("arg2", -1) is float and in_range(grid_pos, tile_map.local_to_map(entity.position), thought.get("arg2", -1)):
								thinking = false
			"x in range":
				match thought.get("arg1", ""):
					"robot":
						var count = 0
						for entity in entities.get_children():
							if entity is Robot and thought.get("arg2", -1) is int and in_range(grid_pos, tile_map.local_to_map(entity.position), thought.get("arg2", -1)):
								count += 1
						
						if thought.get("arg3", -1) is int and count >= thought.get("arg3", -1):
							thinking = false
			# implementation currently unclear
			"in home":
				pass
			"has tag":
				if tags.has(thought.get("arg1", -1)):
					thinking = false
			"ally has tag":
				if thought.get("arg1", "") is String:
					match thought.get("arg1", ""):
						# do entities.get_children(), if entity is arg1 here
						_:
							pass
#					for ally in main.find_children("*", thought.get("arg1", "")):
#						if thought.get("arg2", -1) is int and in_range(grid_pos, ally.grid_pos, thought.get("arg2", -1)) and ally.tags.has(thought.get("arg3", "")):
#							thinking = false
			"hp low":
				if thought.get("arg1", 0) is int and float(max_hp) / float(hp) * 100 <= thought.get("arg1", 0):
					thinking = false
			
		if thought.get("not", false) is bool and thought.get("not", false) == true:
			thinking = !thinking
			
		if thought.get("chance", 100) is int and randi() % 100 >= thought.get("chance", 100):
			thinking = true
			
		if thought.get("pass", false) is bool and thought.get("pass", false) == true:
			# if pass is enabled, add this thought to the actions list to revisit later and continue
			if !thinking:
				actions.append(idx)
				thinking = true
			
		if thought.get("and", false) is bool and thought.get("not", false) == true:
			# if this didn't pass, skip to the next non-and thought and skip it
			if thinking:
				while idx < arr.size() and arr[idx].get("and", false) is bool and arr[idx].get("and", false) == true:
					idx += 1
			# if this did pass, pretend it didn't and move on to the next
			else:
				thinking = true
			
		if thinking:
			idx += 1
			
	if !thinking:
		actions.append(idx)
		
	# performs the action[s] found in the previous section
	for action_idx in actions:
		var behavior = arr[action_idx]
		match behavior.get("behavior", "idle"):
			"idle":
				clear_targets()
				tick_lockout = 10
				print("where, oh where...")
			"attack":
				clear_targets()
				match behavior.get("target", ""):
					"robot":
						var attack_target = get_nearest("robot")
						if attack_target != null:
							attack_target.take_damage(attack_damage)
							tick_lockout = 20
							print("heh heh ho! I'm going to stab yo!")
							
					"building":
						print("attack building not implemented yet")
						
					"factory":
						print("attack factory not implemented yet")
						
			"special":
				print("special not implemented yet")
			"seek":
				clear_targets()
				match behavior.get("target", ""):
					"robot":
						var res = get_nearest("robot")
						if res != null:
							if behavior.get("pathfind", false) is bool and behavior.get("pathfind", false) == true:
								move_path = tile_map.land_astar.get_id_path(grid_pos, tile_map.local_to_map(res.position)).slice(1, -1)
								tick_lockout = 100
							else:
								seek_target = res
								tick_lockout = 20
							print("hee hee hee! you can't escape from me!")
					
					"building":
						print("seek building not implemented yet")
					"factory":
						print("seek factory not implemented yet")
			"wander":
				clear_targets()
				if behavior.get("range", "") is int:
					var radius = behavior.get("range", "")
					#TODO: implement after the movement rework
			"flee":
				clear_targets()
				match behavior.get("target", ""):
					"robot":
						var res = get_nearest("robot")
						if res != null:
							flee_target = res
							tick_lockout = 10
			"aoe":
				clear_targets()
				if behavior.get("range", -1) is int:
					for entity in entities.get_children():
						if entity is Robot and in_range(grid_pos, tile_map.local_to_map(entity.position), behavior.get("range", -1)):
							entity.take_damage(attack_damage)
		
	return !thinking
