extends Node

const FILE_PATH: String = "user://settings.cfg"

var music_volume: float = 80.0:
	set(value):
		music_volume = clamp(value, 0.0, 100.0)
		save_settings()
	get:
		return music_volume
var sound_volume: float = 80.0:
	set(value):
		sound_volume = clamp(value, 0.0, 100.0)
		save_settings()
	get:
		return sound_volume
var ghost_gems_enabled: bool = true:
	set(value):
		ghost_gems_enabled = value
		save_settings()
	get:
		return ghost_gems_enabled
var character_shake: bool = true:
	set(value):
		character_shake = value
		save_settings()
	get:
		return character_shake
var combo_text: bool = true:
	set(value):
		combo_text = value
		save_settings()
	get:
		return combo_text
var fullscreen: bool = false:
	set(value):
		fullscreen = value
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		save_settings()
	get:
		return fullscreen

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sound_volume", sound_volume)
	config.set_value("settings", "ghost_gems_enabled", ghost_gems_enabled)
	config.set_value("settings", "character_shake", character_shake)
	config.set_value("settings", "combo_text", combo_text)
	config.set_value("settings", "fullscreen", fullscreen)
	config.save(FILE_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(FILE_PATH) != OK:
		return
	music_volume = config.get_value("settings", "music_volume", 80.0)
	sound_volume = config.get_value("settings", "sound_volume", 80.0)
	ghost_gems_enabled = config.get_value("settings", "ghost_gems_enabled", true)
	character_shake = config.get_value("settings", "character_shake", true)
	combo_text = config.get_value("settings", "combo_text", true)
	fullscreen = config.get_value("settings", "fullscreen", false)
