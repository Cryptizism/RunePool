extends Node

class LobbyData:
	var lobby_id: int
	var version: String
	var name: String = ""
	var members: int
	var max_members: int

class LobbyPlayer:
	var steam_id: int
	var persona_name: String

signal lobby_created()
signal lobby_list_updated(lobbies: Array[LobbyData])
signal lobby_members_updated(members: Array)
signal lobby_left()
signal server_peer_connected()
signal server_peer_disconnected()
signal server_connection_successful
signal server_connection_failed()
signal server_disconnected()
signal slot_assignments_received(assignments: PackedInt32Array)
signal input_received(sender_id: int, frame: int, packet: Dictionary)
signal seed_received(board_seed: int)
signal match_begun()

const LOBBY_TYPE: Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_PUBLIC
const MAX_MEMBERS: int = 4
const GAME_CODE: String = "sk_runepool"

var local_peer_id: int = 1
var peer: SteamMultiplayerPeer
var current_lobby_id: int = 0

func _ready() -> void:
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.join_requested.connect(_on_join_requested)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.connection_failed.connect(_on_server_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		leave_lobby()

func is_host() -> bool:
	return multiplayer.is_server()

func host_lobby() -> void:
	leave_lobby()
	Steam.createLobby(LOBBY_TYPE, MAX_MEMBERS)

func refresh_lobby_list() -> void:
	Steam.addRequestLobbyListStringFilter(
		"version",
		ProjectSettings.get_setting("application/config/version"),
		Steam.LOBBY_COMPARISON_EQUAL
	)
	Steam.addRequestLobbyListStringFilter(
		"game",
		GAME_CODE,
		Steam.LOBBY_COMPARISON_EQUAL
	)
	Steam.requestLobbyList()

func join_lobby(_lobby_id: int) -> void:
	leave_lobby()
	Steam.joinLobby(_lobby_id)

func leave_lobby() -> void:
	if current_lobby_id != 0:
		Steam.leaveLobby(current_lobby_id)
		current_lobby_id = 0
	multiplayer.multiplayer_peer = null
	if peer:
		peer.close()
	peer = null
	lobby_left.emit()

func _on_lobby_created(_result: int, _lobby_id: int) -> void:
	if _result != Steam.RESULT_OK:
		push_warning("Failed to create Steam lobby.")
		return
	current_lobby_id = _lobby_id
	_set_lobby_data(_lobby_id)
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	if peer.create_host() != OK:
		leave_lobby()
		push_warning("Failed to create Steam host.")
		return
	Steam.setLobbyJoinable(_lobby_id, true)
	multiplayer.multiplayer_peer = peer
	update_peer_id()
	lobby_created.emit()
	_update_lobby_members()

func _on_lobby_match_list(_lobbies: Array) -> void:
	var results: Array[LobbyData] = []
	for lobby_id in _lobbies:
		var version: String = Steam.getLobbyData(lobby_id, "version")
		if version != ProjectSettings.get_setting("application/config/version"):
			continue
		var lobby: LobbyData = LobbyData.new()
		lobby.lobby_id = lobby_id
		lobby.name = Steam.getLobbyData(lobby_id, "name")
		lobby.version = Steam.getLobbyData(lobby_id, "version")
		lobby.members = Steam.getNumLobbyMembers(lobby_id)
		lobby.max_members = Steam.getLobbyMemberLimit(lobby_id)
		results.append(lobby)
	lobby_list_updated.emit(results)

func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	if _response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		push_warning("Failed to join lobby %d" % _response)
		server_connection_failed.emit()
		return
	var lobby_owner_id: int = Steam.getLobbyOwner(_lobby_id)
	if lobby_owner_id == Steam.getSteamID():
		return
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	if peer.create_client(lobby_owner_id) != OK:
		push_warning("Failed to create Steam client.")
		return
	current_lobby_id = _lobby_id
	multiplayer.multiplayer_peer = peer
	update_peer_id()
	_update_lobby_members()

func _on_join_requested(_lobby_id: int, _steam_id: int) -> void:
	Steam.joinLobby(_lobby_id)

func _update_lobby_members() -> void:
	var members: Array[LobbyPlayer] = []
	var amount: int = Steam.getNumLobbyMembers(current_lobby_id)
	if amount <= 0:
		return
	for i in range(amount):
		var steam_id: int = Steam.getLobbyMemberByIndex(current_lobby_id, i)
		var lobby_player: LobbyPlayer = LobbyPlayer.new()
		lobby_player.steam_id = steam_id
		lobby_player.persona_name = Steam.getFriendPersonaName(steam_id)
		members.append(lobby_player)
	lobby_members_updated.emit(members)

func update_peer_id() -> void:
	if multiplayer and multiplayer.has_multiplayer_peer():
		local_peer_id = multiplayer.get_unique_id()

func _on_peer_connected(id: int) -> void:
	print("Peer %d connected." % id)
	server_peer_connected.emit()
	_update_lobby_members()

func _on_peer_disconnected(id: int) -> void:
	print("Peer %d disconnected." % id)
	server_peer_disconnected.emit()
	_update_lobby_members()

func _on_server_connected() -> void:
	print("Connection successful.")
	server_connection_successful.emit()

func _on_server_connection_failed() -> void:
	print("Connection failed.")
	server_connection_failed.emit()

func _on_server_disconnected() -> void:
	print("Server disconnected.")
	server_disconnected.emit()

func _set_lobby_data(_lobby_id: int) -> void:
	Steam.setLobbyData(_lobby_id, "name", "%s" % Steam.getPersonaName())
	Steam.setLobbyData(_lobby_id, "game", GAME_CODE)
	Steam.setLobbyData(_lobby_id, "version", ProjectSettings.get_setting("application/config/version"))
	Steam.setLobbyData(_lobby_id, "has_password", "0")

func send_slot_assignments(assignments: PackedInt32Array) -> void:
	receive_slot_assignments.rpc(assignments)

@rpc("any_peer", "unreliable")
func receive_slot_assignments(assignments: PackedInt32Array) -> void:
	slot_assignments_received.emit(assignments)

func send_input(frame: int, packet: Dictionary) -> void:
	receive_input.rpc(frame, packet)

@rpc("any_peer", "unreliable")
func receive_input(frame: int, packet: Dictionary) -> void:
	input_received.emit(multiplayer.get_remote_sender_id(), frame, packet)

func send_seed(generated_seed: int) -> void:
	receive_seed.rpc(generated_seed)

@rpc("any_peer", "unreliable")
func receive_seed(generated_seed: int) -> void:
	seed_received.emit(generated_seed)

func send_match_ready() -> void:
	receive_match_ready.rpc()

@rpc("any_peer", "unreliable")
func receive_match_ready() -> void:
	match_begun.emit()
