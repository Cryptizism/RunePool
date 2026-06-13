extends Node2D
class_name Board

const LEVEL_DATA: Resource = preload("res://scripts/levels.gd")
const CLUSTER_SCENE: PackedScene = preload("res://scenes/gem_cluster.tscn")
const GEM_SCENE: PackedScene = preload("res://scenes/gem.tscn")
const RUNE_SCENE: PackedScene = preload("res://scenes/rune.tscn")
const BRICK_SCENE: PackedScene = preload("res://scenes/brick.tscn")
const CHARACTER_SCENE: PackedScene = preload("res://scenes/character.tscn")

const CELL_SIZE: int = 8
const BASE_GEM_COUNT: int = 20
const COMPLEX_PIECE_TURN_COUNT: int = 5
var debug_attack_enabled: bool = true
var width: int = 10
var height: int = 13
#var seed: String
var turn_number: int = 1
var player_id: int = 1
var character: Character
var enemy: Character
var enemy_gems_waiting: int = 0
var speed: float = 0.0
var difficulty: int = 0
var grid: Array[Array] = []
var colors: Array[String]
var runes_remaining: int = 0
var board_offset: Vector2 = Vector2(
	(1 * CELL_SIZE) + (CELL_SIZE / 2),
	(3 * CELL_SIZE) + (CELL_SIZE / 2)
)
var cell_rune_space: int = 6
var active_cluster: GemCluster
var next_cluster: GemCluster
var cluster_spawn_cell: Vector2i
var cluster_preview_offset: Vector2 = Vector2(
	(5 * CELL_SIZE) + (CELL_SIZE / 2),
	(1 * CELL_SIZE) + (CELL_SIZE / 2)
)

func _ready() -> void:
	width = clamp(width, 2, 15)
	height = clamp(height, 5, 15)
	grid.resize(width)
	cluster_spawn_cell = Vector2i((width / 2) - 1, 0)
	for i in range(width):
		grid[i] = []
		grid[i].resize(height)

func _process(delta: float) -> void:
	_try_debug_attack()

func _try_debug_attack() -> void:
	if !debug_attack_enabled:
		return
	if Input.is_action_just_pressed("ui_accept"):
		character.check_combo({
			"gems": 8,
			"lines": 2
		})
		if enemy.hp <= 0:
			enemy.hp = enemy.max_hp

func _on_game_end() -> void:
	get_tree().reload_current_scene()

func set_character(character_id) -> void:
	character = CHARACTER_SCENE.instantiate()
	character.character_id = character_id
	character.board = self
	add_child(character)
	character.set_max_hp(-1)
	character.position = Vector2(
		(-6 * CELL_SIZE) + (CELL_SIZE / 2),
		(10 * CELL_SIZE) + (CELL_SIZE / 2) + 1
	)
	if enemy:
		return
	position = Vector2((6 * CELL_SIZE), 0)

func set_enemy(character_id) -> void:
	enemy = CHARACTER_SCENE.instantiate()
	enemy.character_id = character_id
	enemy.flipped_portrait = true
	enemy.board = self
	enemy.opponent = character
	character.opponent = enemy
	add_child(enemy)
	enemy.position = Vector2(
		((width + 1) * CELL_SIZE) + (CELL_SIZE / 2),
		(10 * CELL_SIZE) + (CELL_SIZE / 2) + 1
	)
	_center_board_enemy()

func _center_board_enemy() -> void:
	var center_x = get_viewport_rect().size.x / 2
	position.x = center_x - (((width + 2) * CELL_SIZE) / 2)

func _reset_board() -> void:
	for i in range(width):
		for j in range(height):
			var next: CellObject = grid[i][j]
			if next == null:
				continue
			next.destroy()

