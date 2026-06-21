extends Node2D

enum State { PAUSED, PLAYING, CHECKING, ATTACKED }
var state: State = State.PAUSED

const BOARD_SCENE: PackedScene = preload("res://scenes/board.tscn")

var boards: Array[Board] = []

func _ready() -> void:
	_new_game(Global.selected_level)

func _new_game(level_id: String) -> void:
	randomize()
	for board in boards:
		board.reset_board()
		board.queue_free()
	boards.clear()
	var seed: int = Time.get_unix_time_from_system()
	var board_width: int = 8 * 11
	for i in range(Global.player_count):
		var board: Board = BOARD_SCENE.instantiate()
		board.set_player_id(i + 1)
		add_child(board)
		boards.append(board)
		board.set_seed(seed)
		board.load_level(level_id)
		board.set_character(Global.player_characters[i])
		if i == 0 and Global.player_count > 1:
			board.character.flip_portrait()
		board.set_speed(Global.player_speed[i])
		board.set_difficulty(Global.player_difficulty[i])
		board.is_local_player = true
		board.global_position.x += board_width * i
	if Global.player_count == 1 and boards.size() > 0:
		boards[0].set_enemy("tippi")
		return
	for i in range(boards.size()):
		var next = (i + 1) % boards.size()
		boards[i].opponent_board = boards[next]
