extends TileMapLayer

var astar = AStarGrid2D.new()

func _ready():
	var tilemap_size = get_used_rect().end - get_used_rect().position
	astar.region = Rect2i(Vector2i.ZERO, tilemap_size)
	astar.cell_size = tile_set.tile_size
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	# needs to be called to make the above changes take effect immediately
	astar.update()
	
	for i in tilemap_size.x:
		for j in tilemap_size.y:
			var pos = Vector2i(i, j)
			var tile_data = get_cell_tile_data(pos)
			if tile_data and (tile_data.get_custom_data("tile_type") == "mountain" or 
							  tile_data.get_custom_data("tile_type") == "water" or 
							  tile_data.get_custom_data("tile_type") == "wall"):
				astar.set_point_solid(pos)

func is_point_walkable(point):
	var pos = local_to_map(point)
	if astar.region.has_point(pos) and not astar.is_point_solid(pos):
		return true
		
	return false
