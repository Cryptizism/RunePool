extends Node2D
class_name Character

@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var display_label: Label = $DisplayLabel
@onready var sprite_label: CenterContainer = $SpriteLabel

const GHOST_SPRITE: SpriteFrames = preload("uid://dimkkyhw8qawr")
const DAMAGE_TEXT_SCENE: PackedScene = preload("uid://cf0ps5pw36p24")

const CharacterData = preload("res://scripts/character_data.gd")
var character_id: String
var display_name: String = ""
var flipped_portrait: bool = false
var hp: int = -1 #-1 = drop gem instead of deal damage
var max_hp: int = -1
var board: Board
var opponent: Character
var attack_frequency_in_turns: int = 3
var is_shaking: bool = false
var is_flashing: bool = false

func _ready() -> void:
	if !character_id:
		return
	load_character_data(character_id)
	_update_attack_countdown()
	display_label.z_index += 1

func load_character_data(_character_id: String) -> void:
	character_id = _character_id
	var character_data: Dictionary = CharacterData.CHARACTER_DATA.get(_character_id)
	display_name = character_data.get("name")
	display_label.text = display_name
	set_max_hp(character_data.get("max_hp"))
	_set_portrait(character_data.sprite_frames)
	set_attack_frequency_in_turns(character_data.get("attack_frequency"))

func set_max_hp(amount: int) -> void:
	max_hp = clamp(amount, -1, 1000)
	hp = max_hp
	_update_health_bar()
	_update_attack_countdown()

func _update_health_bar() -> void:
	if !health_bar:
		return
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.visible = max_hp >= 0

func _set_portrait(sprite_frames: SpriteFrames) -> void:
	if !character_sprite:
		return
	var flip: bool = true
	var default: SpriteFrames = preload("res://animations/error.tres")
	if !sprite_frames:
		sprite_frames = default
	if sprite_frames == default:
		flip = false
	character_sprite.sprite_frames = sprite_frames
	character_sprite.frame = 1
	character_sprite.play()
	if flip:
		character_sprite.flip_h = flipped_portrait

func set_attack_frequency_in_turns(amount: int) -> void:
	attack_frequency_in_turns = clamp(amount, 0, 10)

func send_attack(amount: int) -> void:
	if !opponent.board:
		return
	opponent.board.receive_attack(amount)

func check_launch_attack() -> void:
	if !opponent:
		return
	_update_attack_countdown()
	if opponent.max_hp >= 0 or hp == 0:
		return
	if board.turn_number % attack_frequency_in_turns != 0:
		return
	if !opponent:
		return
	send_attack(1)

func _update_attack_countdown() -> void:
	if !sprite_label:
		return
	if max_hp <= -1 || hp == 0:
		sprite_label.queue_free()
		return
	var turns_remaining: int = attack_frequency_in_turns - ((board.turn_number - 1) % attack_frequency_in_turns)
	sprite_label.set_text(str(turns_remaining - 1))
	var color: Color = Color(1.0, 0.0, 0.0) if turns_remaining - 1 == 0 else Color(1.0, 1.0, 1.0)
	sprite_label.set_color(color)

func check_combo(combo_data: Dictionary) -> void:
	if !opponent:
		return
	if opponent.max_hp < 0:
		return
	var gem_count: int = combo_data.get("gems")
	var line_count: int = combo_data.get("lines")
	if gem_count <= 4:
		return
	var damage: int = line_count - 1 + ceili(float(gem_count) / 4.0)
	if !opponent:
		return
	opponent.receive_damage(damage)

func receive_damage(amount: int) -> void:
	if max_hp < 0:
		board.incoming_gems_waiting += max(ceil(amount / 2.0), 1)
		return
	take_damage(amount)

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = clamp(hp - amount, 0, max_hp)
	_update_health_bar()
	_flash_portrait()
	_shake_portrait()
	_show_damage_text(amount)
	_update_attack_countdown()
	if hp > 0:
		return
	die()

func die() -> void:
	character_sprite.sprite_frames = GHOST_SPRITE
	display_label.visible = false

func flip_portrait() -> void:
	flipped_portrait = !flipped_portrait
	character_sprite.flip_h = flipped_portrait

func _set_shake(value: bool) -> void:
	is_shaking = value

func _set_flashing(value: bool) -> void:
	is_flashing = value

func _shake_portrait() -> void:
	if !character_sprite or is_shaking or !Settings.character_shake:
		return
	is_shaking = true
	var original_position = character_sprite.position
	var speed = 0.02
	var tween = get_tree().create_tween()
	for i in range(12):
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1))
		tween.tween_property(character_sprite, "position", original_position + offset, speed)
	tween.tween_property(character_sprite, "position", original_position, speed)
	tween.tween_callback(_set_shake.bind(false))

func _flash_portrait(color: Color = Color(1, 0.2, 0.2)) -> void:
	if !character_sprite or is_flashing:
		return
	is_flashing = true
	var tween = get_tree().create_tween()
	tween.tween_property(character_sprite, "modulate", color, 0.05)
	tween.tween_interval(0.1)
	tween.tween_property(character_sprite, "modulate", Color(1, 1, 1), 0.2)
	tween.tween_callback(_set_flashing.bind(false))

func _show_damage_text(amount: int) -> void:
	if !Settings.combo_text:
		return
	var label = DAMAGE_TEXT_SCENE.instantiate()
	label.text = "-" + str(amount)
	add_child(label)
	label.position = character_sprite.position + Vector2(board.CELL_SIZE * 2, board.CELL_SIZE * 2)
	label.z_index += 2
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	var dx = 5 + randi() % 10
	var dy = 10 + randi() % 10
	if !flipped_portrait:
		dx *= -1
	tween.tween_property(label, "position:x", label.position.x + dx, 1).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - dy, 1).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1).set_ease(Tween.EASE_OUT)