func load_level(level_id: String) -> void:
	_reset_board()
	#init_enemy(level_id)
	var layout = LEVEL_DATA.LEVEL_LAYOUTS[level_id]
	if !layout:
		layout = LEVEL_DATA.LEVEL_LAYOUTS["classic"]
	for i in range(layout.size()):
		for j in range(layout[i].length()):
			var cell = layout[i][j]
			if cell != "#":
				continue
			_create_brick(Vector2i(j, i))
	_refresh_colors()
	var rune_pattern: Array[Array] = _generate_rune_pattern()
	_apply_rune_pattern(rune_pattern)
	_create_cluster()

func _refresh_colors() -> void:
	colors = Global.COLORS.duplicate(true)
	colors.pop_at(randi_range(0, colors.size() - 1))

func set_cell_rune_space(tiles: int) -> void:
	cell_rune_space = clamp(tiles, 1, height - 1)

func _cell_is_valid(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= width:
		return false
	if cell.y < 0 or cell.y >= height:
		return false
	return true

func cell_is_free(cell: Vector2i) -> bool:
	if !_cell_is_valid(cell):
		return false
	return grid[cell.x][cell.y] == null

func get_position_at_cell(cell: Vector2i) -> Vector2:
	if !_cell_is_valid(cell):
		return -Vector2.ONE
	return Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE) + board_offset

func get_cell_at_object(cell_object: CellObject) -> Vector2i:
	if !cell_object:
		return -Vector2i.ONE
	return Vector2i(cell_object.target_position - board_offset) / CELL_SIZE

func tp_object_to_cell(cell_object: CellObject, cell: Vector2i) -> void:
	var cell_position: Vector2 = get_position_at_cell(cell)
	if cell_position == -Vector2.ONE:
		return
	var previous_position = get_cell_at_object(cell_object)
	if _cell_is_valid(previous_position):
		grid[previous_position.x][previous_position.y] = null
	cell_object.position = cell_position
	cell_object.target_position = cell_position
	grid[cell.x][cell.y] = cell_object

func set_object_destination_to_cell(cell_object: CellObject, cell: Vector2i) -> void:
	var cell_position: Vector2 = get_position_at_cell(cell)
	if cell_position == -Vector2.ONE:
		return
	var previous_position = get_cell_at_object(cell_object)
	if _cell_is_valid(previous_position):
		grid[previous_position.x][previous_position.y] = null
	cell_object.target_position = cell_position
	grid[cell.x][cell.y] = cell_object

func _generate_empty_pattern() -> Array[Array]:
	var pattern: Array[Array] = []
	pattern.resize(width)
	for i in range(width):
		pattern[i] = []
		pattern[i].resize(height)
	return pattern

func _generate_rune_pattern() -> Array[Array]:
	if colors.size() != 3:
		return []
	var pattern: Array[Array] = _generate_empty_pattern()
	var amount: int = BASE_GEM_COUNT + 2 * round(difficulty)
	var available_cells: Array[Vector2i] = _get_available_cells()
	for i in range(amount):
		var size: int = available_cells.size()
		var index: int = randi_range(0, size - 1)
		var cell: Vector2i = available_cells.get(index)
		available_cells.pop_at(index)
		if !cell_is_free(cell):
			continue
		pattern[cell.x][cell.y] = colors[randi_range(0, 2)]
	return pattern

func _apply_rune_pattern(rune_pattern: Array[Array]) -> void:
	if !rune_pattern:
		return
	if rune_pattern.size() <= 0:
		return
	for i in range(rune_pattern.size()):
		for j in range(rune_pattern[i].size()):
			var cell_color = rune_pattern[i][j]
			if cell_color == null:
				continue
			_create_rune(Vector2i(i, j), cell_color)

func _get_available_cells() -> Array[Vector2i]:
	var options: Array[Vector2i] = []
	for i in range(width):
		for j in range(height - cell_rune_space, height):
			var cell: Vector2i = Vector2i(i, j)
			if !cell_is_free(cell):
				continue
			options.append(cell)
	return options

func _create_preview_cluster() -> GemCluster:
	var cluster: GemCluster = CLUSTER_SCENE.instantiate()
	cluster.board = self
	cluster.pivot_cell = Vector2i.ZERO
	cluster.can_spawn_complex_piece = turn_number % COMPLEX_PIECE_TURN_COUNT == 0
	add_child(cluster)
	cluster.position = cluster_preview_offset
	return cluster

