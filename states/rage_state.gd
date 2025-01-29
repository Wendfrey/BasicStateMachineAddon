extends StateScript

func state_enter():
	print("Rage State")
	target.rage_state(true)

func _physics_process(delta):
	var vector = Input.get_vector("move_left", "move_right", "move_up", "move_down") * 2
	target.position += vector.normalized() * target.speed * 2 * delta
	target.rotation = vector.normalized().angle()
	
	if Input.is_action_just_pressed("shoot_action"):
		target.spawn_bullet()
