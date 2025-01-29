extends CharacterBody2D

var direction:Vector2 = Vector2.RIGHT
var time_alive = 5
func _physics_process(delta: float) -> void:
	position += direction * delta
	if time_alive <= 0:
		queue_free()
	time_alive -= delta
