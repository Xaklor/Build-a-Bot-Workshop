extends TileMapLayer

var land_astar = AStarGrid2D.new()
var water_astar = AStarGrid2D.new()
var flight_astar = AStarGrid2D.new()

func _ready():
	var tilemap_size = get_used_rect().end - get_used_rect().position
	land_astar.region = Rect2i(Vector2i.ZERO, tilemap_size)
	water_astar.region = Rect2i(Vector2i.ZERO, tilemap_size)
	flight_astar.region = Rect2i(Vector2i.ZERO, tilemap_size)
	land_astar.cell_size = tile_set.tile_size
	water_astar.cell_size = tile_set.tile_size
	flight_astar.cell_size = tile_set.tile_size
	land_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	land_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	water_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	water_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	flight_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	flight_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	land_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	water_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	flight_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	# needs to be called to make the above changes take effect immediately
	land_astar.update()
	water_astar.update()
	flight_astar.update()
	
	for i in tilemap_size.x:
		for j in tilemap_size.y:
			var pos = Vector2i(i, j)
			var tile_data = get_cell_tile_data(pos)
			match tile_data.get_custom_data("tile_type"):
				"wall":
					land_astar.set_point_solid(pos)
					water_astar.set_point_solid(pos)
					flight_astar.set_point_solid(pos)
				"mountain":
					land_astar.set_point_solid(pos)
					water_astar.set_point_solid(pos)
				"water":
					land_astar.set_point_solid(pos)

func is_point_walkable(point, mobility):
	var pos = local_to_map(point)
	match mobility:
		"land":
			if land_astar.region.has_point(pos) and not land_astar.is_point_solid(pos):
				return true
		"water":
			if water_astar.region.has_point(pos) and not water_astar.is_point_solid(pos):
				return true
		"flight":
			if flight_astar.region.has_point(pos) and not flight_astar.is_point_solid(pos):
				return true
		_:
			return false
		
	return false
	
# wrapper for robots to claim positions on all three mobility maps
func claim_pos(pos, solid = true):
	land_astar.set_point_solid(pos, solid)
	water_astar.set_point_solid(pos, solid)
	flight_astar.set_point_solid(pos, solid)	
