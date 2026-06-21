extends CellObject
class_name Gem

enum State { IDLE, FALLING, BREAKING }
var state: State = State.IDLE

@onready var sprite: Sprite2D = $Sprite2D

const PARTICLE_SCENE: PackedScene = preload("res://scenes/particle.tscn")

var color: String = "red"
var cluster_id: int = -1
var textures: Dictionary = {
	"blue": {
		"base": preload("res://sprites/game/gems/blue.png"),
		"h_left": preload("res://sprites/game/gems/blue_h_left.png"),
		"h_right": preload("res://sprites/game/gems/blue_h_right.png"),
		"v_top": preload("res://sprites/game/gems/blue_v_top.png"),
		"v_bottom": preload("res://sprites/game/gems/blue_v_bottom.png"),
	},
	"red": {
		"base": preload("res://sprites/game/gems/red.png"),
		"h_left": preload("res://sprites/game/gems/red_h_left.png"),
		"h_right": preload("res://sprites/game/gems/red_h_right.png"),
		"v_top": preload("res://sprites/game/gems/red_v_top.png"),
		"v_bottom": preload("res://sprites/game/gems/red_v_bottom.png"),
	},
	"green": {
		"base": preload("res://sprites/game/gems/green.png"),
		"h_left": preload("res://sprites/game/gems/green_h_left.png"),
		"h_right": preload("res://sprites/game/gems/green_h_right.png"),
		"v_top": preload("res://sprites/game/gems/green_v_top.png"),
		"v_bottom": preload("res://sprites/game/gems/green_v_bottom.png"),
	},
	"yellow": {
		"base": preload("res://sprites/game/gems/yellow.png"),
		"h_left": preload("res://sprites/game/gems/yellow_h_left.png"),
		"h_right": preload("res://sprites/game/gems/yellow_h_right.png"),
		"v_top": preload("res://sprites/game/gems/yellow_v_top.png"),
		"v_bottom": preload("res://sprites/game/gems/yellow_v_bottom.png"),
	},
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
	sprite.texture = textures.get(_color).get("base")

func set_sprite(piece: String) -> void:
	var data = textures.get(color)
	if data == null:
		sprite.texture = data.get("base")
		return
	var texture = data.get(piece)
	if texture == null:
		sprite.texture = data.get("base")
		return
	sprite.texture = texture

func destroy() -> void:
	var particle: Particle = PARTICLE_SCENE.instantiate()
	particle.color = color
	get_tree().current_scene.add_child(particle)
	particle.global_position = global_position
	super()