func _create_cluster() -> GemCluster:
	if active_cluster:
		active_cluster.queue_free()
	if !next_cluster:
		next_cluster = _create_preview_cluster()
	active_cluster = next_cluster
	active_cluster.pivot_cell = cluster_spawn_cell
	next_cluster = _create_preview_cluster()
	active_cluster.set_cluster_id(turn_number)
	if !active_cluster.begin_falling():
		_on_game_end()
		return
	return active_cluster

func _create_gem(cell: Vector2i, color: String) -> CellObject:
	if !cell_is_free(cell):
		return
	var gem: Gem = GEM_SCENE.instantiate()
	gem.color = color
	add_child(gem)
	tp_object_to_cell(gem, cell)
	return gem

func _create_rune(cell: Vector2i, color: String) -> CellObject:
	if !cell_is_free(cell):
		return
	var rune: Rune = RUNE_SCENE.instantiate()
	rune.color = color
	add_child(rune)
	tp_object_to_cell(rune, cell)
	runes_remaining += 1
	return rune

func _create_brick(cell: Vector2i) -> CellObject:
	if !cell_is_free(cell):
		return
	var brick = BRICK_SCENE.instantiate()
	add_child(brick)
	tp_object_to_cell(brick, cell)
	return brick

func _cell_can_fall(cell: Vector2i) -> bool:
	if !is_instance_valid(grid[cell.x][cell.y]):
		return false
	var cell_object: CellObject = grid[cell.x][cell.y]
	if cell_object == null:
		return false
	if !cell_object.has_gravity:
		return false
	if cell_object is Gem:
		var gem: Gem = cell_object as Gem
		if gem.cluster_id != -1:
			return false
	return true

func _cluster_can_fall(cluster_id: int) -> bool:
	for i in range(width):
		for j in range(height):
			if !is_instance_valid(grid[i][j]):
				continue
			var cell_object: CellObject = grid[i][j]
			if cell_object is not Gem:
				continue
			var gem: Gem = cell_object as Gem
			if gem.cluster_id != cluster_id:
				continue
			var cell_below: Vector2i = Vector2i(i, j + 1)
			if !_cell_is_valid(cell_below):
				return false
			if !is_instance_valid(grid[cell_below.x][cell_below.y]):
				continue
			var other: CellObject = grid[cell_below.x][cell_below.y]
			if other == null:
				continue
			if other is Gem and other.cluster_id == cluster_id:
				continue
			return false
	return true

func _apply_gravity() -> bool:
	var moved: bool = false
	var processed_clusters: Array[int] = []
	#move clusters
	for i in range(width):
		for j in range(height):
			if !is_instance_valid(grid[i][j]):
				continue
			var cell_object: CellObject = grid[i][j]
			if cell_object is not Gem:
				continue
			var gem: Gem = cell_object as Gem
			if gem.cluster_id == -1:
				continue
			if processed_clusters.has(gem.cluster_id):
				continue
			processed_clusters.append(gem.cluster_id)
			if _cluster_can_fall(gem.cluster_id):
				_move_cluster_down(gem.cluster_id)
				moved = true
	#move indiv
	for j in range(height - 2, -1, -1): #skip bottom row
		for i in range(width):
			var cell: Vector2i = Vector2i(i, j)
			if !_cell_can_fall(cell):
				continue
			var cell_below: Vector2i = cell + Vector2i.DOWN
			if !cell_is_free(cell_below):
				continue
			var cell_object: CellObject = grid[i][j]
			grid[i][j] = null
			grid[cell_below.x][cell_below.y] = cell_object
			set_object_destination_to_cell(cell_object, cell_below)
			moved = true
	return moved

