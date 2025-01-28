@tool
extends Resource
class_name StateMachineResource
# Resource that holds all the information of the state machine data.
# this information is saved in 2 separate arrays: 
#		- state array
#		- transition array
# 
# It is also in charge to control creation, removal and updating the data
# To allow ease of updating the data, it has been created internal classes which
# react to data updates (See 'Helper Interfaces' below, or State/Transition/
# Condition regions)

const StateData = preload("res://addons/basic_fsm/data_helpers/state/StateData.gd")
const TransitionData = preload("res://addons/basic_fsm/data_helpers/transition/TransitionData.gd")
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")

const STATES: StringName = &"states"
const TRANSITIONS: StringName = &"transitions"
const GLOBAL_PARAMS = {"on_finish": ParamTrigger, "time_on_state": ParamFloat}

const PARAM_TYPES = [ ParamFloat, ParamTrigger]
const ParamTrigger = &"trigger"
const ParamFloat = &"float"

#map of current instances, since it isn't exported it won't be saved on resource
var _instance_map:Dictionary = {
	&"states": {},#states are found by name
	&"transitions":{}#transitions are found first by stateFrom, second by stateTo
}

#array of states that contains info in dict shape, look at StateData#_to_dict()
#to look at the structure
@export var state_array: Array = []

#array of transition that contains info in dict shape, look at TransitionData#_to_dict()
#to look at the structure
#They also contain an array of parameters
@export var transition_array: Array = []

#dictionary of custom parameters, same pattern as GLOBAL_PARAMS
@export var custom_parameters:Dictionary = {}

#only used on editor {
@export var ui_start_pos:Vector2
@export var ui_end_pos:Vector2
@export var offset:Vector2i
#}

func _init():
	GLOBAL_PARAMS.make_read_only()
	PARAM_TYPES.make_read_only()
	
	load_instance_map()


#region PUBLIC FUNCTIONS

###These functions are the ones the be called for external classes

func load_instance_map():
	_get_state_instance_map().clear()
	_get_transition_instance_map().clear()
	state_array.map(
		func (value:Dictionary):
			return StateData._from_dict(value, self)
	).all(
		func (value:StateData):
			_get_state_instance_map()[value.name] = value
			return true
	)
	
	transition_array.map(
		func (value:Dictionary):
			return TransitionData._from_dict(value, self)
	).all(
		func (value:TransitionData):
			if not _get_transition_instance_map().has(value.stateFrom):
				_get_transition_instance_map()[value.stateFrom] = {value.stateTo:value}
			else: 
				_get_transition_instance_map()[value.stateFrom][value.stateTo] = value
			return true
	)

func add_state(name:String, script_state:String) -> StateData:
	var repeated_state = state_array.filter(func (value): return name == value.get("name"))
	if (repeated_state.size() > 0):
		return null

	var state = StateData.new(self)
	state.name = name
	state.script_state = script_state
	state_array.append(state._to_dict())
	_add_state_to_instance(state)
	return state

func add_transition(state_from:String, state_to:String) -> TransitionData:
	
	#Search for the internal data, if data exists then it is a duplicate
	if not _internal_get_transition_dict(state_from, state_to).is_empty():
		print("Not unique instance - rejected { '", state_from, "', '", state_to, "' }")
		return null

	var transition:TransitionData = TransitionData.new()
	transition.stateFrom = state_from
	transition.stateTo = state_to
	transition.owner = weakref(self)
	transition_array.append(transition._to_dict())
	_add_transition_to_instance_map(transition)

	return transition

func get_state(name:String) -> StateData:
	return _get_state_instance_map().get(name)

func get_transitions(stateFrom:String) -> Dictionary:
	return _get_transition_instance_map().get(stateFrom)

func get_transition(stateFrom:String, stateTo:String) -> TransitionData:
	var outerDict = _get_transition_instance_map().get(stateFrom)
	if outerDict:
		return outerDict.get(stateTo)
	return null

func delete_state(state:StateData):
	var filtered = state_array.filter(
		func (value:Dictionary):
			return value.get("name") != state.name
	)

	if filtered.size() == state_array.size():
		push_error("State not found")
		return
	_remove_state_from_instance(state)
	state_array = filtered

	#lets remove all transitions connected to state
	#inverse of filtered, we get a list of transitions to remove
	var t_filtered = transition_array.filter(
		func (value:Dictionary):
			return value.get(&"stateFrom") == state.name or value.get(&"stateTo") == state.name
	)

	t_filtered.all(
		func (value:Dictionary):
			delete_transition(_get_transition_instance_map()[value.get(&"stateFrom")][value.get(&"stateTo")])
			return true
	)

