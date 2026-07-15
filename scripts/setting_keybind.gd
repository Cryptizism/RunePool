extends Control
class_name SettingKeyBind

@onready var button: Button = $Button
@onready var reset_button: Button = $Reset
@export var action: String = "move_left_1"

func _ready() -> void:
	set_process_input(false)
	button.toggle_mode = true
	button.toggled.connect(_on_button_toggled)
	reset_button.pressed.connect(_on_reset_pressed)
	Controls.keybind_changed.connect(_on_keybind_changed)
	add_to_group("setting_hotkey")
	_update_button_text()
	_update_reset_button()

func _update_button_text() -> void:
	var action_events: Array[InputEvent] = InputMap.action_get_events(action)
	if action_events.is_empty():
		button.text = "None"
		return
	var event = action_events[0]
	if event is InputEventKey:
		button.text = OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	elif event is InputEventMouseButton:
		button.text = "Mouse" + str(event.button_index)
	elif event is InputEventJoypadButton:
		button.text = "Joy" + str(event.button_index)
	elif event is InputEventJoypadMotion:
		button.text = "Axis" + str(event.axis)
	else:
		button.text = event.as_text()
	if button.text.length() > 7:
		button.text = button.text.left(7) + ".."

func _update_reset_button() -> void:
	var default: InputEvent = Controls.get_default_keybind(action)
	var current: InputEvent = Controls.get_keybind(action)
	if default == null:
		reset_button.disabled = true
		return
	if current == null:
		reset_button.disabled = false
		return
	reset_button.disabled = default.is_match(current)

func _on_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		button.text = "..."
		set_process_input(true)
		for node in get_tree().get_nodes_in_group("setting_hotkey"):
			if node != self:
				node.button.button_pressed = false
				node.set_process_input(false)
	else:
		set_process_input(false)
		_update_button_text()
		_update_reset_button()

func _on_reset_pressed() -> void:
	Controls.reset_keybind(action)
	Controls.save_keybinds()
	_update_reset_button()
	#button.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and abs(event.axis_value) < 0.5:
		return
	if event.is_echo():
		return
	if !event.is_pressed() and event is not InputEventJoypadMotion:
		return
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			button.button_pressed = false
			return
		if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
			return
	get_viewport().set_input_as_handled()
	_rebind_action(event)
	button.button_pressed = false

func _rebind_action(event: InputEvent) -> void:
	Controls.set_keybind(action, event)
	Controls.save_keybinds()

func _on_keybind_changed(changed_action: String) -> void:
	if action != changed_action:
		return
	_update_button_text()
	_update_reset_button()
