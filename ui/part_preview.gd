extends ColorRect

func initialize(points: Array[Vector2i], texture: Texture):
	for p in points:
		var id = ((p.y + 2) * 5) + p.x + 2 + 1
		get_child(id).visible = true
		get_child(id).texture = texture