func delete_transition( _t:TransitionData):
	var new_transition_array = transition_array.filter(
		func (_value):
			var return_v = _value.get(&"stateFrom") != _t.stateFrom or \
				   _value.get(&"stateTo") != _t.stateTo
			return return_v
	)
	
	transition_array = new_transition_array
	_remove_transition_from_instance(_t)

func create_parameter(parameter_name, parameter_type) -> bool:
	if GLOBAL_PARAMS.has(parameter_name):
		return false
	if not parameter_name or custom_parameters.has(parameter_name) or not PARAM_TYPES.has(parameter_type):
		return false
	
	custom_parameters[parameter_name] = parameter_type
	return true

func delete_parameter(parameter_name):
	var result = custom_parameters.erase(parameter_name)
	if result:
		_get_all_conditions_instances().all(
			func (condition:BaseCondition):
				condition._updated_parameter(parameter_name, "")
				return true
		)
	return result

func _update_parameter_type(_param, _type) -> bool:
	if not _param or not _type:
		return false
	if GLOBAL_PARAMS.has(_param):
		return false
	if not custom_parameters.has(_param):
		return false
	
	if custom_parameters[_param] != _type:
		custom_parameters[_param] = _type
		_get_all_conditions_instances().all(
			func (condition:BaseCondition):
				#Since conditions only support one type of param (trigger or float),
				# updating the parameter type would clash with the condition
				# supported type, so it is safe to assume we can remove it from this condition
				condition._updated_parameter(_param, "")
				return true
		)
	return true

func _update_parameter_name(_param, _n_param):
	if not _param or not _n_param or _param == _n_param:
		return false
	if GLOBAL_PARAMS.has(_param) or GLOBAL_PARAMS.has(_n_param):
		return false
	if not custom_parameters.has(_param) or custom_parameters.has(_n_param):
		return false
		
	var type = custom_parameters[_param]
	custom_parameters.erase(_param)
	custom_parameters[_n_param] = type
	_get_all_conditions_instances().all(
		func (condition:BaseCondition):
			#Since conditions only support one type of param (trigger or float),
			# updating the parameter type would clash with the condition
			# supported type, so it is safe to assume we can remove it from this condition
			condition._updated_parameter(_param, _n_param)
			return true
	)
	return true

func get_paremeter_triggers_name_list() -> Array:
	var array_names = GLOBAL_PARAMS.keys().filter(
		func (_key): return GLOBAL_PARAMS[_key] == ParamTrigger
	)
	array_names.append_array(
		custom_parameters.keys().filter(
			func (_key): return custom_parameters[_key] == ParamTrigger
		)
	)
	
	return array_names

func get_parameter_floats_name_list() -> Array:
	var array_names = GLOBAL_PARAMS.keys().filter(
		func (_key): return GLOBAL_PARAMS[_key] == ParamFloat
	)
	array_names.append_array(
		custom_parameters.keys().filter(
			func (_key): return custom_parameters[_key] == ParamFloat
		)
	)
	
	return array_names
	
#endregion

#region PRIVATE FUNCTIONS
### These are not made to be called externally

func _get_state_instance_map()-> Dictionary:
	return _instance_map[STATES]

func _get_transition_instance_map() -> Dictionary:
	return _instance_map[TRANSITIONS]
	
func _get_all_conditions_instances():
	var conditions = []
	_get_transition_instance_map().values().map(
		func (dict):
			return dict.values().all(
				func (transition):
					conditions.append_array(transition.get_conditions())
					return true
			)
	)
	return conditions

func _add_state_to_instance(state:StateData):
	_get_state_instance_map()[state.name] = state

func _add_transition_to_instance_map(transition:TransitionData):
	var transitions_map = _get_transition_instance_map()
	if not transitions_map.has(transition.stateFrom):
		transitions_map[transition.stateFrom] = {}
	transitions_map[transition.stateFrom][transition.stateTo] = transition

func _remove_state_from_instance(state:StateData):
	_get_state_instance_map().erase(state.name)

func _remove_transition_from_instance(transition:TransitionData):
	var fromMap:Dictionary = _get_transition_instance_map().get(transition.stateFrom)
	fromMap.erase(transition.stateTo)
	if fromMap.is_empty():
		_get_transition_instance_map().erase(fromMap)

func _internal_get_state_dict(state_name:String) -> Dictionary:
	var value = state_array.filter(func (value): return state_name == value[&"name"])\
		.pop_back()
	return value if value else {}

func _internal_get_transitions_dict(state_from:String) -> Array:
	return transition_array.filter(
		func (value):
			return state_from == value[&"stateFrom"]
	)

func _internal_get_transition_dict(state_from:String, state_to:String) -> Dictionary:
	var value = transition_array.filter(
		func (value):
			return state_from == value[&"stateFrom"] and state_to == value[&"stateTo"]
	).pop_back()
	return value if value else {}
