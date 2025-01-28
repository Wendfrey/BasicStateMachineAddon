extends RefCounted
class_name FSM_ConditionSpawner

const TransitionData = preload("res://addons/basic_fsm/data_helpers/transition/TransitionData.gd")

#abstract
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")
const ComparatorCondition = preload("res://addons/basic_fsm/data_helpers/condition/ComparatorCondition.gd")
#

const Parameter2Condition = preload("res://addons/basic_fsm/data_helpers/condition/Parameter2Condition.gd")
const ParameterCondition = preload("res://addons/basic_fsm/data_helpers/condition/ParameterCondition.gd")
const StaticCondition = preload("res://addons/basic_fsm/data_helpers/condition/StaticCondition.gd")
const TriggerCondition = preload("res://addons/basic_fsm/data_helpers/condition/TriggerCondition.gd")

static func new_static_condition(combinator: BaseCondition.CombinatorEnum, comparator: ComparatorCondition.ComparatorEnum, valueLeft:float, valueRight:float, parent:TransitionData = null) -> StaticCondition:
	return StaticCondition._from_dict(
		{
			valueL= valueLeft,
			valueR = valueRight,
			comparator = comparator,
			combinator = combinator
		},
		parent
	)
	
static func new_parameter_condition(combinator: BaseCondition.CombinatorEnum, comparator: ComparatorCondition.ComparatorEnum, parameter:String, valueRight:float, parent:TransitionData = null) -> ParameterCondition:
	return ParameterCondition._from_dict(
		{
			parameter = parameter,
			valueR = valueRight,
			comparator = comparator,
			combinator = combinator
		},
		parent
	)
	
static func new_parameter_2_condition(combinator: BaseCondition.CombinatorEnum, comparator: ComparatorCondition.ComparatorEnum, parameterL:String, parameterR:String, parent:TransitionData = null) -> Parameter2Condition:
	return Parameter2Condition._from_dict(
		{
			parameterL = parameterL,
			parameterR = parameterR,
			comparator = comparator,
			combinator = combinator
		},
		parent
	)

static func new_trigger_condition(combinator: BaseCondition.CombinatorEnum, comparator: ComparatorCondition.ComparatorEnum, trigger_param:String, parent:TransitionData = null) -> TriggerCondition:
	return TriggerCondition._from_dict(
		{
			trigger_param = trigger_param,
			comparator = comparator,
			combinator = combinator
		},
		parent
	)

static func condition_from_data(data:Dictionary, parent:TransitionData = null) -> BaseCondition:
	match(data.get(&"type")):
		&"StaticCondition": return StaticCondition._from_dict(data, parent)
		&"ParameterCondition": return ParameterCondition._from_dict(data, parent)
		&"Parameter2Condition": return Parameter2Condition._from_dict(data, parent)
		&"TriggerCondition": return TriggerCondition._from_dict(data, parent)
		_: return null
