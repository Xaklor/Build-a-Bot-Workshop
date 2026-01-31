class_name Lib

class Upgrade:
	var sprite: Sprite2D
	var polyomino: Array[Vector2i]
	var effect: String
	var effect_strength: int
	func _init(sprite: Sprite2D, polyomino: Array[Vector2i], effect: String, effect_strength: int = 0):
		self.sprite = sprite
		self.polyomino = polyomino
		self.effect = effect
		self.effect_strength = effect_strength
