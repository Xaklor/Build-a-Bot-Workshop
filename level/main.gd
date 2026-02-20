extends Node

signal stop_time
var stopped = false
var robot_ui_pointer = 1
var metals = 1000
var gems = 0
var essence = 0
var upgrades: Array[Lib.Upgrade] = []
var savedata_upgrades: Array = []

func _init() -> void:
	if FileAccess.file_exists("res://lib/parts.json"):
		var json = JSON.new()
		var result = json.parse(FileAccess.get_file_as_string("res://lib/parts.json"))
		if result == OK:
			savedata_upgrades = json.data
			savedata_upgrades.sort_custom(Lib.json_comparator)

func _process(delta: float) -> void:
	var i = 1
	var robots = $robots.get_children()
	var ordering = range(robots.size())
	ordering.sort_custom(func(a, b): return robots[a].position.y < robots[b].position.y)
	for idx in range(robots.size()):
		var ui_element = get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(i))
		ui_element.get_node("hp").value = float(robots[idx].hp) / robots[idx].max_hp * 100
		ui_element.get_node("energy").value = float(robots[idx].energy) / robots[idx].max_energy * 100
		if robots[idx].selected:
			ui_element.get_node("color").color = Color(0xdb879aff)
		else:
			ui_element.get_node("color").color = Color(0xc74462ff)	
		i += 1
		$robots.move_child(robots[idx], ordering[idx])
	

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
