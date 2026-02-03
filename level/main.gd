extends Node

signal stop_time
var stopped = false
var robot_ui_pointer = 1
var metals = 1000
var gems = 0
var essence = 0
var upgrades: Array[Lib.Upgrade] = [
	Lib.Upgrade.new(Sprite2D.new(), [Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(0, 2)], "construction", 10), 
	Lib.Upgrade.new(Sprite2D.new(), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, -1)], "capacity", 10), 
	Lib.Upgrade.new(Sprite2D.new(), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], "energy", 100), 
	Lib.Upgrade.new(Sprite2D.new(), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 0)], "health", 10), 
	Lib.Upgrade.new(Sprite2D.new(), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1)], "power", 2), 
	Lib.Upgrade.new(Sprite2D.new(), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, -1)], "speed", 400)]

func _ready() -> void:
	upgrades[0].sprite.texture = load("res://assets/upgrade tile construction.png")
	upgrades[1].sprite.texture = load("res://assets/upgrade tile capacity.png")
	upgrades[2].sprite.texture = load("res://assets/upgrade tile energy.png")
	upgrades[3].sprite.texture = load("res://assets/upgrade tile health.png")
	upgrades[4].sprite.texture = load("res://assets/upgrade tile power.png")
	upgrades[5].sprite.texture = load("res://assets/upgrade tile speed.png")

	for upgrade in upgrades:
		upgrade.sprite.centered = false

func _process(delta: float) -> void:
	var i = 1
	for robot in get_tree().get_nodes_in_group("robots"):
		var ui_element = get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(i))
		ui_element.get_node("hp").value = robot.hp * 10
		ui_element.get_node("energy").value = robot.energy
		if robot.selected:
			ui_element.get_node("color").color = Color(0xdb879aff)
		else:
			ui_element.get_node("color").color = Color(0xc74462ff)
	
		i += 1

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("timestop"):
		timestop_toggle()

func timestop_toggle(force: bool = false, stop: bool = true):
	if not force:
		stopped = not stopped
		$dimmer.visible = stopped
		stop_time.emit(stopped)
	else:
		stopped = stop
		$dimmer.visible = stop
		stop_time.emit(stop)
		
func update_resource(resource: String, amount: int):
	match resource:
		"metals":
			metals += amount
			$hud/HBoxContainer/metals_label.text = "Metals: %d" % metals
		"gems":
			gems += amount
			$hud/HBoxContainer/gems_label.text = "Gems: %d" % gems
		"essence":
			essence += amount
			$hud/HBoxContainer/essence_label.text = "Essence: %d" % essence
			
func _on_child_entered_tree(node: Node) -> void:
	$dimmer.move_to_front.call_deferred()
	if node.is_in_group("robots"):
		get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(robot_ui_pointer)).visible = true
		robot_ui_pointer += 1
	
	if node.is_in_group("buildings"):
		move_child(node, 1)

func _on_child_exiting_tree(node: Node) -> void:
	if node.is_in_group("robots"):
		robot_ui_pointer -= 1
		get_node("hud/VBoxContainer/robot_ui_element" + var_to_str(robot_ui_pointer)).visible = false
