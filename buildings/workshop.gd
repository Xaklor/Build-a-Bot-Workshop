extends Area2D

@onready var UPGRADE_DATA = get_tree().get_root().get_node("main").savedata_upgrades.duplicate()
@onready var main = get_tree().get_root().get_node("main")
var build_queue: Array[Array]
var build_progress: int

func _ready() -> void:
	for entry in UPGRADE_DATA:
		var row = HBoxContainer.new()
		var name = Label.new()
		var subrow = HBoxContainer.new()
		var metals = Label.new()
		var gems = Label.new()
		var essence = Label.new()
		name.text = entry["display_name"]
		metals.text = str(entry["cost"][0])
		gems.text = str(entry["cost"][1])
		essence.text = str(entry["cost"][2])
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
				$progressbar.value = build_progress / build_queue[0][1] * 100
				if build_progress >= int(build_queue[0][1]):
					# build the new upgrade
					var id = build_queue[0][2]
					var sprite = Sprite2D.new()
					sprite.texture = load(UPGRADE_DATA[id]["sprite_path"])
					sprite.centered = false
					var icon = Sprite2D.new()
					icon.texture = load(UPGRADE_DATA[id]["icon_path"])
					var polyomino: Array[Vector2i] = []
					var variant = randi() % UPGRADE_DATA[id]["xs"].size()
					for idx in range(UPGRADE_DATA[id]["xs"][variant].size()):
						polyomino.append(Vector2i(UPGRADE_DATA[id]["xs"][variant][idx], UPGRADE_DATA[id]["ys"][variant][idx]))
						
					var upgrade: Lib.Upgrade = Lib.Upgrade.new(sprite, icon, polyomino, UPGRADE_DATA[id]["effect"], UPGRADE_DATA[id]["effect_strength"], UPGRADE_DATA[id]["unique"])
					main.upgrades.append(upgrade)
					main.upgrades.sort_custom(Lib.upgrade_comparator)
					
					build_progress = 0
					build_queue.pop_front()
					$menu/queue/scroll_container/queue_list.get_child(0).queue_free()
					if build_queue.size() == 0:
						$progressbar.visible = false

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		$menu.visible = $color.get_rect().has_point(get_local_mouse_position()) or ($menu.get_rect().has_point(get_local_mouse_position()) and $menu.visible)

func _on_parts_click(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc") and $menu.visible:
		for idx in range($menu/parts/scroll_container/parts_list.get_children().size()):
			var entry = $menu/parts/scroll_container/parts_list.get_child(idx)
			if entry.get_rect().has_point($menu/parts/scroll_container/parts_list.get_local_mouse_position()):
				if idx > 0:
					var label = Label.new()
					label.text = UPGRADE_DATA[idx - 1]["display_name"]
					var queue_entry = [UPGRADE_DATA[idx - 1]["display_name"], UPGRADE_DATA[idx - 1]["cost"][3], idx - 1]
					build_queue.append(queue_entry)
					$menu/queue/scroll_container/queue_list.add_child(label)
					$progressbar.visible = true

func _on_queue_click(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc") and $menu.visible:
		for idx in range($menu/queue/scroll_container/queue_list.get_children().size()):
			if $menu/queue/scroll_container/queue_list.get_child(idx).get_rect().has_point($menu/queue/scroll_container/queue_list.get_local_mouse_position()):
				$menu/queue/scroll_container/queue_list.get_child(idx).queue_free()
				build_queue.remove_at(idx)
