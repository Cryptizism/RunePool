extends Control

@onready var label_level_name: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/LabelLevelName
@onready var slider_level_name: HSlider = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/SliderLevelName
@onready var label_enemy: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer2/LabelEnemy
@onready var slider_enemy: HSlider = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer2/SliderEnemy
@onready var label_speed: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer3/LabelSpeed
@onready var slider_speed: HSlider = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer3/SliderSpeed
@onready var label_difficulty: Label = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer4/LabelDifficulty
@onready var slider_difficulty: HSlider = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer4/SliderDifficulty
@onready var button_player_1: Button = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer5/ButtonPlayer1
@onready var button_player_2: Button = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer5/ButtonPlayer2
@onready var button_play: Button = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer5/ButtonPlay

func _ready() -> void:
	pass
