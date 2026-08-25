extends VBoxContainer
class_name PlayerSettingsMenu

const CharacterData = preload("res://scripts/character_data.gd")

@export var player_id: int = 0
@export var player_name: Label
@export var speed_slider: HSlider
@export var speed_label: Label
@export var difficulty_slider: HSlider
@export var difficulty_label: Label
@export var character_name: Label
@export var character_button_left: Button
@export var character_button_right: Button
@export var character_image: TextureRect
@export var character_description: Label
@export var ready_button: Button

var _character_id: String = ""
var _character_keys: Array = []
var _current_index: int = 0

func _ready() -> void:
	if speed_slider:
		speed_slider.value_changed.connect(_on_speed_changed)
		speed_slider.value = Global.player_speed[player_id]
	if difficulty_slider:
		difficulty_slider.value_changed.connect(_on_difficulty_changed)
		difficulty_slider.value = Global.player_difficulty[player_id]
	if character_button_left:
		character_button_left.pressed.connect(_on_character_button_left_pressed)
	if character_button_right:
		character_button_right.pressed.connect(_on_character_button_right_pressed)
	_character_id = Global.player_characters[player_id]
	_character_keys = CharacterData.CHARACTER_DATA.keys()
	_character_keys.erase("error")
	if _character_keys.size() > 0:
		_current_index = 0
		_set_character(_character_keys[_current_index], false)

func set_display_name(display_name: String) -> void:
	player_name.text = display_name

func set_enabled(value: bool) -> void:
	if speed_slider:
		speed_slider.editable = value
	if difficulty_slider:
		difficulty_slider.editable = value
	if character_button_left:
		character_button_left.disabled = !value
	if character_button_right:
		character_button_right.disabled = !value
	if ready_button:
		ready_button.disabled = !value

func set_speed(value: float) -> void:
	if !speed_slider:
		return
	value = clamp(value, speed_slider.min_value, speed_slider.max_value)
	speed_slider.set_value_no_signal(value)
	speed_label.text = str(int(value))

func set_difficulty(value: float) -> void:
	if !difficulty_slider:
		return
	value = clamp(value, difficulty_slider.min_value, difficulty_slider.max_value)
	difficulty_slider.set_value_no_signal(value)
	difficulty_label.text = str(int(value))

func _set_character(character_id: String, send_network: bool) -> void:
	if !character_id:
		return
	_character_id = character_id
	var character_data: Dictionary = CharacterData.CHARACTER_DATA.get(_character_id)
	if character_name:
		character_name.text = character_data.get("name")
	if character_image:
		var atlas_texture: AtlasTexture = AtlasTexture.new()
		var sprite_frames: SpriteFrames = character_data.get("sprite_frames")
		if sprite_frames:
			atlas_texture.atlas = sprite_frames.get_frame_texture("default", 0)
			atlas_texture.region.size = Vector2(32.0, 32.0)
			character_image.texture = atlas_texture
	if character_description:
		character_description.text = character_data.get("ability")
	Global.player_characters[player_id] = _character_id
	if send_network:
		_send_settings()

func set_character(character_id: String) -> void:
	_set_character(character_id, false)

func _on_speed_changed(value: float) -> void:
	Global.player_speed[player_id] = value
	speed_label.text = str(int(value))
	_send_settings()

func _on_difficulty_changed(value: float) -> void:
	Global.player_difficulty[player_id] = value
	difficulty_label.text = str(int(value))
	_send_settings()

func _on_character_button_left_pressed() -> void:
	if _character_keys.size() <= 0:
		return
	_current_index = (_current_index - 1 + _character_keys.size()) % _character_keys.size()
	_set_character(_character_keys[_current_index], true)

func _on_character_button_right_pressed() -> void:
	if _character_keys.size() <= 0:
		return
	_current_index = (_current_index + 1) % _character_keys.size()
	_set_character(_character_keys[_current_index], true)

func _send_settings() -> void:
	var player_settings: NetworkManager.PlayerSettings = NetworkManager.PlayerSettings.new()
	if speed_slider:
		player_settings.speed = speed_slider.value
	if difficulty_slider:
		player_settings.difficulty = difficulty_slider.value
	player_settings.character_id = _character_id
	NetworkManager.send_player_settings(player_settings)
