extends RefCounted

const TransitionData = preload("res://addons/basic_fsm/data_helpers/transition/TransitionData.gd")
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")

enum CombinatorEnum {AND, OR}

#Base for all conditions, abstract, please do not instantiate
var owner:WeakRef
var combinator: CombinatorEnum = CombinatorEnum.AND:
	set(value): if (_setter_condition_allowed(&"combinator", value)): combinator = value

func _init(owner:TransitionData):
	self.owner = weakref(owner)

# 'context' is expected to have the necesary data for the condition to complete
# It should be a dict containing all the params of the current instance
# and their respective value
func _evaluate(context) -> bool:
	return true

func _setter_condition_allowed(attribute:StringName, value:Variant) -> bool:
	var _o:TransitionData = owner.get_ref()
	return not _o or _o._condition_update(self, attribute, value)

func _update(c_data:Dictionary, attribute:StringName, value:Variant) -> bool:
	match(attribute):
		&"combinator": 
			c_data[attribute] = value
			return true
		_: return false

func _updated_parameter(old_param, new_param):
	pass

func _to_dict() -> Dictionary:
	return {
		&"type": &"BaseCondition",
		&"combinator": combinator
	}
	
static func _from_dict(source, owner:TransitionData, condition_optional = null) -> BaseCondition:
	if not condition_optional:
		condition_optional = BaseCondition.new(owner)

	condition_optional.combinator = source.get(&"combinator")
	return condition_optional
