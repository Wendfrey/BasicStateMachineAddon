@tool
extends EditorPlugin

const RESOURCE_EDITOR = preload("res://addons/basic_fsm/ui/state_machine_resource_editor.tscn")
const resourceEditorName = "Basic FSM Editor"
const stateMachineNodeName = "StateMachineNode"
var bottom_dock:Control

func _enter_tree():
	EditorInterface.get_inspector().edited_object_changed.connect(_on_resource_selected)
	
	if EditorInterface.get_inspector().get_edited_object() is StateMachineResource:
		_on_resource_selected()
		
	add_custom_type(stateMachineNodeName, "Node", preload("res://addons/basic_fsm/StateMachineNode.gd"), preload("res://icon.svg"))

func _exit_tree():
	EditorInterface.get_inspector().edited_object_changed.disconnect(_on_resource_selected)
	if bottom_dock:
		if bottom_dock.is_inside_tree():
			remove_control_from_bottom_panel(bottom_dock)
		bottom_dock.free()
		
	remove_tool_menu_item(resourceEditorName)
	remove_custom_type(stateMachineNodeName)

func _on_resource_selected():
	if EditorInterface.get_inspector().get_edited_object() is StateMachineResource:
		if not bottom_dock:
			bottom_dock = RESOURCE_EDITOR.instantiate()
		bottom_dock.request_ready()
		if not bottom_dock.is_inside_tree():
			add_control_to_bottom_panel(bottom_dock, resourceEditorName)
	elif bottom_dock:
		remove_control_from_bottom_panel(bottom_dock)
		
