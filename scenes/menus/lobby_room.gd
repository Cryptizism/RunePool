extends Control

@onready var player_1_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player1Menu
@onready var player_2_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player2Menu

func _ready() -> void:
	NetworkManager.lobby_members_updated.connect(_update_members)
	NetworkManager.player_settings_updated.connect(_player_settings_updated)

func _update_members(members: Array[NetworkManager.LobbyPlayer]) -> void:
	_update_names(members)

func _get_menus() -> Array[PlayerSettingsMenu]:
	return [player_1_menu, player_2_menu]

func _update_names(members: Array[NetworkManager.LobbyPlayer]) -> void:
	var menus: Array[PlayerSettingsMenu] = _get_menus()
	for i in range(menus.size()):
		menus[i].set_enabled(false)
		if i >= members.size():
			menus[i].set_display_name("Waiting...")
			continue
		menus[i].set_display_name(members[i].persona_name)
		if members[i].steam_id == Steam.getSteamID():
			menus[i].set_enabled(true)

func _player_settings_updated(peer_id: int, player_settings: NetworkManager.PlayerSettings) -> void:
	var menus: Array[PlayerSettingsMenu] = _get_menus()
	var members: Array[NetworkManager.LobbyPlayer] = NetworkManager.get_lobby_members()
	for i in range(NetworkManager.get_lobby_size()):
		var member = members[i]
		if member.peer_id != peer_id:
			continue
		menus[i].set_speed(player_settings.speed)
		menus[i].set_difficulty(player_settings.difficulty)
		menus[i].set_character_id(player_settings.character_id)
		return