#endregion

#region OBJECT UPDATE LISTENERS also private
### These methods are made to be called when any Helper class (State, Transition, Condition)
### are updated, these methods will return a boolean true if the change is allowed and
### automatically updates their correspondent dictionary of data
###
### (WIP) each helper class implements an _update method that manages if an update
### is allowed, this is to allow each class to manage their own properties and
### specify when a change is allowed

#TODO each class should have an _update(...) function like BaseCondition, to reduce
# work of implementing custom states/transitions
func _state_update(state:StateData, attribute:StringName, new_value:Variant) -> bool:
	var dict = _internal_get_state_dict(state.name)
	
	#Nothing to modify, allow change
	if dict.is_empty(): return true
	
	match (attribute):
		&"ui_pos":
			dict[&"ui_pos_x"] = new_value.x
			dict[&"ui_pos_y"] = new_value.y
		&"script_state":
			dict[attribute] = new_value
		&"name":
			#Empty state name is reserved for entrance/exit points
			if new_value.is_empty() or not _internal_get_state_dict(new_value).is_empty():
				#State with that name already exists or invalid name
				return false
			else:
				dict[attribute] = new_value
				_get_state_instance_map().erase(state.name)
				_get_state_instance_map()[new_value] = state
				_state_name_changed_update_transitions(state.name, new_value)
		_: return false
	return true
	
func _state_name_changed_update_transitions(old_name:String, new_name:String):
	#First we change internal data
	var _ta_f = transition_array.filter(
		func (value): return value[&"stateFrom"] == old_name or value[&"stateTo"] == old_name
	) 
	_ta_f.all(
		func (value):
			if value[&"stateFrom"] == old_name: value[&"stateFrom"] = new_name
			if value[&"stateTo"] == old_name: value[&"stateTo"] = new_name
			return true
	)
	
	#Now _instance_map, oh god is gonna be so slow
	#our current level {state1: {state2:instance, ... }, ... }
	var transition_instance_map = _get_transition_instance_map()
	if transition_instance_map.has(old_name):
		var _instance_map_old_name:Dictionary = transition_instance_map[old_name]
		#our current level {state2:instance, ... }
		transition_instance_map.erase(old_name)
		transition_instance_map[new_name] = _instance_map_old_name
		for transition:TransitionData in _instance_map_old_name.values():
			transition.stateFrom = new_name
	
	var internal_dicts: Array = transition_instance_map.values()
	#our current level [{state2:instance, ... },{state2:instance, ... }]
	for dict:Dictionary in internal_dicts:
		if dict.has(old_name):
			dict[old_name].stateTo = new_name

func _transition_update(transition:TransitionData, attribute:StringName, new_value:Variant) -> bool:
	var tData = _internal_get_transition_dict(transition.stateFrom, transition.stateTo)
	
	if tData.is_empty():
		#It is either a new transition or either stateFrom or stateTo updated it's
		# name
		return true

	#Disable updates of name
	match(attribute):
		&"stateFrom", &"stateTo":
			return tData[attribute] == new_value
		_:
			return false
	
func _transition_update_added_condition(transition:TransitionData, cBase: TransitionData.BaseCondition) -> bool:
	var t_data = _internal_get_transition_dict(transition.stateFrom, transition.stateTo)
	if t_data.is_empty(): return true #Transition is not in our database, we can ignore their changes
	
	var index = transition.get_conditions().find(cBase)
	#Condition is already in transition, do no repeat
	if index != -1: return false
	
	var c_data = cBase._to_dict()
	t_data.get(&"conditions").append(c_data)
	return true

func _transition_update_remove_condition(transition:TransitionData, cBase:TransitionData.BaseCondition) -> bool:
	var t_data = _internal_get_transition_dict(transition.stateFrom, transition.stateTo)
	if t_data.is_empty(): return true #Transition is not in our database, we can ignore their changes
	
	var index = transition.get_conditions().find(cBase)
	#go back if Condition doesn't exist
	if index == -1: return false
	
	t_data[&"conditions"].remove_at(index)
	return true

func _transition_condition_update(transition:TransitionData, cBase: TransitionData.BaseCondition, attribute:StringName, new_value:Variant) -> bool:
	var t_data = _internal_get_transition_dict(transition.stateFrom, transition.stateTo)
	
	var index = transition.get_conditions().find(cBase)
	#In case Transition wasn't added or condition wasn't added (like creating the Condition)
	if index == -1 or t_data.is_empty(): return true
	var c_data = t_data.get(&"conditions")[transition.get_conditions().find(cBase)]
	return cBase._update(c_data, attribute, new_value)
#endregion
