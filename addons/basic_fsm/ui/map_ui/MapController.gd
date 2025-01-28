@tool
extends Control
#
#const StateUIVisualScene = preload("res://addons/basic_fsm/ui/map_ui/StateUIVisual.tscn")
#const TransitionUI = preload("res://addons/basic_fsm/ui/map_ui/transition_ui.tscn")
#
#enum ControlType { DRAG, TRANSITION }
#enum PopupButtonIds {CREATE_STATE, DELETE_STATE}
#
#signal add_transition(transition:StateMachineResource.TransitionData)
#signal remove_transition(transition:StateMachineResource.TransitionData)
#signal add_state(stateData:StateMachineResource.StateData)
#signal remove_state(stateData:StateMachineResource.StateData)
#signal item_focused(item)
#
#@export var cell_size:Vector2i = Vector2i(32,32)
#@onready var lClickPopup = $LeftClickBlankPopup
#@onready var StateLayer:Control = $StateLayer
#@onready var TransitionLayer:Control = $TransitionLayer
#
#@onready var StartState = $StateLayer/StartState
#@onready var FinishState = $StateLayer/FinishState
#
#var stateMachineResource:StateMachineResource
#
#var offset: Vector2i = Vector2i.ZERO:
	#set(value):
		#if stateMachineResource and visible:
			#stateMachineResource.offset = value
		#offset = value
	#get:
		#return stateMachineResource.offset if stateMachineResource else offset
		#
#var control_type: ControlType = ControlType.TRANSITION
#
#var rClickOnState: bool = false
#var rClickNode: UIMapFocusable
#var transition_array:Array= Array() #Used to avoid creating a duplicate transition
#
## Called when the node enters the scene tree for the first time.
#func _ready():
	#
	#StartState.pressed.connect(_on_state_pressed.bind(StartState))
	#StartState.released.connect(_on_state_released.bind(StartState))
	#
	#FinishState.pressed.connect(_on_state_pressed.bind(FinishState))
	#FinishState.released.connect(_on_state_released.bind(FinishState))
#
#func initialize(resource:StateMachineResource):
	#reset()
	#stateMachineResource = resource
	#
	#offset = resource.offset
	#StateLayer.position = offset
	#TransitionLayer.position = offset
#
	#if (resource.ui_start_pos):
		#StartState.position = resource.ui_start_pos
	#if (resource.ui_end_pos):
		#FinishState.position = resource.ui_end_pos
	#
	#var state_name_dict = {}
	#for state:StateMachineResource.StateData in resource._get_state_instance_map().values():
		#var ui_state = initialize_state_from_resource(state)
		#state_name_dict[state.name] = ui_state
		#
	#var transition_list = resource._get_transition_instance_map().values()
	#for internal_dict:Dictionary in transition_list:
		#for transition:StateMachineResource.TransitionData in internal_dict.values():
			#var s_from = null
			#var s_to = null
			#if transition.stateFrom:
				#s_from = state_name_dict.get(transition.stateFrom)
			#if transition.stateTo:
				#s_to = state_name_dict.get(transition.stateTo)
				#
			#if s_from and not s_to:
				#s_to = FinishState
			#elif not s_from and s_to:
				#s_from = StartState
			#elif not s_from and not s_to:
				#push_error("Corrupted data, can't read resource")
				#return
			#
			#initialize_transition_from_resource(transition, s_from, s_to)
		#
	#StartState.item_rect_changed.connect(_on_start_item_rect_changed)
	#FinishState.item_rect_changed.connect(_on_end_item_rect_changed)
	#queue_redraw()
#
#func _gui_input(event):
	#match control_type:
		#ControlType.DRAG:
			#drag_input(event)
		#ControlType.TRANSITION:
			#connect_input(event)
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_RIGHT and (not connectFromState or not grab):
			#if event.is_pressed():
				#show_popup(UIMapFocusable.NodeType.EMPTY)
				#accept_event()
#
#var grab = false
#var grab_offset: Vector2i = Vector2i()
#var dragStateNode:UIMapFocusable = null
#var dragStateNodeOffset: Vector2 = Vector2()
#func drag_input(event: InputEvent):
	#if event is InputEventMouseButton:
		#if event.is_pressed():
			#if event.button_index == MOUSE_BUTTON_LEFT:
				#grab = true
		#elif event.button_index == MOUSE_BUTTON_LEFT:
				#grab = false
	#elif event is InputEventMouseMotion and grab:
		#if dragStateNode:
			#dragStateNode.global_position = get_global_mouse_position() - dragStateNodeOffset
		#else:
			#offset += Vector2i((event as InputEventMouseMotion).relative * scale)
			#StateLayer.position = Vector2(offset)
			#TransitionLayer.position = Vector2(offset)
			#queue_redraw()
