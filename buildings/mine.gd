extends Area2D

@export var inventory = 100

func update():
	$progress_bar.value = inventory
	if inventory < 100 and inventory > 0:
		$progress_bar.visible = true
		
	if inventory <= 0:
		set_meta("harvestable", false)
		$progress_bar.visible = false
		$empty_highlight.visible = true
