@tool
extends GraphEdit

const StateUINode = preload("res://addons/basic_fsm/ui/map_ui/state_ui_node.tscn")
const StateUINodeScript = preload("res://addons/basic_fsm/ui/map_ui/StateUIVisual.gd")
const TransitionUINode = preload("res://addons/basic_fsm/ui/map_ui/transition_ui.tscn")
const TransitionUINodeScript = preload("res://addons/basic_fsm/ui/map_ui/TransitionUI.gd")

enum PopupButtonIds {
	CREATE_STATE,
	DELETE_ELEMENT,
	CREATE_TRANSITION,
	COPY_STATE_NAME
}

signal item_focused(item)

var add_transition:Callable
var remove_transition:Callable
var add_state:Callable
var remove_state:Callable

@onready var OptionsPopup = $LeftClickBlankPopup
@onready var BeginNode = $BeginState
@onready var ExitNode = $ExitState

var stateMachineResource:StateMachineResource
var transition_array:Array= Array() #Used to avoid creating a duplicate transition
var connectFrom:UIMapFocusable
var connectTo: UIMapFocusable

func _ready():
	add_valid_connection_type(0,0)
	node_selected.connect(func (node): item_focused.emit(node))
	BeginNode.on_item_rclicked = custom_element_open_popup
	ExitNode.on_item_rclicked = custom_element_open_popup

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				end_transition_creation()
				show_popup(UIMapFocusable.NodeType.EMPTY)
				accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed() and connectFrom:
				if connectTo and connectTo.can_transition_to:
					add_new_transition(connectFrom, connectTo)
				end_transition_creation()
	elif event is InputEventMouseMotion and connectFrom:
		queue_redraw()

func initialize(stateMachineResource: StateMachineResource):
	BeginNode.position_offset_changed.connect(_on_begin_state_position_update)
	ExitNode.position_offset_changed.connect(_on_end_state_position_update)
	scroll_offset_changed.connect(_on_scroll_offset_changed)
	
	self.stateMachineResource = stateMachineResource
	
	if not stateMachineResource.ui_end_pos.is_zero_approx() and not stateMachineResource.ui_start_pos.is_zero_approx():
		BeginNode.position_offset = stateMachineResource.ui_start_pos
		ExitNode.position_offset = stateMachineResource.ui_end_pos
		
	scroll_offset = stateMachineResource.offset
	
	
	#clean the map controller from old instances
	while not transition_array.is_empty():
		transition_array.pop_back().queue_free()
	var filtered = get_children()\
		.filter(
			func (_n:Node):\
				return _n is StateUINodeScript
		)
	while not filtered.is_empty():
		filtered.pop_back().queue_free()
		
	stateMachineResource.load_instance_map()
	var stateNodeDict = {}
	var stateDataList = stateMachineResource._get_state_instance_map().values()
	for stateData:StateMachineResource.StateData in stateDataList:
		stateNodeDict[stateData.name] = init_state_from_res(stateData)
	
	var transitionDatalist = []
	for _a in stateMachineResource._get_transition_instance_map().values().map(
		func(innerdict) -> Array:
			return innerdict.values()
	):
		transitionDatalist += _a                 
	for transitionData in transitionDatalist:
		init_transtition_from_res(transitionData, stateNodeDict)
		
func init_state_from_res(stateData:StateMachineResource.StateData) -> UIMapFocusable:
	var stateNode = StateUINode.instantiate()
	add_child(stateNode)
	stateNode.add_state_data(stateData)
	stateNode.on_item_rclicked = custom_element_open_popup
	return stateNode
	
func init_transtition_from_res(transitionData:StateMachineResource.TransitionData, stateUINodeList:Dictionary) -> UIMapFocusable:
	var transitionNode:TransitionUINodeScript = TransitionUINode.instantiate()
	add_child(transitionNode)
	transitionNode.from = stateUINodeList.get(transitionData.stateFrom, BeginNode)
	transitionNode.to = stateUINodeList.get(transitionData.stateTo, ExitNode)
	transitionNode.transitionData = transitionData
	transition_array.append(transitionNode)
	
	transitionNode.on_item_rclicked = custom_element_open_popup
	return transitionNode

#region Popup calls
var rClicked:UIMapFocusable = null
func custom_element_open_popup(node_name:StringName):
	var node = get_node(NodePath(node_name))
	if node is UIMapFocusable:
		end_transition_creation()
		rClicked = node
		set_selected(node)
		show_popup(node.node_type)

