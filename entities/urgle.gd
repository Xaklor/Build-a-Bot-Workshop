extends Area2D

var hp = 5

func _process(delta: float) -> void:
	if $sprite/hurt_highlight.color.a > 0:
		$sprite/hurt_highlight.color.a -= 0.01
		
	if hp <= 0:
		queue_free()
		
func take_damage(damage: int):
	hp -= damage
	$sprite/hurt_highlight.color.a = 1
