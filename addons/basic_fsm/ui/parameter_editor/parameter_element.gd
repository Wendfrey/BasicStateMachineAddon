@tool
extends Control

var close_pressed:Callable
var update_type:Callable
var update_name:Callable

@onready var NameLabel: LineEdit = $HBoxContainer/ParamName
@onready var TypeSelector: OptionButton = $HBoxContainer/ParamType
@onready var ButtonSeparator: Control = $HBoxContainer/SeparatorV2
@onready var CloseButton: Button = $HBoxContainer/CloseButton

var current_name
		
var is_editable = true:
	set(value):
		if not TypeSelector or not NameLabel or not CloseButton:
			await ready
		TypeSelector.disabled = not value
		NameLabel.editable = value
		
		ButtonSeparator.visible = value
		CloseButton.visible = value
		CloseButton.disabled = not value
		is_editable = value

func _ready() -> void:
	CloseButton.pressed.connect(_on_close_pressed)
	TypeSelector.item_selected.connect(_on_type_selector_item_selected)
	NameLabel.text_changed.connect(_on_name_update)

func set_data(_name, _index):
	NameLabel.text = _name
	current_name = _name
	TypeSelector.select(_index)

func _on_type_selector_item_selected(index):
	var new_type = &""
	match (index):
		0: new_type = StateMachineResource.ParamTrigger
		1: new_type = StateMachineResource.ParamFloat
		2: new_type = StateMachineResource.ParamInt
	update_type.call(current_name, new_type)
	
func _on_name_update(new_text):
	if update_name.call(current_name, new_text):
		current_name = new_text
		NameLabel.modulate = Color.WHITE
	else:
		NameLabel.modulate = Color.FIREBRICK

func _on_close_pressed():
	if close_pressed.call(current_name):
		queue_free()
