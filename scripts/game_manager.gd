extends Node2D

enum State { PAUSED, PLAYING, CHECKING, ATTACKED }
var state: State = State.PAUSED

@onready var layer_bg: TileMapLayer = $"../LayerBG"

const BOARD_SCENE: PackedScene = preload("res://scenes/board.tscn")
const TIMEOUT_TIME: float = 3.0
const INPUT_DELAY_FRAMES: int = 10
const LOCKSTEP_DELTA: float = 1.0 / 60.0

var generated_seed: int = 0
var slot_assignments: PackedInt64Array
var players: Array[Player] = []
var _boards_ready: int = 0
var _local_ready: bool = false
var _opponent_ready: bool = false
var current_frame: int = 0
var frame_inputs: Dictionary = {}
var timeout_timer: float = 0.0
var match_in_progress: bool = false

func _ready() -> void:
	NetworkManager.slot_assignments_received.connect(_on_slot_assignments_received)
	NetworkManager.input_received.connect(_on_network_input)
	NetworkManager.seed_received.connect(_on_seed_received)
	NetworkManager.opponent_ready.connect(_on_opponent_ready)
	NetworkManager.start_match.connect(_start_match)
	await _new_game(Global.selected_level)

func _new_game(level_id: String) -> void:
	_reset()
	await _set_lobby_seed()
	#if NetworkManager.is_host():
		#NetworkManager.send_seed(generated_seed) #reinforce seed if missed
	for i in range(Global.player_count):
		_create_board(level_id, i)
	await _set_slot_assignments()
	if _is_singleplayer():
		_load_singleplayer_level()
		match_in_progress = true
		return
	players[0].board.opponent_board = players[1].board
	players[1].board.opponent_board = players[0].board

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
	_boards_ready = 0
	generated_seed = 0
	current_frame = 0
	timeout_timer = 0.0
	match_in_progress = false

func _create_board(level_id: String, slot_number: int) -> void:
	var player: Player = Player.new(slot_number)
	if slot_number < slot_assignments.size():
		player.peer_id = slot_assignments[slot_number]
	else:
		player.peer_id = multiplayer.get_unique_id() if slot_number == 0 else 1
	var board: Board = BOARD_SCENE.instantiate()
	var board_width: int = 8 * 11
	board.board_ready.connect(_board_is_ready)
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

func _board_is_ready() -> void:
	_boards_ready += 1
	if _boards_ready < Global.player_count:
		return
	_local_ready = true
	if _is_online_multiplayer():
		await NetworkManager.wait_for_server_connection()
		NetworkManager.send_opponent_ready()
	else:
		_opponent_ready = true

func _physics_process(delta: float) -> void:
	if !match_in_progress:
		_try_match_begin()
		return
	#if state == State.PAUSED:
		#return
	
	#_send_local_input()
	#if !_has_inputs_for_frame(current_frame):
		#if _is_online_multiplayer():
			#timeout_timer += delta
			#if timeout_timer >= TIMEOUT_TIME:
				#_timeout()
	#else:
		#_simulate_frame()
		#timeout_timer = 0.0
	
	_send_local_input()
	var simulated_frames: int = 0
	var max_catchup_frames: int = 4
	while simulated_frames < max_catchup_frames:
		if !_has_inputs_for_frame(current_frame):
			print("WAITING | peer=", multiplayer.get_unique_id(), " frame=", current_frame, " inputs=", frame_inputs.get(current_frame, {}))
			break
		_simulate_frame()
		simulated_frames += 1
	if simulated_frames == 0 and _is_online_multiplayer():
		timeout_timer += delta
		if timeout_timer >= TIMEOUT_TIME:
			_timeout()
	else:
		timeout_timer = 0.0

