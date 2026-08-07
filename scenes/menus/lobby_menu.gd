extends Control

@onready var lobby_v_box: VBoxContainer = $CenterContainer/Panel/MarginContainer/MenuVBox/ScrollContainer/LobbyVBox

const LOBBY_ENTRY_SCENE: PackedScene = preload("res://scenes/menus/lobby_entry.tscn")

func _ready() -> void:
	NetworkManager.lobby_created.connect(_on_lobby_created)
	NetworkManager.lobby_list_updated.connect(_populate_lobby_list)
	NetworkManager.refresh_lobby_list()
	#_populate_fake_lobby_list()

func _populate_lobby_list(lobbies: Array[NetworkManager.LobbyData]) -> void:
	for child in lobby_v_box.get_children():
		child.queue_free()
	#await get_tree().process_frame
	for lobby_data in lobbies:
		var entry: LobbyEntry = LOBBY_ENTRY_SCENE.instantiate() as LobbyEntry
		entry.lobby_data = lobby_data
		lobby_v_box.add_child(entry)

func _on_button_refresh_pressed() -> void:
	NetworkManager.refresh_lobby_list()

func _on_button_back_pressed() -> void:
	Transition.change_scene("res://scenes/menus/battle_menu.tscn", "", "slide_right")

func _populate_fake_lobby_list() -> void:
	#for child in lobby_v_box.get_children():
		#child.queue_free()
	#await get_tree().process_frame
	for i in range(10):
		var entry: LobbyEntry = LOBBY_ENTRY_SCENE.instantiate() as LobbyEntry
		entry.lobby_data = _create_fake_lobby_data()
		lobby_v_box.add_child(entry)

func _create_fake_lobby_data() -> NetworkManager.LobbyData:
	var lobby_data: NetworkManager.LobbyData = NetworkManager.LobbyData.new()
	lobby_data.name = "test"
	lobby_data.lobby_id = 0
	lobby_data.members = 0
	lobby_data.max_members = 2
	lobby_data.version = ProjectSettings.get_setting("application/config/version")
	return lobby_data

func _on_button_create_lobby_pressed() -> void:
	NetworkManager.host_lobby()

func _on_lobby_created() -> void:
	Transition.change_scene("res://scenes/menus/lobby_room.tscn")