func show_popup(node_type: UIMapFocusable.NodeType):
	OptionsPopup.clear()
	match(node_type):
		UIMapFocusable.NodeType.EMPTY:
			OptionsPopup.add_item("Create state", PopupButtonIds.CREATE_STATE)
		UIMapFocusable.NodeType.STATE:
			OptionsPopup.add_item("Add transition", PopupButtonIds.CREATE_TRANSITION)
			if rClicked is StateUINodeScript:
				OptionsPopup.add_item("Copy name", PopupButtonIds.COPY_STATE_NAME)
				OptionsPopup.add_item("Delete", PopupButtonIds.DELETE_ELEMENT)
		UIMapFocusable.NodeType.TRANSITION:
			OptionsPopup.add_item("Delete", PopupButtonIds.DELETE_ELEMENT)
			
	OptionsPopup.popup()
	OptionsPopup.position = get_global_mouse_position()

func _on_left_click_blank_popup_id_pressed(id):
	match (id):
		PopupButtonIds.CREATE_STATE:
			add_new_state(Vector2(OptionsPopup.position) - global_position)
		PopupButtonIds.DELETE_ELEMENT:
			if rClicked.delete():
				if rClicked.node_type == UIMapFocusable.NodeType.STATE:
					destroy_state(rClicked)
				elif rClicked.node_type == UIMapFocusable.NodeType.TRANSITION:
					destroy_transition(rClicked)
				else:
					rClicked.queue_free()
			else:
				push_warning("This element cannot be deleted")
		PopupButtonIds.CREATE_TRANSITION:
			if rClicked.can_transition_from:
				connectFrom = rClicked
				for n in get_children():
					if n is UIMapFocusable and n.node_type == UIMapFocusable.NodeType.STATE:
						n.mouse_entered.connect(_update_connect_to.bind(n))
						n.mouse_exited.connect(_remove_connect_to.bind(n))
				queue_redraw()
		PopupButtonIds.COPY_STATE_NAME:
			if "state_name" in rClicked:
				DisplayServer.clipboard_set(rClicked.state_name) 
	rClicked = null

func end_transition_creation():
	if not connectFrom: return
	connectFrom = null
	connectTo = null
	for n in get_children():
		if n is UIMapFocusable and n.node_type == UIMapFocusable.NodeType.STATE:
			n.mouse_entered.disconnect(_update_connect_to)
			n.mouse_exited.disconnect(_remove_connect_to)
	queue_redraw()
#endregion

#region callable methods
func add_new_state(_position: Vector2):
	var newStateUI = StateUINode.instantiate()
	add_child(newStateUI)
	var nStateData = add_state.call()
	nStateData.ui_pos = ( _position + scroll_offset ) / zoom #convert position to offset position
	newStateUI.add_state_data(nStateData)
	newStateUI.on_item_rclicked = custom_element_open_popup
	
func add_new_transition(fromUI:UIMapFocusable, toUI:UIMapFocusable):
	var fromData = fromUI.stateData.name if ("stateData" in fromUI) else ""
	var toData = toUI.stateData.name if ("stateData" in toUI) else ""
	var transitionData = add_transition.call(fromData,toData)
	if transitionData:
		var nTransition = TransitionUINode.instantiate()
		add_child(nTransition)
		nTransition.from = fromUI
		nTransition.to = toUI
		nTransition.transitionData = transitionData
		transition_array.append(nTransition)
		nTransition.on_item_rclicked = custom_element_open_popup
	else:
		print("Avoided duplicate")

func destroy_state(state: UIMapFocusable):
	var transitions_to_remove = transition_array.filter(
		func (value):
			return value.from == state or value.to == state
	)
	
	var size = transitions_to_remove.size()
	for i in range(size):
		destroy_transition(transitions_to_remove.pop_back())
	remove_state.call(state.stateData)
	state.delete()
	
func destroy_transition(transition: UIMapFocusable):
	transition_array.erase(transition)
	remove_transition.call(transition.transitionData)
	if not transition.is_queued_for_deletion(): transition.delete()
#endregion

func _draw():
	if connectFrom:
		draw_line(
			connectFrom.get_screen_position() + connectFrom.size/2 - get_screen_position(), 
			get_local_mouse_position(),
			Color.GOLDENROD
		)
		queue_redraw()

#region connectTo listeners
func _update_connect_to(node:UIMapFocusable):
	connectTo = node
	
func _remove_connect_to(node:UIMapFocusable):
	if node == connectTo:
		connectTo = null
#endregion

func _on_begin_state_position_update():
	if stateMachineResource:
		stateMachineResource.ui_start_pos = BeginNode.position_offset
	
func _on_end_state_position_update():
	if stateMachineResource:
		stateMachineResource.ui_end_pos = ExitNode.position_offset

func _on_scroll_offset_changed(offset):
	if stateMachineResource:
		stateMachineResource.offset = offset

func _exit_tree() -> void:
	if stateMachineResource:
		stateMachineResource = null
		BeginNode.position_offset_changed.disconnect(_on_begin_state_position_update)
		ExitNode.position_offset_changed.disconnect(_on_end_state_position_update)
		scroll_offset_changed.disconnect(_on_scroll_offset_changed)
	
