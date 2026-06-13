extends Control

@onready var label_speed_1: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player1Menu/HBoxContainer3/LabelSpeed1
@onready var label_difficulty_1: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player1Menu/HBoxContainer4/LabelDifficulty1
@onready var label_speed_2: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player2Menu/HBoxContainer3/LabelSpeed2
@onready var label_difficulty_2: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Player2Menu/HBoxContainer4/LabelDifficulty2

var SPEED_OPTIONS = ["Turtle", "Slow", "Normal", "Normaler", "Fast", "Faster"]
var SPEED = [1, 0.75, 0.5, 0.4, 0.3, 0.2]
var DIFFICULTY_OPTIONS = ["Hatchling", "Easy", "Normal", "Normaler", "Hard", "Harder"]
var DIFFICULTY = [10, 15, 20, 25, 30, 40]

var speed_p1: int = 1
var speed_p2: int = 1
var difficulty_p1: int = 1
var difficulty_p2: int = 1

func _ready() -> void:
	_update_system()

func _update_system() -> void:
	Global.speed_p1 = SPEED[speed_p1]
	Global.difficulty_p1 = DIFFICULTY[difficulty_p1]
	label_speed_1.text = SPEED_OPTIONS[speed_p1]
	label_difficulty_1.text = DIFFICULTY_OPTIONS[difficulty_p1]
	Global.speed_p2 = SPEED[speed_p2]
	Global.difficulty_p2 = DIFFICULTY[difficulty_p2]
	label_speed_2.text = SPEED_OPTIONS[speed_p2]
	label_difficulty_2.text = DIFFICULTY_OPTIONS[difficulty_p2]

func _cycle_option(current: int, options: Array, delta: int) -> int:
	current += delta
	if current < 0:
		current = options.size() - 1
	elif current >= options.size():
		current = 0
	return current

#p1
func _on_button_speed_left_1_pressed() -> void:
	speed_p1 = _cycle_option(speed_p1, SPEED_OPTIONS, -1)
	_update_system()

func _on_button_speed_right_1_pressed() -> void:
	speed_p1 = _cycle_option(speed_p1, SPEED_OPTIONS, 1)
	_update_system()

func _on_button_difficulty_left_1_pressed() -> void:
	difficulty_p1 = _cycle_option(difficulty_p1, DIFFICULTY_OPTIONS, -1)
	_update_system()

func _on_button_difficulty_right_1_pressed() -> void:
	difficulty_p1 = _cycle_option(difficulty_p1, DIFFICULTY_OPTIONS, 1)
	_update_system()

#p2
func _on_button_speed_left_2_pressed() -> void:
	speed_p2 = _cycle_option(speed_p2, SPEED_OPTIONS, -1)
	_update_system()

func _on_button_speed_right_2_pressed() -> void:
	speed_p2 = _cycle_option(speed_p2, SPEED_OPTIONS, 1)
	_update_system()

func _on_button_difficulty_left_2_pressed() -> void:
	difficulty_p2 = _cycle_option(difficulty_p2, DIFFICULTY_OPTIONS, -1)
	_update_system()

func _on_button_difficulty_right_2_pressed() -> void:
	difficulty_p2 = _cycle_option(difficulty_p2, DIFFICULTY_OPTIONS, 1)
	_update_system()

#menu
func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_menu.tscn")

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/multiplayer.tscn")
