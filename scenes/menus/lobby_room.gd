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

func _player_settings_updated(steam_id: int, player_settings: NetworkManager.PlayerSettings) -> void:
	var menus: Array[PlayerSettingsMenu] = _get_menus()
	var members: Array[NetworkManager.LobbyPlayer] = NetworkManager.get_lobby_members()
	for i in range(min(members.size(), menus.size())):
		if !members[i]:
			continue
		if members[i].steam_id != steam_id:
			continue
		menus[i].set_speed(player_settings.speed)
		menus[i].set_difficulty(player_settings.difficulty)
		menus[i].set_character(player_settings.character_id)
		return

#func _player_settings_updated(peer_id: int, player_settings: NetworkManager.PlayerSettings) -> void:
	##var slot: int = NetworkManager.get_slot_from_peer(peer_id) #function doesnt exist
	##if slot == -1:
		##return
	##var menus: Array[PlayerSettingsMenu] = _get_menus()
	##if slot >= menus.size():
		##return
	##menus[slot].set_speed(player_settings.speed)
	##menus[slot].set_difficulty(player_settings.difficulty)
	##menus[slot].set_character_id(player_settings.character_id)
	#var menus: Array[PlayerSettingsMenu] = _get_menus()
	#var members: Array[NetworkManager.LobbyPlayer] = NetworkManager.get_lobby_members()
	#for i in range(NetworkManager.get_lobby_size()):
		#if i < 0 or i >= members.size():
			#continue
		#if i < 0 or i >= menus.size():
			#continue
		#var member = members[i]
		#if member.peer_id != peer_id:
			#continue #failing here
		#menus[i].set_speed(player_settings.speed)
		#menus[i].set_difficulty(player_settings.difficulty)
		#menus[i].set_character_id(player_settings.character_id)
		#return
