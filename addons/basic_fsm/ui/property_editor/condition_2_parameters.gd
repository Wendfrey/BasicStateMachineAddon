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
			
			
var get_property_floats_callable:Callable
var current_loaded_list_properties: Array

func _ready() -> void:
	#this is important, if a parameter has changed we need to update the visuals
	# of the conditions, this allows that
	visibility_changed.connect(
		func ():
			if visible and get_property_floats_callable and itemData:
				set_data(itemData, get_property_floats_callable)
	)

func set_data(itemData:Param2Condition, _property_callable:Callable):
	self.itemData = itemData
	CombinatorSelector.select(itemData.combinator)
	ComparatorSelector.select(itemData.comparator)
	
	ParameterLeftSelector.clear()
	ParameterRightSelector.clear()
	
	current_loaded_list_properties = _property_callable.call()
	get_property_floats_callable = _property_callable
	
	for _f in current_loaded_list_properties:
		ParameterLeftSelector.add_item(_f)
		ParameterRightSelector.add_item(_f)
		
	var _index_left = current_loaded_list_properties.find(itemData.parameterL)
	var _index_right = current_loaded_list_properties.find(itemData.parameterR)
	ParameterLeftSelector.tooltip_text = itemData.parameterL
	ParameterRightSelector.tooltip_text = itemData.parameterR
	
	ParameterLeftSelector.select(_index_left)
	ParameterRightSelector.select(_index_right)
	
func _on_combinator_selector_item_selected(index):
	itemData.combinator = index

func _on_parameter_left_selector_item_selected(index):
	if index >= 0:
		ParameterLeftSelector.modulate = Color.WHITE
		var new_param = current_loaded_list_properties[index]
		itemData.parameterL = new_param
		if itemData.parameterL != new_param:
			current_loaded_list_properties = get_property_floats_callable.call()
			ParameterLeftSelector.selected = current_loaded_list_properties.find(itemData.parameterL)
			ParameterLeftSelector.tooltip_text = itemData.parameterL
	else:
		ParameterLeftSelector.modulate = Color.DARK_RED

func _on_comparator_selector_item_selected(index):
	itemData.comparator = index

func _on_parameter_right_selector_item_selected(index):
	if index >= 0:
		ParameterRightSelector.modulate = Color.WHITE
		var new_param = current_loaded_list_properties[index]
		itemData.parameterR = new_param
		if itemData.parameterR != new_param:
			current_loaded_list_properties = get_property_floats_callable.call()
			ParameterRightSelector.selected = current_loaded_list_properties.find(itemData.parameterR)
			ParameterRightSelector.tooltip_text = itemData.parameterR
	else:
		ParameterRightSelector.modulate = Color.DARK_RED

func _on_erase_button_pressed():
	get_parent().remove_child(self)
	queue_free()
	erase_condition.emit(itemData)
