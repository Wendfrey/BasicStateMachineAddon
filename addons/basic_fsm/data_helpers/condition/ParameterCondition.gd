extends "res://addons/basic_fsm/data_helpers/condition/ComparatorCondition.gd"

const ParameterCondition = preload("res://addons/basic_fsm/data_helpers/condition/ParameterCondition.gd")

var parameter: String:
	set(value): if (_setter_condition_allowed(&"parameter", value)): parameter = value
var valueR:float:
	set(value): if (_setter_condition_allowed(&"valueR", value)): valueR = value

func _evaluate(context) -> bool:
	return _evaluate_compare(context[parameter], valueR)
	
func _update(c_data:Dictionary, attribute:StringName, value:Variant) -> bool:
	match(attribute):
		&"parameter":
			var valid = _parameter_exists(value)
			if valid:
				c_data[attribute] = value
			return valid
		&"valueR":
			c_data[attribute] = value
			return true
		_: return super._update(c_data, attribute, value)

func _updated_parameter(old_param, new_param):
	if parameter == old_param and _parameter_exists(new_param):
		parameter = new_param

func _to_dict() -> Dictionary:
	var dict = super._to_dict()
	dict[&"type"] = &"ParameterCondition"
	dict[&"parameter"] = parameter
	dict[&"valueR"] = valueR
	return dict

static func _from_dict(source, owner:TransitionData, condition_optional = null) -> ParameterCondition:
	if not condition_optional:
		condition_optional = ParameterCondition.new(owner)
	condition_optional = super._from_dict(source, owner, condition_optional)
	condition_optional.parameter = source.get(&"parameter")
	condition_optional.valueR = source.get(&"valueR")
	return condition_optional
