extends Control

@onready var player_1_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player1Menu
@onready var player_2_menu: VBoxContainer = $CenterContainer/HBoxContainer/Player2Menu

func _ready() -> void:
	NetworkManager.lobby_members_updated.connect(_update_members)

func _update_members(members: Array[NetworkManager.LobbyPlayer]) -> void:
	_update_names(members)

func _update_names(members: Array[NetworkManager.LobbyPlayer]) -> void:
	var menus: Array[PlayerSettings] = [player_1_menu, player_2_menu]
	for i in range(menus.size()):
		menus[i].set_enabled(false)
		if i >= members.size():
			menus[i].set_display_name("Waiting...")
			continue
		menus[i].set_display_name(members[i].persona_name)
		if members[i].steam_id == Steam.getSteamID():
			menus[i].set_enabled(true)
