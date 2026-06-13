extends Gem
class_name Rune

var board: Board

func _ready() -> void:
	super()
	has_gravity = false
	textures = {
		"red": preload("res://sprites/game/rune_red.png"),
		"blue": preload("res://sprites/game/rune_blue.png"),
		"green": preload("res://sprites/game/rune_green.png"),
		"yellow": preload("res://sprites/game/rune_yellow.png"),
	}
	set_color(color)
	add_to_group("runes")

func destroy() -> void:
	super()
	if !board:
		return
	board.runes_remaining -= 1
