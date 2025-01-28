@tool
extends "res://addons/basic_fsm/ui/map_ui/UIMapFocusable.gd"

@export var alert_color = Color.YELLOW
@onready var NameLabel = $MarginContainer/VBoxContainer/NameLabel
@onready var ScriptLabel = $MarginContainer/VBoxContainer/ScriptLabel
@onready var PanelBackground:Panel =  $Panel

var stateData:StateMachineResource.StateData = null

var is_name_valid = true
		
var is_script_valid = true

var state_name:String :
	set(value):
		if stateData:
			stateData.name = value
			#if the statedata name didnt change then it was rejected
			is_name_valid = stateData.name == value
			if is_name_valid:
				NameLabel.text = value
		else:
			NameLabel.text = value
	get:
		return stateData.name if stateData else NameLabel.text

var script_src:GDScript :
	set(value):
		if not ScriptLabel:
			await ready
		
		if stateData:
			stateData.script_state = value.resource_path
			is_script_valid = ResourceLoader.exists(stateData.script_state)
		script_src = value
		
		ScriptLabel.text = value.get_global_name()

func _ready():
	item_rect_changed.connect(_on_item_rect_changed)
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)

func add_state_data(stateData:StateMachineResource.StateData):
	state_name = stateData.name
	if ResourceLoader.exists(stateData.script_state):
		script_src = load(stateData.script_state)
	if stateData.script_state:
		ScriptLabel.text = "Script assigned"
	else:
		ScriptLabel.text = "No script assigned"
	position_offset = stateData.ui_pos
	self.stateData = stateData

func _on_item_rect_changed():
	if visible and stateData:
		stateData.ui_pos = position_offset

func _on_node_selected():
	PanelBackground.add_theme_stylebox_override("panel", PanelBackground.get_theme_stylebox("focus"))

func _on_node_deselected():
	PanelBackground.remove_theme_stylebox_override("panel")
