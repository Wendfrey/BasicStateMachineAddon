@tool
extends GraphElement
class_name UIMapFocusable

enum NodeType {EMPTY, STATE, TRANSITION}

@export var deleteable: bool = true
@export var can_transition_to: bool = true
@export var can_transition_from: bool = true
@export var node_type = NodeType.EMPTY

var on_item_rclicked: Callable

func delete() -> bool:
	if deleteable:
		queue_free()
	return deleteable

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			var owner = get_parent_control() as GraphEdit
			if not owner:
				push_warning("GraphElement must be a child of GraphEdit")
				return
				
			on_item_rclicked.call(name)
			accept_event()
