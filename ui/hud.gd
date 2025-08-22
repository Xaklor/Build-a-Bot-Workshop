extends CanvasLayer

@onready var robots: Array[HBoxContainer] = [
	$VBoxContainer/robot_ui_element1,
	$VBoxContainer/robot_ui_element2,
	$VBoxContainer/robot_ui_element3,
	$VBoxContainer/robot_ui_element4,
	$VBoxContainer/robot_ui_element5,
	$VBoxContainer/robot_ui_element6]

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		var i = 0
		for ui_element in robots:
			i += 1
			if ui_element.get_node("color").get_rect().has_point(ui_element.get_local_mouse_position()) and ui_element.visible:
				var j = 1
				for robot in get_tree().get_nodes_in_group("robots"):
					if i == j:
						robot.selected = true
						robot.get_node("select_highlight").visible = true
						break
					else:
						j += 1
