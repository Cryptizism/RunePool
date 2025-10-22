extends Node2D

@onready var portrait_player = $AnimatedPlayer
@onready var portrait_enemy = $AnimatedEnemy
@onready var label_enemy = $AnimatedEnemy/LabelEnemy
@onready var health_bar_enemy = $AnimatedEnemy/HealthBarEnemy
var gem_scene = preload("res://scenes/gem.tscn")
var brick_scene = preload("res://scenes/brick.tscn")
var level_data = preload("res://scripts/levels.gd")
var current_enemy: EnemyData

const TILE_SIZE: int = 8
const WIDTH: int = 10
const HEIGHT: int = 13
const START_INTERVAL: float = 3
const CLUSTER_FALL_INTERVAL: float = 0.5
const GEM_FALL_INTERVAL: float = 0.1
const INPUT_DELAY_INTERVAL: float = 0.08
const COLOR_OPTIONS = {
	"red": "res://sprites/game/red.png",
	"blue": "res://sprites/game/blue.png",
	"green": "res://sprites/game/green.png",
	"yellow": "res://sprites/game/yellow.png",
}
const RUNE_OPTIONS = {
	"red": "res://sprites/game/rune_red.png",
	"blue": "res://sprites/game/rune_blue.png",
	"green": "res://sprites/game/rune_green.png",
	"yellow": "res://sprites/game/rune_yellow.png",
}
const PARTICLES = {
	"red": "res://sprites/game/fire.png",
	"blue": "res://sprites/game/water.png",
	"green": "res://sprites/game/leaf.png",
	"yellow": "res://sprites/game/lightning.png",
}
const EXTRAS = {
	"brick": "res://sprites/ui/brick.png"
}
var color_options = COLOR_OPTIONS.duplicate(true)
var rune_options = RUNE_OPTIONS.duplicate(true)

var board: Array[Array] = []
var current_gem_cluster: Node2D
var current_gem_cluster_position: Vector2i = Vector2i(0, 0)
var current_gem_cluster_offsets: Array = [Vector2i(0, 0), Vector2i(0, 0)]
var next_color_index: int = 0
var gems_in_combo: int = 0
var preview_gem1: Node2D
var preview_gem2: Node2D
var start_game_delay: float = 0.0
var cluster_fall_delay: float = 0.0
var input_delay: float = 0.0
var gem_move_delay: float = 0.0

var rune_count: int = 20

func new_game(level_name: String) -> void:
	randomize()
	reset_board()
	load_level(level_name)
	remove_random_color()
	create_runes(rune_count, int(HEIGHT * 0.4))
	# settle any stray runes
	destroy_lines(get_all_gem_lines())
	start_game_delay = 0
	randomize_preview_gems()
	print("starting new " + str(WIDTH) + "x" + str(HEIGHT) + " game with " + str(rune_count) + " runes.")

func _ready() -> void:
	create_preview_gems()
	new_game("wide")

func _physics_process(delta: float) -> void:
	debug_button()
	check_victory()
	if timer_is_waiting(delta):
		return
	if gems_must_process():
		return
	if !current_gem_cluster and !gems_are_moving():
		start_new_turn()
		return
	handle_control_inputs(delta)
	if placement_delay():
		return
	if !move_cluster_in_direction(Vector2.DOWN):
		lock_gem_cluster()

func placement_delay() -> bool:
	if cluster_fall_delay < CLUSTER_FALL_INTERVAL:
		return true
	cluster_fall_delay = 0
	return false

func start_new_turn() -> void:
	attack_enemy_with_combo()
	run_enemy_turn()
	try_spawning_gem_cluster()

func gems_must_process() -> bool:
	var gem_lines = get_all_gem_lines()
	if gem_lines.size() > 0:
		destroy_lines(gem_lines)
		gem_move_delay = 0
		# settle fully after destroy
		if drop_all_floating_gems():
			# after falling, new lines may form — let the loop run again
			return true
		return true
	# if anything falls (stable settle), we processed physics
	if drop_all_floating_gems():
		gem_move_delay = 0
		return true
	# if gems are still animating visually, hold
	if gems_are_moving():
		return true
	return false

