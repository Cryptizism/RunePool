extends Control

@onready var button_story_mode: Button = $CenterContainer/VBoxContainer/VBoxContainer/ButtonStoryMode

func _ready() -> void:
	button_story_mode.grab_focus()

func _on_button_story_mode_pressed() -> void:
	Global.player_count = 1
	get_tree().change_scene_to_file("res://scenes/singleplayer.tscn")

func _on_button_battle_mode_pressed() -> void:
	Global.player_count = 2
	get_tree().change_scene_to_file("res://scenes/menus/level_menu.tscn")

func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _on_button_settings_pressed() -> void:
	pass
