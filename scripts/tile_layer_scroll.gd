extends TileMapLayer

@export var loop_distance: Vector2 = Vector2(8, 8)
@export var scroll_speed: Vector2 = Vector2(1, 1)

var initial_position: Vector2
var distance_travelled: Vector2 = Vector2.ZERO

func _ready() -> void:
	initial_position = global_position
	modulate.a = 0.35

func _process(delta: float) -> void:
	var change = scroll_speed * delta
	global_position += change
	distance_travelled += change
	if abs(distance_travelled.x) >= loop_distance.x:
		global_position.x = initial_position.x
		distance_travelled.x = 0
	if abs(distance_travelled.y) >= loop_distance.y:
		global_position.y = initial_position.y
		distance_travelled.y = 0
