class_name Equipment

static var weapons: Array[Weapon] = [
	Weapon.new(1, true, "wooden bow"),
	Weapon.new(3, true, "iron bow"),
	Weapon.new(7, true, "celestial bow"),
	Weapon.new(1, false, "wooden sword"),
	Weapon.new(3, false, "iron sword"),
	Weapon.new(7, false, "celestial sword")]

class Weapon:
	var name: String
	var attack: int
	var ranged: bool
	func _init(attack: int, ranged: bool, name: String) -> void:
		self.name = name
		self.attack = attack
		self.ranged = ranged
