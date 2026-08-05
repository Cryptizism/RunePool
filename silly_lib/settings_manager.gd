extends Node

signal setting_changed(setting_name: String, value: Variant)
signal settings_loaded
signal settings_saved

enum Language { ENGLISH, JAPANESE, CHINESE_SIMPLIFIED, KOREAN, SPANISH }

const FILE_PATH: String = "user://settings.cfg"
const DEFAULT: Dictionary = {
	"music_volume": 1.0,
	"mute_music": false,
	"sound_volume": 1.0,
	"mute_sound": false,
	"fullscreen": false,
	"vsync": false,
	"resolution": Vector2i(1920, 1080),
	"mouse_sensitivity": 3.0,
	"invert_mouse_y": false,
	"controller_vibrate": true,
	"camera_shake": true,
	"language": Language.ENGLISH,
	"autosave": false,
}

var _data: Dictionary = {}
var _signals_enabled: bool = true

func _ready() -> void:
	reset_defaults(false)
	load_data()

func _update_setting(key: String, value: Variant) -> void:
	_data[key] = value
	if !_signals_enabled:
		return
	setting_changed.emit(key, value)

### AUDIO ###

func get_music_volume() -> float:
	return AudioManager.get_bus_volume("MSC")

func set_music_volume(value: float) -> void:
	value = clamp(value, 0.0, 1.0)
	AudioManager.set_bus_volume("MSC", value)
	_update_setting("music_volume", value)

func set_music_muted(value: bool) -> void:
	AudioManager.mute_bus("MSC", value)
	_update_setting("mute_music", value)

func get_sound_volume() -> float:
	return AudioManager.get_bus_volume("SFX")

func set_sound_volume(value: float) -> void:
	value = clamp(value, 0.0, 1.0)
	AudioManager.set_bus_volume("SFX", value)
	_update_setting("sound_volume", value)

func set_sound_muted(value: bool) -> void:
	AudioManager.mute_bus("SFX", value)
	_update_setting("mute_sound", value)

### VIDEO ###

func set_fullscreen(value: bool) -> void:
	var mode: DisplayServer.WindowMode = \
			DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	_update_setting("fullscreen", value)

func is_fullscreen_enabled() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func set_vsync(value: bool) -> void:
	var mode: DisplayServer.VSyncMode = \
			DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)
	_update_setting("vsync", value)

func is_vsync_enabled() -> bool:
	return DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED

func get_resolution() -> Vector2i:
	return DisplayServer.window_get_size()

func set_resolution(size: Vector2i = Vector2i(1920, 1080)) -> void:
	DisplayServer.window_set_size(size)
	_update_setting("resolution", size)

### INPUT ###

func get_mouse_sensitivity() -> float:
	return _data["mouse_sensitivity"]

func set_mouse_sensitivity(value: float) -> void:
	value = clamp(value, 0.1, 10.0)
	_update_setting("mouse_sensitivity", value)

func set_invert_mouse_y(value: bool) -> void:
	_update_setting("invert_mouse_y", value)

func is_invert_mouse_y_enabled() -> bool:
	return _data["invert_mouse_y"]

### ACCESSIBILITY ###

func set_controller_vibration_enabled(value: bool) -> void:
	_update_setting("controller_vibrate", value)

func is_controller_vibration_enabled() -> bool:
	return _data["controller_vibrate"]

func set_camera_shake(value: bool) -> void:
	_update_setting("camera_shake", value)

func is_camera_shake_enabled() -> bool:
	return _data["camera_shake"]

### SYSTEM ###

func get_language() -> Language:
	return _data["language"]

func set_language(language: Language) -> void:
	
	_update_setting("language", language)

func set_autosave_enabled(value: bool) -> void:
	SaveManager.set_autosave_enabled(value)
	_update_setting("autosave", value)

func is_autosave_enabled() -> bool:
	return SaveManager.get_autosave_enabled()

### API ###

func load_data() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(FILE_PATH) != OK:
		push_warning("Error loading settings.")
		return
	for entry in _data:
		_data[entry] = config.get_value("_data", entry, _data[entry])
	_apply_settings_data()
	settings_loaded.emit()

func save_data() -> void:
	var config: ConfigFile = ConfigFile.new()
	for entry in _data:
		config.set_value("_data", entry, _data[entry])
	if config.save(FILE_PATH) != OK:
		push_warning("Failed to save settings.")
		return
	settings_saved.emit()

func reset_defaults(save: bool = true) -> void:
	_data = DEFAULT.duplicate(true)
	_apply_settings_data()
	if !save:
		return
	save_data()

func _apply_settings_data() -> void:
	_signals_enabled = false
	set_music_volume(_data.get("music_volume", DEFAULT["music_volume"]))
	set_music_muted(_data.get("mute_music", DEFAULT["mute_music"]))
	set_sound_volume(_data.get("sound_volume", DEFAULT["sound_volume"]))
	set_sound_muted(_data.get("mute_sound", DEFAULT["mute_sound"]))
	set_fullscreen(_data.get("fullscreen", DEFAULT["fullscreen"]))
	set_vsync(_data.get("vsync", DEFAULT["vsync"]))
	set_resolution(_data.get("resolution", DEFAULT["resolution"]))
	set_mouse_sensitivity(_data.get("mouse_sensitivity", DEFAULT["mouse_sensitivity"]))
	set_invert_mouse_y(_data.get("invert_mouse_y", DEFAULT["invert_mouse_y"]))
	set_controller_vibration_enabled(_data.get("controller_vibrate", DEFAULT["controller_vibrate"]))
	set_camera_shake(_data.get("camera_shake", DEFAULT["camera_shake"]))
	set_language(_data.get("language", DEFAULT["language"]))
	set_autosave_enabled(_data.get("autosave", DEFAULT["autosave"]))
	_signals_enabled = true
