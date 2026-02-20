class_name Lib

const UNIQUE_ORDERING = ["swim", "flight"]
const EFFECT_ORDERING = ["health", "energy", "power", "speed", "capacity", "construction"]
# return true if a comes before b, false otherwise
static func upgrade_comparator(a: Upgrade, b: Upgrade):
	if a.unique and not b.unique:
		return true
	elif b.unique and not a.unique:
		return false
	elif a.unique and b.unique:
		return UNIQUE_ORDERING.find(a.effect) < UNIQUE_ORDERING.find(b.effect)
	elif a.effect != b.effect:
		return EFFECT_ORDERING.find(a.effect) < EFFECT_ORDERING.find(b.effect)
	else:
		return a.effect_strength > b.effect_strength
		
static func json_comparator(a: Dictionary, b: Dictionary):
	if a["unique"] and not b["unique"]:
		return true
	elif b["unique"] and not a["unique"]:
		return false
	elif a["unique"] and b["unique"]:
		return UNIQUE_ORDERING.find(a["effect"]) < UNIQUE_ORDERING.find(b["effect"])
	elif a["effect"] != b["effect"]:
		return EFFECT_ORDERING.find(a["effect"]) < EFFECT_ORDERING.find(b["effect"])
	else:
		return a["effect_strength"] > b["effect_strength"]

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
