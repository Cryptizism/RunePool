extends Node2D

@onready var board_sprite: Sprite2D = $Sprite2D
var gem_scene = preload("res://scenes/gem.tscn")

const TILE_SIZE: int = 8
const WIDTH: int = 8
const HEIGHT: int = 16
const START_INTERVAL: float = 3
const FALL_INTERVAL: float = 0.5
const INPUT_INTERVAL: float = 0.1
const DROP_INTERVAL: float = 0.3
const COLOR_OPTIONS = {
	"red": "res://sprites/red.png",
	"blue": "res://sprites/blue.png",
	"green": "res://sprites/green.png",
	"yellow": "res://sprites/yellow.png",
}
const RUNE_OPTIONS = {
	"red": "res://sprites/rune_red.png",
	"blue": "res://sprites/rune_blue.png",
	"green": "res://sprites/rune_green.png",
	"yellow": "res://sprites/rune_yellow.png",
}
var color_options = COLOR_OPTIONS.duplicate(true)
var rune_options = RUNE_OPTIONS.duplicate(true)

var board: Array[Array] = []
var current_gem_cluster: Node2D
var current_gem_cluster_position: Vector2i = Vector2i(0, 0)
var current_gem_cluster_offsets: Array = [Vector2i(0, 0), Vector2i(0, 0)]
var next_color_index: int = 0
var next_gem_cluster_colors: Array
var start_timer: float = 0.0
var fall_timer: float = 0.0
var input_timer: float = 0.0
var drop_timer: float = 0.0
var game_modes = {
	"classic": Callable(self, "check_gem_lines"),
	"chain": Callable(self, "check_gem_clusters")
}
var game_mode = "classic"

func new_game() -> void:
	randomize()
	reset_board()
	color_options = COLOR_OPTIONS.duplicate(true)
	rune_options = RUNE_OPTIONS.duplicate(true)
	remove_random_color()
	var height_gap = HEIGHT * 0.4 if game_mode == "classic" else HEIGHT - 1.0
	create_runes(3, height_gap)
	start_timer = 0

func _ready() -> void:
	new_game()
	@warning_ignore("integer_division")
	board_sprite.position += Vector2(WIDTH * TILE_SIZE / 2, HEIGHT * TILE_SIZE / 2)
	position += Vector2(30, 30)

func _physics_process(delta: float) -> void:
	fall_timer += delta
	input_timer += delta
	if start_timer < START_INTERVAL:
		start_timer += delta
		if start_timer >= START_INTERVAL:
			try_spawn_gem_cluster()
		return
	if drop_gems():
		return
	else:
		run_game_logic(game_mode)
	if Input.is_action_pressed("move_down"):
		fall_timer += delta * 8
	if Input.is_action_just_pressed("ui_accept"):
		rotate_gem()
	if input_timer >= INPUT_INTERVAL:
		handle_inputs()
	if fall_timer >= FALL_INTERVAL:
		fall_timer = 0
		if !move_gem(Vector2.DOWN):
			lock_gem_cluster()
			try_spawn_gem_cluster()

func run_game_logic(mode: String) -> void:
	game_modes[mode].call()

func handle_inputs() -> void:
	input_timer = 0
	if Input.is_action_pressed("move_left"):
		move_gem(Vector2.LEFT)
	elif Input.is_action_pressed("move_right"):
		move_gem(Vector2.RIGHT)

func reset_board() -> void:
	board.resize(WIDTH)
	for x in range(WIDTH):
		board[x] = []
		board[x].resize(HEIGHT)
		for y in range(HEIGHT):
			board[x][y] = null
	if current_gem_cluster:
		current_gem_cluster.queue_free()
	for gem in $Gems.get_children():
		gem.queue_free()
	for rune in $Runes.get_children():
		rune.queue_free()
	color_options = COLOR_OPTIONS.duplicate(true)
	rune_options = RUNE_OPTIONS.duplicate(true)

func get_random_cell(vertical_gap: int) -> Vector2i:
	for i in 30:
		var x = randi() % WIDTH
		var y = randi() % (HEIGHT - vertical_gap)
		y += vertical_gap
		var location = Vector2i(x, y)
		if !is_colliding(location):
			return location
	return Vector2i(-1, -1)

func create_rune(spawn_position: Vector2i) -> void:
	var rune = gem_scene.instantiate()
	var keys = rune_options.keys()
	var color = keys[next_color_index % keys.size()]
	next_color_index += 1
	rune.connected_gem = rune
	set_gem_color(rune, color, rune_options)
	rune.position = center_in_cell(spawn_position)
	rune.target_position = rune.position
	board[spawn_position.x][spawn_position.y] = rune
	$Runes.add_child(rune)

