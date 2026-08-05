extends CellObject
class_name GemCluster

enum State { PREVIEW, FALLING, LOCKED }
var state: State = State.PREVIEW

const GEM_SCENE: PackedScene = preload("res://scenes/gem.tscn")
const SPEED_POTENCY: float = 0.000099

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
var small_kick_table: Array[Vector2i] = [
	Vector2i.ZERO,
	Vector2i.LEFT,
	Vector2i.RIGHT,
]
var big_kick_table: Array[Vector2i] = [
	Vector2i.ZERO,
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.LEFT * 2,
	Vector2i.RIGHT * 2,
]

func _ready() -> void:
	if board == null:
		queue_free()
		return
	_set_shape()
	_create_shape_gems()
	_update_gem_positions()

func _process(delta: float) -> void:
	super(delta)

func tick(delta: float) -> void:
	if board.state != board.State.ACTIVE:
		return
	match state:
		State.FALLING:
			_process_active(delta)

func _process_active(delta: float) -> void:
	fall_delay -= (delta * 0.5) + (board.speed * SPEED_POTENCY)
	move_delay -= delta
	if fall_delay > 0:
		return
	fall_delay = base_fall_delay
	board.update_ghost_cluster(self)
	if shape_cells.size() > 3:
		fall_delay += base_fall_delay_bonus
	if !move_cluster(Vector2i.DOWN):
		lock_cluster()

func handle_input(delta: float) -> void:
	if board.state != board.State.ACTIVE:
		return
	if move_delay <= 0:
		if board.input.move_left:
			move_cluster(Vector2i.LEFT)
		elif board.input.move_right:
			move_cluster(Vector2i.RIGHT)
		else:
			move_delay = 0
	if board.input.rotate_left:
		rotate_cluster(-1)
	if board.input.rotate_right:
		rotate_cluster(1)
	if board.input.move_down:
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
	limited_color_options.remove_at(board.rng.randi_range(0, limited_color_options.size() - 1))
	for offset in shape_cells:
		var color: String = limited_color_options[board.rng.randi_range(0, limited_color_options.size() -1)]
		var gem: Gem = _create_gem(color)
		gem.cluster_id = cluster_id
		gems.append(gem)
	_apply_pair_sprites()

func _update_gem_positions() -> void:
	target_position = board.get_position_at_cell(pivot_cell)
	for i in range(gems.size()):
		gems[i].target_position = shape_cells[i] * board.CELL_SIZE
	board.update_ghost_cluster(self)

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

func rotation_is_valid(rotated_cells: Array[Vector2i], test_pivot: Vector2i) -> bool:
	if invalid_rotation_shapes.has(shape_id):
		return false
	for offset in rotated_cells:
		var cell = test_pivot + offset
		if !board.cell_is_free(cell):
			return false
	return true

func rotate_cluster(direction: int) -> void:
	if !SHAPES.has(shape_id):
		return
	var rotations: Array = SHAPES[shape_id]
	var new_rotation := wrapi(
		current_rotation + direction,
		0,
		rotations.size()
	)
	var rotated_cells: Array[Vector2i] = []
	for cell in rotations[new_rotation]:
		rotated_cells.append(cell)
	var kick_table: Array = small_kick_table if shape_id == "pair" else big_kick_table
	for kick in kick_table:
		var test_pivot = pivot_cell + kick
		if !rotation_is_valid(rotated_cells, test_pivot):
			continue
		pivot_cell = test_pivot
		current_rotation = new_rotation
		shape_cells = rotated_cells
		_update_gem_positions()
		_apply_pair_sprites()
		return

func lock_cluster() -> void:
	var size: int = gems.size()
	for i in range(size):
		var gem: Gem = gems[i]
		var cell: Vector2i = pivot_cell + shape_cells[i]
		gem.reparent(board)
		board.tp_object_to_cell(gem, cell)
		if size <= 2:
			continue
		gem.cluster_id = -1
		gem.set_sprite("base")
	board.active_cluster = null
	board.resolve_board()
	board.clear_ghosts()
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
		var keys: Array = SHAPES.keys()
		shape_id = keys[board.rng.randi_range(0, keys.size() -1)]
	if debug_force_shape_enabled:
		shape_id = debug_force_shape
	current_rotation = 0
	shape_cells.clear()
	for cell: Vector2i in SHAPES[shape_id][0]:
		shape_cells.append(cell)

func _apply_pair_sprites() -> void:
	if shape_id != "pair":
		return
	if gems.size() != 2:
		return
	var delta := shape_cells[1] - shape_cells[0]
	if delta.x != 0:
		if delta.x > 0:
			gems[0].set_sprite("h_left")
			gems[1].set_sprite("h_right")
		else:
			gems[0].set_sprite("h_right")
			gems[1].set_sprite("h_left")
	else:
		if delta.y > 0:
			gems[0].set_sprite("v_top")
			gems[1].set_sprite("v_bottom")
		else:
			gems[0].set_sprite("v_bottom")
			gems[1].set_sprite("v_top")
