extends Area2D

@export var resource: String = "metals"
@export var inventory: int = 100
var max_inventory: int

func _ready() -> void:
	max_inventory = inventory

func update():
	$progress_bar.value = (float(inventory) / float(max_inventory)) * 100
	if inventory < max_inventory and inventory > 0:
		$progress_bar.visible = true
		
	if inventory <= 0:
		set_meta("harvestable", false)
		$progress_bar.visible = false
		$empty_highlight.visible = true
