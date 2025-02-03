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

func set_data(itemData:TriggerCondition):
	self.itemData = itemData
	CombinatorSelector.select(itemData.combinator)
	
	TriggerSelector.clear()
	
	property_list = _stateMachine.get_paremeter_triggers_name_list()
	
	for _f in property_list:
		TriggerSelector.add_item(_f)
	
	var _index_trigger = property_list.find(itemData.trigger_param)
	TriggerSelector.tooltip_text = itemData.trigger_param
	
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
		var new_param = property_list[index]
		itemData.trigger_param = new_param
		if itemData.trigger_param != new_param:
			property_list = _stateMachine.get_paremeter_triggers_name_list()
			TriggerSelector.selected = property_list.find(itemData.trigger_param)
			TriggerSelector.tooltip_text = itemData.trigger_param
	else:
		TriggerSelector.modulate = Color.DARK_RED