func debug_button() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func check_victory() -> void:
	if $Runes.get_child_count() > 0:
		return
	new_game("thin")

func timer_is_waiting(delta: float) -> bool:
	cluster_fall_delay += delta
	input_delay += delta
	gem_move_delay += delta
	if start_game_delay < START_INTERVAL:
		start_game_delay += delta
		if start_game_delay >= START_INTERVAL:
			try_spawning_gem_cluster()
		return true
	if gem_move_delay <= GEM_FALL_INTERVAL:
		return true
	return false

func handle_control_inputs(delta: float) -> void:
	if !current_gem_cluster:
		return
	if Input.is_action_pressed("move_down"):
		cluster_fall_delay += delta * 8
	if Input.is_action_just_pressed("rotate_left") or Input.is_action_just_pressed("ui_accept"):
		rotate_gem(1)
	if Input.is_action_just_pressed("rotate_right"):
		rotate_gem(-1)
	if input_delay >= INPUT_DELAY_INTERVAL:
		input_delay = 0
		if Input.is_action_pressed("move_left"):
			move_cluster_in_direction(Vector2.LEFT)
		elif Input.is_action_pressed("move_right"):
			move_cluster_in_direction(Vector2.RIGHT)

func attack_enemy_with_combo() -> void:
	print("turn ended, " + str(gems_in_combo) + " gems in combo.")
	if !current_enemy or current_enemy.hp <= 0:
		return
	if gems_in_combo <= 4:
		print("dealing 0 damage.")
		gems_in_combo = 0
		return
	var damage = 1 + int((gems_in_combo - 4) / 2)
	damage = clamp(damage, 0, current_enemy.max_hp)
	print("dealing " + str(damage) + " damage.")
	damage_enemy(damage)
	gems_in_combo = 0

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

########################################################
# gems (creation, spawning, preview)
########################################################

func create_rune(spawn_position: Vector2i) -> void:
	if is_colliding(spawn_position):
		return
	var rune = gem_scene.instantiate()
	var keys = rune_options.keys()
	var color = keys[next_color_index % keys.size()]
	next_color_index += 1
	# runes are single gems (not paired)
	rune.connected_gem = null
	set_gem_color(rune, color, rune_options)
	rune.position = center_in_cell(spawn_position)
	rune.target_position = rune.position
	rune.add_to_group("gems")
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

func create_gem(x:int, y:int, color: String) -> Node2D:
	var gem = gem_scene.instantiate()
	set_gem_color(gem, color, color_options)
	gem.board_x = x
	gem.board_y = y
	gem.position = center_in_cell(Vector2i(gem.board_x, gem.board_y))
	gem.target_position = gem.position
	board[x][y] = gem
	gem.add_to_group("gems")
	$Gems.add_child(gem)
	return gem

func copy_preview_gem(parent_gem: Node2D) -> Node2D:
	var gem = gem_scene.instantiate()
	while (!color_options.has(parent_gem.gem_color)):
		set_gem_color(parent_gem, get_random_color(), color_options)
	set_gem_color(gem, parent_gem.gem_color, color_options)
	# position inside the preview area
	gem.position = center_in_cell(Vector2i(WIDTH + 2, 1))
	gem.target_position = gem.position
	gem.add_to_group("gems")
	current_gem_cluster.add_child(gem)
	return gem

func spawn_gem_cluster(spawn_position: Vector2i) -> void:
	if current_gem_cluster:
		current_gem_cluster.queue_free()
	current_gem_cluster = Node2D.new()
	add_child(current_gem_cluster)
	var gem1 = copy_preview_gem(preview_gem1)
	var gem2 = copy_preview_gem(preview_gem2)
	# connect pair both ways
	gem1.connected_gem = gem2
	gem2.connected_gem = gem1
	current_gem_cluster_position = spawn_position
	current_gem_cluster_offsets = [Vector2i(0, 0), Vector2i(1, 0)]
	randomize_preview_gems()
	update_cluster_position()

