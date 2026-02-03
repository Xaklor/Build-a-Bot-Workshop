class_name Part extends Node2D

signal clicked

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		for child in get_children():
			if child.get_rect().has_point(child.get_local_mouse_position()):
				clicked.emit(self)
