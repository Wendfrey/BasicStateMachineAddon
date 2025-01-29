extends StateScript

func state_enter():
	target.rage_state(false)

func _physics_process(delta):
	var vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	target.position += vector.normalized() * target.speed * delta
	target.rotation = vector.normalized().angle()
	
	if Input.is_action_just_pressed("shoot_action"):
		target.spawn_bullet()
