extends Control
class_name LevelDisplay

@export var level_label: Label
@export var button_left: Button
@export var button_right: Button

var level_data = preload("res://scripts/levels.gd")
var level_names: Array = []
var current_level: int = 0
var layout: Array = []
var cell_size: int = 4

func _ready() -> void:
	if button_left:
		button_left.pressed.connect(_on_button_level_left_pressed)
	if button_right:
		button_right.pressed.connect(_on_button_level_right_pressed)
	level_names = level_data.LEVEL_LAYOUTS.keys()
	var test_layout = level_data.LEVEL_LAYOUTS[level_data.get_random_level_name()]
	_set_level_layout(test_layout)
	_update_level_display()

func _draw() -> void:
	if layout.is_empty():
		return
	var layout_width = layout[0].length() * cell_size
	var layout_height = layout.size() * cell_size
	var offset = (size - Vector2(layout_width, layout_height)) / 2.0
	draw_rect(Rect2(offset, Vector2(layout_width, layout_height)), Color.WHITE, true)
	draw_rect(Rect2(offset + Vector2(1, 1), Vector2(layout_width - 2, layout_height - 2)), Color.BLACK, true)
	for y in range(layout.size()):
		for x in range(layout[y].length()):
			var pos = Vector2(x, y) * cell_size + offset
			if layout[y][x] == "#":
				draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), Color.WHITE, true)

func _set_level_layout(new_layout: Array) -> void:
	layout = new_layout
	Global.selected_level = level_names[current_level]
	_update_size()
	queue_redraw()

func _update_size() -> void:
	if layout.is_empty():
		custom_minimum_size = Vector2.ZERO
		return
	var width = layout[0].length() * cell_size
	var height = layout.size() * cell_size
	custom_minimum_size = Vector2(width, height)

func set_level_id(level_id: String) -> void:
	var index: int = level_names.find(level_id)
	if index == -1:
		return
	current_level = index
	_set_level_layout(level_data.LEVEL_LAYOUTS[level_id])

func _on_button_level_left_pressed() -> void:
	current_level = (current_level - 1 + level_names.size()) % level_names.size()
	_update_level_display()

func _on_button_level_right_pressed() -> void:
	current_level = (current_level + 1) % level_names.size()
	_update_level_display()

func _update_level_display() -> void:
	var level_name = level_names[current_level]
	if level_label:
		level_label.text = level_name.capitalize()
	_set_level_layout(level_data.LEVEL_LAYOUTS[level_name])
