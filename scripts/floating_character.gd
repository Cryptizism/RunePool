extends Label
class_name FloatingCharacter

var hue: float = 0.0
var wave_timer: float = 0.0
var origin: Vector2
var position_offset: Vector2 = Vector2.ZERO
var move_speed: float = 5.0
var float_direction: float = randf_range(0.0, TAU)
var float_speed: float = 12.0
var float_radius: float = 1.0

func _ready() -> void:
	origin = position
	z_index = 10
	var animation_length: float = 1.5
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_length).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_death)

func _process(delta: float) -> void:
	float_direction += delta * float_speed
	var character_offset: Vector2 = Vector2(
		cos(float_direction) * float_radius,
		sin(float_direction) * float_radius
	)
	position = origin + character_offset
	position += position_offset
	position_offset += Vector2(delta * move_speed / 2, delta * -move_speed)
	hue += delta
	modulate = Color.from_hsv(fmod(hue, 1.0), 1.0, 1.0)

func _on_death() -> void:
	get_parent().queue_free()
