extends StateScript

func state_enter():
	print("Normal state")
	target.rage_state(false)

func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		activate_trigger("rage_trigger")

	var vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	target.position += vector 
