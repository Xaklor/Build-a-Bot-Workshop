extends Node

signal stop_time
signal tick
var time: float = 0.0
var stopped = false
var robot_ui_pointer = 1
var metals = 1000
var gems = 0
var essence = 0
var upgrades: Array[Lib.Upgrade] = []
var savedata_upgrades: Array = []

func _init() -> void:
	if FileAccess.file_exists("res://data/parts.json"):
		var json = JSON.new()
		var result = json.parse(FileAccess.get_file_as_string("res://data/parts.json"))
		if result == OK:
			savedata_upgrades = json.data
			savedata_upgrades.sort_custom(Lib.json_comparator)
			
	if FileAccess.file_exists("res://data/dummy.json"):
		var json = JSON.new()
		var result = json.parse(FileAccess.get_file_as_string("res://data/dummy.json"))
		if result == OK:
			for behavior in json.data["behaviors"]:
				if behavior["condition"] == "none":
					print(behavior["behavior"])
		

func _process(delta: float) -> void:
	if !stopped:
		time += delta
		if time >= 0.05:
			time -= 0.05
			tick.emit()
	
	var i = 1
	var entities = $entities.get_children()
	var ordering = range(entities.size())
	ordering.sort_custom(func(a, b): return entities[a].position.y < entities[b].position.y)
	for idx in range(entities.size()):
		$entities.move_child(entities[idx], ordering[idx])
		if entities[idx] is Robot:
			var ui_element = get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(i))
			ui_element.get_node("hp").value = float(entities[idx].hp) / entities[idx].max_hp * 100
			ui_element.get_node("energy").value = float(entities[idx].energy) / entities[idx].max_energy * 100
			if entities[idx].selected:
				ui_element.get_node("color").color = Color(0xdb879aff)
			else:
				ui_element.get_node("color").color = Color(0xc74462ff)	
			i += 1
	

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("timestop"):
		timestop_toggle()

func timestop_toggle(force: bool = false, stop: bool = true):
	if not force:
		stopped = not stopped
		$dimmer.visible = stopped
		stop_time.emit(stopped)
	else:
		stopped = stop
		$dimmer.visible = stop
		stop_time.emit(stop)
		
func update_resource(resource: String, amount: int):
	match resource:
		"metals":
			metals += amount
			$hud/HBoxContainer/metals_label.text = "Metals: %d" % metals
		"gems":
			gems += amount
			$hud/HBoxContainer/gems_label.text = "Gems: %d" % gems
		"essence":
			essence += amount
			$hud/HBoxContainer/essence_label.text = "Essence: %d" % essence
			
func _on_child_entered_tree(node: Node) -> void:
	$dimmer.move_to_front.call_deferred()
	if node.is_in_group("robots"):
		get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(robot_ui_pointer)).visible = true
		robot_ui_pointer += 1
	
	if node.is_in_group("buildings"):
		move_child(node, 1)

func _on_child_exiting_tree(node: Node) -> void:
	if node.is_in_group("robots"):
		robot_ui_pointer -= 1
		get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(robot_ui_pointer)).visible = false