func _create_runes_async(amount: int, vertical_gap: int) -> void:
	for i in range(amount):
		var location = get_random_cell(vertical_gap)
		if location == Vector2i(-1, -1):
			continue
		create_rune(location)
		await get_tree().create_timer(0.1).timeout

func create_runes(amount: int, vertical_gap: int) -> void:
	await _create_runes_async(amount, vertical_gap)

func try_spawn_gem_cluster() -> void:
	@warning_ignore("integer_division")
	var spawn_location = Vector2i(WIDTH / 2 - 1, 0)
	if is_colliding(spawn_location):
		#GAME OVER
		new_game()
		return
	spawn_gem_cluster(spawn_location)

func create_gem() -> Node2D:
	var gem = gem_scene.instantiate()
	set_gem_color(gem, get_random_color(), color_options)
	@warning_ignore("integer_division")
	gem.position = center_in_cell(Vector2i(WIDTH / 2, -5))
	gem.target_position = gem.position
	current_gem_cluster.add_child(gem)
	return gem

func spawn_gem_cluster(spawn_position: Vector2i) -> void:
	if current_gem_cluster:
		current_gem_cluster.queue_free()
	current_gem_cluster = Node2D.new()
	add_child(current_gem_cluster)
	var gem1 = create_gem()
	var gem2 = create_gem()
	gem1.connected_gem = gem2
	gem2.connected_gem = gem1
	current_gem_cluster_position = spawn_position
	current_gem_cluster_offsets = [Vector2i(0, 0), Vector2i(1, 0)]
	update_gem_world_position()

func is_colliding(gem_position: Vector2i) -> bool:
	return (
		gem_position.x < 0
		or gem_position.x >= WIDTH
		or gem_position.y < 0
		or gem_position.y >= HEIGHT
		or board[gem_position.x][gem_position.y] != null
	)

func move_gem(direction: Vector2i) -> bool:
	for offset in current_gem_cluster_offsets:
		var next_position = current_gem_cluster_position + offset + direction
		if is_colliding(next_position):
			return false
	current_gem_cluster_position += direction
	update_gem_world_position()
	return true

func _rotation_collides(offsets: Array) -> bool:
	for offset in offsets:
		if is_colliding(current_gem_cluster_position + offset):
			return true
	return false

func rotate_gem() -> void:
	var new_offsets = []
	match current_gem_cluster_offsets:
		[Vector2i(0, 0), Vector2i(1, 0)]: new_offsets = [Vector2i(0, 1), Vector2i(0, 0)]
		[Vector2i(1, 0), Vector2i(0, 0)]: new_offsets = [Vector2i(0, 0), Vector2i(0, 1)]
		[Vector2i(0, 0), Vector2i(0, 1)]: new_offsets = [Vector2i(0, 0), Vector2i(1, 0)]
		[Vector2i(0, 1), Vector2i(0, 0)]: new_offsets = [Vector2i(1, 0), Vector2i(0, 0)]
		_: return
	for dx in [0, -1, 1]:
		current_gem_cluster_position.x += dx
		if not _rotation_collides(new_offsets):
			current_gem_cluster_offsets = new_offsets
			update_gem_world_position()
			return
		current_gem_cluster_position.x -= dx

func lock_gem_cluster() -> void:
	if !current_gem_cluster:
		return
	for gem in current_gem_cluster.get_children():
		if gem == null:
			continue
		var i = current_gem_cluster.get_children().find(gem)
		var final_position = current_gem_cluster_position + current_gem_cluster_offsets[i]
		board[final_position.x][final_position.y] = gem
	for gem in current_gem_cluster.get_children():
		gem.reparent($Gems)
	current_gem_cluster.queue_free()
	run_game_logic(game_mode)

func drop_gems() -> bool:
	var dropped_gem = false
	for x in range(WIDTH):
		for y in range(HEIGHT - 2, -1, -1):
			var gem = board[x][y]
			if !gem:
				continue
			if board[x][y + 1] != null:
				continue
			if gem == gem.connected_gem:
				continue
			if gem.connected_gem:
				var nx = gem.connected_gem.board_x
				var ny = gem.connected_gem.board_y + 1
				if ny < HEIGHT and nx >= 0 and nx < WIDTH:
					if board[nx][ny] != null and board[nx][ny] != gem:
						continue
			board[x][y + 1] = gem
			board[x][y] = null
			gem.board_y += 1
			gem.target_position = center_in_cell(Vector2i(gem.board_x, gem.board_y))
			dropped_gem = true
	return dropped_gem

