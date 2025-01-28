extends "res://addons/basic_fsm/data_helpers/condition/ComparatorCondition.gd"

const StaticCondition = preload("res://addons/basic_fsm/data_helpers/condition/StaticCondition.gd")

#Mostly valuable for testing
var valueR: float:
	set(value): if (_setter_condition_allowed(&"valueR", value)): valueR = value
var valueL: float:
	set(value): if (_setter_condition_allowed(&"valueL", value)): valueL = value

func _evaluate(context) -> bool:
	return _evaluate_compare(valueL, valueR)

func _update(c_data:Dictionary, attribute:StringName, value:Variant) -> bool:
	match(attribute):
		&"valueL", &"valueR":
			c_data[attribute] = value
			return true
		_: return super._update(c_data, attribute, value)
		
func _to_string():
	var combineText
	var compareText
	match (combinator):
		CombinatorEnum.AND:
			combineText = "AND"
		CombinatorEnum.OR:
			combineText = "OR"

	match(comparator):
		ComparatorEnum.EQ:
			compareText = "=="
		ComparatorEnum.NEQ:
			compareText = "!="
		ComparatorEnum.GT:
			compareText = ">"
		ComparatorEnum.GT_EQ:
			compareText = ">="
		ComparatorEnum.LT:
			compareText = "<"
		ComparatorEnum.LT_EQ:
			compareText = "<="

	return "{ {cb} {vl} {op} {vr} }".format({cb = combineText, vl= str(valueL), vr= str(valueR), op= compareText})

func _to_dict() -> Dictionary:
	var dict = super._to_dict()
	dict[&"type"] = &"StaticCondition"
	dict[&"valueL"] = valueL
	dict[&"valueR"] = valueR
	return dict

static func _from_dict(source, owner:TransitionData, condition_optional = null) -> StaticCondition:
	if not condition_optional:
		condition_optional = StaticCondition.new(owner)
	condition_optional = super._from_dict(source, owner, condition_optional)
	condition_optional.valueL = source.get(&"valueL")
	condition_optional.valueR = source.get(&"valueR")
	return condition_optional
