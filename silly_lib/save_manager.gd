extends Node

signal save_begun(slot_number: int)
signal save_complete(slot_number: int)
signal save_loaded(slot_number: int)
signal save_deleted(slot_number: int)
signal save_slot_changed(slot_number: int)

const FILE_PATH: String = "user://save_%d.cfg"
const SAVE_SLOT_COUNT: int = 10
const SAVE_VERSION: float = 1.0

var _data: Dictionary = {}
var _active_save_slot: int = 1
var _autosave_enabled: bool = false
var _autosave_interval: float = 30.0
var _autosave_timer: float = _autosave_interval

func _ready() -> void:
	_data["playtime"] = 0.0

func _process(delta: float) -> void:
	_data["playtime"] += delta
	if !_autosave_enabled:
		return
	_autosave_timer -= delta
	if _autosave_timer <= 0.0:
		save_data()
		_autosave_timer = _autosave_interval

func _get_save_path(slot_number: int) -> String:
	return FILE_PATH % slot_number

func _is_valid_save_slot(slot_number: int) -> bool:
	if slot_number < -1 or slot_number > SAVE_SLOT_COUNT:
		push_warning("Attempted to swap to invalid save slot.")
		return false
	return true

func _validate_slot_number(slot_number: int) -> int:
	if !_is_valid_save_slot(slot_number):
		return -2
	if slot_number == -1:
		slot_number = _active_save_slot
	return slot_number

func get_autosave_enabled() -> bool:
	return _autosave_enabled

func set_autosave_enabled(value: bool) -> void:
	_autosave_enabled = value
	_autosave_timer = _autosave_interval

func set_autosave_interval(interval: float = 30.0) -> void:
	_autosave_interval = interval
	_autosave_timer = _autosave_interval

func get_current_save_slot() -> int:
	return _active_save_slot

func set_active_save_slot(slot_number: int) -> void:
	slot_number = _validate_slot_number(slot_number)
	if slot_number == -2:
		return
	_active_save_slot = slot_number
	save_slot_changed.emit(slot_number)

func get_data(key: String, default: Variant = null) -> Variant:
	return _data.get(key, default)

func set_data(key: String, value: Variant) -> void:
	_data[key] = value

func has_data(key: String) -> bool:
	return _data.has(key)

func load_data(slot_number: int = -1) -> void:
	slot_number = _validate_slot_number(slot_number)
	if slot_number == -2:
		return
	var config: ConfigFile = ConfigFile.new()
	if config.load(_get_save_path(slot_number)) != OK:
		push_warning("Error loading save data.")
		return
	for entry in _data:
		_data[entry] = config.get_value("_data", entry, _data[entry])
	save_loaded.emit(slot_number)

func save_data(slot_number: int = -1) -> void:
	slot_number = _validate_slot_number(slot_number)
	if slot_number == -2:
		return
	save_begun.emit(slot_number)
	_autosave_timer = _autosave_interval
	_data["save_version"] = SAVE_VERSION
	_data["time_last_played"] = Time.get_datetime_string_from_system()
	var config: ConfigFile = ConfigFile.new()
	for entry in _data:
		config.set_value("_data", entry, _data[entry])
	if config.save(_get_save_path(slot_number)) != OK:
		push_warning("Failed to save data.")
		return
	save_complete.emit(slot_number)

func delete_save(slot_number: int = -1) -> void:
	slot_number = _validate_slot_number(slot_number)
	if slot_number == -2:
		return
	save_deleted.emit(slot_number)
	DirAccess.remove_absolute(_get_save_path(slot_number))

func save_exists(slot_number: int = -1) -> bool:
	slot_number = _validate_slot_number(slot_number)
	if slot_number == -2:
		return false
	return FileAccess.file_exists(_get_save_path(slot_number))

func delete_all_saves() -> void:
	for i in range(1, SAVE_SLOT_COUNT + 1):
		delete_save(i)
