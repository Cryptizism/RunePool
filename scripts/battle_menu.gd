extends Control

@onready var label_speed_1: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player1Menu/HBoxContainer3/LabelSpeed1
@onready var label_difficulty_1: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player1Menu/HBoxContainer4/LabelDifficulty1
@onready var label_speed_2: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player2Menu/HBoxContainer3/LabelSpeed2
@onready var label_difficulty_2: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player2Menu/HBoxContainer4/LabelDifficulty2
@onready var button_play: Button = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer5/ButtonPlay

var SPEED_OPTIONS = ["Turtle", "Slow", "Normal", "Normaler", "Fast", "Faster"]
#var SPEED = [1, 0.75, 0.5, 0.4, 0.3, 0.2]
var DIFFICULTY_OPTIONS = ["Hatchling", "Easy", "Normal", "Normaler", "Hard", "Harder"]
#var DIFFICULTY = [10, 15, 20, 25, 30, 40]

func _ready() -> void:
	button_play.grab_focus()
	label_speed_1.text = SPEED_OPTIONS[Global.player_speed[0]]
	label_speed_2.text = SPEED_OPTIONS[Global.player_speed[1]]
	label_difficulty_1.text = DIFFICULTY_OPTIONS[Global.player_difficulty[0]]
	label_difficulty_2.text = DIFFICULTY_OPTIONS[Global.player_difficulty[1]]

func _cycle_option(current: int, options: Array, delta: int) -> int:
	current += delta
	if current < 0:
		current = options.size() - 1
	elif current >= options.size():
		current = 0
	return current

func _update_option(player_number: int, player_option: Array, option_list: Array, label: Label, delta: int) -> void:
	player_option[player_number] = _cycle_option(player_option[player_number], option_list, delta)
	label.text = option_list[player_option[player_number]]

#p1
func _on_button_speed_left_1_pressed() -> void:
	_update_option(0, Global.player_speed, SPEED_OPTIONS, label_speed_1, -1)

func _on_button_speed_right_1_pressed() -> void:
	_update_option(0, Global.player_speed, SPEED_OPTIONS, label_speed_1, 1)

func _on_button_difficulty_left_1_pressed() -> void:
	_update_option(0, Global.player_difficulty, DIFFICULTY_OPTIONS, label_difficulty_1, -1)

func _on_button_difficulty_right_1_pressed() -> void:
	_update_option(0, Global.player_difficulty, DIFFICULTY_OPTIONS, label_difficulty_1, 1)

#p2
func _on_button_speed_left_2_pressed() -> void:
	_update_option(1, Global.player_speed, SPEED_OPTIONS, label_speed_2, -1)

func _on_button_speed_right_2_pressed() -> void:
	_update_option(1, Global.player_speed, SPEED_OPTIONS, label_speed_2, 1)

func _on_button_difficulty_left_2_pressed() -> void:
	_update_option(1, Global.player_difficulty, DIFFICULTY_OPTIONS, label_difficulty_2, -1)

func _on_button_difficulty_right_2_pressed() -> void:
	_update_option(1, Global.player_difficulty, DIFFICULTY_OPTIONS, label_difficulty_2, 1)

#menu
func _on_button_back_pressed() -> void:
	Transition.change_scene("res://scenes/menus/level_menu.tscn", "", "slide_up")

func _on_button_play_pressed() -> void:
	Transition.change_scene_loading(
		"res://scenes/game_room.tscn",
		"Good luck!",
		"",
		"slide_left",
	)
