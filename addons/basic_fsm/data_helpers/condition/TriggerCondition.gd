extends "res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd"

const TriggerCondition = preload("res://addons/basic_fsm/data_helpers/condition/TriggerCondition.gd")

var trigger_param:StringName:
	set(value): if (_setter_condition_allowed(&"trigger_param", value)): trigger_param = value

func _evaluate(context:Dictionary) -> bool:
	return context.get(trigger_param, false)

func _update(c_data:Dictionary, attribute:StringName, value:Variant) -> bool:
	var _o = owner.get_ref()
	match(attribute):
		&"trigger_param":
			var valid = _trigger_exists(value)
			if valid:
				c_data[attribute] = value
			return valid
		_: return super._update(c_data, attribute, value)

func _updated_parameter(old_param, new_param):
	if trigger_param == old_param and _trigger_exists(new_param):
		trigger_param = new_param

func _to_dict() -> Dictionary:
	var dict = super._to_dict()
	dict[&"type"] = &"TriggerCondition"
	dict[&"trigger_param"] = trigger_param
	return dict

func _trigger_exists(trigger_name:String) -> bool:
	var _o = owner.get_ref()
	if not _o:
		return true
	var _o_o = _o.owner.get_ref()
	if not _o_o:
		return true
	return _o_o.is_parameter_trigger(trigger_name)

static func _from_dict(source, owner:TransitionData, condition_optional = null) -> TriggerCondition:
	if not condition_optional:
		condition_optional = TriggerCondition.new(owner)
	condition_optional = super._from_dict(source, owner, condition_optional)
	condition_optional.trigger_param = source.get(&"trigger_param")
	return condition_optional
