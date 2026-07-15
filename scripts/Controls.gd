extends Node

signal keybind_changed(action_name: String)
const FILE_PATH: String = "user://keybinds.cfg"

func _ready() -> void:
	load_keybinds()

func get_default_keybind(action: String) -> InputEvent:
	var path: String = "input/" + action
	if !ProjectSettings.has_setting(path):
		push_warning("Input action not found: " + action)
		return null
	var defaults: Dictionary = ProjectSettings.get_setting(path)
	if !defaults:
		return null
	if !defaults.has("events"):
		return null
	if defaults["events"].size() <= 0:
		return null
	return defaults["events"][0]

func get_keybind(action: String) -> InputEvent:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if events.size() <= 0:
		return null
	return events[0]

func set_keybind(action: String, event: InputEvent) -> void:
	if event == null:
		return
	for conflicting_action in InputMap.get_actions():
		if conflicting_action == action:
			continue
		for conflicting_event in InputMap.action_get_events(conflicting_action):
			if !conflicting_event.is_match(event):
				continue
			InputMap.action_erase_events(conflicting_action)
			#InputMap.action_erase_event(conflicting_action, conflicting_event)
			keybind_changed.emit(conflicting_action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)

func keybind_has_conflict(input_event: InputEvent) -> String:
	if input_event == null:
		return ""
	for action in InputMap.get_actions():
		for event in InputMap.action_get_events(action):
			if !event.is_match(input_event):
				continue
			return action
	return ""

func reset_keybind(action: String) -> void:
	InputMap.action_erase_events(action)
	
	#var default_event: InputEvent = get_default_keybind(action)
	#if default_event:
		#InputMap.action_add_event(action, default_event)
	
	var defaults: Dictionary = ProjectSettings.get_setting("input/" + action)
	if defaults and defaults.has("events"):
		for event in defaults["events"]:
			InputMap.action_add_event(action, event)
	
	keybind_changed.emit(action)
	get_tree().call_group("setting_hotkey", "_update_button_text")

func reset_all_keybinds() -> void:
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		reset_keybind(action)

func save_keybinds() -> void:
	var config = ConfigFile.new()
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		var events = InputMap.action_get_events(action)
		config.set_value("keybinds", action, events)
	config.save(FILE_PATH)

func load_keybinds() -> void:
	var config = ConfigFile.new()
	if config.load(FILE_PATH) != OK:
		return
	for action in config.get_section_keys("keybinds"):
		if !InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var events = config.get_value("keybinds", action)
		for event in events:
			InputMap.action_add_event(action, event)
