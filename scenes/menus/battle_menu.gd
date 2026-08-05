extends Control

@onready var button_local_battle: UIButton = $CenterContainer/VBoxContainer/VBoxContainer/ButtonLocalBattle

func _ready() -> void:
	button_local_battle.grab_focus()
	Global.current_floor = 1

func _on_button_local_battle_pressed() -> void:
	Transition.change_scene(
		"res://scenes/menus/player_menu.tscn",
		"",
		"slide_down",
	)

func _on_button_back_pressed() -> void:
	Transition.change_scene(
		"res://scenes/menus/main_menu.tscn",
		"",
		"slide_left",
	)

func _on_button_host_lobby_pressed() -> void:
	Transition.change_scene(
		"res://scenes/menus/lobby_menu.tscn",
		"",
		"slide_down",
	)
