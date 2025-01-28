@tool
extends "res://addons/basic_fsm/ui/map_ui/UIMapFocusable.gd"

const PI_HALF = PI/2

var transitionData:StateMachineResource.TransitionData:
	set(value):
		transitionData = value
		
@export var line_width:float = 0
@export var offset_weight = 8

var from: UIMapFocusable = null:
	set(value):
		if from == value:
			return
			
		if from and from.item_rect_changed.is_connected(update):
			from.item_rect_changed.disconnect(update)
		if value and not value.item_rect_changed.is_connected(update):
			value.item_rect_changed.connect(update)
			from = value
		update()

var to: UIMapFocusable = null:
	set(value):
		if to == value:
			return
		if to and to.item_rect_changed.is_connected(update):
			to.item_rect_changed.disconnect(update)
		if value and not value.item_rect_changed.is_connected(update):
			value.item_rect_changed.connect(update)
			to = value
		update()

@export var color_base = Color.WHITE_SMOKE
@export var color_focus = Color.GOLD

func update():
	visible = from and to
	if not visible:
		return
	var from_pos = from.position_offset + from.size/2
	var to_pos = to.position_offset + to.size/2
	var center_offset = offset_weight * Vector2.RIGHT.rotated(
		from_pos.angle_to_point(to_pos) - PI/2
	)
	from_pos += center_offset
	to_pos += center_offset
	position_offset = from_pos.move_toward(to_pos, (from_pos - to_pos).length()/2) - size/2

func _ready():
	node_selected.connect(_on_node_selected)
	node_deselected.connect(_on_node_deselected)

var _color = color_base
func _draw():
	if not _color:
		_color = color_base if not selected else color_focus
		
	var half_c = size.x/2
	var full_c = size.x
	
	var point_triangle = PackedVector2Array()
	
	var _angle = 0
	if from and to:
		var from_center = from.position_offset + from.size/2 - position_offset
		var to_center = to.position_offset + to.size/2 - position_offset
		_angle = from_center.angle_to_point(to_center)
		
		var center_offset = offset_weight * Vector2.RIGHT.rotated(_angle - PI_HALF)
		var from_offset = get_offset_for_size_angled(_angle, from.size, center_offset)
		var to_offset = get_offset_for_size_angled(to_center.angle_to_point(from_center), to.size, center_offset)
		draw_dashed_line(from_center + from_offset, to_center + to_offset, _color, line_width, line_width * 2)
		
	point_triangle.append(Vector2(-half_c, half_c).rotated(_angle) + size/2)
	point_triangle.append(Vector2(half_c, 0).rotated(_angle) + size/2)
	point_triangle.append(Vector2(-half_c, -half_c).rotated(_angle) + size/2)
	
	draw_colored_polygon(point_triangle, _color)

func get_intersection_point(a_p1, a_p2, b_p1, b_p2) -> Vector2:
	#https://en.m.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line_segment
	var numerator_a_p1p2 = a_p1.x*a_p2.y - a_p2.x*a_p1.y
	var numerator_b_p1p2 = b_p1.x*b_p2.y - b_p2.x*b_p1.y
	
	var a_px_diff = a_p1.x - a_p2.x
	var b_px_diff = b_p1.x - b_p2.x
	
	var a_py_diff = a_p1.y - a_p2.y
	var b_py_diff = b_p1.y - b_p2.y
	
	var inv_common_denominator = 1/((a_px_diff * b_py_diff) - (b_px_diff * a_py_diff))
	
	return Vector2(
		(numerator_a_p1p2 * b_px_diff - numerator_b_p1p2 * a_px_diff) * inv_common_denominator,
		(numerator_a_p1p2 * b_py_diff - numerator_b_p1p2 * a_py_diff) * inv_common_denominator
	)

func get_offset_for_size_angled(_angle, _size, _offset_center):
	var final_offset = Vector2.ZERO
	var half_size = _size/2
	
	#if the angle is parallel to one of the sides we can know directly
	# given that _offset_center is perpendicular to the line of our desired point
	# i'm not responsible of what will happen if _offset_center is not perp.
	if is_equal_approx(_angle, 0):
		final_offset = Vector2(half_size.x,0) + _offset_center
	elif is_equal_approx(_angle, PI_HALF):
		final_offset = Vector2(0,half_size.y) + _offset_center
	elif is_equal_approx(_angle, PI):
		final_offset = Vector2(-half_size.x,0) + _offset_center
	elif is_equal_approx(_angle, -PI_HALF):
		final_offset = Vector2(0,-half_size.y) + _offset_center
	else:
		#it is not parallel, calculate intersecting point
		
		#define corners of our intersecting square
		var corner_up_right = Vector2(half_size.x, half_size.y)
		var corner_up_left = Vector2(-half_size.x, half_size.y)
		var corner_down_right = Vector2(half_size.x, -half_size.y)
		var corner_down_left = Vector2(-half_size.x, -half_size.y)
		
		#We use array to define segments [only 2 points per segment]
		var vertical_segment = []
		var horizontal_segment = []
		
		#Since the sides of the elements 'from' and 'to'
		# are parallel we only search for the pair segments of interest based
		# on the _angle
		if 0 < _angle and _angle < PI:
			horizontal_segment = [corner_up_left, corner_up_right]
		else:
			horizontal_segment = [corner_down_left, corner_down_right]
		
		# Since we know that _angle value ranges from -179.99... to 180
		if -PI_HALF < _angle and _angle < PI_HALF:
			vertical_segment = [corner_down_right, corner_up_right]
		else:
			vertical_segment = [corner_down_left, corner_up_left]

		var offset_p2 = _offset_center + Vector2.RIGHT.rotated(_angle)
		var intersection_points = [
			get_intersection_point(_offset_center, offset_p2, vertical_segment[0], vertical_segment[1]),
			get_intersection_point(_offset_center, offset_p2, horizontal_segment[0], horizontal_segment[1])
		]
		
		intersection_points.sort_custom(
			func (a, b): return a.length_squared() <= b.length_squared()
		)
		final_offset = intersection_points[0]
		
	return final_offset

func _on_node_selected():
	_color = color_focus
	queue_redraw()
	
func _on_node_deselected():
	_color = color_base
	queue_redraw()
	
