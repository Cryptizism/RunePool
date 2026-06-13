extends Node2D

enum State { PAUSED, PLAYING, CHECKING, ATTACKED }
var state: State = State.PAUSED

const BOARD_SCENE: PackedScene = preload("res://scenes/board.tscn")

var boards: Array[Board] = []

#TODO: Rotation Kick
#TODO: Drop Ghost Preview
#TODO: Juice

func _ready() -> void:
	_new_game(Global.selected_level)

func _new_game(level_id: String, player_count: int = 1) -> void:
	randomize()
	for board in boards:
		board.reset_board()
		board.queue_free()
	for i in range(player_count):
		var board: Board = BOARD_SCENE.instantiate()
		add_child(board)
		boards.append(board)
		board.load_level(level_id)
		board.set_character("tippi")
		board.set_enemy("tippi")
