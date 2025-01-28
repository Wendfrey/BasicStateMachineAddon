@tool
extends "res://addons/basic_fsm/ui/map_ui/UIMapFocusable.gd"

@onready var PanelBackground:Panel = $Panel
@onready var TextLabel:Label = $MarginContainer/Label

@export var text:String:
	set(value):
		text = value
		if not TextLabel:
			await ready 
		if value:
			TextLabel.text = value
	get:
		if TextLabel:
			return TextLabel.text
		return text

func _ready():
	if theme:
		PanelBackground.theme = theme
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)
	
func _on_node_selected():
	PanelBackground.add_theme_stylebox_override(
		"panel",
		PanelBackground.get_theme_stylebox("focus")
	)
	
func _on_node_deselected():
	PanelBackground.remove_theme_stylebox_override("panel")
