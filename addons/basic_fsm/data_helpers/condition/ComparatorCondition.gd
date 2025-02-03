extends "res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd"
#Abstract Class
# Base for all comparing floating values, due _evaluate_compare and ComparatorEnum
const ComparatorCondition = preload("res://addons/basic_fsm/data_helpers/condition/ComparatorCondition.gd")

enum ComparatorEnum {EQ, NEQ, GT, GT_EQ, LT, LT_EQ}

#Base for value comparison conditions, abstract, please do not instantiate
var comparator: ComparatorEnum = ComparatorEnum.EQ:
	set(value):
		if (_setter_condition_allowed(&"comparator", value)): comparator = value

func _evaluate(context) -> bool:
	return _evaluate_compare(0,0)

func _evaluate_compare(a, b) -> bool:
	var comparison_value = a-b
	var result:int = 0
	if (is_zero_approx(comparison_value)):
		result = 0
	elif comparison_value > 0:
		result = 1
	else:
		result = -1

	match(comparator):
		ComparatorEnum.EQ:
			return result == 0
		ComparatorEnum.NEQ:
			return result != 0
		ComparatorEnum.GT:
			return result > 0
		ComparatorEnum.GT_EQ:
			return result >= 0
		ComparatorEnum.LT:
			return result < 0
		ComparatorEnum.LT_EQ:
			return result <= 0
		_: return false
	
func _update(c_data:Dictionary, attribute:StringName, value:Variant) -> bool:
	match(attribute):
		&"comparator": 
			c_data[attribute] = value
			return true
		_: return super._update(c_data, attribute, value)

func _to_dict() -> Dictionary:
	var dict = super._to_dict()
	dict[&"type"] = &"ComparatorCondition"
	dict[&"comparator"] = comparator
	return dict

func _parameter_exists(parameter_name:String) -> bool:
	var _o = owner.get_ref()
	if not _o:
		return true
	var _o_o = _o.owner.get_ref()
	if not _o_o:
		return true
	
	return _o_o.is_parameter_int(parameter_name) or _o_o.is_parameter_float(parameter_name)

static func _from_dict(source, owner:TransitionData, condition_optional = null) -> ComparatorCondition:
	if not condition_optional:
		condition_optional = ComparatorCondition.new(owner)
	condition_optional = super._from_dict(source, owner, condition_optional)
	condition_optional.comparator = source.get(&"comparator")
	return condition_optional
