extends Node2D

enum State { PAUSED, PLAYING, CHECKING, ATTACKED }
var state: State = State.PAUSED

@onready var layer_bg: TileMapLayer = $"../LayerBG"

const BOARD_SCENE: PackedScene = preload("res://scenes/board.tscn")
const TIMEOUT_TIME: float = 2.0

var generated_seed: int = 0
var slot_assignments: PackedInt32Array
var players: Array[Player] = []
var current_frame: int = 0
var frame_inputs: Dictionary = {}
var timeout_timer: float = 0.0

func _ready() -> void:
	NetworkManager.slot_assignments_received.connect(_on_slot_assignments_received)
	NetworkManager.input_received.connect(_on_network_input)
	NetworkManager.seed_received.connect(_on_seed_received)
	await _new_game(Global.selected_level)

func _new_game(level_id: String) -> void:
	_reset()
	await _set_lobby_seed()
	for i in range(Global.player_count):
		_create_board(level_id, i)
	_set_slot_assignments()
	if _is_singleplayer():
		_load_singleplayer_level()
		return
	players[0].board.opponent_board = players[1].board
	players[1].board.opponent_board = players[0].board
	await NetworkManager.match_begun

func _reset() -> void:
	if !is_inside_tree():
		queue_free()
		return
	for player in players:
		if player and is_instance_valid(player.board):
			player.board.queue_free()
	players.clear()
	frame_inputs.clear()
	slot_assignments.clear()
	generated_seed = 0
	current_frame = 0
	timeout_timer = 0.0

func _create_board(level_id: String, slot_number: int) -> void:
	var player: Player = Player.new(slot_number)
	var board: Board = BOARD_SCENE.instantiate()
	var board_width: int = 8 * 11
	board.set_player_id(slot_number + 1)
	add_child(board)
	player.board = board
	players.append(player)
	board.game_ended.connect(_on_game_ended)
	board.set_seed(generated_seed)
	board.set_speed(Global.player_speed[slot_number])
	board.set_difficulty(Global.player_difficulty[slot_number])
	board.load_level(level_id)
	board.set_character(Global.player_characters[slot_number])
	if _is_right_side_player(slot_number):
		board.character.flip_portrait()
	board.global_position.x += board_width * slot_number

func _physics_process(delta: float) -> void:
	#if state == State.PAUSED:
		#return
	timeout_timer += delta
	if !frame_inputs.has(current_frame):
		frame_inputs[current_frame] = {}
	for player in players:
		if !player.is_local():
			continue
		player.input.update_local(player.slot_number + 1)
		var packet: Dictionary = player.input.to_packet()
		frame_inputs[current_frame][player.slot_number] = packet
		NetworkManager.send_input(
			current_frame,
			packet
		)
	if _has_inputs_for_frame(current_frame):
		_simulate_frame(delta)
		timeout_timer = 0.0
		return
	if timeout_timer >= TIMEOUT_TIME:
		_timeout()

func _simulate_frame(delta: float) -> void:
	for player in players:
		if !player.is_local():
			player.input.update_network(
				frame_inputs[current_frame][player.slot_number]
			)
		player.board.input = player.input
		player.board.tick(delta)
	frame_inputs.erase(current_frame)
	current_frame += 1

func _has_inputs_for_frame(frame: int) -> bool:
	if !frame_inputs.has(frame):
		return false
	var inputs = frame_inputs[frame]
	for player in players:
		if !inputs.has(player.slot_number):
			return false
	return true

func _set_lobby_seed() -> void:
	var _generated_seed: int = int(Time.get_unix_time_from_system())
	if _is_local_game():
		generated_seed = _generated_seed
		return
	if !NetworkManager.is_host():
		await NetworkManager.seed_received
		return
	generated_seed = _generated_seed
	NetworkManager.send_seed(_generated_seed)

func _set_slot_assignments() -> void:
	slot_assignments.clear()
	if !NetworkManager.is_host():
		await NetworkManager.slot_assignments_received
		return
	slot_assignments.append(multiplayer.get_unique_id()) #Host
	if _is_local_multiplayer():
		slot_assignments.append(1)
	elif _is_online_multiplayer():
		for peer_id in multiplayer.get_peers():
			slot_assignments.append(peer_id)
		NetworkManager.send_slot_assignments(slot_assignments)
	_apply_slot_assignments()

func _load_singleplayer_level() -> void:
	var enemy_id: String = _get_floor_enemy(Global.current_floor)
	Global.current_floor += 1
	players[0].board.set_enemy(enemy_id)

func _get_floor_enemy(floor_number: int) -> String:
	var enemy_array: Array[String] = Global.story_mode_enemies
	var array_shifted_floor_number: int = floor_number - 1
	if array_shifted_floor_number < 0 or array_shifted_floor_number >= enemy_array.size():
		return "error"
	return enemy_array[array_shifted_floor_number]

func _on_game_ended() -> void:
	if layer_bg:
		layer_bg.queue_free()

func _on_network_input(sender_id: int, frame: int, packet: Dictionary) -> void:
	var slot_number: int = _get_peer_slot_number(sender_id)
	if slot_number == -1:
		return
	var player: Player = players[slot_number]
	if player.is_local():
		return
	if !frame_inputs.has(frame):
		frame_inputs[frame] = {}
	frame_inputs[frame][slot_number] = packet
	timeout_timer = 0.0

func _on_seed_received(_generated_seed: int) -> void:
	generated_seed = _generated_seed

func _get_peer_slot_number(peer_id: int) -> int:
	for i in range(players.size()):
		if players[i].peer_id != peer_id:
			continue
		return i
	return -1

func _on_slot_assignments_received(assignments: PackedInt32Array) -> void:
	slot_assignments = assignments
	_apply_slot_assignments()

func _apply_slot_assignments() -> void:
	if players.size() != slot_assignments.size():
		push_error("Invalid slot assignment count.")
		return
	for i in range(players.size()):
		players[i].peer_id = slot_assignments[i]

func _timeout() -> void:
	print("Connection timeout.")

func _is_local_game() -> bool:
	return NetworkManager.current_lobby_id == 0

func _is_singleplayer() -> bool:
	return Global.player_count == 1

func _is_local_multiplayer() -> bool:
	return Global.player_count > 1 and _is_local_game()

func _is_online_multiplayer() -> bool:
	return Global.player_count > 1 and !_is_local_game()

func _is_right_side_player(slot_number: int) -> bool:
	return slot_number == 1 and Global.player_count > 1

#func _is_host() -> bool:
	#if NetworkManager.current_lobby_id == 0:
		#return true
	#return Steam.getLobbyOwner(NetworkManager.current_lobby_id) == NetworkManager.local_peer_id