func try_spawning_gem_cluster() -> void:
	cluster_fall_delay = 0
	var spawn_location = Vector2i(WIDTH / 2 - 1, 0)
	if is_colliding(spawn_location):
		#GAME OVER
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	spawn_gem_cluster(spawn_location)

func create_brick(x:int, y:int) -> Node2D:
	var brick = brick_scene.instantiate()
	brick.texture = load(EXTRAS["brick"])
	brick.board_x = x
	brick.board_y = y
	brick.position = center_in_cell(Vector2i(x, y))
	brick.target_position = brick.position
	brick.add_to_group("bricks")
	board[x][y] = brick
	add_child(brick)
	return brick

# movement for the falling active cluster (player controlled)
func move_cluster_in_direction(direction: Vector2i) -> bool:
	# current cluster is not in board[] yet, so check board collisions
	for offset in current_gem_cluster_offsets:
		var next_position = current_gem_cluster_position + offset + direction
		if next_position.x < 0 or next_position.x >= WIDTH or next_position.y < 0 or next_position.y >= HEIGHT:
			return false
		# if there's a board occupant, collision
		if board[next_position.x][next_position.y]:
			return false
	current_gem_cluster_position += direction
	update_cluster_position()
	return true

func _rotation_collides(offsets: Array) -> bool:
	for offset in offsets:
		if is_colliding(current_gem_cluster_position + offset):
			return true
	return false

var ROTATIONS: Array = [
	[Vector2i(0,0), Vector2i(1,0)],  # horizontal (right)
	[Vector2i(0,1), Vector2i(0,0)],  # vertical (down)
	[Vector2i(1,0), Vector2i(0,0)],  # horizontal (left)
	[Vector2i(0,0), Vector2i(0,1)]   # vertical (up)
]

func rotate_gem(dir: int) -> void:
	var idx = ROTATIONS.find(current_gem_cluster_offsets)
	if idx == -1:
		for i in range(ROTATIONS.size()):
			if ROTATIONS[i] == current_gem_cluster_offsets:
				idx = i
				break
	if idx == -1:
		return
	var new_index = (idx + dir) % ROTATIONS.size()
	if new_index < 0:
		new_index += ROTATIONS.size()
	var new_offsets: Array = ROTATIONS[new_index]
	# try small horizontal shifts to rotate in tight spots (wall kicks)
	for dx in [0, -1, 1]:
		current_gem_cluster_position.x += dx
		if not _rotation_collides(new_offsets):
			current_gem_cluster_offsets = new_offsets
			update_cluster_position()
			return
		current_gem_cluster_position.x -= dx

# locking cluster into board
func lock_gem_cluster() -> void:
	if !current_gem_cluster:
		return
	var children := current_gem_cluster.get_children()
	for i in range(children.size()):
		var gem = children[i]
		if gem == null:
			continue
		var final_position = current_gem_cluster_position + current_gem_cluster_offsets[i]
		# safety check
		if final_position.x < 0 or final_position.x >= WIDTH or final_position.y < 0 or final_position.y >= HEIGHT:
			# invalid lock - treat as game over fallback
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			return
		# place gem into board
		board[final_position.x][final_position.y] = gem
		gem.board_x = final_position.x
		gem.board_y = final_position.y
		gem.target_position = center_in_cell(final_position)
	# reparent visual nodes
	for gem in children:
		gem.reparent($Gems)
	current_gem_cluster.queue_free()
	current_gem_cluster = null

