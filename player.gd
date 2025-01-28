extends Node2D

func rage_state(is_rage):
	if is_rage:
		modulate = Color.FIREBRICK
	else:
		modulate = Color.WHITE
