extends RefCounted

const ClassType = preload("res://addons/basic_fsm/data_helpers/state/StateData.gd")

var ui_pos: Vector2:
	set(value): if (_setter_state_update(&"ui_pos", value)): ui_pos = value
var script_state: String:
	set(value): if (_setter_state_update(&"script_state", value)): script_state = value
var name:String:
	set(value):
		if (_setter_state_update(&"name", value)):
			name = value
var owner:WeakRef

func _init(owner:StateMachineResource):
	self.owner = weakref(owner)

func _setter_state_update(attribute, value) -> bool:
	var _o = owner.get_ref()
	return (not _o or _o._state_update(self, attribute, value))

func _to_dict() -> Dictionary:
	return {
		type= &"StateData",
		name= name,
		ui_pos_x = ui_pos.x if ui_pos else 0,
		ui_pos_y = ui_pos.y if ui_pos else 0,
		script_state= script_state
	}

static func _from_dict(source: Dictionary, owner:StateMachineResource) -> ClassType:
	var state = ClassType.new(owner)
	state.name = source.get(&"name")
	state.ui_pos = Vector2(source.get(&"ui_pos_x",0),source.get(&"ui_pos_y",0))
	state.script_state = source.get(&"script_state")
	return state