func remove_unused_colors() -> void:
	if $Runes.get_child_count() <= 0:
		return
	var remaining_colors := {}
	for rune in $Runes.get_children():
		if rune.gem_color != null:
			remaining_colors[rune.gem_color] = true
	var current_colors := color_options.keys()
	for color in current_colors:
		if !remaining_colors.has(color):
			color_options.erase(color)
			rune_options.erase(color)
			for gem in $Gems.get_children():
				if gem.gem_color == color:
					gem.queue_free()

func remove_random_color() -> void:
	var keys = COLOR_OPTIONS.keys()
	var random = keys[randi() % keys.size()]
	color_options.erase(random)
	rune_options.erase(random)

func set_gem_color(gem: Sprite2D, gem_color: String, type) -> void:
	gem.gem_color = gem_color
	gem.texture = load(type[gem_color])

func get_random_color() -> String:
	var keys = color_options.keys()
	return keys[randi() % keys.size()]

func get_random_rune() -> String:
	var keys = rune_options.keys()
	return keys[randi() % keys.size()]

func center_in_cell(cell_position: Vector2i) -> Vector2:
	@warning_ignore("integer_division")
	return (cell_position * TILE_SIZE) + Vector2i(TILE_SIZE/2, TILE_SIZE/2)

func update_gem_world_position() -> void:
	for i in range(current_gem_cluster.get_child_count()):
		var gem = current_gem_cluster.get_child(i)
		var new_position = current_gem_cluster_position + current_gem_cluster_offsets[i]
		gem.board_x = new_position.x
		gem.board_y = new_position.y
		gem.target_position = center_in_cell(new_position)

#CHAIN STYLE
func check_gem_clusters() -> void:
	var visited: Array = []
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var pos = Vector2i(x, y)
			if pos in visited or board[x][y] == null:
				continue
			var gem = board[x][y]
			var cluster = get_cluster_from(pos, gem.gem_color)
			for c in cluster:
				visited.append(c)
			if has_enough_runes(cluster):
				destroy_cluster(cluster)

func get_cluster_from(start: Vector2i, color: String) -> Array:
	var cluster: Array = []
	var open: Array = [start]
	var seen: Array = []
	while open.size() > 0:
		var pos = open.pop_back()
		if pos in seen:
			continue
		seen.append(pos)
		var gem = board[pos.x][pos.y]
		if gem == null or gem.gem_color != color:
			continue
		cluster.append(pos)
		for n in get_neighbors(pos):
			if n not in seen:
				open.append(n)
	return cluster

func get_neighbors(pos: Vector2i) -> Array:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	var result: Array = []
	for d in dirs:
		var n = pos + d
		if n.x >= 0 and n.x < WIDTH and n.y >= 0 and n.y < HEIGHT:
			result.append(n)
	return result

func has_enough_runes(cluster: Array) -> bool:
	var count = 0
	for pos in cluster:
		var gem = board[pos.x][pos.y]
		if gem and gem.connected_gem == gem: # rune check
			count += 1
	return count >= 3

func destroy_cluster(cluster: Array) -> void:
	for pos in cluster:
		var gem = board[pos.x][pos.y]
		if gem:
			gem.queue_free()
			board[pos.x][pos.y] = null

#CLASSIC STYLE
func get_gem_line(start_position: Vector2i, delta: Vector2i) -> Array:
	var line: Array = []
	var gem = board[start_position.x][start_position.y]
	if !gem:
		return line
	var color = gem.gem_color
	var next_position = start_position
	while next_position.x >= 0 and next_position.x < WIDTH and next_position.y >= 0 and next_position.y < HEIGHT:
		var next_gem = board[next_position.x][next_position.y]
		if next_gem and next_gem.gem_color == color:
			line.append(next_position)
		else:
			break
		next_position += delta
	return line

func destroy_gem_line(start_position: Vector2i, direction: Vector2i) -> void:
	var line = get_gem_line(start_position, direction)
	if line.size() <= 3:
		return
	for gem_position in line:
		var gem = board[gem_position.x][gem_position.y]
		if !gem:
			continue
		gem.queue_free()
		board[gem_position.x][gem_position.y] = null

func destroy_gem_lines(start_position: Vector2i) -> void:
	destroy_gem_line(start_position, Vector2i(0, -1))
	destroy_gem_line(start_position, Vector2i(0, 1))
	destroy_gem_line(start_position, Vector2i(1, 0))
	destroy_gem_line(start_position, Vector2i(-1, 0))

func check_gem_lines() -> void:
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var gem = board[x][y]
			var start_position = Vector2i(x, y)
			if gem == null:
				continue
			destroy_gem_lines(start_position)
			remove_unused_colors()
			drop_gems()
			if $Runes.get_child_count() <= 0:
				#VICTORY
				new_game()
