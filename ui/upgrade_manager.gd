extends CanvasLayer

@onready var main = get_tree().get_root().get_node("main")
var tile_grid: AStarGrid2D = AStarGrid2D.new()
var grid_pos: Vector2i
var upgrades: Array[Lib.Upgrade]
var held_sprite: Sprite2D
var held_id: int = -1
var slotted_upgrades: Array[Lib.Upgrade]
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
	if held_sprite != null:
		grid_pos = floor($grid.get_local_mouse_position() / tile_grid.cell_size)
		held_sprite.position = (Vector2(grid_pos) * tile_grid.cell_size) + $grid.position
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("rc"):
		remove_child(held_sprite)
		held_sprite = null
		held_id = -1
	if Input.is_action_just_pressed("lc"):
		if held_sprite != null and tile_grid.region.has_point(grid_pos):
			var valid = true
			for p in upgrades[held_id].polyomino:
				if not tile_grid.region.has_point(grid_pos + p) and not tile_grid.is_point_solid(grid_pos + p):
					valid = false
			
			if valid:
				for p in upgrades[held_id].polyomino:
					tile_grid.set_point_solid(grid_pos + p)
				slotted_upgrades.append(upgrades[held_id])
				held_sprite = null
				held_id = -1

func _on_menu_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		get_viewport().set_input_as_handled()
		for entry in $menu/upgrades_list.get_children():
			if entry.get_rect().has_point($menu/upgrades_list.get_local_mouse_position()):
				remove_child(held_sprite)
				held_sprite = null
				held_id = -1
				
				var sprite = upgrades[entry.get_meta("id")].sprite
				held_sprite = sprite
				held_id = entry.get_meta("id")
				add_child(sprite)


func _on_build_button_pressed() -> void:
	factory.receive_orders(slotted_upgrades)
	main.timestop_toggle(true, false)
	queue_free()
