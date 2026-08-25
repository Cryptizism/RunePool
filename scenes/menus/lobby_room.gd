extends Control

@onready var player_1_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player1Menu
@onready var player_2_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player2Menu
@onready var button_level_left: UIButton = $CenterContainer/HBoxContainer/LevelMenu/HBoxContainer2/ButtonLevelLeft
@onready var button_level_right: UIButton = $CenterContainer/HBoxContainer/LevelMenu/HBoxContainer2/ButtonLevelRight

func _ready() -> void:
	NetworkManager.lobby_members_updated.connect(_update_members)
	NetworkManager.player_settings_updated.connect(_player_settings_updated)

func _update_members(members: Array[NetworkManager.LobbyPlayer]) -> void:
	_update_names(members)
	_update_ui_access(members)
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
	button_level_left.disabled = !NetworkManager.is_host()
	button_level_right.disabled = !NetworkManager.is_host()

func _player_settings_updated(peer_id: int, player_settings: NetworkManager.PlayerSettings) -> void:
	var steam_id: int = NetworkManager.get_steam_id_from_peer_id(peer_id)
	if steam_id == -1:
		return
	var members := NetworkManager.get_lobby_members()
	var menus := _get_menus()
	for i in range(min(members.size(), menus.size())):
		if members[i].steam_id == steam_id:
			menus[i].set_speed(player_settings.speed)
			menus[i].set_difficulty(player_settings.difficulty)
			menus[i].set_character(player_settings.character_id)
			return
