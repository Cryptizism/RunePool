extends Node2D
class_name RainbowText

const FLOATING_CHARACTER: PackedScene = preload("uid://c0jctsqh5bsga")

var text: String = ""

func _create_characters() -> void:
	if !text or text == "":
		return
	var spacing: float = 8.0
	var x_offset: float = 0.0
	for i in text.length():
		var label: FloatingCharacter = FLOATING_CHARACTER.instantiate()
		label.position = Vector2(x_offset, 0)
		add_child(label)
		label.text = text[i]
		label.hue = float(i) * 0.08
		x_offset += spacing

func update_combo_text(gem_count: int) -> void:
	if gem_count > 4:
		text = "nice!"
	if gem_count == 8:
		text = "great!"
	if gem_count > 8:
		text = "amazing!!"
	if gem_count > 10:
		text = "incredible!!"
	if gem_count >= 12:
		text = "phenomenal!!!"
	if gem_count > 16:
		text = "SHOW-OFF!"
	_create_characters()
