extends Area2D

var hp = 5

func _process(delta: float) -> void:
	if $hurt_highlight.color.a > 0:
		$hurt_highlight.color.a -= 0.01
		
	if hp <= 0:
		queue_free()
		
func take_damage(damage: int):
	hp -= damage
	$hurt_highlight.color.a = 1
