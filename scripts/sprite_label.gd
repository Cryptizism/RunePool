extends CenterContainer

@onready var texture_rect: TextureRect = $HBoxContainer/TextureRect
@onready var label: Label = $HBoxContainer/Label

@export var texture: Texture2D
@export var text: String

func _ready() -> void:
	set_texture(texture)
	set_text(text)

func set_texture(_texture: Texture2D) -> void:
	if !_texture:
		return
	texture_rect.texture = _texture

func set_text(_text: String) -> void:
	if !_text:
		return
	if _text is not String:
		_text = str(_text)
	label.text = _text

func set_color(_color: Color) -> void:
	if !_color:
		return
	label.modulate = _color
