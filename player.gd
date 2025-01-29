extends Node2D

const BulletScene = preload("res://bullet_scene.tscn")

@export var speed: float = 160
@export var max_bullets: int = 10

@onready var stateMachineNode:StateMachineNode = $StateMachineNode
func _ready() -> void:
	stateMachineNode.set_parameter_float("bullets", max_bullets)
	
func spawn_bullet():
	var bullets = stateMachineNode.get_parameter("bullets")
	if bullets > 0:
		var bullet = BulletScene.instantiate()
		get_parent().add_child(bullet)
		bullet.direction = (get_global_mouse_position() - global_position).normalized() * 500
		bullet.position = position
		stateMachineNode.set_parameter_float("bullets", bullets-1)

func rage_state(is_rage):
	if is_rage:
		modulate = Color.FIREBRICK
	else:
		modulate = Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("recharge_action"):
		stateMachineNode.active_trigger("recharge_activated")
	elif event.is_action_pressed("rage_action"):
		stateMachineNode.active_trigger("rage_trigger")

func reloading_color():
	modulate = Color.YELLOW
