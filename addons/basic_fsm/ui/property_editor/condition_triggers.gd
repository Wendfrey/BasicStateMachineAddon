@tool
extends HBoxContainer
const BaseCondition = preload("res://addons/basic_fsm/data_helpers/condition/BaseCondition.gd")
const TriggerCondition = preload("res://addons/basic_fsm/data_helpers/condition/TriggerCondition.gd")

signal erase_condition(condition:BaseCondition)

@onready var CombinatorSelector = $CombinatorSelector
@onready var TriggerSelector:OptionButton = $TriggerSelector
var itemData:TriggerCondition
			
var combinator_visible:bool:
	set(value):
		if not CombinatorSelector:
			await ready
			
		CombinatorSelector.visible = value
	get:
		if not CombinatorSelector:
			await ready
		
		return CombinatorSelector.visible
			
			
var get_property_triggers_callable:Callable
var current_loaded_list_properties: Array

func _ready() -> void:
	visibility_changed.connect(
		func ():
			if visible and get_property_triggers_callable and itemData:
				set_data(itemData, get_property_triggers_callable)
	)

func set_data(itemData:TriggerCondition, _property_callable:Callable):
	self.itemData = itemData
	CombinatorSelector.select(itemData.combinator)
	
	TriggerSelector.clear()
	
	current_loaded_list_properties = _property_callable.call()
	get_property_triggers_callable = _property_callable
	
	for _f in current_loaded_list_properties:
		TriggerSelector.add_item(_f)
	
	var _index_trigger = current_loaded_list_properties.find(itemData.trigger_param)
	
	TriggerSelector.select(_index_trigger)
	
func _on_combinator_selector_item_selected(index):
	itemData.combinator = index

func _on_erase_button_pressed():
	get_parent().remove_child(self)
	queue_free()
	erase_condition.emit(itemData)
	
func _on_trigger_selector_item_selected(index: int) -> void:
	if index >= 0:
		TriggerSelector.modulate = Color.WHITE
		var new_param = current_loaded_list_properties[index]
		itemData.trigger_param = new_param
		if itemData.trigger_param != new_param:
			current_loaded_list_properties = get_property_triggers_callable.call()
			TriggerSelector.selected = current_loaded_list_properties.find(itemData.trigger_param)
	else:
		TriggerSelector.modulate = Color.DARK_RED