#
#var connectToState:UIMapFocusable = null
#var connectFromState:UIMapFocusable = null
#func connect_input(event: InputEvent):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#if not event.is_pressed():
				#var dont_connect_to_itself = connectToState and connectFromState and connectFromState != connectToState
				#var start_to_end = connectFromState == StartState and connectToState == FinishState
				#var has_duplicates = not transition_array.filter(
					#func (value):
						#return value.from == connectFromState and value.to == connectToState
				#).is_empty()
				#if dont_connect_to_itself and not has_duplicates and not start_to_end:
					#instantiate_transition(connectFromState, connectToState)
				#connectFromState = null
				#connectToState = null
				#queue_redraw()
	#elif event is InputEventMouseMotion:
		#if connectFromState:
			#queue_redraw()
#
#func _on_left_click_blank_popup_id_pressed(id):
	#match (id):
		#PopupButtonIds.CREATE_STATE:
			#instantiate_state(Vector2(lClickPopup.position - offset) - global_position)
		#PopupButtonIds.DELETE_STATE:
			#if rClickNode.deleteable:
				#if rClickNode.node_type == UIMapFocusable.NodeType.STATE:
					#destroy_state(rClickNode)
				#elif rClickNode.node_type == UIMapFocusable.NodeType.TRANSITION:
					#destroy_transition(rClickNode)
				#else:
					#rClickNode.queue_free()
			#else:
				#push_warning("This element cannot be deleted")
			#rClickNode = null
#
#func _on_state_pressed(button_index, node: UIMapFocusable):
	#if (button_index == MOUSE_BUTTON_LEFT):
		#match (control_type):
			#ControlType.DRAG:
				#if node.draggable:
					#dragStateNode = node
					#dragStateNodeOffset = get_global_mouse_position() - node.global_position
			#ControlType.TRANSITION:
				#if node.can_transition_from:
					#connectFromState = node
					#for child in StateLayer.get_children():
						#child.mouse_entered.connect(_on_state_mouse_entered.bind(child))
						#child.mouse_exited.connect(_on_state_mouse_exited.bind(child))
	#elif (button_index == MOUSE_BUTTON_RIGHT):
		#rClickNode = node
		#show_popup(node.node_type)
		#node.accept_event() #to prevent MapContainer from showing popup
#
#func _on_state_released(button_index, node: UIMapFocusable):
	#if (button_index == MOUSE_BUTTON_LEFT):
		#match (control_type):
			#ControlType.DRAG:
				#dragStateNode = null
			#ControlType.TRANSITION:
				#if connectFromState:
					#for child in StateLayer.get_children():
						#child.mouse_entered.disconnect(_on_state_mouse_entered)
						#child.mouse_exited.disconnect(_on_state_mouse_exited)
#
#func _on_state_mouse_entered(node:UIMapFocusable):
	#if node.can_transition_to:
		#connectToState = node
	#
#func _on_state_mouse_exited(node:UIMapFocusable):
	#if connectToState == node:
		#connectToState = null
#
#
#var backgroundColor = Color("#00000033")
#func _draw():
	#draw_rect(Rect2(Vector2.ZERO, size), backgroundColor)
	#var poolVector = PackedVector2Array()
	#for pos_x in range(offset.x % cell_size.x * scale.x, size.x*scale.x, cell_size.x * scale.x):
		#poolVector.append(Vector2(pos_x, 0))
		#poolVector.append(Vector2(pos_x, size.y))
	#for pos_y in range(offset.y % cell_size.y * scale.y, size.y * scale.y, cell_size.y * scale.y):
		#poolVector.append(Vector2(0, pos_y))
		#poolVector.append(Vector2(size.x, pos_y))
	#
	#for v_idx in range(0, poolVector.size(), 2):
		#draw_dashed_line(poolVector[v_idx], poolVector[v_idx+1], Color.WHITE, -1, 1, true)
		#
	#draw_line(Vector2.ZERO, Vector2(size.x,0), Color.WHITE_SMOKE, 2)
	#draw_line(Vector2.ZERO, Vector2(0,size.y), Color.WHITE_SMOKE, 2)
	#draw_line(Vector2(size.x,0), size, Color.WHITE_SMOKE, 2)
	#draw_line(Vector2(0,size.y), size, Color.WHITE_SMOKE, 2)
	#
	#
		#
	#if connectFromState:
		#draw_line(
			#connectFromState.get_screen_position() + connectFromState.size/2 - get_screen_position(), 
			#get_local_mouse_position(),
			#Color.GOLDENROD
		#)
#
#func initialize_state_from_resource(stateData: StateMachineResource.StateData) -> UIMapFocusable:
	#var new_state = StateUIVisualScene.instantiate()
	#StateLayer.add_child(new_state)
	#new_state.add_state_data(stateData)
	#new_state.pressed.connect(_on_state_pressed.bind(new_state))
	#new_state.released.connect(_on_state_released.bind(new_state))
	#new_state.focus_entered.connect(emit_signal.bind("item_focused", new_state))
	#return new_state
