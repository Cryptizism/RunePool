extends UIButton

const READY_THEME = preload("res://themes/green_theme.tres")
const NOT_READY_THEME = preload("res://themes/red_theme.tres")
const OTHER_PLAYER_THEME = preload("res://themes/other_player_theme.tres")

var is_ready: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	theme = NOT_READY_THEME

func _on_pressed() -> void:
	if disabled:
		return
	set_ready(!is_ready)
	NetworkManager.send_opponent_ready_button(is_ready)

func set_other_player_mode(value: bool) -> void:
	if value:
		theme = OTHER_PLAYER_THEME
		disabled = true
	else:
		disabled = false
	_update_theme()

func set_ready(_is_ready: bool) -> void:
	is_ready = _is_ready
	_update_theme()

func _update_theme() -> void:
	if disabled:
		if is_ready:
			add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		if is_ready:
			theme = READY_THEME
		else:
			theme = NOT_READY_THEME
