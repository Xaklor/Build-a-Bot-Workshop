extends Node

signal stop_time
var stopped = false

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("timestop"):
		stopped = not stopped
		$dimmer.visible = stopped
		stop_time.emit(stopped)
