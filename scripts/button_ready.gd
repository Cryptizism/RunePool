extends UIButton

const READY_THEME = preload("res://themes/green_theme.tres")
const NOT_READY_THEME = preload("res://themes/red_theme.tres")

var is_ready: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	theme = NOT_READY_THEME

func _on_pressed() -> void:
	if disabled:
		return
	set_ready(!is_ready)
	NetworkManager.send_opponent_ready_button(is_ready)

func set_ready(_is_ready: bool) -> void:
	is_ready = _is_ready
	if _is_ready:
		theme = READY_THEME
	else:
		theme = NOT_READY_THEME