func _move_cluster_down(cluster_id: int) -> void:
	var cells: Array[Vector2i] = []
	for i in range(width):
		for j in range(height):
			if !is_instance_valid(grid[i][j]):
				continue
			var gem := grid[i][j] as Gem
			if gem and gem.cluster_id == cluster_id:
				cells.append(Vector2i(i, j))
	cells.sort_custom(func(a, b): return a.y > b.y)
	for cell in cells:
		var gem: Gem = grid[cell.x][cell.y]
		set_object_destination_to_cell(gem, cell + Vector2i.DOWN)

func _destroy_cell(cell: Vector2i) -> void:
	if !is_instance_valid(grid[cell.x][cell.y]):
		return
	var cell_object: CellObject = grid[cell.x][cell.y]
	if !cell_object:
		return
	cell_object.destroy()
	grid[cell.x][cell.y] = null

func _get_breakable_lines() -> Array[Array]:
	var lines: Array[Array] = []
	lines.append_array(_scan_lines(true))
	lines.append_array(_scan_lines(false))
	return lines

func _scan_lines(vertical: bool) -> Array[Array]:
	var lines: Array[Array] = []
	var outer_limit = width if vertical else height
	var inner_limit = height if vertical else width
	for outer in range(outer_limit):
		var line_color: String = ""
		var line_cells: Array[Vector2i] = []
		for inner in range(inner_limit):
			var x = outer if vertical else inner
			var y = inner if vertical else outer
			if !is_instance_valid(grid[x][y]) or grid[x][y] is not Gem:
				if line_cells.size() >= 4:
					lines.append(line_cells.duplicate())
				line_cells.clear()
				line_color = ""
				continue
			var gem: Gem = grid[x][y]
			if gem.color == line_color:
				line_cells.append(Vector2i(x, y))
			else:
				if line_cells.size() >= 4:
					lines.append(line_cells.duplicate())
				line_color = gem.color
				line_cells = [Vector2i(x, y)]
		if line_cells.size() >= 4:
			lines.append(line_cells.duplicate())
	return lines

func _destroy_lines(lines: Array[Vector2i]) -> void:
	var affected_clusters: Array[int] = []
	for cell in lines:
		if !is_instance_valid(grid[cell.x][cell.y]):
			continue
		var gem: Gem = grid[cell.x][cell.y]
		if gem.cluster_id != -1 and !affected_clusters.has(gem.cluster_id):
			affected_clusters.append(gem.cluster_id)
		_destroy_cell(cell)
	for cluster_id in affected_clusters:
		_separate_clusters(cluster_id)

func _separate_clusters(cluster_id: int) -> void:
	for i in range(width):
		for j in range(height):
			if !is_instance_valid(grid[i][j]) or grid[i][j] is not Gem:
				continue
			var gem: Gem = grid[i][j] as Gem
			if gem.cluster_id != cluster_id:
				continue
			gem.cluster_id = -1

func _drop_enemy_gem() -> void:
	var options: Array[Vector2i] = _get_available_cells()
	if options.size() <= 0:
		return
	var cell: Vector2i = options.pick_random()
	var color: String = colors.pick_random()
	_create_gem(cell, color)

func resolve_board() -> void:
	var attempts: int = 100
	var gem_count: int = 0
	var line_count: int = 0
	#settle board
	while attempts > 0:
		attempts -= 1
		var lines = _get_breakable_lines()
		#if board is settled
		if lines.size() <= 0:
			if enemy_gems_waiting > 0:
				enemy_gems_waiting -= 1
				_drop_enemy_gem()
				continue
			break
		#complete board iteration
		line_count += lines.size()
		var cells_to_destroy: Array[Vector2i] = []
		for line in lines:
			gem_count += line.size()
			cells_to_destroy.append_array(line)
		_destroy_lines(cells_to_destroy)
		while _apply_gravity():
			await get_tree().create_timer(0.2).timeout
	#board is settled
	if character:
		character.check_launch_attack()
		character.check_combo({
			"gems": gem_count,
			"lines": line_count,
		})
	turn_number += 1
	_create_cluster()
	if runes_remaining > 0:
		return
	_on_game_end()
