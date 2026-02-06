class_name Lib

class Upgrade:
	var sprite: Sprite2D
	var mini: Sprite2D
	var polyomino: Array[Vector2i]
	var effect: String
	var effect_strength: int
	var unique: bool
	var loose: bool
	func _init(sprite: Sprite2D, mini: Sprite2D, polyomino: Array[Vector2i], effect: String, effect_strength: int = 0, unique: bool = false):
		self.sprite = sprite
		self.mini = mini
		self.polyomino = polyomino
		self.effect = effect
		self.effect_strength = effect_strength
		self.unique = unique
		self.loose = false
