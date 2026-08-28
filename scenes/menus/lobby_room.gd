extends Control

@onready var player_1_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player1Menu
@onready var player_2_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player2Menu
@onready var button_level_left: UIButton = $CenterContainer/HBoxContainer/LevelMenu/HBoxContainer2/ButtonLevelLeft
@onready var button_level_right: UIButton = $CenterContainer/HBoxContainer/LevelMenu/HBoxContainer2/ButtonLevelRight
@onready var level_display: Control = $CenterContainer/HBoxContainer/LevelMenu/LevelDisplay
@onready var button_ready_1: UIButton = $CenterContainer/HBoxContainer/LevelMenu/HBoxContainer/ButtonReady1
@onready var button_ready_2: UIButton = $CenterContainer/HBoxContainer/LevelMenu/HBoxContainer/ButtonReady2

func _ready() -> void:
	NetworkManager.lobby_members_updated.connect(_update_members)
	NetworkManager.player_settings_updated.connect(_player_settings_updated)
	NetworkManager.is_opponent_ready.connect(_opponent_ready_pressed)
	NetworkManager.level_updated.connect(_level_updated)
	level_display.level_changed.connect(_level_changed)
	button_ready_1.pressed.connect(_on_ready_button_pressed)
	button_ready_2.pressed.connect(_on_ready_button_pressed)

func _update_members(members: Array[NetworkManager.LobbyPlayer]) -> void:
	_update_names(members)
	_update_ui_access(members)
	_reset_ready_buttons()
	#TODO: members/menus array not clearing lost players

func _get_menus() -> Array[PlayerSettingsMenu]:
	return [player_1_menu, player_2_menu]

func _update_names(members: Array[NetworkManager.LobbyPlayer]) -> void:
	var menus: Array[PlayerSettingsMenu] = _get_menus()
	for i in range(menus.size()):
		if i >= members.size():
			menus[i].set_display_name("Waiting...")
			continue
		menus[i].set_display_name(members[i].persona_name)

func _update_ui_access(members: Array[NetworkManager.LobbyPlayer]) -> void:
	var menus: Array[PlayerSettingsMenu] = _get_menus()
	for i in range(menus.size()):
		if i >= members.size():
			menus[i].set_enabled(false)
			continue
		menus[i].set_enabled(members[i].steam_id == Steam.getSteamID())
	var is_host: bool = NetworkManager.is_host()
	button_level_left.disabled = !is_host
	button_level_right.disabled = !is_host
	if is_host:
		button_ready_2.set_other_player_mode(true)
	else:
		button_ready_1.set_other_player_mode(true)

func _player_settings_updated(peer_id: int, player_settings: NetworkManager.PlayerSettings) -> void:
	var steam_id: int = NetworkManager.get_steam_id_from_peer_id(peer_id)
	if steam_id == -1:
		return
	_reset_ready_buttons()
	var members: Array[NetworkManager.LobbyPlayer] = NetworkManager.get_lobby_members()
	var menus: Array[PlayerSettingsMenu] = _get_menus()
	for i in range(min(members.size(), menus.size())):
		if members[i].steam_id == steam_id:
			menus[i].set_speed(player_settings.speed)
			menus[i].set_difficulty(player_settings.difficulty)
			menus[i].set_character(player_settings.character_id)
			return

func _level_updated(level_id: String) -> void:
	level_display.set_level_id(level_id)
	_reset_ready_buttons()

func _level_changed(level_id: String) -> void:
	_reset_ready_buttons()

func _on_ready_button_pressed() -> void:
	if !button_ready_1.is_ready:
		return
	if !button_ready_2.is_ready:
		return
	Transition.change_scene("res://scenes/game_room.tscn")

func _opponent_ready_pressed(is_ready: bool) -> void:
	var opponent_button: UIButton = button_ready_2 if NetworkManager.is_host() else button_ready_1
	opponent_button.set_ready(is_ready)
	_on_ready_button_pressed()

func _reset_ready_buttons() -> void:
	button_ready_1.set_ready(false)
	button_ready_2.set_ready(false)
	NetworkManager.send_opponent_ready_button(false)
