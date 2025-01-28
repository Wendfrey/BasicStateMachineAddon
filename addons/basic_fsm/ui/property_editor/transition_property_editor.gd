@tool
extends Control

const TransitionData = StateMachineResource.TransitionData

const Condition2ParameterNode = preload("res://addons/basic_fsm/ui/property_editor/condition_2_parameters.tscn")
const ConditionParameterNode = preload("res://addons/basic_fsm/ui/property_editor/condition_parameters.tscn")
const ConditionTriggerNode = preload("res://addons/basic_fsm/ui/property_editor/condition_triggers.tscn")

const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")
const Parameter2Condition = preload("res://addons/basic_fsm/data_helpers/condition/Parameter2Condition.gd")
const ParameterCondition = preload("res://addons/basic_fsm/data_helpers/condition/ParameterCondition.gd")
const TriggerCondition = preload("res://addons/basic_fsm/data_helpers/condition/TriggerCondition.gd")

const ComparatorEnum = Parameter2Condition.ComparatorEnum
const CombinatorEnum = Parameter2Condition.CombinatorEnum
@onready var ConditionContainer = $MarginContainer/Control/ConditionMain/ConditionContainer
@onready var AddConditionButton = $MarginContainer/Control/ConditionMain/AddConditionButton

var itemData:TransitionData:
	set(value):
		if not ConditionContainer:
			await ready
		itemData = value
		if itemData:
			for _c in itemData.get_conditions():
				_spawn_container_for_condition(_c)

var get_property_triggers_callable:Callable
var get_property_floats_callable:Callable

func _ready():
	if not AddConditionButton.get_popup().id_pressed.is_connected(_on_add_condition_button):
		AddConditionButton.get_popup().id_pressed.connect(_on_add_condition_button)

func _on_add_condition_button(id):
	#TODO Allow other types of Conditions to be created
	var _condition:BaseCondition = null
	match(id):
		1:
			_condition = FSM_ConditionSpawner.new_parameter_2_condition(CombinatorEnum.AND, ComparatorEnum.EQ, "", "", itemData)
		0:
			_condition = FSM_ConditionSpawner.new_parameter_condition(CombinatorEnum.AND, ComparatorEnum.EQ, "", 0)
		2:
			_condition = FSM_ConditionSpawner.new_trigger_condition(CombinatorEnum.AND, ComparatorEnum.EQ, "")
	
	if _condition:
		itemData.append_condition(_condition)
		_spawn_container_for_condition(_condition)
	
func _on_erase_condition(condition:BaseCondition):
	itemData.remove_condition(condition)
	if ConditionContainer.get_child_count() > 0:
		ConditionContainer.get_children()[0].combinator_visible = false

func _spawn_container_for_condition(cBase:BaseCondition):
	var conditionNode
	var desired_property_list = get_property_floats_callable
	if cBase is Parameter2Condition:
		conditionNode = Condition2ParameterNode.instantiate()
	elif cBase is ParameterCondition:
		conditionNode = ConditionParameterNode.instantiate()
	elif cBase is TriggerCondition:
		conditionNode = ConditionTriggerNode.instantiate()
		desired_property_list = get_property_triggers_callable

	if conditionNode:
		ConditionContainer.add_child(conditionNode)
		conditionNode.set_data(cBase, desired_property_list)
		conditionNode.combinator_visible = (ConditionContainer.get_child(0) != conditionNode)
		conditionNode.erase_condition.connect(_on_erase_condition)
