extends Control

@onready var fullscreen_box: CheckBox = $TabContainer/TabVideo/MarginContainer/VBoxContainer/FullscreenToggle/UICheckBox
@onready var combo_text_box: CheckBox = $TabContainer/TabVideo/MarginContainer/VBoxContainer/ComboTextToggle/UICheckBox
@onready var character_shake_box: CheckBox = $TabContainer/TabVideo/MarginContainer/VBoxContainer/CharShakeToggle/UICheckBox
@onready var ghost_gems_enabled_box: CheckBox = $TabContainer/TabVideo/MarginContainer/VBoxContainer/GhostToggle/UICheckBox
@onready var music_slider: HSlider = $TabContainer/TabAudio/MarginContainer/VBoxContainer/MusicSlider/HSlider
@onready var sound_slider: HSlider = $TabContainer/TabAudio/MarginContainer/VBoxContainer/SoundSlider/HSlider
@onready var first_control: UIButton = $TabContainer/TabControls/MarginContainer/VBoxContainer/MoveUp/Button

func _ready() -> void:
	fullscreen_box.grab_focus()
	fullscreen_box.button_pressed = Settings.fullscreen
	combo_text_box.button_pressed = Settings.combo_text
	character_shake_box.button_pressed = Settings.character_shake
	ghost_gems_enabled_box.button_pressed = Settings.ghost_gems_enabled
	music_slider.value = Settings.music_volume
	sound_slider.value = Settings.sound_volume

func _on_back_button_pressed() -> void:
	Transition.change_scene("res://scenes/menus/main_menu.tscn", "", "slide_right")

func _on_reset_all_pressed() -> void:
	Controls.reset_all_keybinds()

func _on_music_value_changed(value: float) -> void:
	Settings.music_volume = value

func _on_sound_value_changed(value: float) -> void:
	Settings.sound_volume = value
