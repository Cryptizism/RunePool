extends Control
class_name SettingToggle

@onready var check_box: CheckBox = $UICheckBox

signal check_box_toggled(value: bool)

func _ready() -> void:
	check_box.toggled.connect(_on_check_box_toggled)

func _on_check_box_toggled(toggled_on: bool) -> void:
	check_box_toggled.emit(toggled_on)

func _on_fullscreen_toggled(value: bool) -> void:
	Settings.fullscreen = value

func _on_combo_text_toggled(value: bool) -> void:
	Settings.combo_text = value

func _on_character_shake_toggled(value: bool) -> void:
	Settings.character_shake = value

func _on_ghost_gems_toggled(value: bool) -> void:
	Settings.ghost_gems_enabled = value
