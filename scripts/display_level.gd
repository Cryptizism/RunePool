extends Control

var level_data = preload("res://scripts/levels.gd")
var layout: Array = []
var cell_size: int = 4

func _ready() -> void:
	var test_layout = level_data.LEVEL_LAYOUTS[level_data.get_random_level_name()]
	set_level_layout(test_layout)

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

func set_level_layout(new_layout: Array) -> void:
	layout = new_layout
	update_size()
	queue_redraw()

func update_size() -> void:
	if layout.is_empty():
		custom_minimum_size = Vector2.ZERO
		return
	var w = layout[0].length() * cell_size
	var h = layout.size() * cell_size
	custom_minimum_size = Vector2(w, h)
