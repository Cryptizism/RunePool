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
const FALL_INTERVAL: float = 0.5
const INPUT_INTERVAL: float = 0.08
const DROP_INTERVAL: float = 0.1
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
var combo_length: int = 0
var preview_gem1: Node2D
var preview_gem2: Node2D
var start_timer: float = 0.0
var fall_timer: float = 0.0
var input_timer: float = 0.0
var drop_timer: float = 0.0

func new_game(level_name: String) -> void:
	randomize()
	reset_board()
	load_level(level_name)
	remove_random_color()
	create_runes(20, HEIGHT * 0.4)
	destroy_all_gem_lines()
	start_timer = 0
	randomize_preview_gems()

func _ready() -> void:
	create_preview_gems()
	new_game(level_data.get_random_level_name())

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	#check victory
	if $Runes.get_child_count() <= 0:
		#VICTORY
		new_game("thin")
	#handle timers
	fall_timer += delta
	input_timer += delta
	drop_timer += delta
	if start_timer < START_INTERVAL:
		start_timer += delta
		if start_timer >= START_INTERVAL:
			try_spawn_gem_cluster()
		return
	if drop_timer <= DROP_INTERVAL:
		return
	#handle game physics
	if drop_gems():
		destroy_all_gem_lines()
		drop_timer = 0
		return
	if gems_are_moving():
		return
	if !current_gem_cluster:
		try_spawn_gem_cluster()
	#handle controls
	if Input.is_action_pressed("move_down"):
		fall_timer += delta * 8
	if Input.is_action_just_pressed("rotate_left") or Input.is_action_just_pressed("ui_accept"):
		rotate_gem(1)
	if Input.is_action_just_pressed("rotate_right"):
		rotate_gem(-1)
	if input_timer >= INPUT_INTERVAL:
		input_timer = 0
		if Input.is_action_pressed("move_left"):
			move_gem(Vector2.LEFT)
		elif Input.is_action_pressed("move_right"):
			move_gem(Vector2.RIGHT)
	#handle falling
	if fall_timer >= FALL_INTERVAL:
		fall_timer = 0
		if !move_gem(Vector2.DOWN):
			lock_gem_cluster()
			if combo_length > 1:
				damage_enemy(clamp(combo_length - 1, 0, current_enemy.max_hp))
				combo_length = 0
			enemy_turn()

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
# gems
########################################################

func create_rune(spawn_position: Vector2i) -> void:
	if is_colliding(spawn_position):
		return
	var rune = gem_scene.instantiate()
	var keys = rune_options.keys()
	var color = keys[next_color_index % keys.size()]
	next_color_index += 1
	rune.connected_gem = rune
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
	gem.target_position = center_in_cell(Vector2i(gem.board_x, 0))
	board[x][y] = gem
	gem.add_to_group("gems")
	$Gems.add_child(gem)
	return gem

func copy_preview_gem(parent_gem: Node2D) -> Node2D:
	var gem = gem_scene.instantiate()
	while (!color_options.has(parent_gem.gem_color)):
		set_gem_color(parent_gem, get_random_color(), color_options)
	set_gem_color(gem, parent_gem.gem_color, color_options)
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
	gem1.connected_gem = gem2
	gem2.connected_gem = gem1
	current_gem_cluster_position = spawn_position
	current_gem_cluster_offsets = [Vector2i(0, 0), Vector2i(1, 0)]
	randomize_preview_gems()
	update_gem_world_position()

func try_spawn_gem_cluster() -> void:
	fall_timer = 0
	var spawn_location = Vector2i(WIDTH / 2 - 1, 0)
	if is_colliding(spawn_location):
		#GAME OVER
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
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

var ROTATIONS: Array = [
	[Vector2i(0,0), Vector2i(1,0)],  # horizontal (right)
	[Vector2i(0,1), Vector2i(0,0)],  # vertical (down)
	[Vector2i(1,0), Vector2i(0,0)],  # horizontal (left)  (this arrangement matches your prior mapping)
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
	destroy_all_gem_lines()

func drop_enemy_gem(count: int = 1) -> void:
	flash_portrait(portrait_player)
	shake_portrait(portrait_player)
	for i in range(count):
		var x
		var y = 0
		var safe_location = false
		var attempts = 0
		while (!safe_location):
			attempts += 1
			if (attempts > 50):
				return
			x = randi() % WIDTH
			if board[x][y] or is_colliding(Vector2i(x, y)):
				continue
			if board[x][y + 2] and board[x][y + 2].is_in_group("bricks"):
				continue
			safe_location = true
		var gem = create_gem(x, y, get_random_color())
		gem.target_position = gem.position
		gem.position = center_in_cell(Vector2i(WIDTH + 2, HEIGHT - 1))
		gem.move_speed = 5
	drop_gems()

func drop_gems() -> bool:
	var moved = false
	for x in range(WIDTH):
		for y in range(HEIGHT - 2, -1, -1):
			var gem = board[x][y]
			if gem == null or !gem.is_in_group("gems"):
				continue
			if y + 1 >= HEIGHT or board[x][y + 1] != null:
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
			moved = true
	return moved

func gems_are_moving() -> bool:
	for gem in $Gems.get_children():
		if gem and gem.position.distance_to(gem.target_position) > 0.1:
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

func destroy_gem(gem: Sprite2D) -> void:
	gem.texture = load(PARTICLES[gem.gem_color])
	gem.pulsate = true
	await get_tree().create_timer(0.75).timeout
	gem.queue_free()

########################################################
# misc
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

func remove_unused_colors() -> void:
	if $Runes.get_child_count() == 0:
		return
	var remaining = {}
	for r in $Runes.get_children():
		if r.gem_color:
			remaining[r.gem_color] = true
	for color in color_options.keys():
		if not remaining.has(color):
			color_options.erase(color)
			rune_options.erase(color)
			for gem in $Gems.get_children():
				if gem.gem_color == color:
					destroy_gem(gem)
			randomize_preview_gems()

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

func get_random_color() -> String: return color_options.keys()[randi() % color_options.size()]
func get_random_rune() -> String: return rune_options.keys()[randi() % rune_options.size()]

func center_in_cell(cell_position: Vector2i) -> Vector2:
	@warning_ignore("integer_division")
	var location = (cell_position * TILE_SIZE) + Vector2i(TILE_SIZE/2, TILE_SIZE + 1)
	return location - Vector2i(WIDTH * TILE_SIZE / 2, HEIGHT * TILE_SIZE / 2)

func update_gem_world_position() -> void:
	if !current_gem_cluster:
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
	var gems_to_destroy = []
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var gem = board[x][y]
			if !gem or !gem.is_in_group("gems"):
				continue
			var start_pos = Vector2i(x, y)
			for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0)]:
				var line = get_gem_line(start_pos, dir)
				if line.size() > 3:
					combo_length += 1
					for pos in line:
						if not gems_to_destroy.has(pos):
							gems_to_destroy.append(pos)
	return gems_to_destroy

func destroy_all_gem_lines() -> void:
	var gems_to_destroy = get_all_gem_lines()
	for pos in gems_to_destroy:
		var gem = board[pos.x][pos.y]
		if !gem.is_in_group("gems"):
			continue
		if gem:
			destroy_gem(gem)
			board[pos.x][pos.y] = null

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

func enemy_turn() -> void:
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