# enemy drops — create gem and let falling system settle it
func drop_enemy_gem(count: int = 1) -> void:
	flash_portrait(portrait_player)
	shake_portrait(portrait_player)
	for i in range(count):
		var x = 0
		var y = 0
		var safe_location = false
		var attempts = 0
		while (!safe_location):
			attempts += 1
			if attempts > 200:
				return
			x = randi() % WIDTH
			y = 0
			if board[x][y]:
				continue
			# optional: avoid dropping directly over a brick two below
			if y + 2 < HEIGHT and board[x][y + 2] and board[x][y + 2].is_in_group("bricks"):
				continue
			safe_location = true
		var gem = create_gem(x, y, get_random_color())
		# place visually off-screen to fall in - preserve board logical position already set
		gem.position = center_in_cell(Vector2i(WIDTH + 2, HEIGHT - 1))
		gem.target_position = center_in_cell(Vector2i(x, y))
		gem.move_speed = 5
	# after placing, settle board
	drop_all_floating_gems()

func disconnect_gem(gem: Node2D) -> void:
	if !gem or not gem.is_in_group("gems"):
		return
	if not gem.connected_gem:
		return
	# break link both ways
	var other = gem.connected_gem
	gem.connected_gem = null
	if other:
		other.connected_gem = null

# move_gem_in_direction left mostly unused by falling system, keep for single moves if needed
func move_gem_in_direction(gem: Node2D, direction: Vector2) -> void:
	if !gem or !gem.is_in_group("gems"):
		return
	var nx = gem.board_x + int(direction.x)
	var ny = gem.board_y + int(direction.y)
	if nx < 0 or nx >= WIDTH or ny < 0 or ny >= HEIGHT:
		return
	if board[nx][ny]:
		return
	board[nx][ny] = gem
	board[gem.board_x][gem.board_y] = null
	gem.board_x = nx
	gem.board_y = ny
	gem.target_position = center_in_cell(Vector2i(gem.board_x, gem.board_y))

func destroy_gem(gem: Sprite2D) -> void:
	if !gem or !gem.is_in_group("gems"):
		return
	# remove from board first
	if board[gem.board_x][gem.board_y] == gem:
		board[gem.board_x][gem.board_y] = null
	disconnect_gem(gem)
	gem.texture = load(PARTICLES[gem.gem_color])
	gem.pulsate = true
	get_tree().create_timer(0.75).timeout.connect(func(): gem.queue_free())

########################################################
# misc helpers
########################################################

func is_colliding(gem_position: Vector2i) -> bool:
	if gem_position.x < 0 or gem_position.x >= WIDTH or gem_position.y < 0 or gem_position.y >= HEIGHT:
		return true
	return board[gem_position.x][gem_position.y] != null

func get_random_cell(vertical_gap: int) -> Vector2i:
	for i in 30:
		var x = randi() % WIDTH
		var y = randi() % (HEIGHT - vertical_gap)
		y += vertical_gap
		var location = Vector2i(x, y)
		if !is_colliding(location):
			return location
	return Vector2i(-1, -1)

func remove_random_color() -> void:
	var keys = COLOR_OPTIONS.keys()
	var random = keys[randi() % keys.size()]
	color_options.erase(random)
	rune_options.erase(random)

func set_gem_color(gem: Sprite2D, gem_color: String, type) -> void:
	if !type.has(gem_color):
		return
	gem.gem_color = gem_color
	gem.texture = load(type[gem_color])

func get_random_color() -> String:
	return color_options.keys()[randi() % color_options.size()]

func get_random_rune() -> String:
	return rune_options.keys()[randi() % rune_options.size()]

func center_in_cell(cell_position: Vector2i) -> Vector2:
	@warning_ignore("integer_division")
	var location = (cell_position * TILE_SIZE) + Vector2i(TILE_SIZE/2, TILE_SIZE + 1)
	return location - Vector2i(WIDTH * TILE_SIZE / 2, HEIGHT * TILE_SIZE / 2)

func update_cluster_position() -> void:
	if not current_gem_cluster:
		return
	for i in range(current_gem_cluster.get_child_count()):
		var gem = current_gem_cluster.get_child(i)
		var new_position = current_gem_cluster_position + current_gem_cluster_offsets[i]
		gem.board_x = new_position.x
		gem.board_y = new_position.y
		gem.target_position = center_in_cell(new_position)

########################################################
# gem lines
########################################################

