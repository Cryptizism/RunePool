extends Sprite2D

var board_x: float
var board_y: float
var target_position: Vector2i
var starting_scale: float = 0
var target_scale: float = 1
var move_speed: float = 30
var pulsate: bool = false

func _ready() -> void:
	scale = Vector2(starting_scale, starting_scale)
	target_position = Vector2i(position.x, position.y)

func _process(delta: float) -> void:
	position = position.lerp(target_position, delta * move_speed)
	scale = scale.lerp(Vector2(target_scale, target_scale), 0.2)
	if !pulsate:
		return
	var new_scale = scale.x * 1.1
	modulate.a -= 0.02
	scale = Vector2(new_scale, new_scale)
