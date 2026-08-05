extends Control

@onready var button_story_mode: Button = $CenterContainer/VBoxContainer/VBoxContainer/ButtonStoryMode

func _ready() -> void:
	button_story_mode.grab_focus()
	Global.current_floor = 1

func _on_button_story_mode_pressed() -> void:
	Global.player_count = 1
	Transition.change_scene_loading(
		"res://scenes/game_room.tscn",
		"Descending to Floor " + str(Global.current_floor) + "/8",
		"",
		"slide_up",
	)

func _on_button_battle_mode_pressed() -> void:
	Global.player_count = 2
	Transition.change_scene("res://scenes/menus/battle_menu.tscn", "", "slide_right")

func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _on_button_settings_pressed() -> void:
	Transition.change_scene("res://scenes/menus/settings_menu.tscn", "", "slide_left")
