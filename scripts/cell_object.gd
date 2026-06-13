extends Node2D
class_name CellObject

var target_position: Vector2
var base_move_speed: float = 30
var move_speed: float = base_move_speed
#var pulsate: bool = false
var has_gravity: bool = false

func _ready() -> void:
	target_position = Vector2i(position.x, position.y)

func _process(delta: float) -> void:
	position = position.lerp(target_position, delta * move_speed)
	if position.distance_to(target_position) < 0.1:
		move_speed = base_move_speed
	#_pulse()

func destroy() -> void:
	queue_free()

#func _pulse() -> void:
	#if !pulsate:
		#return
	#var new_scale = scale.x * 1.1
	#modulate.a -= 0.02
	#scale = Vector2(new_scale, new_scale)
