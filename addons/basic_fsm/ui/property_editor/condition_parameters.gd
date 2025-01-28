@tool
extends HBoxContainer
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")
const ParamCondition = preload("res://addons/basic_fsm/data_helpers/condition/ParameterCondition.gd")

signal erase_condition(condition:BaseCondition)

@onready var CombinatorSelector = $CombinatorSelector
@onready var ParameterLeftSelector:OptionButton = $ParameterLeftSelector
@onready var ComparatorSelector = $ComparatorSelector
@onready var ParameterRightSelector:SpinBox = $ParameterRightSelector
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
			
			
var get_property_floats_callable:Callable
var current_loaded_list_properties: Array

func _ready() -> void:
	visibility_changed.connect(
		func ():
			if visible and get_property_floats_callable and itemData:
				set_data(itemData, get_property_floats_callable)
	)

func set_data(itemData:ParamCondition, _property_callable:Callable):
	self.itemData = itemData
	CombinatorSelector.select(itemData.combinator)
	ComparatorSelector.select(itemData.comparator)
	
	ParameterLeftSelector.clear()
	
	current_loaded_list_properties = _property_callable.call()
	get_property_floats_callable = _property_callable
	
	for _f in current_loaded_list_properties:
		ParameterLeftSelector.add_item(_f)
	
	var _index_left = current_loaded_list_properties.find(itemData.parameter)
	
	ParameterLeftSelector.select(_index_left)
	ParameterRightSelector.set_value_no_signal(itemData.valueR)
	
func _on_combinator_selector_item_selected(index):
	itemData.combinator = index

func _on_parameter_left_selector_item_selected(index):
	if index >= 0:
		ParameterLeftSelector.modulate = Color.WHITE
		var new_param = current_loaded_list_properties[index]
		itemData.parameter = new_param
		if itemData.parameter != new_param:
			current_loaded_list_properties = get_property_floats_callable.call()
			ParameterLeftSelector.selected = current_loaded_list_properties.find(itemData.parameter)
	else:
		ParameterLeftSelector.modulate = Color.DARK_RED

func _on_comparator_selector_item_selected(index):
	itemData.comparator = index
	
func _on_parameter_right_selector_value_changed(value: float) -> void:
	itemData.valueR = value

func _on_erase_button_pressed():
	get_parent().remove_child(self)
	queue_free()
	erase_condition.emit(itemData)
