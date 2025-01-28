extends StateScript

func state_enter():
	print("Rage State")
	target.rage_state(true)

func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		activate_trigger("rage_trigger")
		
	var vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * 2
	target.position += vector 
