extends Control

@onready var button_story_mode: Button = $CenterContainer/VBoxContainer/HBoxContainer/VBoxContainer/ButtonStoryMode

func _ready() -> void:
	button_story_mode.grab_focus()

func _on_button_story_mode_pressed() -> void:
	Global.current_mode = Global.MODE.STORY
	get_tree().change_scene_to_file("res://scenes/singleplayer.tscn")

func _on_button_battle_mode_pressed() -> void:
	Global.current_mode = Global.MODE.BATTLE
	get_tree().change_scene_to_file("res://scenes/level_menu.tscn")

func _on_button_close_pressed() -> void:
	get_tree().quit()

func _on_button_gear_pressed() -> void:
	pass # Replace with function body.
