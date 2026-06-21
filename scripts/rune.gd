extends Gem
class_name Rune

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var board: Board
var sprite_frames: Dictionary = {
	"blue": preload("res://animations/rune_blue.tres"),
	"red": preload("res://animations/rune_red.tres"),
	"green": preload("res://animations/rune_green.tres"),
	"yellow": preload("res://animations/rune_yellow.tres"),
}

func _ready() -> void:
	super()
	has_gravity = false
	sprite.visible = false
	var new_sprite_frames: SpriteFrames = sprite_frames.get(color)
	if animated_sprite && new_sprite_frames:
		animated_sprite.sprite_frames = new_sprite_frames
		animated_sprite.stop()
	add_to_group("runes")

func destroy() -> void:
	super()
	if !board:
		return
	board.runes_remaining -= 1
