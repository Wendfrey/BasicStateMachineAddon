extends Node
class_name StateMachineNode

const StateData = StateMachineResource.StateData
const TransitionData = StateMachineResource.TransitionData
const BaseCondition = TransitionData.BaseCondition

@export var target:Node
@export var stateMachineResource: StateMachineResource

var instanced_states: Dictionary = {}
var current_state:StateScript = null
var current_transitions = Array()
var parameters = {}
var check_conditions = false

func _ready():
	if not stateMachineResource:
		return
		
	stateMachineResource.load_instance_map()
	#Load parameter list
	for n in stateMachineResource.get_parameter_floats_name_list():
		parameters[n] = 0
	for n in stateMachineResource.get_paremeter_triggers_name_list():
		parameters[n] = false
	
	
	for state_data:StateMachineResource.StateData in stateMachineResource._get_state_instance_map().values():
		var scriptState:StateScript = load(state_data.script_state).new()
		scriptState.smNode = self
		instanced_states[state_data.name] = scriptState
	
	current_transitions = stateMachineResource.get_transitions("").values()
	if not current_transitions:
		push_error("No starting node defined")
		return
		
	_evaluate_current_transitions()

func _navigate_to_next_state(stateName):
	if stateName == "":
		current_state.state_exit()
		current_state = null
		print("Finish!")
	else:
		_reset_time_on_state()
		if current_state: current_state.state_exit()
		current_state = (instanced_states.get(stateName) as StateScript)
		current_transitions = stateMachineResource.get_transitions(stateName).values()
		current_state.state_enter()
		if not current_state:
			push_error("Error! Unkownk state")

func _evaluate_current_transitions():
	var filtered = current_transitions.filter(func (value):
		return value.evaluate(parameters)
	)
	_reset_triggers()
	
	if filtered.is_empty():
		return
	
	check_conditions = true
	_navigate_to_next_state(filtered.pop_back().stateTo)

func _reset_triggers():
	for n in stateMachineResource.get_paremeter_triggers_name_list():
		parameters[n] = false

func _reset_time_on_state():
	parameters["time_on_state"] = 0

func _process(delta):
	if current_state:
		current_state._process(delta)

func _physics_process(delta):
	if current_state:
		set_parameter_float("time_on_state", parameters.get("time_on_state") + delta)
		current_state._physics_process(delta)
		_evaluate_current_transitions()

func set_parameter_float(_name, _value):
	if stateMachineResource.get_parameter_floats_name_list().has(_name):
		parameters[_name] = _value
		check_conditions = true
	else:
		push_error("Not an existing float parameter")

func active_trigger(_name):
	if stateMachineResource.get_paremeter_triggers_name_list().has(_name):
		parameters[_name] = true
		check_conditions = true
	else:
		push_error("Not an existing trigger parameter")

func get_parameter(p_name):
	return parameters.get(p_name)