func get_gem_line(start: Vector2i, delta: Vector2i) -> Array:
	var line = []
	var gem = board[start.x][start.y]
	if !gem or !gem.is_in_group("gems"):
		return line
	var color = gem.gem_color
	var pos = start
	while pos.x >= 0 and pos.x < WIDTH and pos.y >= 0 and pos.y < HEIGHT:
		var g = board[pos.x][pos.y]
		if !g or !g.is_in_group("gems"):
			break
		if g.gem_color == color:
			line.append(pos)
		else:
			break
		pos += delta
	return line

func get_all_gem_lines() -> Array:
	var lines := []
	var seen_positions := {}
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var gem = board[x][y]
			if !gem or !gem.is_in_group("gems"):
				continue
			var start_pos = Vector2i(x, y)
			for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]:
				var line = get_gem_line(start_pos, dir)
				if line.size() > 3:
					var key := ""
					for pos in line:
						key += str(pos.x) + "," + str(pos.y) + ";"
					if not seen_positions.has(key):
						seen_positions[key] = true
						lines.append(line)
	return lines

func destroy_lines(gem_lines: Array) -> void:
	for line in gem_lines:
		for location in line:
			var gem = board[location.x][location.y]
			if !gem or !gem.is_in_group("gems"):
				continue
			gems_in_combo += 1
			destroy_gem(gem)

func load_level(level_name: String) -> void:
	reset_board()
	init_enemy(level_name)
	var layout = level_data.LEVEL_LAYOUTS[level_name]
	for y in range(layout.size()):
		for x in range(layout[y].length()):
			var c = layout[y][x]
			if c == "#":
				create_brick(x, y)

func damage_enemy(amount: int) -> void:
	if amount > 0 and current_enemy.hp > 0:
		flash_portrait(portrait_enemy)
		shake_portrait(portrait_enemy)
	current_enemy.hp -= amount
	health_bar_enemy.value = clamp(current_enemy.hp, 0, current_enemy.max_hp)
	if current_enemy.hp > 0:
		return
	label_enemy.text = ""
	portrait_enemy.sprite_frames = load("res://animations/ghost.tres")
	portrait_enemy.play()

func init_enemy(level_name: String) -> void:
	current_enemy = EnemyData.new(level_name)
	label_enemy.text = current_enemy.name
	portrait_enemy.sprite_frames = load(current_enemy.animation_path)
	portrait_enemy.frame = 1
	portrait_enemy.play()
	health_bar_enemy.max_value = current_enemy.max_hp
	health_bar_enemy.value = current_enemy.hp

func run_enemy_turn() -> void:
	if !current_enemy or current_enemy.hp <= 0:
		return
	current_enemy.turns_since_attack += 1
	if current_enemy.turns_since_attack >= current_enemy.attack_speed:
		drop_enemy_gem(current_enemy.attacks_per_turn)
		current_enemy.turns_since_attack = 0

func shake_portrait(portrait: AnimatedSprite2D) -> void:
	if !portrait:
		return
	var original_position = portrait.position
	var speed = 0.02
	var tween = get_tree().create_tween()
	for i in range(12):
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1))
		tween.tween_property(portrait, "position", original_position + offset, speed)
	tween.tween_property(portrait, "position", original_position, speed)

func flash_portrait(portrait: AnimatedSprite2D) -> void:
	if !portrait:
		return
	var red = Color(1, 0.2, 0.2)
	var tween = get_tree().create_tween()
	tween.tween_property(portrait, "modulate", red, 0.05)
	tween.tween_property(portrait, "modulate", red, 0.1)
	tween.tween_property(portrait, "modulate", Color(1, 1, 1), 0.2)

# ---- helpers ------------------------------------------------------------

# safe board read
func board_at(x:int, y:int):
	if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
		return null
	return board[x][y]

