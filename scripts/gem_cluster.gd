extends CellObject
class_name GemCluster

enum State { PREVIEW, FALLING, LOCKED }
var state: State = State.PREVIEW

const GEM_SCENE: PackedScene = preload("res://scenes/gem.tscn")
var board: Board
var cluster_id: int = 0
var active: bool = false
var can_spawn_complex_piece: bool = false
var shape_id: String
var pivot_cell: Vector2i = Vector2i(0, 0)
var shape_cells: Array[Vector2i] = []
var gems: Array[Gem] = []
var invalid_rotation_shapes: Array[String] = []
var base_fall_delay: float = 0.5
var base_fall_delay_bonus: float = 0.2
var fall_delay: float = base_fall_delay
var base_move_delay: float = 0.15
var move_delay: float = 0
var drop_speed_mult: float = 4.0
var current_rotation: int = 0
var debug_force_shape: String = "T"
var debug_force_shape_enabled: bool = false
const SHAPES: Dictionary = {
	"pair": [
		[Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(0, 0), Vector2i(0, 1)],
		[Vector2i(1, 0), Vector2i(0, 0)],
		[Vector2i(0, 1), Vector2i(0, 0)],
	],
	"L": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, -1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, -1)],
		[Vector2i(1, -1), Vector2i(0, -1), Vector2i(1, 0)],
		[Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 0)],
	],
	"T": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0)],
		[Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)],
		[Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)],
	],
	#FIX ROTATION
	"block": [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1)],
		[Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1)],
		[Vector2i(1, -1), Vector2i(0, -1), Vector2i(0, 0), Vector2i(1, 0)],
		[Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(0, 0)],
	],
}

func _ready() -> void:
	if board == null:
		queue_free()
		return
	_set_shape()
	_create_shape_gems()
	_update_gem_positions()

func _process(delta: float) -> void:
	match state:
		State.FALLING:
			super(delta)
			_process_active(delta)

func _process_active(delta: float) -> void:
	fall_delay -= delta
	move_delay -= delta
	_handle_input(delta)
	if fall_delay > 0:
		return
	fall_delay = base_fall_delay
	if shape_cells.size() > 3:
		fall_delay += base_fall_delay_bonus
	if !move_cluster(Vector2i.DOWN):
		lock_cluster()

func _handle_input(delta: float) -> void:
	if move_delay <= 0:
		if Input.is_action_pressed("move_left"):
			move_cluster(Vector2i.LEFT)
		elif Input.is_action_pressed("move_right"):
			move_cluster(Vector2i.RIGHT)
		else:
			move_delay = 0
	if Input.is_action_just_pressed("rotate_left"):
		rotate_cluster(-1)
	if Input.is_action_just_pressed("rotate_right"):
		rotate_cluster(1)
	if Input.is_action_pressed("move_down"):
		fall_delay -= delta * drop_speed_mult

func set_cluster_id(_cluster_id: int) -> void:
	cluster_id = _cluster_id
	for gem in gems:
		gem.cluster_id = cluster_id

func begin_falling() -> bool:
	if !can_move(Vector2i.DOWN):
		return false
	_update_gem_positions()
	state = State.FALLING
	return true

func _create_shape_gems() -> void:
	var limited_color_options = board.colors.duplicate()
	limited_color_options.remove_at(randi_range(0, limited_color_options.size() - 1))
	for offset in shape_cells:
		var color: String = limited_color_options.pick_random()
		var gem: Gem = _create_gem(color)
		gem.cluster_id = cluster_id
		gems.append(gem)

func _update_gem_positions() -> void:
	target_position = board.get_position_at_cell(pivot_cell)
	for i in range(gems.size()):
		gems[i].target_position = shape_cells[i] * board.CELL_SIZE

func can_move(offset: Vector2i) -> bool:
	for cell in _get_shape_cells_on_board():
		var target_cell: Vector2i = cell + offset
		if !board.cell_is_free(target_cell):
			return false
	return true

func move_cluster(offset: Vector2i) -> bool:
	if !can_move(offset):
		return false
	pivot_cell += offset
	_update_gem_positions()
	move_delay = base_move_delay
	return true

func rotation_is_valid(rotated_cells: Array[Vector2i]) -> bool:
	if invalid_rotation_shapes.has(shape_id):
		return false
	for offset in rotated_cells:
		var cell: Vector2i = pivot_cell + offset
		if !board.cell_is_free(cell):
			return false
	return true

func rotate_cluster(direction: int) -> void:
	if !SHAPES.has(shape_id):
		return
	var rotations: Array = SHAPES[shape_id]
	var new_rotation: int = wrapi(current_rotation + direction, 0, rotations.size())
	var rotated_cells: Array[Vector2i] = []
	for cell in rotations[new_rotation]:
		rotated_cells.append(cell)
	if !rotation_is_valid(rotated_cells):
		return
	current_rotation = new_rotation
	shape_cells = rotated_cells
	_update_gem_positions()

func lock_cluster() -> void:
	for i in range(gems.size()):
		var gem: Gem = gems[i]
		var cell: Vector2i = pivot_cell + shape_cells[i]
		gem.reparent(board)
		board.tp_object_to_cell(gem, cell)
	board.active_cluster = null
	board.resolve_board()
	queue_free()

func _get_shape_cells_on_board() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in shape_cells:
		cells.append(pivot_cell + offset)
	return cells

func _create_gem(color: String) -> CellObject:
	var gem: Gem = GEM_SCENE.instantiate()
	gem.color = color
	add_child(gem)
	return gem

func _set_shape() -> void:
	shape_id = "pair"
	if can_spawn_complex_piece and SHAPES.size() > 0:
		shape_id = SHAPES.keys().pick_random()
	if debug_force_shape_enabled:
		shape_id = debug_force_shape
	current_rotation = 0
	shape_cells.clear()
	for cell: Vector2i in SHAPES[shape_id][0]:
		shape_cells.append(cell)
