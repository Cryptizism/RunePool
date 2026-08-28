extends UIButton

const READY_THEME = preload("res://themes/green_theme.tres")
const NOT_READY_THEME = preload("res://themes/red_theme.tres")

var is_ready: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	theme = NOT_READY_THEME

func _on_pressed() -> void:
	is_ready =  !is_ready
	if is_ready:
		theme = READY_THEME
	else:
		theme = NOT_READY_THEME
