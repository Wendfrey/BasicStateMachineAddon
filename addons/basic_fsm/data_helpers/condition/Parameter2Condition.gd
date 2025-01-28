extends "res://addons/basic_fsm/data_helpers/condition/ComparatorCondition.gd"

const Parameter2Condition = preload("res://addons/basic_fsm/data_helpers/condition/Parameter2Condition.gd")

var parameterL:String:
	set(value): if (_setter_condition_allowed(&"parameterL", value)): parameterL = value
var parameterR:String:
	set(value): if (_setter_condition_allowed(&"parameterR", value)): parameterR = value

func _evaluate(context) -> bool:
	return _evaluate_compare(context[parameterL],context[parameterR])
	
func _update(c_data:Dictionary, attribute:StringName, value:Variant) -> bool:
	match(attribute):
		&"parameterL", &"parameterR":
			var valid = _parameter_exists(value)
			if valid:
				c_data[attribute] = value
			return valid
		_: return super._update(c_data, attribute, value)
		
func _updated_parameter(old_param, new_param):
	if _parameter_exists(new_param):
		if parameterL == old_param:
			parameterL = new_param
		if parameterR == old_param:
			parameterR = new_param
	
func _to_dict() -> Dictionary:
	var dict = super._to_dict()
	dict[&"type"] = &"Parameter2Condition"
	dict[&"parameterL"] = parameterL
	dict[&"parameterR"] = parameterR
	return dict

static func _from_dict(source, owner:TransitionData, condition_optional = null) -> Parameter2Condition:
	if not condition_optional:
		condition_optional = Parameter2Condition.new(owner)
	condition_optional = super._from_dict(source, owner, condition_optional)
	condition_optional.parameterL = source.get(&"parameterL")
	condition_optional.parameterR = source.get(&"parameterR")
	return condition_optional
