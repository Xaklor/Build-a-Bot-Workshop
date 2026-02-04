class_name Part extends Node2D

var upgrade: Lib.Upgrade
var grid_pos: Vector2i

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc") and get_parent().has_method("_on_slotted_part_clicked"):
		for child in get_children():
			if child.get_rect().has_point(child.get_local_mouse_position()):
				get_parent()._on_slotted_part_clicked(self)
