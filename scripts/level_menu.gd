extends Control

var level_data = preload("res://scripts/levels.gd")
var level_names: Array = []
var current_level: int = 0

@onready var label_level_name: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer2/LabelLevelName
@onready var level_display: Control = $CenterContainer/VBoxContainer/VBoxContainer/LevelDisplay

func _ready() -> void:
	level_names = level_data.LEVEL_LAYOUTS.keys()
	update_level_display()

func _on_button_level_left_pressed() -> void:
	current_level = (current_level - 1 + level_names.size()) % level_names.size()
	update_level_display()

func _on_button_level_right_pressed() -> void:
	current_level = (current_level + 1) % level_names.size()
	update_level_display()

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_button_play_pressed() -> void:
	Global.selected_level = level_names[current_level]
	get_tree().change_scene_to_file("res://scenes/battle_menu.tscn")

func update_level_display() -> void:
	var level_name = level_names[current_level]
	label_level_name.text = level_name.capitalize()
	if !level_display:
		return
	level_display.set_level_layout(level_data.LEVEL_LAYOUTS[level_name])
