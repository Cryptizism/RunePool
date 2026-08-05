extends Control

@onready var label: Label = $HBoxContainer/Label
@onready var button_left: UIButton = $HBoxContainer/ButtonLeft
@onready var button_right: UIButton = $HBoxContainer/ButtonRight

enum Setting { SPEED, DIFFICULTY, CHARACTER, MAP }
var setting: Setting = Setting.SPEED
