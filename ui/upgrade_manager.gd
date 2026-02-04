extends CanvasLayer

@onready var main = get_tree().get_root().get_node("main")
@export var part_scene: PackedScene
var tile_grid: AStarGrid2D = AStarGrid2D.new()
var left: Transform2D = Transform2D(Vector2(0, -1), Vector2(1, 0), Vector2(0, 0))
var right: Transform2D = Transform2D(Vector2(0, 1), Vector2(-1, 0), Vector2(0, 0))
var grid_pos: Vector2i
var upgrades: Array[Lib.Upgrade]
var held_part: Part
var slotted_upgrades: Array[Lib.Upgrade]
var slotted_parts: Array[Part]
var factory: Factory

func _ready() -> void:
	main.timestop_toggle(true, true)
	
	var grid_size = $grid.get_rect().end - $grid.get_rect().position
	tile_grid.region = Rect2i(Vector2i.ZERO, grid_size / 64)
	tile_grid.cell_size = grid_size / 7
	tile_grid.update()
	
	for idx in range(main.upgrades.size()):
		var upgrade = main.upgrades[idx]
		upgrades.append(upgrade)
		var entry = HBoxContainer.new()
		var label = Label.new()
		label.text = upgrade.effect + " " + str(upgrade.effect_strength)
		entry.add_child(label)
		entry.set_meta("id", idx)
		$menu/upgrades_list.add_child(entry)
		
func _process(delta: float) -> void:
	if held_part != null:
		grid_pos = floor($grid.get_local_mouse_position() / tile_grid.cell_size)
		grid_pos.x = clamp(grid_pos.x, 0, 6)
		grid_pos.y = clamp(grid_pos.y, 0, 6)
		held_part.position = (Vector2(grid_pos) * tile_grid.cell_size) + $grid.position
		held_part.grid_pos = grid_pos
	
func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("scroll_down") and held_part != null:
		for i in range(held_part.upgrade.polyomino.size()):
			held_part.upgrade.polyomino[i] = Vector2i(left * Vector2(held_part.upgrade.polyomino[i]))
			held_part.get_child(i).position = held_part.upgrade.polyomino[i] * 64
	if Input.is_action_pressed("scroll_up") and held_part != null:
		for i in range(held_part.upgrade.polyomino.size()):
			held_part.upgrade.polyomino[i] = Vector2i(right * Vector2(held_part.upgrade.polyomino[i]))
			held_part.get_child(i).position = held_part.upgrade.polyomino[i] * 64
	if Input.is_action_just_pressed("rc") and held_part != null:
		held_part.queue_free()
		held_part = null
	if Input.is_action_just_pressed("lc"):
		if held_part != null and tile_grid.region.has_point(grid_pos):
			var valid = true
			var edge_only = true
			var loose = false
			for p in held_part.upgrade.polyomino:
				if not tile_grid.region.has_point(grid_pos + p) or tile_grid.is_point_solid(grid_pos + p):
					valid = false
				print(tile_grid.size)
				if 0 < (grid_pos + p).x and (grid_pos + p).x < tile_grid.size.x - 1 and 0 < (grid_pos + p).y and (grid_pos + p).y < tile_grid.size.y - 1:
					edge_only = false
				else:
					loose = true
			
			if valid and not edge_only:
				held_part.upgrade.loose = loose
				for p in held_part.upgrade.polyomino:
					tile_grid.set_point_solid(grid_pos + p)
				slotted_parts.append(held_part)
				slotted_upgrades.append(held_part.upgrade)
				for tile in held_part.get_children():
					tile.modulate = Color("ffffffff")
				held_part = null

func _on_menu_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		get_viewport().set_input_as_handled()
		for entry in $menu/upgrades_list.get_children():
			if entry.get_rect().has_point($menu/upgrades_list.get_local_mouse_position()):
				remove_child(held_part)
				held_part = null
				
				var part = part_scene.instantiate()
				part.upgrade = upgrades[entry.get_meta("id")]
				for point in part.upgrade.polyomino:
					var temp = part.upgrade.sprite.duplicate()
					temp.position = point * 64
					temp.modulate = Color("ffffff99")
					part.add_child(temp)
					
				held_part = part
				add_child(held_part)

func _on_build_button_pressed() -> void:
	factory.receive_orders(slotted_upgrades)
	main.timestop_toggle(true, false)
	queue_free()

# called by placed parts when clicked on
func _on_slotted_part_clicked(part: Part) -> void:
	if held_part == null:
		get_viewport().set_input_as_handled()
		held_part = part
		slotted_parts.remove_at(slotted_parts.rfind(part))
		slotted_upgrades.remove_at(slotted_upgrades.rfind(part.upgrade))
		for i in range(part.upgrade.polyomino.size()):
			part.get_child(i).modulate = Color("ffffff99")
			tile_grid.set_point_solid(part.upgrade.polyomino[i] + part.grid_pos, false)
