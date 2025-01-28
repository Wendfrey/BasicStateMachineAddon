extends RefCounted
#Holds information of the transitions of states and the conditions attached
# for it to happen. Also eases condition checking with evaluate.
#
# _conditions should not be accessed directly outside of TransitionData.
#
# Setters for stateFrom and stateTo should'nt allow for it to change,
# unless a disparity between the helper class and internal data occurs.
# (Only should happen when '_state_name_changed_update_transitions' happens)

const TransitionData = preload("res://addons/basic_fsm/data_helpers/transition/TransitionData.gd")
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")
const ComparatorCondition = preload("res://addons/basic_fsm/data_helpers/condition/ComparatorCondition.gd")
const StaticCondition = preload("res://addons/basic_fsm/data_helpers/condition/StaticCondition.gd")

var _conditions: Array = []
#StateFrom and StateTo only exists due to stateFrom/stateTo, do not allow
#changes never (only exception being the State itself changing it's name)
var stateFrom: String:
	set(value): if(_setter_transition_allowed(&"stateFrom", value)): stateFrom = value
var stateTo: String:
	set(value): if(_setter_transition_allowed(&"stateTo", value)): stateTo = value
var owner:WeakRef = weakref(null)

func evaluate(context) -> bool:
	if _conditions.is_empty():
		return true
	
	var tempConditions = _conditions.duplicate()
	var result: bool = tempConditions.pop_front()._evaluate(context)
	for _cond:BaseCondition in tempConditions:
		match _cond.combinator:
			BaseCondition.CombinatorEnum.AND:
				# we skip evaluate because due to result being false makes next
				# ANDs useless to check
				if result:
					result = _cond._evaluate(context)
			BaseCondition.CombinatorEnum.OR:
				if result:
					return true
				else:
					result = _cond._evaluate(context)
	return result

func get_conditions():
	return _conditions.duplicate()

func append_condition( _condition:BaseCondition):
	var error_msg:String = ""
	var _c_owner = null if not _condition else _condition.owner.get_ref()
	if _condition and not _conditions.has(_condition) and ( not _c_owner or _c_owner == self ):
		_condition.owner = weakref(self)
		var _o = owner.get_ref()
		if not _o or _o._transition_update_added_condition(self, _condition):
			_conditions.append(_condition)
		else:
			error_msg = "Error appending condition to transition."
	elif not _condition:
		error_msg = "Null condition"
	elif _conditions.has(_condition):
		error_msg = "Condition is already incorporated"
	elif _c_owner and _c_owner != self:
		error_msg = "This condition already belongs to other transition"
	
	if not error_msg.is_empty():
		push_error("Error! " + error_msg)

func remove_condition(cBase:BaseCondition):
	var _o = owner.get_ref()
	if not _o or _o._transition_update_remove_condition(self, cBase):
		_conditions.erase(cBase)

func _condition_update(condition:BaseCondition, attribute:StringName, new_value) -> bool:
	var _o:StateMachineResource = owner.get_ref()
	return not _o or _o._transition_condition_update(self, condition, attribute, new_value)

func get_param_float_list() -> Array:
	var _o:StateMachineResource = owner.get_ref()
	if _o:
		return _o.get_parameter_floats_name_list()
	return [] 

func get_param_trigger_list() -> Array:
	var _o:StateMachineResource = owner.get_ref()
	if _o:
		return _o.get_paremeter_triggers_name_list()
	return [] 

func _to_dict() -> Dictionary:
	return {
		type = &"TransitionData",
		conditions= _conditions.map(func (value:BaseCondition): return value._to_dict()),
		stateFrom = stateFrom,
		stateTo = stateTo
	}

static func _from_dict(source: Dictionary, owner:StateMachineResource) -> TransitionData:
	var transition:TransitionData = TransitionData.new()
	var _dict_conditions = source.get(&"conditions")
	if (_dict_conditions):
		var _c = _dict_conditions.map(
			func (value):
				return FSM_ConditionSpawner.condition_from_data(value, transition)
		)
		transition._conditions = _c
	transition.stateFrom = source.get(&"stateFrom")
	transition.stateTo = source.get(&"stateTo")
	transition.owner = weakref(owner)
	return transition

func _setter_transition_allowed(attribute, value) -> bool:
	var _o = owner.get_ref()
	return (not _o or _o._transition_update(self, attribute, value))

#region Conditions
