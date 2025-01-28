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
	if not path.ends_with(".gd"):
		push_error("Not a valid type")
	elif not temp is GDScript:
		push_warning("not a Script")
	else:
		var temp_instance = temp.new()
		if temp_instance is StateScript and itemData:
			itemData.script_src = temp
			_update_values()
		else:
			push_warning("not instance of StateScript")
			
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