#
#func initialize_transition_from_resource(transitionData: StateMachineResource.TransitionData, from:UIMapFocusable, to:UIMapFocusable):
	#var nTransition = TransitionUI.instantiate()
	#nTransition.from = from
	#nTransition.to = to
	#TransitionLayer.add_child(nTransition)
	#nTransition.pressed.connect(_on_state_pressed.bind(nTransition))
	#nTransition.released.connect(_on_state_released.bind(nTransition))
	#nTransition.transitionData = transitionData
	#transition_array.append(nTransition)
	#nTransition.focus_entered.connect(emit_signal.bind("item_focused", nTransition))
#
#func instantiate_state(position: Vector2):
	#var newStateUI = StateUIVisualScene.instantiate()
	#StateLayer.add_child(newStateUI)
	#var nStateData = stateMachineResource.add_state("State", "")
	#if nStateData == null:
		#var count = 1
		#while(nStateData == null):
			#nStateData = stateMachineResource.add_state("State%s"%[count], "")
			#count += 1
	#nStateData.ui_pos = position - newStateUI.size/2
	#newStateUI.pressed.connect(_on_state_pressed.bind(newStateUI))
	#newStateUI.released.connect(_on_state_released.bind(newStateUI))
	#newStateUI.focus_entered.connect(emit_signal.bind("item_focused", newStateUI))
	#newStateUI.add_state_data(nStateData)
	#add_state.emit(newStateUI.stateData)
	#
#func instantiate_transition(fromUI:UIMapFocusable, toUI:UIMapFocusable):
	#var nTransition = TransitionUI.instantiate()
	#nTransition.from = fromUI
	#nTransition.to = toUI
	#TransitionLayer.add_child(nTransition)
	#nTransition.pressed.connect(_on_state_pressed.bind(nTransition))
	#nTransition.released.connect(_on_state_released.bind(nTransition))
	#var fromData = fromUI.stateData.name if ("stateData" in fromUI) else ""
	#var toData = toUI.stateData.name if ("stateData" in toUI) else ""
	#nTransition.transitionData = stateMachineResource.add_transition(fromData, toData)
	#transition_array.append(nTransition)
	#add_transition.emit(nTransition.transitionData)
	#nTransition.focus_entered.connect(emit_signal.bind("item_focused", nTransition))
	#
#func show_popup(node_type: UIMapFocusable.NodeType):
	#lClickPopup.clear()
	#match(node_type):
		#UIMapFocusable.NodeType.EMPTY:
			#lClickPopup.add_item("Create state", PopupButtonIds.CREATE_STATE)
		#UIMapFocusable.NodeType.STATE, UIMapFocusable.NodeType.TRANSITION:
			#lClickPopup.add_item("Delete", PopupButtonIds.DELETE_STATE)
	#lClickPopup.popup()
	#lClickPopup.position = get_global_mouse_position()
	#
#func _on_start_item_rect_changed():
	#if visible:
		#stateMachineResource.ui_start_pos = StartState.position
#func _on_end_item_rect_changed():
	#if visible:
		#stateMachineResource.ui_end_pos = FinishState.position
#
#func destroy_state(state: UIMapFocusable):
	#var transitions_to_remove = transition_array.filter(
		#func (value):
			#return value.from == state or value.to == state
	#)
	#
	#var size = transitions_to_remove.size()
	#for i in range(size):
		#destroy_transition(transitions_to_remove.pop_back())
	#remove_state.emit(state.stateData)
	#state.queue_free()
	#
#func destroy_transition(transition: UIMapFocusable):
	#var position = transition_array.find(transition)
	#transition_array.remove_at(position)
	#remove_transition.emit(transition.transitionData)
	#transition.queue_free()
#
#func reset():
	#if StartState.item_rect_changed.is_connected(_on_start_item_rect_changed):
		#StartState.item_rect_changed.disconnect(_on_start_item_rect_changed)
	#if FinishState.item_rect_changed.is_connected(_on_end_item_rect_changed):
		#FinishState.item_rect_changed.disconnect(_on_end_item_rect_changed)
#
	#stateMachineResource = null
	#StartState.position = Vector2(177,270)
	#FinishState.position = Vector2(612,270)
	#for child in StateLayer.get_children():
		#if child != StartState and child != FinishState:
			#child.queue_free()
	#for child in TransitionLayer.get_children():
		#child.queue_free()
	#transition_array.clear()
	#rClickNode = null
	#rClickOnState = false
	#offset = Vector2i.ZERO
	#grab = false
	#grab_offset = Vector2i.ZERO
	#dragStateNode = null
	#dragStateNodeOffset = Vector2i.ZERO
	#connectToState = null
	#connectFromState = null
