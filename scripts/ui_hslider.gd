extends HSlider
class_name UIHSlider

const HOVER_SCALE: Vector2 = Vector2(1.03, 1.03)
const TILT_ANGLE: float = 0.5
const ANIM_SPEED: float = 0.3
var base_z_index: int = 0

func _ready() -> void:
	pivot_offset = size / 2.0
	base_z_index = z_index
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)

func _on_pressed() -> void:
	_stop_animation()

func _on_mouse_entered() -> void:
	if !editable:
		return
	call_deferred("grab_focus")
	_play_animation()

func _on_focus_entered() -> void:
	if !editable:
		return
	_play_animation()

func _on_focus_exited() -> void:
	_stop_animation()

func _play_animation() -> void:
	var tween: Tween = create_tween()\
		.set_parallel(true)
	tween.tween_property(self, "scale", HOVER_SCALE, ANIM_SPEED)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", TILT_ANGLE, ANIM_SPEED)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	z_index = base_z_index + 10

func _stop_animation() -> void:
	var tween: Tween = create_tween()\
		.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, ANIM_SPEED)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", 0.0, ANIM_SPEED)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	z_index = base_z_index
