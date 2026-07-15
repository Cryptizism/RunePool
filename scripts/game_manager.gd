extends Node2D

enum State { PAUSED, PLAYING, CHECKING, ATTACKED }
var state: State = State.PAUSED

@onready var layer_bg: TileMapLayer = $"../LayerBG"

const BOARD_SCENE: PackedScene = preload("res://scenes/board.tscn")

var boards: Array[Board] = []

func _ready() -> void:
	_new_game(Global.selected_level)

func _new_game(level_id: String) -> void:
	if !is_inside_tree():
		queue_free()
		return
	randomize()
	for board in boards:
		board.reset_board()
		board.queue_free()
	boards.clear()
	var board_seed: int = Time.get_unix_time_from_system()
	var board_width: int = 8 * 11
	for i in range(Global.player_count):
		var board: Board = BOARD_SCENE.instantiate()
		board.set_player_id(i + 1)
		add_child(board)
		boards.append(board)
		board.game_ended.connect(_on_game_ended)
		board.set_seed(board_seed)
		board.load_level(level_id)
		board.set_character(Global.player_characters[i])
		if i == 1 and Global.player_count > 1:
			board.character.flip_portrait()
		board.set_speed(Global.player_speed[i])
		board.set_difficulty(Global.player_difficulty[i])
		board.global_position.x += board_width * i
	if Global.player_count == 1 and boards.size() > 0:
		var enemy_id: String = _get_floor_enemy(Global.current_floor)
		Global.current_floor += 1
		boards[0].set_enemy(enemy_id)
		return
	for i in range(boards.size()):
		var next = (i + 1) % boards.size()
		boards[i].opponent_board = boards[next]

func _get_floor_enemy(floor_number: int) -> String:
	var enemy_array: Array[String] = Global.story_mode_enemies
	var array_shifted_floor_number: int = floor_number - 1
	if array_shifted_floor_number < 0 or array_shifted_floor_number >= enemy_array.size():
		return "error"
	return enemy_array[array_shifted_floor_number]

func _on_game_ended() -> void:
	if layer_bg:
		layer_bg.queue_free()
