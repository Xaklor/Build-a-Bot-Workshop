extends Node

signal stop_time
var stopped = false
var robot_ui_pointer = 1
var metals = 0
var gems = 0
var essence = 0

func _process(delta: float) -> void:
	var i = 1
	for robot in get_tree().get_nodes_in_group("robots"):
		var ui_element = get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(i))
		ui_element.get_node("hp").value = robot.hp * 10
		ui_element.get_node("energy").value = robot.energy
		if robot.selected:
			ui_element.get_node("color").color = Color(0xdb879aff)
		else:
			ui_element.get_node("color").color = Color(0xc74462ff)
	
		i += 1

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("timestop"):
		timestop_toggle()

func timestop_toggle(force: bool = false, stop: bool = true):
	update_resource("metals", 5)
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
		
