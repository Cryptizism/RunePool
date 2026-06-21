extends CellObject
class_name Particle

@onready var sprite: Sprite2D = $Sprite2D

var color: String = ""
var textures: Dictionary = {
	"blue": {
		"base": preload("res://sprites/game/particles/water.png"),
	},
	"red": {
		"base": preload("res://sprites/game/particles/fire.png"),
	},
	"green": {
		"base": preload("res://sprites/game/particles/leaf.png"),
	},
	"yellow": {
		"base": preload("res://sprites/game/particles/lightning.png"),
	},
}

func _ready() -> void:
	super()
	set_color(color)
	_animate()

func _process(delta: float) -> void:
	pass

func _animate() -> void:
	if !sprite:
		return
	var target_scale: float = 2.5
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(sprite, "scale", Vector2(target_scale, target_scale), 0.5)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func set_color(_color: String) -> void:
	if !textures.has(_color):
		return
	color = _color
	sprite.texture = textures.get(_color).get("base")
