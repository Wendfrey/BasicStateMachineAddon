@tool
extends HBoxContainer
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")
const Param2Condition = preload("res://addons/basic_fsm/data_helpers/condition/Parameter2Condition.gd")

signal erase_condition(condition:BaseCondition)

@onready var CombinatorSelector = $CombinatorSelector
@onready var ParameterLeftSelector:OptionButton = $ParameterLeftSelector
@onready var ComparatorSelector = $ComparatorSelector
@onready var ParameterRightSelector:OptionButton = $ParameterRightSelector
var itemData:Param2Condition
			
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

func set_data(itemData:Param2Condition):
	self.itemData = itemData
	CombinatorSelector.select(itemData.combinator)
	ComparatorSelector.select(itemData.comparator)
	
	ParameterLeftSelector.clear()
	ParameterRightSelector.clear()
	
	property_list = _stateMachine.get_parameter_floats_name_list()
	
	for _f in property_list:
		ParameterLeftSelector.add_item(_f)
		ParameterRightSelector.add_item(_f)
		
	var _index_left = property_list.find(itemData.parameterL)
	var _index_right = property_list.find(itemData.parameterR)
	ParameterLeftSelector.tooltip_text = itemData.parameterL
	ParameterRightSelector.tooltip_text = itemData.parameterR
	
	ParameterLeftSelector.select(_index_left)
	ParameterRightSelector.select(_index_right)
	
func _on_combinator_selector_item_selected(index):
	itemData.combinator = index

func _on_parameter_left_selector_item_selected(index):
	if index >= 0:
		ParameterLeftSelector.modulate = Color.WHITE
		var new_param = property_list[index]
		itemData.parameterL = new_param
		if itemData.parameterL != new_param:
			property_list = _stateMachine.get_parameter_floats_name_list()
			ParameterLeftSelector.selected = property_list.find(itemData.parameterL)
			ParameterLeftSelector.tooltip_text = itemData.parameterL
	else:
		ParameterLeftSelector.modulate = Color.DARK_RED

func _on_comparator_selector_item_selected(index):
	itemData.comparator = index

func _on_parameter_right_selector_item_selected(index):
	if index >= 0:
		ParameterRightSelector.modulate = Color.WHITE
		var new_param = property_list[index]
		itemData.parameterR = new_param
		if itemData.parameterR != new_param:
			property_list = _stateMachine.get_parameter_floats_name_list()
			ParameterRightSelector.selected = property_list.find(itemData.parameterR)
			ParameterRightSelector.tooltip_text = itemData.parameterR
	else:
		ParameterRightSelector.modulate = Color.DARK_RED

func _on_erase_button_pressed():
	get_parent().remove_child(self)
	queue_free()
	erase_condition.emit(itemData)
