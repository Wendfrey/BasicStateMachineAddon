@tool
extends PanelContainer

const ParamNode = preload("res://addons/basic_fsm/ui/parameter_editor/parameter_element.tscn")

@onready var GlobalPropertiesContainer = $VBoxContainer/Body/ScrollContainer/PropertyLists/GlobalPropertiesContainer/BodyContainer/ElementList
@onready var CustomPropertiesContainer = $VBoxContainer/Body/ScrollContainer/PropertyLists/CustomPropertiesContainer/BodyContainer/ElementList

var _stateMachineResource: StateMachineResource

func set_state_machine_resource(stateMachineRes):
	reset()
	_stateMachineResource = stateMachineRes
	instantiate_parameters(GlobalPropertiesContainer, _stateMachineResource.GLOBAL_PARAMS, false)
	instantiate_parameters(CustomPropertiesContainer, _stateMachineResource.custom_parameters)

func instantiate_parameters(parent:Control, parameterList:Dictionary, editable:bool = true):
	for _p in parameterList.keys():
		var ins = ParamNode.instantiate()
		parent.add_child(ins)
		var index = 0
		match (parameterList[_p]):
			StateMachineResource.ParamTrigger:
				index = 0
			StateMachineResource.ParamFloat:
				index = 1
		
		ins.set_data(_p, index)
		ins.is_editable = editable
		
		ins.close_pressed = _on_delete_item_pressed
		ins.update_type = _on_update_item_type
		ins.update_name = _on_update_item_name

func _on_add_custom_param_button_pressed() -> void:
	if not _stateMachineResource:
		return
		
	var baseName = "Param"
	var count = 1
	while(not _stateMachineResource.create_parameter(baseName + str(count), StateMachineResource.ParamFloat)):
		count += 1
		
	var array = CustomPropertiesContainer.get_children()
	while not array.is_empty():
		array.pop_back().queue_free()
	instantiate_parameters(CustomPropertiesContainer, _stateMachineResource.custom_parameters)

func _on_delete_item_pressed(_name):
	return _stateMachineResource.delete_parameter(_name)

func _on_update_item_type(_name, _n_type):
	return _stateMachineResource._update_parameter_type(_name, _n_type)
	
func _on_update_item_name(old_name, new_name):
	return _stateMachineResource._update_parameter_name(old_name, new_name)

func _exit_tree() -> void:
	reset()
		
func reset():
	var remove_children = CustomPropertiesContainer.get_children()
	remove_children += GlobalPropertiesContainer.get_children()
	
	while(remove_children.size() > 0):
		remove_children.pop_back().queue_free()
	
