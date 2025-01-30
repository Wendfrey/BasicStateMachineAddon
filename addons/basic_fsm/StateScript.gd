extends RefCounted
class_name StateScript

const SMNode = preload("res://addons/basic_fsm/StateMachineNode.gd")


var smNode:SMNode

var target:Node : 
	set(value): pass
	get:
		if smNode:
			return smNode.target
		return null

func activate_trigger(_trigger:String):
	smNode.active_trigger(_trigger)
	
func set_parameter(_parameter:String, _value:float):
	smNode.set_parameter_float(_parameter, _value)
	
func _state_enter():
	pass
	
func _state_exit():
	pass
	
func _process(delta: float):
	pass
	
func _physics_process(delta: float):
	pass
