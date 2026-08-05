extends Control

@onready var button_play: UIButton = $CenterContainer/VBoxContainer/HBoxContainer/LevelMenu/HBoxContainer5/ButtonPlay

func _ready() -> void:
	button_play.grab_focus()

#menu
func _on_button_back_pressed() -> void:
	Transition.change_scene("res://scenes/menus/battle_menu.tscn", "", "slide_up")

func _on_button_play_pressed() -> void:
	Global.player_count = 2
	Transition.change_scene_loading(
		"res://scenes/game_room.tscn",
		"Good luck!",
		"",
		"slide_left",
	)
