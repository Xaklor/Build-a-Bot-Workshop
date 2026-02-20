extends Node2D

var parts = []
var sprite_path
var icon_path
var shapes = []
var points = [[false, false, false, false, false], 
			  [false, false, false, false, false],
			  [false, false, false, false, false],
			  [false, false, false, false, false],
			  [false, false, false, false, false]]

func _on_add_shape_pressed() -> void:
	shapes.append(points.duplicate(true))

func _on_add_pressed() -> void:
	var save = {
		"sprite_path": sprite_path, 
		"icon_path": icon_path,
		"unique": false,
		"effect_strength": 0,
		"xs": [],
		"ys": []
	}
	if sprite_path.contains("health"):
		save["effect"] = "health"
	elif sprite_path.contains("energy"):
		save["effect"] = "energy"
	elif sprite_path.contains("power"):
		save["effect"] = "power"
	elif sprite_path.contains("speed"):
		save["effect"] = "speed"
	elif sprite_path.contains("capacity"):
		save["effect"] = "capacity"
	elif sprite_path.contains("construction"):
		save["effect"] = "construction"
	else:
		save["effect"] = ""
	
	for shape in shapes:
		var xlist = []
		var ylist = []
		for i in range(5):
			for j in range(5):
				if shape[i][j]:
					xlist.append(j - 2)
					ylist.append(i - 2)
		save["xs"].append(xlist)
		save["ys"].append(ylist)
				
	parts.append(save)
	shapes = []

func _on_rects_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		for idx in $rects.get_children().size():
			if $rects.get_child(idx).get_rect().has_point($rects.get_local_mouse_position()):
				if points[idx / 5][idx % 5]:
					$rects.get_child(idx).color.s -= 10
				else:
					$rects.get_child(idx).color.s += 10
				points[idx / 5][idx % 5] = !points[idx / 5][idx % 5]


func _on_hp_pressed() -> void:
	sprite_path = "res://assets/upgrade sprites/upgrade tile health.png"
	icon_path = "res://assets/upgrade sprites/upgrade tile health mini.png"

func _on_energy_pressed() -> void:
	sprite_path = "res://assets/upgrade sprites/upgrade tile energy.png"
	icon_path = "res://assets/upgrade sprites/upgrade tile energy mini.png"

func _on_power_pressed() -> void:
	sprite_path = "res://assets/upgrade sprites/upgrade tile power.png"
	icon_path = "res://assets/upgrade sprites/upgrade tile power mini.png"

func _on_speed_pressed() -> void:
	sprite_path = "res://assets/upgrade sprites/upgrade tile speed.png"
	icon_path = "res://assets/upgrade sprites/upgrade tile speed mini.png"

func _on_capacity_pressed() -> void:
	sprite_path = "res://assets/upgrade sprites/upgrade tile capacity.png"
	icon_path = "res://assets/upgrade sprites/upgrade tile capacity mini.png"

func _on_construction_pressed() -> void:
	sprite_path = "res://assets/upgrade sprites/upgrade tile construction.png"
	icon_path = "res://assets/upgrade sprites/upgrade tile construction mini.png"

func _on_unique_pressed() -> void:
	sprite_path = "res://assets/upgrade sprites/upgrade tile unique.png"
	icon_path = "res://assets/upgrade sprites/upgrade tile unique mini.png"

func _on_button_pressed() -> void:
	var file = FileAccess.open("res://lib/out.json", FileAccess.WRITE)
	file.store_line(JSON.stringify(parts, "\t"))
