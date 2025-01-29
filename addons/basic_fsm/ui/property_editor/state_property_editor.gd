@tool
extends Control

const StateUIVisual = preload("res://addons/basic_fsm/ui/map_ui/StateUIVisual.gd")

@onready var nameEditor = $MarginContainer/VBoxContainer2/VBoxContainer/NameLineEdit
@onready var scriptValue = $MarginContainer/VBoxContainer2/VBoxContainer/ScriptValueLabel
@onready var scriptSelector = $ScriptSelector

var itemData:StateUIVisual:
	set(value):
		if itemData and itemData.tree_exited.is_connected(queue_free):
			itemData.tree_exited.disconnect(queue_free)
		itemData = value
		_update_values()

func _on_add_script_button_pressed():
	scriptSelector.popup_centered()

func _on_script_selector_file_selected(path:String):
	var temp = load(path)
	if temp is GDScript:
		temp.get_base_script()
		var script_check:Script = temp
		while script_check and script_check != StateScript:
			script_check = script_check.get_base_script()
			
		if script_check == StateScript and itemData:
			itemData.script_src = temp
			_update_values()
		else:
			push_error("%s does not inherit StateScript" % [path])
	else:
		push_warning("not a Script")
		
func _update_values():
	if itemData:
		if not nameEditor or not scriptValue:
			await ready
		nameEditor.text = itemData.state_name
		if itemData.script_src:
			scriptValue.text = itemData.script_src.resource_path
		if not itemData.tree_exited.is_connected(queue_free):
			itemData.tree_exited.connect(queue_free)

func _on_name_line_edit_text_changed(new_text):
	if itemData:
		itemData.state_name = new_text
		$MarginContainer/VBoxContainer2/WarningNameLabel.visible = not itemData.is_name_valid
