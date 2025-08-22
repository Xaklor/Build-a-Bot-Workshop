extends Area2D

@export var inventory = 0

func _ready():
	pass 
	
func _mouse_enter() -> void:
	$progress_bar.visible = true

func _mouse_exit() -> void:
	$progress_bar.visible = false

func update():
	$progress_bar.value = inventory
