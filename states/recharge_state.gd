extends StateScript

func _state_enter():
	target.reloading_color()
	
func _physics_process(delta):
	var vector = Input.get_vector("move_left", "move_right", "move_up", "move_down") * 2
	target.position += vector.normalized() * target.speed * delta * 0.5
	target.rotation = vector.normalized().angle()

func _state_exit():
	set_parameter("bullets", target.max_bullets)