func _send_local_input() -> void:
	var target_frame: int = current_frame + INPUT_DELAY_FRAMES
	var local_packets: Dictionary = {}
	for player in players:
		if !player.is_local():
			continue
		player.input.update_local(player.slot_number + 1)
		local_packets[player.slot_number] = player.input.to_packet()
	for frame in range(current_frame, target_frame + 1):
		if !frame_inputs.has(frame):
			frame_inputs[frame] = {}
		for player in players:
			if !player.is_local():
				continue
			if frame_inputs[frame].has(player.slot_number):
				continue
			var packet: Dictionary = local_packets[player.slot_number]
			frame_inputs[frame][player.slot_number] = packet
			if _is_online_multiplayer():
				for opponent in players:
					if opponent.is_local():
						continue
					NetworkManager.send_input(opponent.peer_id, frame, packet)
	for player in players:
		if player.is_local():
			continue
		player.input.clear_one_shot_inputs()
	#var target_frame: int = current_frame + INPUT_DELAY_FRAMES
	#for player in players:
		#if !player.is_local():
			#continue
		#player.input.update_local(player.slot_number + 1)
		#var packet: Dictionary = player.input.to_packet()
		#if !frame_inputs.has(target_frame):
			#frame_inputs[target_frame] = {}
		#frame_inputs[target_frame][player.slot_number] = packet
		#if _is_online_multiplayer():
			#for opponent in players:
				#if opponent.is_local():
					#continue
				#NetworkManager.send_input(opponent.peer_id, target_frame, packet)

func _simulate_frame() -> void:
	if _is_singleplayer():
		var player = players[0]
		player.board.input = player.input
		player.board.tick(LOCKSTEP_DELTA)
	else:
		for player in players:
			if !player.is_local() and frame_inputs.has(current_frame) and frame_inputs[current_frame].has(player.slot_number):
				player.input.update_network(frame_inputs[current_frame][player.slot_number])
			player.board.input = player.input
			player.board.tick(LOCKSTEP_DELTA)
	frame_inputs.erase(current_frame)
	current_frame += 1

func _has_inputs_for_frame(frame: int) -> bool:
	if _is_singleplayer():
		return frame_inputs.has(frame)
	if !frame_inputs.has(frame):
		return false
	var inputs = frame_inputs[frame]
	for player in players:
		if !inputs.has(player.slot_number):
			return false
	return true

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

func _set_lobby_seed() -> void:
	var _time_seed: int = int(Time.get_unix_time_from_system())
	if _is_local_game():
		generated_seed = _time_seed
		return
	if NetworkManager.is_host():
		generated_seed = _time_seed
		NetworkManager.send_seed(generated_seed)
		return
	if NetworkManager.lobby_seed != 0:
		generated_seed = NetworkManager.lobby_seed
		return
	await NetworkManager.seed_received
	generated_seed = NetworkManager.lobby_seed

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

func _prep_input_buffer() -> void:
	for frame in range(INPUT_DELAY_FRAMES):
		frame_inputs[frame] = {}
		for player in players:
			frame_inputs[frame][player.slot_number] = player.input.get_neutral_input()

func _on_game_ended() -> void:
	if layer_bg:
		layer_bg.queue_free()

func _on_seed_received(_generated_seed: int) -> void:
	generated_seed = _generated_seed

func _get_peer_slot_number(peer_id: int) -> int:
	for i in range(players.size()):
		if players[i].peer_id != peer_id:
			continue
		return i
	return -1

func _on_slot_assignments_received(assignments: PackedInt64Array) -> void:
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
	Transition.change_scene("res://scenes/menus/battle_menu.tscn")
	NetworkManager.leave_lobby()

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

func _on_opponent_ready() -> void:
	_opponent_ready = true

func _start_match() -> void:
	if match_in_progress:
		return
	_prep_input_buffer()
	match_in_progress = true

func _try_match_begin() -> void:
	if !_local_ready or !_opponent_ready:
		return
	if NetworkManager.is_host():
		_start_match()
		NetworkManager.send_start_match()
