extends Area2D

const MASTER_UPGRADES_LIST = [
	["Swim Upgrade", "50", "50", "-", "200"],
	["Flight Upgrade", "100", "50", "50", "500"],
	["HP Lv 1", "10", "-", "-", "100"],
	["HP Lv 2", "20", "10", "-", "150"],
	["HP Lv 3", "40", "20", "10", "200"],
	["Energy Lv 1", "10", "-", "-", "100"],
	["Energy Lv 2", "20", "10", "-", "150"],
	["Energy Lv 3", "40", "20", "10", "200"],
	["Power Lv 1", "10", "-", "-", "100"],
	["Power Lv 2", "20", "10", "-", "150"],
	["Power Lv 3", "40", "20", "10", "200"],
	["Speed Lv 1", "10", "-", "-", "100"],
	["Speed Lv 2", "20", "10", "-", "150"],
	["Speed Lv 3", "40", "20", "10", "200"],
	["Capacity Lv 1", "10", "-", "-", "100"],
	["Capacity Lv 2", "20", "10", "-", "150"],
	["Capacity Lv 3", "40", "20", "10", "200"],
	["Construction Lv 1", "10", "-", "-", "100"],
	["Construction Lv 2", "20", "10", "-", "150"],
	["Construction Lv 3", "40", "20", "10", "200"],
]

var build_queue: Array[Array]
var build_progress: int

func _ready() -> void:
	for entry in MASTER_UPGRADES_LIST:
		var row = HBoxContainer.new()
		var name = Label.new()
		var subrow = HBoxContainer.new()
		var metals = Label.new()
		var gems = Label.new()
		var essence = Label.new()
		name.text = entry[0]
		metals.text = entry[1]
		gems.text = entry[2]
		essence.text = entry[3]
		row.set_h_size_flags(row.SIZE_EXPAND_FILL)
		name.set_h_size_flags(name.SIZE_EXPAND_FILL)
		subrow.set_h_size_flags(subrow.SIZE_EXPAND_FILL)
		metals.set_h_size_flags(metals.SIZE_EXPAND_FILL)
		gems.set_h_size_flags(gems.SIZE_EXPAND_FILL)
		essence.set_h_size_flags(essence.SIZE_EXPAND_FILL)
		name.custom_minimum_size = Vector2(120, 0)
		subrow.add_child(metals)
		subrow.add_child(gems)
		subrow.add_child(essence)
		row.add_child(name)
		row.add_child(subrow)
		$menu/parts/scroll_container/parts_list.add_child(row)

func _process(delta: float) -> void:
	if build_queue.size() > 0:
		var robot_list = get_tree().get_nodes_in_group("robots")
		for robot in robot_list:
			if robot.position == self.position + Vector2(0, 64):
				build_progress += robot.build_speed
				if build_progress >= int(build_queue[0][1]):
					build_progress = 0
					build_queue.pop_front()
					$menu/queue/scroll_container/queue_list.get_child(0).queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		$menu.visible = $color.get_rect().has_point(get_local_mouse_position())

func _on_parts_click(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		for idx in range($menu/parts/scroll_container/parts_list.get_children().size()):
			var entry = $menu/parts/scroll_container/parts_list.get_child(idx)
			if entry.get_rect().has_point($menu/parts/scroll_container/parts_list.get_local_mouse_position()):
				if idx > 0:
					var label = Label.new()
					label.text = MASTER_UPGRADES_LIST[idx - 1][0]
					var queue_entry = [MASTER_UPGRADES_LIST[idx - 1][0], MASTER_UPGRADES_LIST[idx - 1][4]]
					build_queue.append(queue_entry)
					$menu/queue/scroll_container/queue_list.add_child(label)

func _on_queue_click(event: InputEvent) -> void:
	pass # Replace with function body.
