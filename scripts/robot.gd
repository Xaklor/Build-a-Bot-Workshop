extends Area2D

@export var speed = 400
@onready var tile_map = $"../tile_map"
@onready var main = get_tree().get_root().get_node("main")

var path: Array[Vector2i]
var idle = true
var selected = false
var stopped = false
var mobility = "land"
var claimed_pos

func _ready():
	claimed_pos = position
	tile_map.claim_pos(tile_map.local_to_map(claimed_pos))
	main.stop_time.connect(_on_timestop)
	
func _process(delta):
	if not stopped:
		# if we have a path that's been set, move to the next point in the path
		if not path.is_empty():
			var target = tile_map.map_to_local(path[0])
			global_position = global_position.move_toward(target, speed * delta)
			
			# if we've reached the point, remove it from the path
			if global_position == target:
				path.pop_front()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("lc"):
		var click_pos = get_global_mouse_position()
		if selected and tile_map.is_point_walkable(click_pos, mobility):
			selected = false
			$select_highlight.visible = false
			match mobility:
				"land":
					path = tile_map.land_astar.get_id_path(
						tile_map.local_to_map(global_position),
						tile_map.local_to_map(click_pos)
						# ignore the first item in the array, it's our current position
						).slice(1)
				"water":
					path = tile_map.water_astar.get_id_path(tile_map.local_to_map(global_position),	tile_map.local_to_map(click_pos)).slice(1)
				"flight":
					path = tile_map.flight_astar.get_id_path(tile_map.local_to_map(global_position), tile_map.local_to_map(click_pos)).slice(1)
					
			update_claimed_position(click_pos)
				
		elif $color.get_rect().has_point(get_local_mouse_position()):
			selected = true
			$select_highlight.visible = true
			
	elif Input.is_action_just_pressed("rc"):
		if $color.get_rect().has_point(get_local_mouse_position()):
			match mobility:
				"land":
					mobility = "water"
					$color.color = 0x78b2f8ff
				"water":
					mobility = "flight"
					$color.color = 0xebd680ff
				"flight":
					mobility = "land"
					$color.color = 0xc74462ff
		
			
func update_claimed_position(pos: Vector2):
	tile_map.claim_pos(tile_map.local_to_map(claimed_pos), false)
	claimed_pos = pos
	tile_map.claim_pos(tile_map.local_to_map(claimed_pos))
	
func _on_timestop(b):
	stopped = b
	
