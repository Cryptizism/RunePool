extends Node2D
class_name CellObject

var target_position: Vector2
var base_move_speed: float = 30
var move_speed: float = base_move_speed
var has_gravity: bool = false

func _ready() -> void:
	target_position = Vector2i(position.x, position.y)

func _process(delta: float) -> void:
	position = position.lerp(target_position, delta * move_speed)
	if position.distance_to(target_position) < 0.1:
		move_speed = base_move_speed

func destroy() -> void:
	queue_free()