# defines a deterministic "primary" gem for a 2-gem cluster so we only move it once
func is_cluster_primary(gem: Node2D) -> bool:
	if not gem or not gem.is_in_group("gems"):
		return false
	var other = gem.connected_gem
	if not other or other == gem:
		return true
	# primary rules:
	# - if gem is higher (smaller y) it's primary
	# - if same row, leftmost (smaller x) is primary
	if gem.board_y < other.board_y:
		return true
	if gem.board_y > other.board_y:
		return false
	return gem.board_x <= other.board_x

# ---- falling checks / moves --------------------------------------------

# Can this gem fall one cell down considering clusters?
func gem_can_fall(gem: Node2D) -> bool:
	if not gem or not gem.is_in_group("gems"):
		return false
	var nx = gem.board_x
	var ny = gem.board_y + 1
	if ny >= HEIGHT:
		return false
	var below = board_at(nx, ny)
	# If there's something below and it's not our connected partner -> can't fall
	if below:
		if gem.connected_gem and below == gem.connected_gem:
			# allowed if the connected gem occupies below (they'll move together)
			# but only if the connected gem can also fall into its own below
			# we check that when moving cluster
			pass
		else:
			return false
	return true

# Move an entire 1- or 2-gem cluster down by 1 cell (atomic board update)
func move_cluster_down(gem: Node2D) -> bool:
	if not gem or not gem.is_in_group("gems"):
		return false

	# Build cluster array (gem + optional partner)
	var cluster:Array = [gem]
	var other = gem.connected_gem
	if other and other != gem:
		cluster.append(other)

	# Ensure only primary gem attempts move to avoid double-moving
	if cluster.size() == 2:
		if not is_cluster_primary(gem):
			return false

	# validate both members can fall into their below cell (not blocked by non-cluster piece)
	for g in cluster:
		var nx = g.board_x
		var ny = g.board_y + 1
		if ny >= HEIGHT:
			return false
		var below = board_at(nx, ny)
		# below is allowed if it's null or it is (the other) gem that is part of cluster
		if below and not cluster.has(below):
			return false

	# remove cluster from board first (prevents overwrite problems)
	for g in cluster:
		if board[g.board_x][g.board_y] == g:
			board[g.board_x][g.board_y] = null

	# now move each member down and write back
	for g in cluster:
		g.board_y += 1
		board[g.board_x][g.board_y] = g
		g.target_position = center_in_cell(Vector2i(g.board_x, g.board_y))

	return true

# Drop all floating gems until stable (iterative, bottom-up)
# Returns true if any gem moved
func drop_all_floating_gems() -> bool:
	var any_moved = false
	var moved_this_pass = true
	while moved_this_pass:
		moved_this_pass = false
		# bottom-up traversal ensures gems above are processed later
		for y in range(HEIGHT - 2, -1, -1):
			for x in range(WIDTH):
				var gem = board_at(x, y)
				if not gem or not gem.is_in_group("gems"):
					continue
				if move_cluster_down(gem):
					moved_this_pass = true
					any_moved = true
	return any_moved

# Optional: check if any gem is still animating toward target
func gems_are_moving() -> bool:
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var gem = board_at(x, y)
			if gem and gem.is_in_group("gems"):
				if gem.position.distance_to(gem.target_position) > 0.5:
					return true
	return false



func create_preview_gem(location: Vector2i) -> Node2D:
	var gem = gem_scene.instantiate()
	set_gem_color(gem, get_random_color(), color_options)
	gem.position = Vector2(location.x, location.y)
	gem.target_position = gem.position
	$Preview.add_child(gem)
	return gem

func create_preview_gems() -> void:
	if preview_gem1 and preview_gem2:
		return
	preview_gem1 = create_preview_gem(center_in_cell(Vector2i(WIDTH + 1, 1)))
	preview_gem2 = create_preview_gem(center_in_cell(Vector2i(WIDTH + 2, 1)))
	preview_gem1.connected_gem = preview_gem2
	preview_gem2.connected_gem = preview_gem1

func randomize_preview_gems() -> void:
	set_gem_color(preview_gem1, get_random_color(), color_options)
	set_gem_color(preview_gem2, get_random_color(), color_options)
