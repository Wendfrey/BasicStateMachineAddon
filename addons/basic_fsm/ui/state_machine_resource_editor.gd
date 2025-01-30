@tool
extends Control
#The main editor for the StateMachineResource, if not given a smResource it will
# will create a new one (for testing porpuses)
#
# MapController is assigned callables to create and delete data, and the elements
# that hold the data [see addons/basic_fsm/ui/map_ui/StateUIVisual.gd and 
# addons/basic_fsm/ui/map_ui/TransitionUI.gd ] are responsible to request modi-
# cations of data
#
# Property editors modify the elements, which these elements modify the data
# (Keep in mind that the elements only request changes, StateMachineResource
# might reject the changes)

const StateUINode = preload("res://addons/basic_fsm/ui/map_ui/StateUIVisual.gd")
const StatePropertyEditor = preload("res://addons/basic_fsm/ui/property_editor/state_property_editor.tscn")

const TransitionUINode = preload("res://addons/basic_fsm/ui/map_ui/TransitionUI.gd")
const TransitionUIEditor = preload("res://addons/basic_fsm/ui/property_editor/transition_property_editor.tscn")
@onready var ParameterEditor = $MainFrame/ParameterEditor
@onready var MapController: GraphEdit = $MainFrame/FlowEditor/PanelSplitter/MapController
@onready var OptionSelector: ItemList = $MainFrame/OptionSelector
@onready var PropertyContainer: MarginContainer = $MainFrame/FlowEditor/PanelSplitter/PropertyContainer
@onready var MapControllerParent: Control = $MainFrame/FlowEditor
var stateMachineResource:StateMachineResource = null

func _ready():
	MapController.add_state = _create_state
	MapController.add_transition = _create_empty_transition
	MapController.remove_state = _delete_state
	MapController.remove_transition = _delete_transition
	OptionSelector.select(0)
	_on_option_selector_item_selected(0)
		
	if (Engine.is_editor_hint()):
		EditorInterface.get_inspector().edited_object_changed.connect(_on_edited_object_changed)
		var edited_object = EditorInterface.get_inspector().get_edited_object()
		if edited_object is StateMachineResource:
			stateMachineResource = edited_object
			MapController.initialize(stateMachineResource)
			ParameterEditor.set_state_machine_resource(stateMachineResource)
	else:
		stateMachineResource = StateMachineResource.new()
		MapController.initialize(stateMachineResource)
		ParameterEditor.set_state_machine_resource(stateMachineResource)

func _on_option_selector_item_selected(index):
	match (index):
		0:
			MapControllerParent.visible = true
			ParameterEditor.visible = false
		1:
			MapControllerParent.visible = false
			ParameterEditor.visible = true
	pass

func _on_edited_object_changed():
	var children = PropertyContainer.get_children()
	while children.size() > 0:
		children.pop_back().queue_free()
		
	var edited_object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is StateMachineResource:
		stateMachineResource = edited_object
		MapController.initialize(stateMachineResource)
		ParameterEditor.set_state_machine_resource(stateMachineResource)

func _exit_tree():
	if Engine.is_editor_hint() and EditorInterface.get_inspector().edited_object_changed.is_connected(_on_edited_object_changed):
		EditorInterface.get_inspector().edited_object_changed.disconnect(_on_edited_object_changed)
		
	var children = PropertyContainer.get_children()
	while children.size() > 0:
		children.pop_back().queue_free()
		
func _create_state(st_name:String, st_script:String):
	if st_name.strip_edges().is_empty():
		st_name = "State"
	if not ResourceLoader.exists(st_script):
		st_script = ""
		
	var nStateData:StateMachineResource.StateData = stateMachineResource.add_state(st_name, st_script)
	var count: int = 1
	while (not nStateData):
		nStateData = stateMachineResource.add_state("%s%s"%[st_name, count], st_script)
		count += 1
	return nStateData
	
func _create_empty_transition(fromStateName:String, toStateName:String):
	return stateMachineResource.add_transition(fromStateName, toStateName)
	
func _delete_state(stateData):
	stateMachineResource.delete_state(stateData)

func _delete_transition(transition):
	stateMachineResource.delete_transition(transition)
	
func _on_map_controller_item_focused(item):
	var propertyEditor = null
	if item is StateUINode:
		propertyEditor = StatePropertyEditor.instantiate()
		propertyEditor.itemData = item
	elif item is TransitionUINode:
		propertyEditor = TransitionUIEditor.instantiate()
		propertyEditor.itemData = item.transitionData
		propertyEditor.get_property_triggers_callable = stateMachineResource.get_paremeter_triggers_name_list
		propertyEditor.get_property_floats_callable = stateMachineResource.get_parameter_floats_name_list
		
	
	if propertyEditor:
		PropertyContainer.get_children().all(func (n): n.queue_free())
		PropertyContainer.add_child(propertyEditor)
