extends UIButton

const READY_THEME = preload("res://themes/green_theme.tres")
const NOT_READY_THEME = preload("res://themes/red_theme.tres")
const OTHER_PLAYER_THEME = preload("res://themes/other_player_theme.tres")

var active_theme = READY_THEME
var inactive_theme = NOT_READY_THEME
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
		active_theme = OTHER_PLAYER_THEME
		inactive_theme = OTHER_PLAYER_THEME
		disabled = true
	else:
		active_theme = READY_THEME
		inactive_theme = NOT_READY_THEME
		disabled = false
	set_ready(is_ready)

func set_ready(_is_ready: bool) -> void:
	is_ready = _is_ready
	if _is_ready:
		theme = active_theme
	else:
		theme = inactive_theme
