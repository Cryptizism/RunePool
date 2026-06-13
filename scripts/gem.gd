extends CellObject
class_name Gem

enum State { IDLE, FALLING, BREAKING }
var state: State = State.IDLE

@onready var sprite: Sprite2D = $Sprite2D

var color: String = "red"
var cluster_id: int = -1
var textures: Dictionary = {
	"red": preload("res://sprites/game/red.png"),
	"blue": preload("res://sprites/game/blue.png"),
	"green": preload("res://sprites/game/green.png"),
	"yellow": preload("res://sprites/game/yellow.png"),
}

func _ready() -> void:
	if !sprite:
		queue_free()
		return
	super()
	has_gravity = true
	set_color(color)
	add_to_group("gems")

func _process(delta: float) -> void:
	super(delta)

func set_color(_color: String) -> void:
	if !textures.has(_color):
		return
	color = _color
	sprite.texture = textures.get(_color)

func destroy() -> void:
	super()
