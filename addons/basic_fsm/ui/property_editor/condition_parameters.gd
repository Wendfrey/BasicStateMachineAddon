@tool
extends HBoxContainer
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")
const ParamCondition = preload("res://addons/basic_fsm/data_helpers/condition/ParameterCondition.gd")

signal erase_condition(condition:BaseCondition)

@onready var CombinatorSelector = $CombinatorSelector
@onready var ParameterLeftSelector:OptionButton = $ParameterLeftSelector
@onready var ComparatorSelector = $ComparatorSelector
@onready var ParameterRightFloat:SpinBox = $ParameterRightFloat
@onready var ParameterRightInt:SpinBox = $ParameterRightInt
var itemData:ParamCondition

var combinator_visible:bool:
	set(value):
		if not CombinatorSelector:
			await ready
			
		CombinatorSelector.visible = value
	get:
		if not CombinatorSelector:
			await ready
		
		return CombinatorSelector.visible

var property_list: Array
var _stateMachine:StateMachineResource

func _ready() -> void:
	if Engine.is_editor_hint():
		var _editedObject = EditorInterface.get_inspector().get_edited_object()
		if _editedObject is StateMachineResource:
			_stateMachine = _editedObject
	else:
		_stateMachine = StateMachineResource.new()
	#this is important, if a parameter has changed we need to update the visuals
	# of the conditions, this allows that
	visibility_changed.connect(
		func ():
			if visible and _stateMachine and itemData:
				set_data(itemData)
	)

func set_data(itemData:ParamCondition):
	self.itemData = itemData
	CombinatorSelector.select(itemData.combinator)
	ComparatorSelector.select(itemData.comparator)
	
	ParameterLeftSelector.clear()
	
	property_list = _stateMachine.get_parameter_floats_name_list()
	
	for _f in property_list:
		ParameterLeftSelector.add_item(_f)
	
	var _index_left = property_list.find(itemData.parameter)
	ParameterLeftSelector.tooltip_text = itemData.parameter
	
	ParameterLeftSelector.select(_index_left)
	
	_update_rounded_parameterR()
	
func _on_combinator_selector_item_selected(index):
	itemData.combinator = index

func _on_parameter_left_selector_item_selected(index):
	if index >= 0:
		ParameterLeftSelector.modulate = Color.WHITE
		var new_param = property_list[index]
		itemData.parameter = new_param
		if itemData.parameter != new_param:
			property_list = _stateMachine.get_parameter_floats_name_list()
			ParameterLeftSelector.selected = property_list.find(itemData.parameter)
			ParameterLeftSelector.tooltip_text = itemData.parameter
		_update_rounded_parameterR()
	else:
		ParameterLeftSelector.modulate = Color.DARK_RED

func _on_comparator_selector_item_selected(index):
	itemData.comparator = index
	
func _on_parameter_right_selector_value_changed(value: float) -> void:
	itemData.valueR = int(value) if _stateMachine and _stateMachine.is_parameter_int(itemData.parameter) else value

func _on_erase_button_pressed():
	get_parent().remove_child(self)
	queue_free()
	erase_condition.emit(itemData)

func _update_rounded_parameterR():
	if _stateMachine.is_parameter_float(itemData.parameter):
		ParameterRightFloat.set_value_no_signal(itemData.valueR)
		ParameterRightFloat.visible = true
		
		ParameterRightInt.visible = false
	elif _stateMachine.is_parameter_int(itemData.parameter):
		ParameterRightInt.set_value_no_signal(int(itemData.valueR))
		ParameterRightInt.visible = true
		
		ParameterRightFloat.visible = false
		itemData.valueR = int(itemData.valueR)
